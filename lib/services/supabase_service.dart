import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service managing client initialization, authentication lifecycle,
/// and OAuth login with Google Calendar & Google Tasks scopes.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supaUrl = 'https://uewczwnrchvmvmccrdqf.supabase.co';
  static const String supaAnonKey =
      'sb_publishable_41OOohizBAgv9RJMp-lsXg_vLbR_mcX';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('SupabaseService has not been initialized. Call init() first.');
    }
    return Supabase.instance.client;
  }

  User? get currentUser => _isInitialized ? client.auth.currentUser : null;
  Session? get currentSession => _isInitialized ? client.auth.currentSession : null;

  /// Returns the authenticated user's ID, or falls back to 'singleton' for local/offline mode.
  String get effectiveUserId => currentUser?.id ?? 'singleton';

  /// Whether a live authenticated user session is active.
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState>? get authStateChanges =>
      _isInitialized ? client.auth.onAuthStateChange : null;

  /// Initializes the Supabase client.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supaUrl,
        // ignore: deprecated_member_use
        anonKey: supaAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('SupabaseService: Initialized successfully ($supaUrl)');
    } catch (e) {
      debugPrint('SupabaseService: Initialization warning/error: $e');
      // If already initialized elsewhere or running under test harness
      try {
        final _ = Supabase.instance.client;
        _isInitialized = true;
      } catch (_) {}
    }
  }

  /// Sign in with Google OAuth requesting calendar & tasks scopes.
  Future<bool> signInWithGoogle({String? redirectTo}) async {
    if (!_isInitialized) await init();
    try {
      final redirect = redirectTo ?? 'zeta://login-callback';
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        scopes: 'https://www.googleapis.com/auth/tasks',
      );
    } catch (e) {
      debugPrint('SupabaseService: signInWithGoogle error - $e');
      rethrow;
    }
  }

  /// Sign out the current user session.
  Future<void> signOut() async {
    if (!_isInitialized) return;
    try {
      await client.auth.signOut();
      debugPrint('SupabaseService: Signed out current user.');
    } catch (e) {
      debugPrint('SupabaseService: signOut error - $e');
    }
  }
}
