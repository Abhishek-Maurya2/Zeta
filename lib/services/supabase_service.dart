import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns Supabase client initialization and exposes the active authenticated user.
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
      throw StateError(
        'SupabaseService has not been initialized. Call init() first.',
      );
    }
    return Supabase.instance.client;
  }

  User? get currentUser => _isInitialized ? client.auth.currentUser : null;
  Session? get currentSession =>
      _isInitialized ? client.auth.currentSession : null;

  /// Current account id for row ownership. Cloud data access requires a session.
  String get effectiveUserId {
    final id = currentUser?.id;
    if (id == null) {
      throw StateError('A signed-in user is required for cloud data access.');
    }
    return id;
  }

  bool get isAuthenticated => currentUser != null;

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
