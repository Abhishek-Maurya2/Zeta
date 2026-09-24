import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/preferences_service.dart';
import '../utils/app_logger.dart';

/// Provider responsible strictly for Live Weather state, location, and weather preferences.
class WeatherProvider extends ChangeNotifier {
  static const String _prefKeyCityName = PreferencesService.keyCityName;
  static const String _prefKeyWeatherCache = PreferencesService.keyWeatherCache;
  static const String _prefKeyWeatherEnabled = PreferencesService.keyWeatherEnabled;
  static const String _prefKeyShowWeatherInHeader = PreferencesService.keyShowWeatherInHeader;

  bool _weatherEnabled = true;
  bool _showWeatherInHeader = true;
  String _cityName = 'San Francisco, US';
  WeatherData? _weatherData;
  bool _isWeatherLoading = false;

  WeatherProvider() {
    _loadSettings();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────
  bool get weatherEnabled => _weatherEnabled;
  bool get showWeatherInHeader => _showWeatherInHeader;
  String get cityName => _cityName;
  WeatherData? get weatherData => _weatherData;
  bool get isWeatherLoading => _isWeatherLoading;

  // ─── Mutators ──────────────────────────────────────────────────────────────
  void setWeatherEnabled(bool val) {
    if (_weatherEnabled == val) return;
    _weatherEnabled = val;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyWeatherEnabled, val));
    if (val) {
      unawaited(refreshWeather());
    }
  }

  void setShowWeatherInHeader(bool val) {
    if (_showWeatherInHeader == val) return;
    _showWeatherInHeader = val;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyShowWeatherInHeader, val));
  }

  void setCityName(String city) {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    _cityName = trimmed;
    notifyListeners();
    unawaited(_saveSetting(_prefKeyCityName, trimmed));
    if (_weatherEnabled) {
      unawaited(refreshWeather());
    }
  }

  Future<void> refreshWeather() async {
    if (!_weatherEnabled) return;
    _isWeatherLoading = true;
    notifyListeners();
    try {
      if (_cityName == 'San Francisco, US') {
        final loc = await WeatherService.detectLocation();
        if (loc != null) {
          final city = loc['city'] as String;
          final lat = loc['lat'] as double;
          final lon = loc['lon'] as double;
          _cityName = city;
          await _saveSetting(_prefKeyCityName, _cityName);
          final data = await WeatherService.fetchWeatherByCoordinates(lat, lon, city);
          _weatherData = data;
          await _saveSetting(_prefKeyWeatherCache, jsonEncode(data.toJson()));
          return;
        }
      }
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
      _cityName = prefs.getString(_prefKeyCityName) ?? 'San Francisco, US';

      final cache = prefs.getString(_prefKeyWeatherCache);
      if (cache != null && cache.isNotEmpty) {
        try {
          _weatherData = WeatherData.fromJson(jsonDecode(cache) as Map<String, dynamic>);
        } catch (_) {}
      }
      notifyListeners();

      if (_weatherEnabled) {
        unawaited(refreshWeather());
      }
    } catch (e, st) {
      AppLogger.warning('Failed to load weather settings', error: e, stackTrace: st);
    }
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
      AppLogger.warning('Failed to save weather setting $key', error: e, stackTrace: st);
    }
  }
}
