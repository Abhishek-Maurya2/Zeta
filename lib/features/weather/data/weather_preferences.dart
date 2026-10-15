import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_client.dart';

/// Modular preferences for Weather domain.
class WeatherPreferences {
  static const String keyCityName = 'zeta_city_name';
  static const String keyWeatherCache = 'zeta_weather_cache';
  static const String keyWeatherEnabled = 'zeta_weather_enabled';
  static const String keyShowWeatherInHeader = 'zeta_show_weather_in_header';

  final PreferencesClient _client;

  WeatherPreferences(this._client);

  String? getCityName() => _client.getString(keyCityName);
  Future<void> setCityName(String value) =>
      _client.setString(keyCityName, value);

  String? getWeatherCache() => _client.getString(keyWeatherCache);
  Future<void> setWeatherCache(String value) =>
      _client.setString(keyWeatherCache, value);

  bool getWeatherEnabled() => _client.getBool(keyWeatherEnabled) ?? true;
  Future<void> setWeatherEnabled(bool value) =>
      _client.setBool(keyWeatherEnabled, value);

  bool getShowWeatherInHeader() =>
      _client.getBool(keyShowWeatherInHeader) ?? true;
  Future<void> setShowWeatherInHeader(bool value) =>
      _client.setBool(keyShowWeatherInHeader, value);
}

final weatherPreferencesProvider = Provider<WeatherPreferences>((ref) {
  final client = ref.watch(preferencesClientProvider);
  return WeatherPreferences(client);
});
