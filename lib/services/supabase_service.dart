import 'dart:async';
import 'dart:io';
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

  /// In zero-auth single-user mode, all cloud operations map directly to the 'singleton' workspace.
  String get effectiveUserId => 'singleton';

  /// In zero-auth mode, the connection is active as long as Supabase client is initialized.
  bool get isAuthenticated => _isInitialized;

  Stream<AuthState>? get authStateChanges =>
      _isInitialized ? client.auth.onAuthStateChange : null;

  /// Initializes the Supabase client.
  Future<void> init() async {
    if (_isInitialized) return;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
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
}
