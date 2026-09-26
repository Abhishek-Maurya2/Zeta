import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'preferences_service.dart';

/// Local disk and memory caching service for user profile data (name, email, avatar).
///
/// Ensures profile details and avatar images are loaded instantly on startup
/// from device storage without network roundtrips, and only downloaded from the
/// cloud when the remote data has actually changed or been updated.
class ProfileCacheService {
  ProfileCacheService._();
  static final ProfileCacheService instance = ProfileCacheService._();

  static const String _prefPrefixName = 'zeta_profile_name_';
  static const String _prefPrefixEmail = 'zeta_profile_email_';
  static const String _prefPrefixRemoteUrl = 'zeta_avatar_remote_url_';
  static const String _prefPrefixBase64 = 'zeta_avatar_web_base64_';

  Directory? _avatarDir;
  Directory? customAvatarDir;

  Future<Directory?> _getAvatarDirectory() async {
    if (kIsWeb) return null;
    if (customAvatarDir != null) return customAvatarDir;
    if (_avatarDir != null) return _avatarDir;
    try {
      final baseDir = await getApplicationSupportDirectory();
      final dir = Directory(
        '${baseDir.path}${Platform.pathSeparator}zeta_avatars',
      );
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      _avatarDir = dir;
      return dir;
    } catch (_) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final dir = Directory(
          '${docDir.path}${Platform.pathSeparator}zeta_avatars',
        );
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
        _avatarDir = dir;
        return dir;
      } catch (_) {
        try {
          final tempDir = Directory.systemTemp;
          final dir = Directory(
            '${tempDir.path}${Platform.pathSeparator}zeta_avatars',
          );
          if (!dir.existsSync()) {
            await dir.create(recursive: true);
          }
          _avatarDir = dir;
          return dir;
        } catch (_) {
          return null;
        }
      }
    }
  }

  /// Synchronously returns any locally cached profile fields for [userId].
  Map<String, String?> getCachedProfile(String userId) {
    return {
      'display_name': getCachedName(userId),
      'email': getCachedEmail(userId),
      'avatar_image': getCachedAvatarPath(userId),
    };
  }

  /// Returns cached user display name.
  String? getCachedName(String userId) {
    return _getPrefString('$_prefPrefixName$userId');
  }

  /// Caches user display name locally.
  Future<void> setCachedName(String userId, String? name) async {
    if (name == null || name.trim().isEmpty) {
      await _removePref('$_prefPrefixName$userId');
    } else {
      await _setPrefString('$_prefPrefixName$userId', name.trim());
    }
  }

  /// Returns cached user email.
  String? getCachedEmail(String userId) {
    return _getPrefString('$_prefPrefixEmail$userId');
  }

  /// Caches user email locally.
  Future<void> setCachedEmail(String userId, String? email) async {
    if (email == null || email.trim().isEmpty) {
      await _removePref('$_prefPrefixEmail$userId');
    } else {
      await _setPrefString('$_prefPrefixEmail$userId', email.trim());
    }
  }

  /// Synchronously returns the cached local avatar path or web base64.
  String? getCachedAvatarPath(String userId) {
    if (kIsWeb) {
      return _getPrefString('$_prefPrefixBase64$userId');
    }
    if (_avatarDir != null) {
      for (final ext in ['png', 'jpg', 'jpeg', 'webp', 'gif']) {
        final file = File(
          '${_avatarDir!.path}${Platform.pathSeparator}avatar_$userId.$ext',
        );
        if (file.existsSync()) {
          return file.path;
        }
      }
    }
    return null;
  }

  /// Returns the local file path (or base64 data URI on Web) if cached on device.
  Future<String?> getLocalAvatar(String userId) async {
    if (kIsWeb) {
      return _getPrefString('$_prefPrefixBase64$userId');
    }
    final dir = await _getAvatarDirectory();
    if (dir == null) return null;

    for (final ext in ['png', 'jpg', 'jpeg', 'webp', 'gif']) {
      final file = File(
        '${dir.path}${Platform.pathSeparator}avatar_$userId.$ext',
      );
      if (file.existsSync()) {
        return file.path;
      }
    }
    return null;
  }

  /// Saves raw image bytes to local device storage and returns local path/URI.
  Future<String> saveAvatarLocally({
    required String userId,
    required Uint8List bytes,
    String extension = 'png',
  }) async {
    final cleanExt = extension.toLowerCase().replaceAll('.', '');
    if (kIsWeb) {
      final mime = cleanExt == 'jpg' || cleanExt == 'jpeg' ? 'jpeg' : cleanExt;
      final dataUri = 'data:image/$mime;base64,${base64Encode(bytes)}';
      await _setPrefString('$_prefPrefixBase64$userId', dataUri);
      return dataUri;
    }

    final dir = await _getAvatarDirectory();
    if (dir == null) {
      return 'data:image/$cleanExt;base64,${base64Encode(bytes)}';
    }

    // Clean up any old files with different extensions for this user
    for (final ext in ['png', 'jpg', 'jpeg', 'webp', 'gif']) {
      final oldFile = File(
        '${dir.path}${Platform.pathSeparator}avatar_$userId.$ext',
      );
      if (oldFile.existsSync()) {
        try {
          oldFile.deleteSync();
        } catch (_) {}
      }
    }

    final targetFile = File(
      '${dir.path}${Platform.pathSeparator}avatar_$userId.$cleanExt',
    );
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile.path;
  }

  /// Returns the cached remote URL for [userId] (to check if cloud has a newer version).
  String? getCachedRemoteUrl(String userId) {
    return _getPrefString('$_prefPrefixRemoteUrl$userId');
  }

  /// Records the cloud URL that corresponds to the locally stored avatar image.
  Future<void> setCachedRemoteUrl(String userId, String? url) async {
    if (url == null || url.isEmpty) {
      await _removePref('$_prefPrefixRemoteUrl$userId');
    } else {
      await _setPrefString('$_prefPrefixRemoteUrl$userId', url);
    }
  }

  /// Synchronizes local storage with [remoteAvatarUrl]:
  /// 1. If [remoteAvatarUrl] is null -> clear local avatar.
  /// 2. If [remoteAvatarUrl] equals cached URL and local file exists -> DO NOT FETCH (return local).
  /// 3. If [remoteAvatarUrl] is new/changed -> download from cloud, save locally, update cache.
  Future<String?> syncAvatarFromRemote({
    required String userId,
    required String? remoteAvatarUrl,
  }) async {
    if (remoteAvatarUrl == null || remoteAvatarUrl.isEmpty) {
      await clearLocalAvatar(userId);
      return null;
    }

    // If it's an inline data URI (legacy), save bytes locally
    if (remoteAvatarUrl.startsWith('data:image/')) {
      final base64Str = remoteAvatarUrl.split(',').last;
      final bytes = base64Decode(base64Str.trim());
      final path = await saveAvatarLocally(userId: userId, bytes: bytes);
      return path;
    }

    final cachedUrl = getCachedRemoteUrl(userId);
    final localPath = await getLocalAvatar(userId);

    // If the remote URL has not changed AND we already have the local file on disk:
    // DO NOT fetch from cloud. Use the device-stored image!
    if (cachedUrl != null && cachedUrl == remoteAvatarUrl && localPath != null) {
      return localPath;
    }

    // Cloud image is new, modified, or not yet stored locally:
    try {
      final response = await http.get(Uri.parse(remoteAvatarUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final ext = _extensionFromUrl(remoteAvatarUrl);
        final newLocalPath = await saveAvatarLocally(
          userId: userId,
          bytes: response.bodyBytes,
          extension: ext,
        );
        await setCachedRemoteUrl(userId, remoteAvatarUrl);
        return newLocalPath;
      }
    } catch (_) {
      // Offline / network failure: keep existing local file if available
      if (localPath != null) return localPath;
    }

    return localPath ?? remoteAvatarUrl;
  }

  /// Removes local cached avatar files and preferences.
  Future<void> clearLocalAvatar(String userId) async {
    await _removePref('$_prefPrefixRemoteUrl$userId');
    await _removePref('$_prefPrefixBase64$userId');
    if (!kIsWeb) {
      final dir = await _getAvatarDirectory();
      if (dir != null) {
        for (final ext in ['png', 'jpg', 'jpeg', 'webp', 'gif']) {
          final file = File(
            '${dir.path}${Platform.pathSeparator}avatar_$userId.$ext',
          );
          if (file.existsSync()) {
            try {
              file.deleteSync();
            } catch (_) {}
          }
        }
      }
    }
  }

  /// Clears all local profile cache for [userId] (name, email, avatar).
  Future<void> clearProfileCache(String userId) async {
    await clearLocalAvatar(userId);
    await _removePref('$_prefPrefixName$userId');
    await _removePref('$_prefPrefixEmail$userId');
  }

  String _extensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'gif']) {
        if (path.endsWith('.$ext')) return ext == 'jpeg' ? 'jpg' : ext;
      }
    } catch (_) {}
    return 'png';
  }

  String? _getPrefString(String key) {
    try {
      return PreferencesService.instance.prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setPrefString(String key, String value) async {
    try {
      await PreferencesService.instance.prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _removePref(String key) async {
    try {
      await PreferencesService.instance.prefs.remove(key);
    } catch (_) {}
  }
}

/// Backwards compatible alias.
typedef AvatarCacheService = ProfileCacheService;
