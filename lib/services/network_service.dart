import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'supabase_service.dart';

/// Central network connectivity service that provides fast-fail checks,
/// tracks online/offline transitions, and eliminates long network hangs.
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal() {
    final isRunningTests = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isRunningTests) {
      _startPeriodicCheck();
    }
  }

  bool _isOnline = true;
  DateTime? _lastCheckedAt;
  Timer? _checkTimer;

  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream emitting connectivity state changes (true = online, false = offline).
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Current cached online state.
  bool get isOnline => _isOnline;

  /// Call this when an HTTP operation succeeds to confirm online state.
  void markOnline() {
    if (!_isOnline) {
      _isOnline = true;
      _connectivityController.add(true);
      debugPrint('NetworkService: Connectivity restored (Online).');
    }
  }

  /// Call this when an HTTP request fails due to SocketException / Timeout
  /// to immediately fast-fail subsequent requests without waiting 15s.
  void markOffline() {
    if (_isOnline) {
      _isOnline = false;
      _connectivityController.add(false);
      debugPrint('NetworkService: Network unreachable (Offline).');
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
        final result = await InternetAddress.lookup('uewczwnrchvmvmccrdqf.supabase.co')
            .timeout(const Duration(milliseconds: 1500));
        reachable = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (_) {
      reachable = false;
    }

    if (reachable != _isOnline) {
      _isOnline = reachable;
      _connectivityController.add(_isOnline);
      debugPrint('NetworkService: Connectivity state changed -> $_isOnline');
    }
    return _isOnline;
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    // Check every 25 seconds; if offline, check more frequently (every 8s) to auto-recover quickly
    _checkTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      await checkConnectivity(force: true);
    });
  }

  void dispose() {
    _checkTimer?.cancel();
    _connectivityController.close();
  }
}
