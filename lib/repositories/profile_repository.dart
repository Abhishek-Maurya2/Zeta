import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/profile_dao.dart';
import '../database/database_provider.dart';
import '../services/profile_cache_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';

/// Local-first repository coordinating SQLite profile state with Supabase.
class ProfileRepository {
  final ProfileDao _profileDao;
  final ProfileService _remote;
  final SupabaseService _supabase;
  final AvatarCacheService _avatarCache;

  ProfileRepository({
    ProfileDao? profileDao,
    ProfileService? profileService,
    SupabaseService? supabase,
    AvatarCacheService? avatarCache,
  }) : _profileDao = profileDao ?? DatabaseProvider.instance.profileDao,
       _remote = profileService ?? ProfileService(supabase: supabase),
       _supabase = supabase ?? SupabaseService(),
       _avatarCache = avatarCache ?? AvatarCacheService.instance;

  String get _safeUserId {
    try {
      return _supabase.effectiveUserId;
    } catch (_) {
      return 'singleton';
    }
  }

  /// Synchronously returns cached profile fields (name, email, avatar).
  Map<String, String?> getCachedProfile({String? userId}) {
    final id = userId ?? _safeUserId;
    return _avatarCache.getCachedProfile(id);
  }

  Future<Map<String, dynamic>?> getLocalProfile({String? userId}) async {
    final id = userId ?? _safeUserId;
    final row = await _profileDao.getProfile(id);
    if (row == null) {
      final cached = _avatarCache.getCachedProfile(id);
      if (cached.values.any((v) => v != null && v.isNotEmpty)) {
        return {
          'display_name': cached['display_name'] ?? '',
          'email': cached['email'] ?? '',
          'avatar_image': cached['avatar_image'],
        };
      }
      return null;
    }
    var avatar = row.avatarImage;
    final localCached = await _avatarCache.getLocalAvatar(id);
    if (localCached != null) {
      avatar = localCached;
    }
    final displayName = row.displayName.isNotEmpty
        ? row.displayName
        : (_avatarCache.getCachedName(id) ?? '');
    final email = (_supabase.currentUser?.email ?? row.email).isNotEmpty
        ? (_supabase.currentUser?.email ?? row.email)
        : (_avatarCache.getCachedEmail(id) ?? '');

    // Keep cache fresh
    await _avatarCache.setCachedName(id, displayName);
    await _avatarCache.setCachedEmail(id, email);

    return {
      'display_name': displayName,
      'email': email,
      'avatar_image': avatar,
    };
  }

  /// Saves an avatar locally to disk immediately and returns the local file path.
  Future<String> saveAvatarLocally({
    String? userId,
    required Uint8List bytes,
    String extension = 'png',
  }) async {
    final id = userId ?? _safeUserId;
    return _avatarCache.saveAvatarLocally(
      userId: id,
      bytes: bytes,
      extension: extension,
    );
  }

  /// Clears local cached avatar files for [userId].
  Future<void> clearAvatarLocally({String? userId}) async {
    final id = userId ?? _safeUserId;
    await _avatarCache.clearLocalAvatar(id);
  }

  /// Saves a profile snapshot locally and leaves it pending until cloud sync.
  Future<void> saveLocalProfile({
    String? userId,
    required String displayName,
    required String email,
    String? avatarImage,
  }) async {
    final id = userId ?? _safeUserId;
    await _avatarCache.setCachedName(id, displayName);
    await _avatarCache.setCachedEmail(id, email);
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
      return getLocalProfile(userId: id);
    }

    final remote = await _remote.fetchProfile(id);
    if (remote == null) {
      await _pushLocalProfile(local);
      return getLocalProfile(userId: id);
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

    // Check if cloud profile (name, email, avatar) has been updated/changed on another device
    final remoteAvatar = remote['avatar_image'] as String?;
    final remoteName = remote['display_name'] as String? ?? '';
    final remoteEmail =
        _supabase.currentUser?.email ?? remote['email'] as String? ?? '';

    final localAvatar = await _avatarCache.syncAvatarFromRemote(
      userId: id,
      remoteAvatarUrl: remoteAvatar,
    );
    final nameChanged =
        remoteName.isNotEmpty && remoteName != local.displayName;
    final emailChanged = remoteEmail.isNotEmpty && remoteEmail != local.email;
    final avatarChanged = localAvatar != local.avatarImage;

    if (nameChanged || emailChanged || avatarChanged) {
      final effectiveName = nameChanged ? remoteName : local.displayName;
      final effectiveEmail = emailChanged ? remoteEmail : local.email;
      await _avatarCache.setCachedName(id, effectiveName);
      await _avatarCache.setCachedEmail(id, effectiveEmail);
      await _profileDao.upsertProfile(
        id: id,
        displayName: effectiveName,
        email: effectiveEmail,
        avatarImage: localAvatar,
        updatedAt: local.updatedAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(
                local.updatedAtMs!,
                isUtc: true,
              )
            : DateTime.now().toUtc(),
        lastSyncedAt: local.lastSyncedAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(
                local.lastSyncedAtMs!,
                isUtc: true,
              )
            : DateTime.now().toUtc(),
      );
    }

    return getLocalProfile(userId: id);
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
    await _avatarCache.setCachedName(userId, name.trim());
    await _avatarCache.setCachedEmail(userId, email.trim());
    String? localAvatar;
    if (avatarBytes != null && avatarBytes.isNotEmpty) {
      localAvatar = await _avatarCache.saveAvatarLocally(
        userId: userId,
        bytes: avatarBytes,
        extension: avatarExtension,
      );
    }
    await saveLocalProfile(
      userId: userId,
      displayName: name.trim(),
      email: email.trim(),
      avatarImage: localAvatar,
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
    final localAvatar = local.avatarImage;
    var remoteAvatarUrl = localAvatar;
    final shouldRemoveAvatar = localAvatar == null;

    if (localAvatar != null && !localAvatar.startsWith('http')) {
      Uint8List bytes;
      String extension = 'png';
      if (_isDataUri(localAvatar)) {
        final parsed = _parseDataUri(localAvatar);
        bytes = parsed.bytes;
        extension = parsed.extension;
      } else if (!kIsWeb && File(localAvatar).existsSync()) {
        final file = File(localAvatar);
        bytes = await file.readAsBytes();
        extension = file.path.split('.').last.toLowerCase();
      } else {
        bytes = Uint8List(0);
      }

      if (bytes.isNotEmpty) {
        remoteAvatarUrl = await _remote.uploadAvatar(
          userId: local.id,
          bytes: bytes,
          extension: extension,
          cacheVersion: updatedAt.millisecondsSinceEpoch.toString(),
        );
        await _avatarCache.setCachedRemoteUrl(local.id, remoteAvatarUrl);
      }
    }

    await _remote.saveProfile({
      'id': local.id,
      'display_name': local.displayName,
      'email': _supabase.currentUser?.email ?? local.email,
      'avatar_image': remoteAvatarUrl,
      'updated_at': updatedAt.toIso8601String(),
    });
    if (shouldRemoveAvatar) {
      await _remote.removeAvatar(local.id);
      await _avatarCache.clearLocalAvatar(local.id);
    }

    await _profileDao.markSynced(
      id: local.id,
      expectedUpdatedAt: updatedAt,
      syncedAt: DateTime.now().toUtc(),
      avatarImage: localAvatar,
    );
  }

  Future<void> _saveRemoteLocally(
    String id,
    Map<String, dynamic> remote, [
    DateTime? updatedAt,
  ]) async {
    final syncedAt = DateTime.now().toUtc();
    final remoteAvatar = remote['avatar_image'] as String?;
    final remoteName = remote['display_name'] as String? ?? '';
    final remoteEmail =
        _supabase.currentUser?.email ?? remote['email'] as String? ?? '';

    final localAvatar = await _avatarCache.syncAvatarFromRemote(
      userId: id,
      remoteAvatarUrl: remoteAvatar,
    );
    await _avatarCache.setCachedName(id, remoteName);
    await _avatarCache.setCachedEmail(id, remoteEmail);

    final hasLegacyInlineAvatar =
        remoteAvatar != null && _isDataUri(remoteAvatar);
    await _profileDao.upsertProfile(
      id: id,
      displayName: remoteName,
      email: remoteEmail,
      avatarImage: localAvatar,
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

  bool _isDataUri(String value) => value.startsWith('data:image/');

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
