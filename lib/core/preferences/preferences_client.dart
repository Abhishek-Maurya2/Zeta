import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/preferences_service.dart';

/// Abstract, decoupled key-value preferences client.
/// Eliminates monolithic preference key pollution across features.
abstract class PreferencesClient {
  String? getString(String key);
  Future<bool> setString(String key, String value);

  bool? getBool(String key);
  Future<bool> setBool(String key, bool value);

  int? getInt(String key);
  Future<bool> setInt(String key, int value);

  double? getDouble(String key);
  Future<bool> setDouble(String key, double value);

  List<String>? getStringList(String key);
  Future<bool> setStringList(String key, List<String> value);

  Future<bool> remove(String key);
  Future<bool> clear();
}

/// SharedPreferences implementation of [PreferencesClient].
class SharedPreferencesClient implements PreferencesClient {
  final SharedPreferences Function() _prefsResolver;

  SharedPreferencesClient([SharedPreferences Function()? prefsResolver])
      : _prefsResolver =
            prefsResolver ?? (() => PreferencesService.instance.prefs);

  SharedPreferences get _prefs => _prefsResolver();

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  double? getDouble(String key) => _prefs.getDouble(key);

  @override
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  @override
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  @override
  Future<bool> remove(String key) => _prefs.remove(key);

  @override
  Future<bool> clear() => _prefs.clear();
}

/// Global provider for the abstract preferences client.
final preferencesClientProvider = Provider<PreferencesClient>((ref) {
  return SharedPreferencesClient();
});
