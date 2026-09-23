import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Centralized, type-safe abstraction for user preferences and persistent settings.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  SharedPreferences? _prefs;

  Future<void> init([SharedPreferences? customPrefs]) async {
    if (customPrefs != null) {
      _prefs = customPrefs;
      return;
    }
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e, st) {
      AppLogger.error('Failed to initialize PreferencesService', error: e, stackTrace: st);
    }
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('PreferencesService must be initialized before access. Call PreferencesService.instance.init() first.');
    }
    return _prefs!;
  }

  // ─── Theme Keys ────────────────────────────────────────────────────────────
  static const String keyThemeMode = 'zeta_theme_mode';
  static const String keySeedColor = 'zeta_seed_color';
  static const String keyUseSystemColor = 'zeta_use_system_color';
  static const String keyVariant = 'zeta_scheme_variant';
  static const String keyHighContrast = 'zeta_high_contrast';
  static const String keyAnimations = 'zeta_animations';
  static const String keyCompactDensity = 'zeta_compact_density';
  static const String keyFontScale = 'zeta_font_scale';
  static const String keyCornerStyle = 'zeta_corner_style';
  static const String keyTypographyHeadings = 'zeta_typo_headings';
  static const String keyTypographyTitles = 'zeta_typo_titles';
  static const String keyTypographyBody = 'zeta_typo_body';
  static const String keyTypographyLabels = 'zeta_typo_labels';

  // ─── Profile Keys ──────────────────────────────────────────────────────────
  static const String keyUserName = 'zeta_user_name';
  static const String keyUserEmail = 'zeta_user_email';
  static const String keyAvatarPhoto = 'zeta_avatar_photo';
  static const String keyAvatarColorIndex = 'zeta_avatar_color_index';

  // ─── Weather Keys ──────────────────────────────────────────────────────────
  static const String keyCityName = 'zeta_city_name';
  static const String keyWeatherCache = 'zeta_weather_cache';
  static const String keyWeatherEnabled = 'zeta_weather_enabled';
  static const String keyShowWeatherInHeader = 'zeta_show_weather_in_header';

  // ─── General Keys ──────────────────────────────────────────────────────────
  static const String keySoundEffects = 'zeta_sound_effects';
  static const String keyTaskSortBy = 'zeta_task_sort_by_v1';
  static const String keyPomodoroSettings = 'zeta_pomodoro_settings_v1';
  static const String keyRevisionSettings = 'zeta_revision_settings_v1';

  // ─── Generic Helpers ───────────────────────────────────────────────────────
  String? getString(String key) => _prefs?.getString(key);
  Future<bool> setString(String key, String value) async => _prefs?.setString(key, value) ?? false;

  bool? getBool(String key) => _prefs?.getBool(key);
  Future<bool> setBool(String key, bool value) async => _prefs?.setBool(key, value) ?? false;

  int? getInt(String key) => _prefs?.getInt(key);
  Future<bool> setInt(String key, int value) async => _prefs?.setInt(key, value) ?? false;

  double? getDouble(String key) => _prefs?.getDouble(key);
  Future<bool> setDouble(String key, double value) async => _prefs?.setDouble(key, value) ?? false;

  Future<bool> remove(String key) async => _prefs?.remove(key) ?? false;
}
