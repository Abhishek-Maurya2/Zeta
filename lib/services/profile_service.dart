import 'package:flutter/widgets.dart';
import 'supabase_service.dart';

/// Service managing user profile persistence with the Supabase `public.profiles` table.
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseService _supabase = SupabaseService();

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

  /// Fetches the profile from the `public.profiles` table.
  Future<Map<String, dynamic>?> fetchProfile() async {
    if (inTestEnvironment) {
      return mockProfileData;
    }
    try {
      if (!_supabase.isInitialized) await _supabase.init();
      final userId = _supabase.effectiveUserId;
      final response = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('ProfileService: Fetched profile for $userId');
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('ProfileService: fetchProfile failed: $e');
      return null;
    }
  }

  /// Upserts user profile information (display_name, email, avatar_image) in the database.
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
    try {
      if (!_supabase.isInitialized) await _supabase.init();
      final userId = _supabase.effectiveUserId;
      final payload = <String, dynamic>{
        'id': userId,
        'display_name': displayName,
        'email': email,
        'avatar_image': avatarImage,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _supabase.client.from('profiles').upsert(payload);
      debugPrint('ProfileService: Saved profile to DB successfully.');
      return true;
    } catch (e) {
      debugPrint('ProfileService: saveProfile failed: $e');
      return false;
    }
  }
}
