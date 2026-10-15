import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_client.dart';

/// Modular preferences for Theme & Expressive Styling.
class ThemePreferences {
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

  final PreferencesClient _client;

  ThemePreferences(this._client);

  String? getThemeMode() => _client.getString(keyThemeMode);
  Future<void> setThemeMode(String value) =>
      _client.setString(keyThemeMode, value);

  int? getSeedColor() => _client.getInt(keySeedColor);
  Future<void> setSeedColor(int value) => _client.setInt(keySeedColor, value);

  bool getUseSystemColor() => _client.getBool(keyUseSystemColor) ?? false;
  Future<void> setUseSystemColor(bool value) =>
      _client.setBool(keyUseSystemColor, value);

  String? getVariant() => _client.getString(keyVariant);
  Future<void> setVariant(String value) => _client.setString(keyVariant, value);

  bool getHighContrast() => _client.getBool(keyHighContrast) ?? false;
  Future<void> setHighContrast(bool value) =>
      _client.setBool(keyHighContrast, value);

  bool getAnimations() => _client.getBool(keyAnimations) ?? true;
  Future<void> setAnimations(bool value) =>
      _client.setBool(keyAnimations, value);

  bool getCompactDensity() => _client.getBool(keyCompactDensity) ?? false;
  Future<void> setCompactDensity(bool value) =>
      _client.setBool(keyCompactDensity, value);

  String? getFontScale() => _client.getString(keyFontScale);
  Future<void> setFontScale(String value) =>
      _client.setString(keyFontScale, value);

  String? getCornerStyle() => _client.getString(keyCornerStyle);
  Future<void> setCornerStyle(String value) =>
      _client.setString(keyCornerStyle, value);

  String? getTypographyHeadings() => _client.getString(keyTypographyHeadings);
  Future<void> setTypographyHeadings(String value) =>
      _client.setString(keyTypographyHeadings, value);

  String? getTypographyTitles() => _client.getString(keyTypographyTitles);
  Future<void> setTypographyTitles(String value) =>
      _client.setString(keyTypographyTitles, value);

  String? getTypographyBody() => _client.getString(keyTypographyBody);
  Future<void> setTypographyBody(String value) =>
      _client.setString(keyTypographyBody, value);

  String? getTypographyLabels() => _client.getString(keyTypographyLabels);
  Future<void> setTypographyLabels(String value) =>
      _client.setString(keyTypographyLabels, value);
}

final themePreferencesProvider = Provider<ThemePreferences>((ref) {
  final client = ref.watch(preferencesClientProvider);
  return ThemePreferences(client);
});
