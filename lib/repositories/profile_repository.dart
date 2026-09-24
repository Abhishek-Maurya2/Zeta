import 'dart:convert';
import 'dart:typed_data';

import '../database/app_database.dart';
import '../database/daos/profile_dao.dart';
import '../database/database_provider.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';

/// Local-first repository coordinating SQLite profile state with Supabase.
class ProfileRepository {
  final ProfileDao _profileDao;
  final ProfileService _remote;
  final SupabaseService _supabase;

  ProfileRepository({
    ProfileDao? profileDao,
    ProfileService? profileService,
    SupabaseService? supabase,
  }) : _profileDao = profileDao ?? DatabaseProvider.instance.profileDao,
       _remote = profileService ?? ProfileService(supabase: supabase),
       _supabase = supabase ?? SupabaseService();

  Future<Map<String, dynamic>?> getLocalProfile({String? userId}) async {
    final id = userId ?? _supabase.effectiveUserId;
    final row = await _profileDao.getProfile(id);
    return row == null ? null : _toMap(row);
  }

  /// Saves a profile snapshot locally and leaves it pending until cloud sync.
  Future<void> saveLocalProfile({
    String? userId,
    required String displayName,
    required String email,
    String? avatarImage,
  }) async {
    final id = userId ?? _supabase.effectiveUserId;
    await _profileDao.upsertProfile(
      id: id,
      displayName: displayName,
      email: email,
      avatarImage: avatarImage,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Pushes pending local profile data, otherwise pulls the remote snapshot.
  Future<Map<String, dynamic>?> syncProfileFromCloud({String? userId}) async {
    final id = userId ?? _supabase.effectiveUserId;
    var local = await _profileDao.getProfile(id);

    if (local == null) {
      final remote = await _remote.fetchProfile(id);
      if (remote != null) {
        await _saveRemoteLocally(id, remote);
        return getLocalProfile(userId: id);
      }

      final authUser = _supabase.currentUser;
      await _profileDao.upsertProfile(
        id: id,
        displayName: authUser?.userMetadata?['display_name'] as String? ?? '',
        email: authUser?.email ?? '',
        updatedAt: DateTime.now().toUtc(),
      );
      local = await _profileDao.getProfile(id);
    }

    if (local == null) return null;
    if (_isPending(local)) {
      final remote = await _remote.fetchProfile(id);
      final remoteUpdatedAt = DateTime.tryParse(
        remote?['updated_at'] as String? ?? '',
      );
      if (remote != null &&
          remoteUpdatedAt != null &&
          local.updatedAtMs != null &&
          remoteUpdatedAt.millisecondsSinceEpoch > local.updatedAtMs!) {
        await _saveRemoteLocally(id, remote, remoteUpdatedAt);
        return getLocalProfile(userId: id);
      }
      await _pushLocalProfile(local);
      final saved = await _profileDao.getProfile(id);
      return saved == null ? null : _toMap(saved);
    }

    final remote = await _remote.fetchProfile(id);
    if (remote == null) {
      await _pushLocalProfile(local);
      final saved = await _profileDao.getProfile(id);
      return saved == null ? null : _toMap(saved);
    }

    final remoteUpdatedAt = DateTime.tryParse(
      remote['updated_at'] as String? ?? '',
    );
    if (remoteUpdatedAt != null &&
        local.updatedAtMs != null &&
        remoteUpdatedAt.millisecondsSinceEpoch > local.updatedAtMs!) {
      await _saveRemoteLocally(id, remote, remoteUpdatedAt);
      return getLocalProfile(userId: id);
    }
    return _toMap(local);
  }

  /// Persists signup details before attempting cloud writes, so a temporary
  /// profile/Storage failure can be retried after the account is activated.
  Future<void> initializeAccountProfile({
    required String userId,
    required String name,
    required String email,
    Uint8List? avatarBytes,
    String avatarExtension = 'jpg',
  }) async {
    final avatar = avatarBytes == null
        ? null
        : _asDataUri(avatarBytes, avatarExtension);
    await saveLocalProfile(
      userId: userId,
      displayName: name.trim(),
      email: email.trim(),
      avatarImage: avatar,
    );
    try {
      await syncProfileFromCloud(userId: userId);
    } catch (_) {
      // The profile remains in SQLite as a pending local write.
    }
  }

  Future<void> _pushLocalProfile(ProfilesTableData local) async {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      local.updatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
      isUtc: true,
    );
    var avatarImage = local.avatarImage;
    final shouldRemoveAvatar = avatarImage == null;
    if (avatarImage != null && _isDataUri(avatarImage)) {
      final parsed = _parseDataUri(avatarImage);
      avatarImage = await _remote.uploadAvatar(
        userId: local.id,
        bytes: parsed.bytes,
        extension: parsed.extension,
        cacheVersion: updatedAt.millisecondsSinceEpoch.toString(),
      );
    }

    await _remote.saveProfile({
      'id': local.id,
      'display_name': local.displayName,
      'email': _supabase.currentUser?.email ?? local.email,
      'avatar_image': avatarImage,
      'updated_at': updatedAt.toIso8601String(),
    });
    if (shouldRemoveAvatar) await _remote.removeAvatar(local.id);

    await _profileDao.markSynced(
      id: local.id,
      expectedUpdatedAt: updatedAt,
      syncedAt: DateTime.now().toUtc(),
      avatarImage: avatarImage,
    );
  }

  Future<void> _saveRemoteLocally(
    String id,
    Map<String, dynamic> remote, [
    DateTime? updatedAt,
  ]) async {
    final syncedAt = DateTime.now().toUtc();
    final remoteAvatar = remote['avatar_image'] as String?;
    final hasLegacyInlineAvatar =
        remoteAvatar != null && _isDataUri(remoteAvatar);
    await _profileDao.upsertProfile(
      id: id,
      displayName: remote['display_name'] as String? ?? '',
      email: _supabase.currentUser?.email ?? remote['email'] as String? ?? '',
      avatarImage: remoteAvatar,
      updatedAt: updatedAt ?? syncedAt,
      lastSyncedAt: hasLegacyInlineAvatar ? null : syncedAt,
    );
    if (hasLegacyInlineAvatar) {
      final local = await _profileDao.getProfile(id);
      if (local != null) await _pushLocalProfile(local);
    }
  }

  Future<void> claimLegacyWorkspace() async {
    await _supabase.client.rpc('claim_legacy_workspace');
  }

  bool _isPending(ProfilesTableData profile) =>
      profile.lastSyncedAtMs == null ||
      (profile.updatedAtMs ?? 0) > profile.lastSyncedAtMs!;

  Map<String, dynamic> _toMap(ProfilesTableData row) => {
    'display_name': row.displayName,
    'email': _supabase.currentUser?.email ?? row.email,
    'avatar_image': row.avatarImage,
  };

  bool _isDataUri(String value) => value.startsWith('data:image/');

  String _asDataUri(Uint8List bytes, String extension) {
    final contentType = switch (extension.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };
    return 'data:$contentType;base64,${base64Encode(bytes)}';
  }

  ({Uint8List bytes, String extension}) _parseDataUri(String value) {
    final header = value.substring(0, value.indexOf(','));
    final mime = RegExp(r'^data:image/([^;]+);base64$').firstMatch(header);
    final extension = switch (mime?.group(1)?.toLowerCase()) {
      'jpeg' => 'jpg',
      'jpg' || 'png' || 'webp' || 'gif' => mime!.group(1)!.toLowerCase(),
      _ => 'png',
    };
    return (
      bytes: base64Decode(value.substring(value.indexOf(',') + 1)),
      extension: extension,
    );
  }
}
