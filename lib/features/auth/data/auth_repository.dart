import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../repositories/profile_repository.dart';
import 'auth_service.dart';

/// Application boundary for authentication and account session state.
class AuthRepository {
  final AuthService _service;
  final ProfileRepository _profiles;

  AuthRepository({AuthService? service, ProfileRepository? profiles})
    : _service = service ?? AuthService(),
      _profiles = profiles ?? ProfileRepository();

  User? get currentUser => _service.currentUser;
  Stream<AuthState> get authChanges => _service.authChanges;

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _service.signIn(email: email, password: password);
    return result.user;
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
    Uint8List? avatarBytes,
    String avatarExtension = 'jpg',
  }) async {
    final response = await _service.signUp(
      name: name,
      email: email,
      password: password,
    );
    final user = response.user;
    if (response.session != null && user != null) {
      await _profiles.initializeAccountProfile(
        userId: user.id,
        name: name,
        email: email,
        avatarBytes: avatarBytes,
        avatarExtension: avatarExtension,
      );
      await _profiles.claimLegacyWorkspace();
    }
    return response;
  }

  Future<void> signOut() => _service.signOut();
}
