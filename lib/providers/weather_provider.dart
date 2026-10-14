import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/weather_service.dart';
import '../services/preferences_service.dart';
import '../utils/app_logger.dart';
import '../utils/performance_trace.dart';

/// Provider responsible strictly for Live Weather state, location, and weather preferences.
class WeatherProvider extends ChangeNotifier {
  static const String _prefKeyCityName = PreferencesService.keyCityName;
  static const String _prefKeyWeatherCache = PreferencesService.keyWeatherCache;
  static const String _prefKeyWeatherEnabled =
      PreferencesService.keyWeatherEnabled;
  static const String _prefKeyShowWeatherInHeader =
      PreferencesService.keyShowWeatherInHeader;
  static const String _prefKeyAutoLocation = 'zeta_weather_auto_location';

  bool _weatherEnabled = true;
  bool _showWeatherInHeader = true;
  bool _autoLocation = false;
  String _cityName = 'Bokaro';
  WeatherData? _weatherData;
  bool _isWeatherLoading = false;
  DateTime? _lastGpsCheckTime;
  Timer? _startupRefreshTimer;
  bool _isDisposed = false;

  WeatherProvider() {
    _loadSettings();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────
  bool get weatherEnabled => _weatherEnabled;
  bool get showWeatherInHeader => _showWeatherInHeader;
  bool get autoLocation => _autoLocation;
  String get cityName => _cityName;
  WeatherData? get weatherData => _weatherData;
  bool get isWeatherLoading => _isWeatherLoading;
  DateTime? get lastGpsCheckTime => _lastGpsCheckTime;

  // ─── Mutators ──────────────────────────────────────────────────────────────
  void setWeatherEnabled(bool val) {
    if (_weatherEnabled == val) return;
    _weatherEnabled = val;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyWeatherEnabled, val));
    if (val) {
      _startupRefreshTimer?.cancel();
      unawaited(refreshWeather());
    }
  }

  void setShowWeatherInHeader(bool val) {
    if (_showWeatherInHeader == val) return;
    _showWeatherInHeader = val;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyShowWeatherInHeader, val));
  }

  void setAutoLocation(bool val) {
    if (_autoLocation == val) return;
    _autoLocation = val;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyAutoLocation, val));
    if (val && _weatherEnabled) {
      unawaited(detectDeviceLocationFromGps());
    }
  }

  void setCityName(String city) {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    _startupRefreshTimer?.cancel();
    _cityName = trimmed;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyCityName, trimmed));
    if (_weatherEnabled) {
      unawaited(refreshWeather());
    }
  }

  Future<bool> updateLocationFromCoordinates(
    double lat,
    double lon,
    String city,
  ) async {
    if (!_weatherEnabled) return false;
    _isWeatherLoading = true;
    _cityName = city;
    notifyListeners();
    try {
      await _saveSetting(_prefKeyCityName, _cityName);
      final data = await WeatherService.fetchWeatherByCoordinates(
        lat,
        lon,
        city,
      );
      _weatherData = data;
      _lastGpsCheckTime = DateTime.now();
      await _saveSetting(_prefKeyWeatherCache, jsonEncode(data.toJson()));
      return true;
    } catch (e, st) {
      AppLogger.warning(
        'Weather update for coordinates failed',
        error: e,
        stackTrace: st,
      );
      return false;
    } finally {
      _isWeatherLoading = false;
      notifyListeners();
    }
  }

  /// Detects the device location strictly using hardware GPS, updates the city name,
  /// and fetches fresh weather data.
  Future<bool> detectDeviceLocationFromGps() async {
    try {
      final loc = await WeatherService.detectLocationFromGps();
      if (loc != null) {
        final city = loc['city'] as String;
        final lat = loc['lat'] as double;
        final lon = loc['lon'] as double;
        return await updateLocationFromCoordinates(lat, lon, city);
      }
    } catch (e, st) {
      AppLogger.warning(
        'Manual GPS location detection failed',
        error: e,
        stackTrace: st,
      );
    }
    return false;
  }

  /// Refreshes weather data.
  /// When [isStartup] is true:
  /// - Only checks GPS if permission is already granted and throttled (>3 hours).
  /// - If GPS is unavailable/disabled on startup, silently falls back to the saved city without popups.
  Future<void> refreshWeather({bool isStartup = false}) => traceAsync(
    'weather.refresh',
    () => _refreshWeather(isStartup: isStartup),
  );

  Future<void> _refreshWeather({required bool isStartup}) async {
    if (!_weatherEnabled) return;
    _isWeatherLoading = true;
    notifyListeners();

    try {
      // 1. Check if background GPS auto-detect should run on startup or default city
      final shouldCheckGps = _autoLocation || _cityName == 'Bokaro';
      final isGpsThrottled =
          _lastGpsCheckTime != null &&
          DateTime.now().difference(_lastGpsCheckTime!) <
              const Duration(hours: 3);

      if (shouldCheckGps && !isGpsThrottled) {
        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          final permission = await Geolocator.checkPermission();

          // On startup: only query GPS if permission is ALREADY granted and service is enabled
          final hasPermission =
              permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;

          if (serviceEnabled && hasPermission) {
            final loc = await WeatherService.detectLocation();
            if (loc != null) {
              final city = loc['city'] as String;
              final lat = loc['lat'] as double;
              final lon = loc['lon'] as double;
              _cityName = city;
              _lastGpsCheckTime = DateTime.now();
              await _saveSetting(_prefKeyCityName, _cityName);
              final data = await WeatherService.fetchWeatherByCoordinates(
                lat,
                lon,
                city,
              );
              _weatherData = data;
              await _saveSetting(
                _prefKeyWeatherCache,
                jsonEncode(data.toJson()),
              );
              return;
            }
          }
          // Silent fallback on startup if GPS is off or permission is not granted
        } catch (e) {
          debugPrint('Silent GPS background check note: $e');
        }
      }

      // 2. Fetch fresh weather and 24-hour hourly forecast for the saved city
      final data = await WeatherService.fetchWeather(_cityName);
      _weatherData = data;
      await _saveSetting(_prefKeyWeatherCache, jsonEncode(data.toJson()));
    } catch (e, st) {
      AppLogger.warning('Weather refresh failed', error: e, stackTrace: st);
    } finally {
      _isWeatherLoading = false;
      notifyListeners();
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────
  void _loadSettings() {
    try {
      final prefs = PreferencesService.instance;
      _weatherEnabled = prefs.getBool(_prefKeyWeatherEnabled) ?? true;
      _showWeatherInHeader = prefs.getBool(_prefKeyShowWeatherInHeader) ?? true;
      _autoLocation = prefs.getBool(_prefKeyAutoLocation) ?? false;
      _cityName = prefs.getString(_prefKeyCityName) ?? 'Bokaro';

      final cache = prefs.getString(_prefKeyWeatherCache);
      if (cache != null && cache.isNotEmpty) {
        try {
          _weatherData = WeatherData.fromJson(
            jsonDecode(cache) as Map<String, dynamic>,
          );
        } catch (_) {}
      }
      notifyListeners();

      if (_weatherEnabled) {
        final fetchedAt = _weatherData?.fetchedAt;
        const freshnessWindow = Duration(minutes: 30);
        final cacheAge = fetchedAt == null
            ? freshnessWindow
            : DateTime.now().difference(fetchedAt);
        final refreshDelay = cacheAge >= freshnessWindow
            ? const Duration(seconds: 2)
            : freshnessWindow - cacheAge;
        _startupRefreshTimer = Timer(refreshDelay, () {
          if (!_isWeatherLoading) {
            unawaited(refreshWeather(isStartup: true));
          }
        });
      }
    } catch (e, st) {
      AppLogger.warning(
        'Failed to load weather settings',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _startupRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = PreferencesService.instance;
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save weather setting $key',
        error: e,
        stackTrace: st,
      );
    }
  }
}
