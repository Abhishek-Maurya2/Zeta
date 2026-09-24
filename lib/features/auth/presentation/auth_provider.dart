import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../../../services/supabase_service.dart';
import '../../../database/database_provider.dart';
import '../../../services/preferences_service.dart';
import '../../../services/account_sync_session_service.dart';

enum AuthStatus { loading, signedOut, signedIn, unavailable }

/// UI-facing session state and auth actions. Feature data providers are mounted
/// only after this provider reports a signed-in account.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final SupabaseService _supabase;
  StreamSubscription<AuthState>? _subscription;

  AuthStatus _status = AuthStatus.loading;
  String? _error;
  bool _authActionInProgress = false;

  AuthProvider({AuthRepository? repository, SupabaseService? supabase})
    : _repository = repository ?? AuthRepository(),
      _supabase = supabase ?? SupabaseService() {
    unawaited(_initialize());
  }

  AuthStatus get status => _status;
  User? get user => _repository.currentUser;
  String? get error => _error;
  bool get isBusy => _status == AuthStatus.loading;

  Future<void> _initialize() async {
    try {
      if (!_supabase.isInitialized) await _supabase.init();
      if (!_supabase.isInitialized) {
        _status = AuthStatus.unavailable;
      } else {
        final user = _repository.currentUser;
        if (user == null) {
          _status = AuthStatus.signedOut;
          DatabaseProvider.instance.clearAccountScope();
        } else {
          await _activateAccount(user.id);
          _status = AuthStatus.signedIn;
        }
        _subscription = _repository.authChanges.listen(_onAuthChanged);
      }
    } catch (e, st) {
      debugPrint('AuthProvider._initialize ERROR: $e\n$st');
      _error = _friendlyMessage(e);
      _status = AuthStatus.unavailable;
    }
    notifyListeners();
  }

  void _onAuthChanged(AuthState state) {
    if (_authActionInProgress) return;
    _error = null;
    final user = state.session?.user;
    if (user == null) {
      AccountSyncSessionService.instance.endSession();
      DatabaseProvider.instance.clearAccountScope();
      _status = AuthStatus.signedOut;
      notifyListeners();
    } else {
      unawaited(_activateAndNotify(user.id));
    }
  }

  Future<void> _activateAndNotify(String userId) async {
    try {
      await _activateAccount(userId);
      _status = AuthStatus.signedIn;
    } catch (e, st) {
      debugPrint('AuthProvider._activateAndNotify ERROR: $e\n$st');
      _error = _friendlyMessage(e);
      _status = AuthStatus.unavailable;
    }
    notifyListeners();
  }

  Future<void> _activateAccount(String userId) async {
    try {
      await PreferencesService.instance.claimLegacySyncQueues(userId);
    } catch (e) {
      debugPrint('AuthProvider._activateAccount: claimLegacySyncQueues error: $e');
    }
    try {
      await DatabaseProvider.instance.claimLegacyRows(userId);
    } catch (e) {
      debugPrint('AuthProvider._activateAccount: claimLegacyRows error: $e');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _beginRequest();
    try {
      final user = await _repository.signIn(email: email, password: password);
      if (user != null) await _activateAccount(user.id);
      _status = AuthStatus.signedIn;
      return true;
    } catch (e) {
      _error = _friendlyMessage(e);
      _status = AuthStatus.signedOut;
      return false;
    } finally {
      _authActionInProgress = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    Uint8List? avatarBytes,
    String avatarExtension = 'jpg',
  }) async {
    _beginRequest();
    try {
      final response = await _repository.signUp(
        name: name,
        email: email,
        password: password,
        avatarBytes: avatarBytes,
        avatarExtension: avatarExtension,
      );
      if (response.session == null) {
        _error = 'Supabase email confirmation is enabled. Disable it in Auth settings to use immediate signup.';
        _status = AuthStatus.signedOut;
        return false;
      }
      if (response.user != null) await _activateAccount(response.user!.id);
      _status = AuthStatus.signedIn;
      return true;
    } catch (e) {
      _error = _friendlyMessage(e);
      _status = AuthStatus.signedOut;
      return false;
    } finally {
      _authActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _beginRequest();
    try {
      await _repository.signOut();
      AccountSyncSessionService.instance.endSession();
      DatabaseProvider.instance.clearAccountScope();
      _status = AuthStatus.signedOut;
    } catch (e) {
      _error = _friendlyMessage(e);
      _status = AuthStatus.signedIn;
      final userId = _repository.currentUser?.id;
      if (userId != null) await _activateAccount(userId);
    }
    _authActionInProgress = false;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _beginRequest() {
    _authActionInProgress = true;
    _error = null;
    _status = AuthStatus.loading;
    notifyListeners();
  }

  String _friendlyMessage(Object error) {
    debugPrint('AuthProvider._friendlyMessage: $error (${error.runtimeType})');
    if (error is AuthException) return error.message;
    return 'Could not connect to your account. Check your connection and try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
