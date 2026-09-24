import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/profile_repository.dart';
import '../services/preferences_service.dart';
import '../utils/app_logger.dart';

/// Provider responsible strictly for User Profile, Avatar, and Profile Sync state.
class ProfileProvider extends ChangeNotifier {
  static const String _prefKeyUserName = PreferencesService.keyUserName;
  static const String _prefKeyUserEmail = PreferencesService.keyUserEmail;
  static const String _prefKeyAvatarPhoto = PreferencesService.keyAvatarPhoto;
  static const String _prefKeyAvatarColorIndex = PreferencesService.keyAvatarColorIndex;

  static const List<Color> avatarColors = [
    Color(0xFF10B981), // Emerald Green
    Color(0xFF6750A4), // Iris Violet
    Color(0xFF006494), // Ocean Sapphire
    Color(0xFFD97706), // Warm Amber
    Color(0xFFE11D48), // Berry Rose
    Color(0xFF0D9488), // Glacier Teal
  ];

  final ProfileRepository _repository;

  String _userName = 'Abhishek';
  String _userEmail = '';
  String? _avatarPhoto;
  int _avatarColorIndex = 0;

  ProfileProvider({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository() {
    _loadSettings();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get avatarPhoto => _avatarPhoto;
  bool get hasAvatarPhoto => _avatarPhoto != null && _avatarPhoto!.isNotEmpty;
  int get avatarColorIndex => _avatarColorIndex;

  Color get currentAvatarColor =>
      avatarColors[_avatarColorIndex.clamp(0, avatarColors.length - 1)];

  String get avatarInitial {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty) return 'A';
    return trimmed[0].toUpperCase();
  }

  String get userInitials => avatarInitial;

  // ─── Mutators ──────────────────────────────────────────────────────────────
  void setUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _userName == trimmed) return;
    _userName = trimmed;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyUserName, trimmed));
    unawaited(
      _repository.saveProfile(
        displayName: _userName,
        email: _userEmail,
        avatarImage: _avatarPhoto,
      ),
    );
  }

  void setUserEmail(String email) {
    final trimmed = email.trim();
    if (_userEmail == trimmed) return;
    _userEmail = trimmed;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyUserEmail, trimmed));
    unawaited(
      _repository.saveProfile(
        displayName: _userName,
        email: _userEmail,
        avatarImage: _avatarPhoto,
      ),
    );
  }

  void setAvatarPhoto(String? base64Photo) {
    if (_avatarPhoto == base64Photo) return;
    _avatarPhoto = base64Photo;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyAvatarPhoto, base64Photo ?? ''));
    unawaited(
      _repository.saveProfile(
        displayName: _userName,
        email: _userEmail,
        avatarImage: _avatarPhoto,
      ),
    );
  }

  void setAvatarColorIndex(int index) {
    if (index < 0 || index >= avatarColors.length || _avatarColorIndex == index) return;
    _avatarColorIndex = index;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyAvatarColorIndex, index));
  }

  // ─── Cloud & Local Sync ────────────────────────────────────────────────────
  Future<void> syncProfileWithDb() async {
    try {
      final data = await _repository.syncProfileFromCloud();
      if (data != null) {
        final name = data['display_name'] as String?;
        final email = data['email'] as String?;
        final photo = data['avatar_image'] as String?;
        var changed = false;

        if (name != null && name.trim().isNotEmpty && name != _userName) {
          _userName = name.trim();
          await _saveSetting(_prefKeyUserName, _userName);
          changed = true;
        }
        if (email != null && email != _userEmail) {
          _userEmail = email.trim();
          await _saveSetting(_prefKeyUserEmail, _userEmail);
          changed = true;
        }
        if (photo != null && photo != _avatarPhoto) {
          _avatarPhoto = photo.isEmpty ? null : photo;
          await _saveSetting(_prefKeyAvatarPhoto, _avatarPhoto ?? '');
          changed = true;
        }
        if (changed) {
          notifyListeners();
        }
      }
    } catch (e, st) {
      AppLogger.error('Failed to sync profile', error: e, stackTrace: st);
    }
  }

  void resetProfile() {
    _userName = 'Abhishek';
    _userEmail = '';
    _avatarPhoto = null;
    _avatarColorIndex = 0;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyUserName, _userName));
    unawaited(_saveSetting(_prefKeyUserEmail, _userEmail));
    unawaited(_saveSetting(_prefKeyAvatarPhoto, ''));
    unawaited(_saveSetting(_prefKeyAvatarColorIndex, 0));
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────
  void _loadSettings() {
    try {
      final prefs = PreferencesService.instance;
      _userName = prefs.getString(_prefKeyUserName) ?? 'Abhishek';
      _userEmail = prefs.getString(_prefKeyUserEmail) ?? '';
      final photo = prefs.getString(_prefKeyAvatarPhoto);
      _avatarPhoto = (photo != null && photo.isNotEmpty) ? photo : null;
      _avatarColorIndex = prefs.getInt(_prefKeyAvatarColorIndex) ?? 0;
      notifyListeners();

      _loadFallbackFromDb();
    } catch (e, st) {
      AppLogger.warning('Failed to load profile settings', error: e, stackTrace: st);
    }
  }

  Future<void> _loadFallbackFromDb() async {
    try {
      final local = await _repository.getLocalProfile();
      if (local != null) {
        var changed = false;
        final name = local['display_name'] as String?;
        final email = local['email'] as String?;
        final photo = local['avatar_image'] as String?;

        if (name != null && name.trim().isNotEmpty && _userName == 'Abhishek') {
          _userName = name.trim();
          await _saveSetting(_prefKeyUserName, _userName);
          changed = true;
        }
        if (email != null && email.trim().isNotEmpty && _userEmail.isEmpty) {
          _userEmail = email.trim();
          await _saveSetting(_prefKeyUserEmail, _userEmail);
          changed = true;
        }
        if (photo != null && photo.isNotEmpty && _avatarPhoto == null) {
          _avatarPhoto = photo;
          await _saveSetting(_prefKeyAvatarPhoto, photo);
          changed = true;
        }
        if (changed) {
          notifyListeners();
        }
      }
    } catch (e, st) {
      AppLogger.warning('Failed to load local DB profile fallback', error: e, stackTrace: st);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = PreferencesService.instance;
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      }
    } catch (e, st) {
      AppLogger.warning('Failed to save profile setting $key', error: e, stackTrace: st);
    }
  }
}
