import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'supabase_service.dart';

/// Central network connectivity service that provides fast-fail checks,
/// tracks online/offline transitions, and eliminates long network hangs.
class NetworkService with WidgetsBindingObserver {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal() {
    final isRunningTests =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isRunningTests) {
      WidgetsBinding.instance.addObserver(this);
      final state = WidgetsBinding.instance.lifecycleState;
      _backgroundMode = _isBackgroundState(state);
      _schedulePeriodicCheck(background: _backgroundMode);
    }
  }

  bool _isOnline = true;
  DateTime? _lastCheckedAt;
  Timer? _checkTimer;
  bool _backgroundMode = false;

  static bool _isBackgroundState(AppLifecycleState? state) =>
      state == AppLifecycleState.hidden ||
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.detached;

  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream emitting connectivity state changes (true = online, false = offline).
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Current cached online state.
  bool get isOnline => _isOnline;

  /// Call this when an HTTP operation succeeds to confirm online state.
  void markOnline() {
    _offlineRetryCount = 0;
    if (!_isOnline) {
      _isOnline = true;
      _connectivityController.add(true);
      debugPrint('NetworkService: Connectivity restored (Online).');
      if (_checkTimer != null) {
        _schedulePeriodicCheck(background: _backgroundMode);
      }
    }
  }

  /// Call this when an HTTP request fails due to SocketException / Timeout
  /// to immediately fast-fail subsequent requests without waiting 15s.
  void markOffline() {
    if (_isOnline) {
      _isOnline = false;
      _connectivityController.add(false);
      debugPrint('NetworkService: Network unreachable (Offline).');
      if (_checkTimer != null) {
        _schedulePeriodicCheck(background: _backgroundMode);
      }
    }
  }

  /// Performs a fast (<1.5s) connectivity check.
  Future<bool> checkConnectivity({bool force = false}) async {
    // Avoid spamming check if checked within last 3 seconds unless forced
    if (!force &&
        _lastCheckedAt != null &&
        DateTime.now().difference(_lastCheckedAt!) <
            const Duration(seconds: 3)) {
      return _isOnline;
    }

    _lastCheckedAt = DateTime.now();
    bool reachable = false;

    try {
      if (kIsWeb) {
        // Ping PostgREST REST endpoint with apikey header which sends CORS headers for web origins
        final res = await http
            .head(
              Uri.parse('${SupabaseService.supaUrl}/rest/v1/'),
              headers: {'apikey': SupabaseService.supaAnonKey},
            )
            .timeout(const Duration(milliseconds: 1500));
        reachable = res.statusCode > 0;
      } else {
        // Fast DNS lookup on native platforms
        final result = await InternetAddress.lookup(
          'uewczwnrchvmvmccrdqf.supabase.co',
        ).timeout(const Duration(milliseconds: 1500));
        reachable = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (_) {
      reachable = false;
    }

    if (reachable != _isOnline) {
      _isOnline = reachable;
      _connectivityController.add(_isOnline);
      debugPrint('NetworkService: Connectivity state changed -> $_isOnline');
      _schedulePeriodicCheck(background: _backgroundMode);
    }
    return _isOnline;
  }

  int _offlineRetryCount = 0;

  void _schedulePeriodicCheck({required bool background}) {
    _checkTimer?.cancel();
    _backgroundMode = background;
    Duration interval;
    if (background) {
      interval = _isOnline ? const Duration(minutes: 5) : const Duration(minutes: 2);
    } else {
      if (_isOnline) {
        _offlineRetryCount = 0;
        interval = const Duration(seconds: 60);
      } else {
        // Exponential backoff when offline: 15s -> 30s -> 60s -> 120s max
        final backoffSec = (15 * (1 << _offlineRetryCount)).clamp(15, 120);
        interval = Duration(seconds: backoffSec);
        if (_offlineRetryCount < 3) _offlineRetryCount++;
      }
    }
    _checkTimer = Timer(interval, () async {
      await checkConnectivity(force: true);
      _schedulePeriodicCheck(background: _backgroundMode);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _offlineRetryCount = 0;
      _schedulePeriodicCheck(background: false);
      unawaited(checkConnectivity(force: true));
    } else if (_isBackgroundState(state)) {
      _schedulePeriodicCheck(background: true);
    }
  }

  void dispose() {
    _checkTimer?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _connectivityController.close();
  }
}
