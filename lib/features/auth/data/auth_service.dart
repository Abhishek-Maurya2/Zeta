import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

/// Supabase Auth operations. It contains no UI or profile persistence logic.
class AuthService {
  final SupabaseService _supabase;

  AuthService({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService();

  Stream<AuthState> get authChanges => _supabase.client.auth.onAuthStateChange;

  User? get currentUser => _supabase.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _supabase.client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': name.trim()},
    );
  }

  Future<void> signOut() => _supabase.client.auth.signOut();
}
