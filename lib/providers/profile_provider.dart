import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/profile/data/profile_repository.dart';
import '../services/network_service.dart';
import '../utils/app_logger.dart';
import '../utils/performance_trace.dart';

/// UI state for an account profile; writes are local-first and sync is retriable.
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;
  StreamSubscription<bool>? _networkSubscription;

  String _userName = '';
  String _userEmail = '';
  String? _avatarPhoto;
  bool _isSyncing = false;
  bool _isDisposed = false;
  Timer? _startupSyncTimer;
  String? _syncError;
  DateTime? _lastSyncedAt;
  bool _syncRequestedDuringRun = false;

  ProfileProvider({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository() {
    _initFromCache();
    _networkSubscription = NetworkService().onConnectivityChanged.listen((
      online,
    ) {
      if (online) unawaited(syncProfileWithDb());
    });
    unawaited(_loadProfile());
  }

  void _initFromCache() {
    final cached = _repository.getCachedProfile();
    final name = cached['display_name'];
    final email = cached['email'];
    final photo = cached['avatar_image'];
    if (name != null && name.trim().isNotEmpty) _userName = name.trim();
    if (email != null && email.trim().isNotEmpty) _userEmail = email.trim();
    if (photo != null && photo.trim().isNotEmpty) _avatarPhoto = photo.trim();
  }

  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get avatarPhoto => _avatarPhoto;
  bool get hasAvatarPhoto => _avatarPhoto != null && _avatarPhoto!.isNotEmpty;
  String get avatarInitial =>
      _userName.trim().isEmpty ? 'A' : _userName.trim()[0].toUpperCase();
  String get userInitials => avatarInitial;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _userName == trimmed) return;
    _userName = trimmed;
    notifyListeners();
    await _persistAndSync();
  }

  Future<void> uploadAvatar(Uint8List bytes, {String extension = 'png'}) async {
    if (bytes.isEmpty) return;
    final localPath = await _repository.saveAvatarLocally(
      bytes: bytes,
      extension: extension,
    );
    _avatarPhoto = localPath;
    notifyListeners();
    await _persistAndSync();
  }

  Future<void> clearAvatarPhoto() async {
    if (!hasAvatarPhoto) return;
    _avatarPhoto = null;
    await _repository.clearAvatarLocally();
    notifyListeners();
    await _persistAndSync();
  }

  Future<void> syncProfileWithDb() =>
      traceAsync('profile.sync_cloud', _syncProfileWithDb);

  Future<void> _syncProfileWithDb() async {
    if (_isDisposed) return;
    _startupSyncTimer?.cancel();
    if (_isSyncing) {
      _syncRequestedDuringRun = true;
      return;
    }
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    try {
      final data = await _repository.syncProfileFromCloud();
      if (_isDisposed) return;
      if (data != null) _apply(data);
      _lastSyncedAt = DateTime.now();
    } catch (error, stackTrace) {
      _syncError = error.toString();
      AppLogger.error(
        'Profile synchronization failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncing = false;
      if (!_isDisposed) notifyListeners();
      if (_syncRequestedDuringRun && !_isDisposed) {
        _syncRequestedDuringRun = false;
        unawaited(syncProfileWithDb());
      }
    }
  }

  Future<void> _loadProfile() =>
      traceAsync('profile.load_local', _loadProfileImpl);

  Future<void> _loadProfileImpl() async {
    try {
      final local = await _repository.getLocalProfile();
      if (_isDisposed) return;
      if (local != null) _apply(local);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Could not load local profile',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (_isDisposed) return;
    notifyListeners();
    if (!_isDisposed) {
      _startupSyncTimer = Timer(const Duration(seconds: 12), () {
        if (!_isDisposed) unawaited(syncProfileWithDb());
      });
    }
  }

  Future<void> _persistAndSync() async {
    try {
      await _repository.saveLocalProfile(
        displayName: _userName,
        email: _userEmail,
        avatarImage: _avatarPhoto,
      );
    } catch (error, stackTrace) {
      _syncError = error.toString();
      AppLogger.error(
        'Could not save local profile',
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
      rethrow;
    }
    await syncProfileWithDb();
  }

  void _apply(Map<String, dynamic> data) {
    final name = data['display_name'] as String?;
    final email = data['email'] as String?;
    final photo = data['avatar_image'] as String?;
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    _avatarPhoto = photo?.isEmpty == true ? null : photo;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _startupSyncTimer?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }
}
