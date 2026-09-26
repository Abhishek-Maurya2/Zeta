import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/providers/weather_provider.dart';
import 'package:zeta/services/preferences_service.dart';
import 'package:zeta/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeatherService & HourlyForecast 24-Hour Model Tests', () {
    test('HourlyForecast serializes and deserializes correctly', () {
      final now = DateTime(2026, 9, 26, 14, 0);
      final hourly = HourlyForecast(
        time: now,
        temperature: 23.5,
        weatherCode: 0,
        isDay: true,
        humidity: 55,
        windSpeed: 12.0,
      );

      final json = hourly.toJson();
      final fromJson = HourlyForecast.fromJson(json);

      expect(fromJson.time, equals(now));
      expect(fromJson.temperature, equals(23.5));
      expect(fromJson.weatherCode, equals(0));
      expect(fromJson.isDay, isTrue);
      expect(fromJson.humidity, equals(55));
      expect(fromJson.condition, equals('Clear Sky'));
      expect(fromJson.iconName, equals('clear_day'));
    });

    test('WeatherData serializes and deserializes 24h hourly forecast', () {
      final now = DateTime.now();
      final hourlyList = List.generate(
        24,
        (i) => HourlyForecast(
          time: now.add(Duration(hours: i)),
          temperature: 18.0 + (i % 8),
          weatherCode: i % 3,
          isDay: i >= 6 && i < 18,
          humidity: 50 + i,
          windSpeed: 10.0 + (i * 0.5),
        ),
      );

      final weather = WeatherData(
        temperature: 21.0,
        condition: 'Mainly Clear',
        humidity: 60,
        windSpeed: 14.0,
        weatherCode: 1,
        cityName: 'Tokyo, JP',
        isDay: true,
        fetchedAt: now,
        hourlyForecast: hourlyList,
      );

      final json = weather.toJson();
      final restored = WeatherData.fromJson(json);

      expect(restored.cityName, equals('Tokyo, JP'));
      expect(restored.temperature, equals(21.0));
      expect(restored.hourlyForecast.length, equals(24));
      expect(restored.next24Hours.length, equals(24));
      expect(restored.minTempToday, isNotNull);
      expect(restored.maxTempToday, isNotNull);
      expect(restored.maxTempToday!, greaterThanOrEqualTo(restored.minTempToday!));
    });

    test('WeatherData resolveIconName handles day and night variants', () {
      expect(WeatherData.resolveIconName(0, true), equals('clear_day'));
      expect(WeatherData.resolveIconName(0, false), equals('clear_night'));
      expect(WeatherData.resolveIconName(2, true), equals('partly_cloudy_day'));
      expect(WeatherData.resolveIconName(2, false), equals('partly_cloudy_night'));
      expect(WeatherData.resolveIconName(61, true), equals('rain'));
      expect(WeatherData.resolveIconName(95, true), equals('thunderstorm'));
    });
  });

  group('WeatherProvider Local Caching & Silent Startup Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PreferencesService.instance.init();
    });

    test('WeatherProvider restores 24-hour cached weather on startup', () async {
      final now = DateTime.now();
      final cachedWeather = WeatherData(
        temperature: 25.0,
        condition: 'Clear Sky',
        humidity: 50,
        windSpeed: 12.0,
        weatherCode: 0,
        cityName: 'Bengaluru, IN',
        isDay: true,
        fetchedAt: now,
        hourlyForecast: [
          HourlyForecast(
            time: now,
            temperature: 25.0,
            weatherCode: 0,
            isDay: true,
            humidity: 50,
            windSpeed: 12.0,
          ),
          HourlyForecast(
            time: now.add(const Duration(hours: 1)),
            temperature: 24.0,
            weatherCode: 0,
            isDay: true,
            humidity: 52,
            windSpeed: 11.0,
          ),
        ],
      );

      final prefs = PreferencesService.instance.prefs;
      await prefs.setString(
        PreferencesService.keyWeatherCache,
        jsonEncode(cachedWeather.toJson()),
      );
      await prefs.setString(
        PreferencesService.keyCityName,
        'Bengaluru, IN',
      );

      final provider = WeatherProvider();

      // Synchronously restored from cache before network refresh finishes
      expect(provider.cityName, equals('Bengaluru, IN'));
      expect(provider.weatherData, isNotNull);
      expect(provider.weatherData!.temperature, equals(25.0));
      expect(provider.weatherData!.hourlyForecast.length, equals(2));
    });
  });
}
