import '../database/daos/profile_dao.dart';
import '../database/database_provider.dart';
import '../services/profile_service.dart';
import '../utils/app_logger.dart';

/// Repository coordinating local SQLite profile cache with Supabase profiles table.
class ProfileRepository {
  final ProfileDao _profileDao;
  final ProfileService _profileService;

  ProfileRepository({
    ProfileDao? profileDao,
    ProfileService? profileService,
  })  : _profileDao = profileDao ?? DatabaseProvider.instance.profileDao,
        _profileService = profileService ?? ProfileService();

  Future<Map<String, dynamic>?> getLocalProfile() async {
    final row = await _profileDao.getProfile();
    if (row == null) return null;
    return {
      'display_name': row.displayName,
      'email': row.email,
      'avatar_image': row.avatarImage,
    };
  }

  Future<void> saveProfile({
    required String displayName,
    required String email,
    String? avatarImage,
    bool syncToCloud = true,
  }) async {
    await _profileDao.upsertProfile(
      displayName: displayName,
      email: email,
      avatarImage: avatarImage,
    );
    if (syncToCloud) {
      await _profileService.saveProfile(
        displayName: displayName,
        email: email,
        avatarImage: avatarImage,
      );
    }
  }

  Future<Map<String, dynamic>?> syncProfileFromCloud() async {
    try {
      final remote = await _profileService.fetchProfile();
      if (remote != null) {
        await _profileDao.upsertProfile(
          displayName: remote['display_name'] as String? ?? '',
          email: remote['email'] as String? ?? '',
          avatarImage: remote['avatar_image'] as String?,
        );
      }
      return remote;
    } catch (e, st) {
      AppLogger.error('ProfileRepository sync failed', error: e, stackTrace: st);
      return null;
    }
  }
}
