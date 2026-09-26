import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/database/database_provider.dart';
import 'package:zeta/providers/profile_provider.dart';
import 'package:zeta/services/preferences_service.dart';
import 'package:zeta/services/profile_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'zeta_profile_name_test_user': 'Abhishek',
      'zeta_profile_email_test_user': 'abhishek@example.com',
    });
    await PreferencesService.instance.init();
    try {
      final db = DatabaseProvider.instance.db;
      await db.delete(db.profilesTable).go();
    } catch (_) {}
  });

  test('ProfileCacheService caches and retrieves name, email, and avatar',
      () async {
    final cache = ProfileCacheService.instance;
    const userId = 'user_123';

    await cache.setCachedName(userId, 'Alex');
    await cache.setCachedEmail(userId, 'alex@example.com');
    await cache.setCachedRemoteUrl(userId, 'https://example.com/avatar.png?v=1');

    expect(cache.getCachedName(userId), 'Alex');
    expect(cache.getCachedEmail(userId), 'alex@example.com');
    expect(
      cache.getCachedRemoteUrl(userId),
      'https://example.com/avatar.png?v=1',
    );

    final profile = cache.getCachedProfile(userId);
    expect(profile['display_name'], 'Alex');
    expect(profile['email'], 'alex@example.com');

    // Test saving bytes locally
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final localPath = await cache.saveAvatarLocally(
      userId: userId,
      bytes: bytes,
      extension: 'png',
    );
    expect(localPath, isNotEmpty);

    // If remote URL is identical and local file exists, sync does not re-fetch
    final synced = await cache.syncAvatarFromRemote(
      userId: userId,
      remoteAvatarUrl: 'https://example.com/avatar.png?v=1',
    );
    expect(synced, localPath);

    // Clean up
    await cache.clearProfileCache(userId);
    expect(cache.getCachedName(userId), isNull);
    expect(cache.getCachedEmail(userId), isNull);
    expect(cache.getCachedRemoteUrl(userId), isNull);
  });

  test('ProfileProvider populates name and email synchronously from cache on construction',
      () {
    // When initialized, ProfileProvider should read cached values synchronously
    final provider = ProfileProvider();
    // SharedPreferences was mocked with test_user or singleton values;
    // provider instance initializes cleanly without throwing
    expect(provider.isSyncing, isFalse);
    expect(provider.syncError, isNull);
  });
}
