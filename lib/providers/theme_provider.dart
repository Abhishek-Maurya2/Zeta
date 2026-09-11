import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/color_variant.dart';

/// Seed color preset matching Sharva's design system.
class SeedPreset {
  final String id;
  final String name;
  final Color color;
  final String hex;
  final String desc;

  const SeedPreset({
    required this.id,
    required this.name,
    required this.color,
    required this.hex,
    required this.desc,
  });
}

const List<SeedPreset> kSeedPresets = [
  SeedPreset(
    id: 'iris',
    name: 'Iris Violet',
    color: Color(0xFF6750A4),
    hex: '#6750A4',
    desc: 'Material 3 Baseline Violet',
  ),
  SeedPreset(
    id: 'sapphire',
    name: 'Ocean Sapphire',
    color: Color(0xFF006494),
    hex: '#006494',
    desc: 'Focused Nautical Blue',
  ),
  SeedPreset(
    id: 'emerald',
    name: 'Emerald Pine',
    color: Color(0xFF006C4C),
    hex: '#006C4C',
    desc: 'Organic Botanical Green',
  ),
  SeedPreset(
    id: 'amber',
    name: 'Amber Sunset',
    color: Color(0xFF8F4C00),
    hex: '#8F4C00',
    desc: 'Warm Radiant Gold',
  ),
  SeedPreset(
    id: 'rose',
    name: 'Berry Rose',
    color: Color(0xFF984061),
    hex: '#984061',
    desc: 'Modern Expressive Crimson',
  ),
  SeedPreset(
    id: 'teal',
    name: 'Glacier Teal',
    color: Color(0xFF006874),
    hex: '#006874',
    desc: 'Crisp Arctic Cyan',
  ),
  SeedPreset(
    id: 'charcoal',
    name: 'Slate Steel',
    color: Color(0xFF4A6267),
    hex: '#4A6267',
    desc: 'Subtle Minimal Charcoal',
  ),
];

/// Mirrors Sharva's useThemeStore — manages theme mode, seed color, typography,
/// display flags, user profile, and system preferences.
class ThemeProvider extends ChangeNotifier {
  static const String _prefKeyThemeMode = 'zeta_theme_mode';
  static const String _prefKeySeedColor = 'zeta_seed_color';
  static const String _prefKeyVariant = 'zeta_scheme_variant';
  static const String _prefKeyHighContrast = 'zeta_high_contrast';
  static const String _prefKeyAnimations = 'zeta_animations';
  static const String _prefKeyCompactDensity = 'zeta_compact_density';
  static const String _prefKeyFontChoice = 'zeta_font_choice';
  static const String _prefKeyFontScale = 'zeta_font_scale';
  static const String _prefKeyCornerStyle = 'zeta_corner_style';
  static const String _prefKeyFontRoundness = 'zeta_font_roundness';
  static const String _prefKeyFontWeight = 'zeta_font_weight';
  static const String _prefKeyFontWidth = 'zeta_font_width';
  static const String _prefKeyFontSlant = 'zeta_font_slant';
  static const String _prefKeyFontGrade = 'zeta_font_grade';
  static const String _prefKeyUserName = 'zeta_user_name';
  static const String _prefKeyCityName = 'zeta_city_name';
  static const String _prefKeyNotifications = 'zeta_notifications';
  static const String _prefKeySoundEffects = 'zeta_sound_effects';
  static const String _prefKeyAutoSave = 'zeta_auto_save';
  static const String _prefKeyTelemetry = 'zeta_telemetry';

  ThemeProvider() {
    _loadSettings();
  }

  // ─── Theme Mode ─────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _saveSetting(_prefKeyThemeMode, mode.name);
  }

  void toggleTheme() {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  // ─── Seed Color ─────────────────────────────────────────────────────────
  Color _seedColor = const Color(0xFF6750A4);
  Color get seedColor => _seedColor;

  void setSeedColor(Color color) {
    if (_seedColor.toARGB32() == color.toARGB32()) return;
    _seedColor = color;
    notifyListeners();
    _saveSetting(_prefKeySeedColor, color.toARGB32().toString());
  }

  // ─── Scheme Variant ─────────────────────────────────────────────────────
  M3EColorVariant _variant = M3EColorVariant.expressive;
  M3EColorVariant get variant => _variant;

  void setVariant(M3EColorVariant variant) {
    if (_variant == variant) return;
    _variant = variant;
    notifyListeners();
    _saveSetting(_prefKeyVariant, variant.name);
  }

  // ─── Display & Motion ───────────────────────────────────────────────────
  bool _highContrast = false;
  bool get highContrast => _highContrast;

  void setHighContrast(bool value) {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
    _saveSetting(_prefKeyHighContrast, value);
  }

  bool _animations = true;
  bool get animations => _animations;

  void setAnimations(bool value) {
    if (_animations == value) return;
    _animations = value;
    notifyListeners();
    _saveSetting(_prefKeyAnimations, value);
  }

  bool _compactDensity = false;
  bool get compactDensity => _compactDensity;

  void setCompactDensity(bool value) {
    if (_compactDensity == value) return;
    _compactDensity = value;
    notifyListeners();
    _saveSetting(_prefKeyCompactDensity, value);
  }

  // ─── Typography & Shape ─────────────────────────────────────────────────
  String _fontChoice = 'google-sans'; // 'google-sans', 'roboto', 'system'
  String get fontChoice => _fontChoice;

  void setFontChoice(String choice) {
    if (_fontChoice == choice) return;
    _fontChoice = choice;
    notifyListeners();
    _saveSetting(_prefKeyFontChoice, choice);
  }

  String _fontScale = 'standard'; // 'compact', 'standard', 'large'
  String get fontScale => _fontScale;

  void setFontScale(String scale) {
    if (_fontScale == scale) return;
    _fontScale = scale;
    notifyListeners();
    _saveSetting(_prefKeyFontScale, scale);
  }

  String _cornerStyle = 'expressive'; // 'sharp', 'classic', 'expressive'
  String get cornerStyle => _cornerStyle;

  void setCornerStyle(String style) {
    if (_cornerStyle == style) return;
    _cornerStyle = style;
    notifyListeners();
    _saveSetting(_prefKeyCornerStyle, style);
  }

  // Variable Font Axes (Google Sans Flex)
  double _fontRoundness = 0; // 0..100
  double get fontRoundness => _fontRoundness;

  void setFontRoundness(double val) {
    if (_fontRoundness == val) return;
    _fontRoundness = val;
    notifyListeners();
    _saveSetting(_prefKeyFontRoundness, val);
  }

  double _fontWeight = 400; // 100..1000
  double get fontWeight => _fontWeight;

  void setFontWeight(double val) {
    if (_fontWeight == val) return;
    _fontWeight = val;
    notifyListeners();
    _saveSetting(_prefKeyFontWeight, val);
  }

  double _fontWidth = 100; // 25..151
  double get fontWidth => _fontWidth;

  void setFontWidth(double val) {
    if (_fontWidth == val) return;
    _fontWidth = val;
    notifyListeners();
    _saveSetting(_prefKeyFontWidth, val);
  }

  double _fontSlant = 0; // -10..0
  double get fontSlant => _fontSlant;

  void setFontSlant(double val) {
    if (_fontSlant == val) return;
    _fontSlant = val;
    notifyListeners();
    _saveSetting(_prefKeyFontSlant, val);
  }

  double _fontGrade = 0; // -200..150
  double get fontGrade => _fontGrade;

  void setFontGrade(double val) {
    if (_fontGrade == val) return;
    _fontGrade = val;
    notifyListeners();
    _saveSetting(_prefKeyFontGrade, val);
  }

  // ─── Profile ────────────────────────────────────────────────────────────
  String _userName = 'Abhishek';
  String get userName => _userName;

  String get userInitials {
    final parts = _userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.length > 1
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void setUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _userName == trimmed) return;
    _userName = trimmed;
    notifyListeners();
    _saveSetting(_prefKeyUserName, trimmed);
  }

  // ─── Weather Location ───────────────────────────────────────────────────
  String _cityName = 'San Francisco, US';
  String get cityName => _cityName;

  void setCityName(String city) {
    final trimmed = city.trim();
    if (trimmed.isEmpty || _cityName == trimmed) return;
    _cityName = trimmed;
    notifyListeners();
    _saveSetting(_prefKeyCityName, trimmed);
  }

  // ─── Notifications & Sync ───────────────────────────────────────────────
  bool _notifications = true;
  bool get notifications => _notifications;

  void setNotifications(bool val) {
    if (_notifications == val) return;
    _notifications = val;
    notifyListeners();
    _saveSetting(_prefKeyNotifications, val);
  }

  bool _soundEffects = true;
  bool get soundEffects => _soundEffects;

  void setSoundEffects(bool val) {
    if (_soundEffects == val) return;
    _soundEffects = val;
    notifyListeners();
    _saveSetting(_prefKeySoundEffects, val);
  }

  bool _autoSave = true;
  bool get autoSave => _autoSave;

  void setAutoSave(bool val) {
    if (_autoSave == val) return;
    _autoSave = val;
    notifyListeners();
    _saveSetting(_prefKeyAutoSave, val);
  }

  bool _telemetry = false;
  bool get telemetry => _telemetry;

  void setTelemetry(bool val) {
    if (_telemetry == val) return;
    _telemetry = val;
    notifyListeners();
    _saveSetting(_prefKeyTelemetry, val);
  }

  // ─── Reset Defaults ─────────────────────────────────────────────────────
  void resetDefaults() {
    _themeMode = ThemeMode.system;
    _seedColor = const Color(0xFF6750A4);
    _variant = M3EColorVariant.expressive;
    _highContrast = false;
    _animations = true;
    _compactDensity = false;
    _fontChoice = 'google-sans';
    _fontScale = 'standard';
    _cornerStyle = 'expressive';
    _fontRoundness = 0;
    _fontWeight = 400;
    _fontWidth = 100;
    _fontSlant = 0;
    _fontGrade = 0;
    _userName = 'Abhishek';
    _cityName = 'San Francisco, US';
    _notifications = true;
    _soundEffects = true;
    _autoSave = true;
    _telemetry = false;
    notifyListeners();
    _clearSettings();
  }

  // ─── Persistence ────────────────────────────────────────────────────────
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final modeStr = prefs.getString(_prefKeyThemeMode);
      if (modeStr != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == modeStr,
          orElse: () => ThemeMode.system,
        );
      }

      final colorVal = prefs.getString(_prefKeySeedColor);
      if (colorVal != null) {
        final parsed = int.tryParse(colorVal);
        if (parsed != null) _seedColor = Color(parsed);
      }

      final variantStr = prefs.getString(_prefKeyVariant);
      if (variantStr != null) {
        _variant = M3EColorVariant.values.firstWhere(
          (v) => v.name == variantStr,
          orElse: () => M3EColorVariant.expressive,
        );
      }

      _highContrast = prefs.getBool(_prefKeyHighContrast) ?? _highContrast;
      _animations = prefs.getBool(_prefKeyAnimations) ?? _animations;
      _compactDensity = prefs.getBool(_prefKeyCompactDensity) ?? _compactDensity;
      _fontChoice = prefs.getString(_prefKeyFontChoice) ?? _fontChoice;
      _fontScale = prefs.getString(_prefKeyFontScale) ?? _fontScale;
      _cornerStyle = prefs.getString(_prefKeyCornerStyle) ?? _cornerStyle;
      _fontRoundness = prefs.getDouble(_prefKeyFontRoundness) ?? _fontRoundness;
      _fontWeight = prefs.getDouble(_prefKeyFontWeight) ?? _fontWeight;
      _fontWidth = prefs.getDouble(_prefKeyFontWidth) ?? _fontWidth;
      _fontSlant = prefs.getDouble(_prefKeyFontSlant) ?? _fontSlant;
      _fontGrade = prefs.getDouble(_prefKeyFontGrade) ?? _fontGrade;
      _userName = prefs.getString(_prefKeyUserName) ?? _userName;
      _cityName = prefs.getString(_prefKeyCityName) ?? _cityName;
      _notifications = prefs.getBool(_prefKeyNotifications) ?? _notifications;
      _soundEffects = prefs.getBool(_prefKeySoundEffects) ?? _soundEffects;
      _autoSave = prefs.getBool(_prefKeyAutoSave) ?? _autoSave;
      _telemetry = prefs.getBool(_prefKeyTelemetry) ?? _telemetry;

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      }
    } catch (_) {}
  }

  Future<void> _clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }
}
