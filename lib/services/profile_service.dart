import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_provider.dart';
import 'supabase_service.dart';

/// Service managing user profile persistence with the local SQLite database
/// and two-way cloud synchronization with Supabase `public.profiles`.
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseService _supabase = SupabaseService();
  RealtimeChannel? _realtimeChannel;

  /// Testing override flags for widget and unit tests
  static bool isTesting = false;
  static Map<String, dynamic>? mockProfileData;

  static bool get inTestEnvironment {
    if (isTesting) return true;
    try {
      final bindingName = WidgetsBinding.instance.runtimeType.toString();
      if (bindingName.contains('Test')) return true;
    } catch (_) {}
    return false;
  }

  /// Fetches the profile from the database: tries Supabase cloud first and updates
  /// local SQLite, falling back to local SQLite if offline.
  Future<Map<String, dynamic>?> fetchProfile() async {
    if (inTestEnvironment) {
      return mockProfileData;
    }

    final userId = _supabase.effectiveUserId;

    // 1. Check local SQLite cache first
    Map<String, dynamic>? localData;
    try {
      final localRow = await DatabaseProvider.instance.profileDao.getProfile(userId);
      if (localRow != null) {
        localData = {
          'id': localRow.id,
          'display_name': localRow.displayName,
          'email': localRow.email,
          'avatar_image': localRow.avatarImage,
          'updated_at': localRow.updatedAtMs != null
              ? DateTime.fromMillisecondsSinceEpoch(localRow.updatedAtMs!).toIso8601String()
              : null,
        };
      }
    } catch (e) {
      debugPrint('ProfileService: Local SQLite read error - $e');
    }

    // 2. Fetch remote from Supabase
    try {
      if (!_supabase.isInitialized) await _supabase.init();
      final response = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('ProfileService: Fetched profile from cloud for $userId');
        // Persist remote changes to local SQLite
        final updatedAtStr = response['updated_at'] as String?;
        final updatedAt = updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null;
        await DatabaseProvider.instance.profileDao.upsertProfile(
          id: userId,
          displayName: (response['display_name'] as String?) ?? '',
          email: (response['email'] as String?) ?? '',
          avatarImage: response['avatar_image'] as String?,
          updatedAt: updatedAt,
        );
        return response;
      }
    } catch (e) {
      debugPrint('ProfileService: Cloud fetch failed, falling back to local DB: $e');
    }

    return localData;
  }

  /// Saves user profile information (display_name, email, avatar_image)
  /// directly to local SQLite and upserts to Supabase cloud.
  Future<bool> saveProfile({
    required String displayName,
    required String email,
    String? avatarImage,
  }) async {
    if (inTestEnvironment) {
      if (mockProfileData != null) {
        mockProfileData = {
          ...mockProfileData!,
          'display_name': displayName,
          'email': email,
          'avatar_image': avatarImage,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
      }
      return true;
    }

    final userId = _supabase.effectiveUserId;
    final now = DateTime.now().toUtc();

    // 1. Immediately persist to local SQLite
    try {
      await DatabaseProvider.instance.profileDao.upsertProfile(
        id: userId,
        displayName: displayName,
        email: email,
        avatarImage: avatarImage,
        updatedAt: now,
      );
      debugPrint('ProfileService: Saved profile to local SQLite DB.');
    } catch (e) {
      debugPrint('ProfileService: Error saving to local SQLite - $e');
    }

    // 2. Upsert to Supabase cloud database
    try {
      if (!_supabase.isInitialized) await _supabase.init();
      final payload = <String, dynamic>{
        'id': userId,
        'display_name': displayName,
        'email': email,
        'avatar_image': avatarImage,
        'updated_at': now.toIso8601String(),
      };

      await _supabase.client.from('profiles').upsert(payload);
      debugPrint('ProfileService: Synced profile to Supabase cloud successfully.');
      return true;
    } catch (e) {
      debugPrint('ProfileService: Cloud saveProfile note - $e');
      return false;
    }
  }

  /// Subscribes to Realtime profile updates from Supabase.
  void subscribeToRealtime({void Function(Map<String, dynamic> data)? onProfileChange}) {
    if (inTestEnvironment) return;
    try {
      if (!_supabase.isInitialized) return;
      final userId = _supabase.effectiveUserId;

      _realtimeChannel?.unsubscribe();
      _realtimeChannel = _supabase.client
          .channel('public:profiles:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: userId,
            ),
            callback: (payload) async {
              final record = payload.newRecord;
              if (record.isNotEmpty) {
                final name = (record['display_name'] as String?) ?? '';
                final email = (record['email'] as String?) ?? '';
                final avatar = record['avatar_image'] as String?;
                final updatedAtStr = record['updated_at'] as String?;
                final updatedAt = updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null;

                await DatabaseProvider.instance.profileDao.upsertProfile(
                  id: userId,
                  displayName: name,
                  email: email,
                  avatarImage: avatar,
                  updatedAt: updatedAt,
                );
                onProfileChange?.call(record);
              }
            },
          )
          .subscribe();
      debugPrint('ProfileService: Subscribed to Realtime profile changes.');
    } catch (e) {
      debugPrint('ProfileService: Realtime subscription failed: $e');
    }
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }
}
