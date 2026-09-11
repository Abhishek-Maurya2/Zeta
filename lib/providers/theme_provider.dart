import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/color_variant.dart';
import '../services/weather_service.dart';

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
/// display flags, user profile, live weather, and system preferences.
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
  static const String _prefKeyUserEmail = 'zeta_user_email';
  static const String _prefKeyAvatarPhoto = 'zeta_avatar_photo';
  static const String _prefKeyAvatarColorIndex = 'zeta_avatar_color_index';
  static const String _prefKeyCityName = 'zeta_city_name';
  static const String _prefKeyWeatherCache = 'zeta_weather_cache';
  static const String _prefKeyNotifications = 'zeta_notifications';
  static const String _prefKeySoundEffects = 'zeta_sound_effects';
  static const String _prefKeyAutoSave = 'zeta_auto_save';
  static const String _prefKeyTelemetry = 'zeta_telemetry';
  static const String _prefKeyCloudLastSync = 'zeta_cloud_last_sync';
  static const String _prefKeyCloudRecordsCount = 'zeta_cloud_records_count';

  static const List<Color> avatarColors = [
    Color(0xFF10B981), // Emerald Green
    Color(0xFF6750A4), // Iris Violet
    Color(0xFF006494), // Ocean Sapphire
    Color(0xFFD97706), // Warm Amber
    Color(0xFFE11D48), // Berry Rose
    Color(0xFF0D9488), // Glacier Teal
  ];

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

  // Variable Font Axes
  double _fontRoundness = 0; // 0..100
  double get fontRoundness => _fontRoundness;

  void setFontRoundness(double val) {
    if (_fontRoundness == val) return;
    _fontRoundness = val;
    notifyListeners();
    _saveSetting(_prefKeyFontRoundness, val);
  }

  double _fontWeight = 400; // 100..900
  double get fontWeight => _fontWeight;

  void setFontWeight(double val) {
    if (_fontWeight == val) return;
    _fontWeight = val;
    notifyListeners();
    _saveSetting(_prefKeyFontWeight, val);
  }

  double _fontWidth = 100; // 50..150
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

  // ─── Profile (Photo avatar with first-alphabet fallback) ────────────────
  String _userName = 'Abhishek';
  String get userName => _userName;

  String? _avatarPhoto;
  String? get avatarPhoto => _avatarPhoto;
  bool get hasAvatarPhoto => _avatarPhoto != null && _avatarPhoto!.trim().isNotEmpty;

  void setAvatarPhoto(String? photo) {
    final cleaned = photo?.trim();
    _avatarPhoto = (cleaned != null && cleaned.isNotEmpty) ? cleaned : null;
    notifyListeners();
    _saveSetting(_prefKeyAvatarPhoto, _avatarPhoto ?? '');
  }

  void clearAvatarPhoto() {
    setAvatarPhoto(null);
  }

  /// When no photo is set, avatar defaults strictly to the first alphabet of user's name
  String get avatarInitial {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }

  String get userInitials => avatarInitial;

  int _avatarColorIndex = 0;
  int get avatarColorIndex => _avatarColorIndex;
  Color get currentAvatarColor =>
      avatarColors[_avatarColorIndex.clamp(0, avatarColors.length - 1)];

  void setAvatarColorIndex(int index) {
    if (index < 0 || index >= avatarColors.length || _avatarColorIndex == index) return;
    _avatarColorIndex = index;
    notifyListeners();
    _saveSetting(_prefKeyAvatarColorIndex, index);
  }

  String _userEmail = 'abhishek@example.com';
  String get userEmail => _userEmail;

  void setUserEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty || _userEmail == trimmed) return;
    _userEmail = trimmed;
    notifyListeners();
    _saveSetting(_prefKeyUserEmail, trimmed);
  }

  void setUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _userName == trimmed) return;
    _userName = trimmed;
    notifyListeners();
    _saveSetting(_prefKeyUserName, trimmed);
  }

  // ─── Weather Location (Celsius Only) ────────────────────────────────────
  String _cityName = 'San Francisco, US';
  String get cityName => _cityName;

  WeatherData? _weatherData;
  WeatherData? get weatherData => _weatherData;

  bool _isWeatherLoading = false;
  bool get isWeatherLoading => _isWeatherLoading;

  void setCityName(String city) {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    _cityName = trimmed;
    notifyListeners();
    _saveSetting(_prefKeyCityName, trimmed);
    refreshWeather();
  }

  Future<void> refreshWeather() async {
    _isWeatherLoading = true;
    notifyListeners();
    try {
      final data = await WeatherService.fetchWeather(_cityName);
      _weatherData = data;
      _saveSetting(_prefKeyWeatherCache, jsonEncode(data.toJson()));
    } catch (_) {
      // Keep previous or fallback
    } finally {
      _isWeatherLoading = false;
      notifyListeners();
    }
  }

  // ─── Cross-Platform Sound & Notifications ────────────────────────────────
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
    if (val) {
      playChime();
    }
  }

  /// Subtle chime on button/checkbox clicks across Web, Windows, Android
  void playChime() {
    if (!_soundEffects) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Expressive alert sound + haptic feedback for timers/deadlines
  void playAlert() {
    if (_soundEffects) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
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

  // ─── Cloud Sync Snapshot ────────────────────────────────────────────────
  DateTime? _lastCloudSyncTime;
  DateTime? get lastCloudSyncTime => _lastCloudSyncTime;

  int _cloudSyncRecordsCount = 0;
  int get cloudSyncRecordsCount => _cloudSyncRecordsCount;

  Future<void> performCloudSync(int taskCount, int pomodoroCount) async {
    _lastCloudSyncTime = DateTime.now();
    _cloudSyncRecordsCount = taskCount + pomodoroCount;
    notifyListeners();

    final snapshot = {
      'timestamp': _lastCloudSyncTime!.toIso8601String(),
      'taskCount': taskCount,
      'pomodoroCount': pomodoroCount,
      'userName': _userName,
      'themeMode': _themeMode.name,
    };
    await _saveSetting(_prefKeyCloudLastSync, _lastCloudSyncTime!.toIso8601String());
    await _saveSetting(_prefKeyCloudRecordsCount, _cloudSyncRecordsCount);
    await _saveSetting('zeta_cloud_snapshot_payload', jsonEncode(snapshot));
  }

  // ─── Storage Calculation ────────────────────────────────────────────────
  Future<Map<String, dynamic>> calculateStorageUsage(
    int taskCount,
    int pomodoroCount,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalBytes = 0;
      for (final key in keys) {
        final val = prefs.get(key);
        if (val is String) {
          totalBytes += key.length + val.length;
        } else if (val is List<String>) {
          totalBytes += key.length + val.fold<int>(0, (s, e) => s + e.length);
        } else {
          totalBytes += key.length + 8;
        }
      }
      // Include estimated serialized tasks and sessions footprint
      totalBytes += (taskCount * 220) + (pomodoroCount * 95);
      final kb = totalBytes / 1024;
      final formatted = kb >= 1024
          ? '${(kb / 1024).toStringAsFixed(2)} MB'
          : '${kb.toStringAsFixed(1)} KB';
      return {
        'totalBytes': totalBytes,
        'formatted': formatted,
        'keysCount': keys.length,
      };
    } catch (_) {
      return {
        'totalBytes': 12400,
        'formatted': '12.4 KB',
        'keysCount': 12,
      };
    }
  }

  // ─── Import Configuration ───────────────────────────────────────────────
  Future<bool> importConfiguration(Map<String, dynamic> json) async {
    try {
      if (json['userName'] is String) setUserName(json['userName'] as String);
      if (json['userEmail'] is String) setUserEmail(json['userEmail'] as String);
      if (json.containsKey('avatarPhoto')) {
        setAvatarPhoto(json['avatarPhoto'] as String?);
      }
      if (json['themeMode'] is String) {
        final mode = ThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => _themeMode,
        );
        setThemeMode(mode);
      }
      if (json['seedColor'] is String) {
        final hex = (json['seedColor'] as String).replaceAll('#', '');
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) {
          setSeedColor(Color(0xFF000000 | parsed));
        }
      }
      if (json['variant'] is String) {
        final v = M3EColorVariant.values.firstWhere(
          (varItem) => varItem.name == json['variant'],
          orElse: () => _variant,
        );
        setVariant(v);
      }
      if (json['highContrast'] is bool) setHighContrast(json['highContrast'] as bool);
      if (json['animations'] is bool) setAnimations(json['animations'] as bool);
      if (json['compactDensity'] is bool) {
        setCompactDensity(json['compactDensity'] as bool);
      }
      if (json['fontChoice'] is String) setFontChoice(json['fontChoice'] as String);
      if (json['fontScale'] is String) setFontScale(json['fontScale'] as String);
      if (json['cornerStyle'] is String) setCornerStyle(json['cornerStyle'] as String);
      if (json['fontWeight'] is num) {
        setFontWeight((json['fontWeight'] as num).toDouble());
      }
      if (json['notifications'] is bool) {
        setNotifications(json['notifications'] as bool);
      }
      if (json['soundEffects'] is bool) {
        setSoundEffects(json['soundEffects'] as bool);
      }
      if (json['autoSave'] is bool) setAutoSave(json['autoSave'] as bool);
      if (json['telemetry'] is bool) setTelemetry(json['telemetry'] as bool);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
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
    _userEmail = 'abhishek@example.com';
    _avatarPhoto = null;
    _avatarColorIndex = 0;
    _cityName = 'San Francisco, US';
    _notifications = true;
    _soundEffects = true;
    _autoSave = true;
    _telemetry = false;
    _lastCloudSyncTime = null;
    _cloudSyncRecordsCount = 0;
    notifyListeners();
    _clearSettings();
    refreshWeather();
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
      _userEmail = prefs.getString(_prefKeyUserEmail) ?? _userEmail;
      final savedPhoto = prefs.getString(_prefKeyAvatarPhoto);
      _avatarPhoto = (savedPhoto != null && savedPhoto.isNotEmpty) ? savedPhoto : null;
      _avatarColorIndex = prefs.getInt(_prefKeyAvatarColorIndex) ?? _avatarColorIndex;
      _cityName = prefs.getString(_prefKeyCityName) ?? _cityName;
      _notifications = prefs.getBool(_prefKeyNotifications) ?? _notifications;
      _soundEffects = prefs.getBool(_prefKeySoundEffects) ?? _soundEffects;
      _autoSave = prefs.getBool(_prefKeyAutoSave) ?? _autoSave;
      _telemetry = prefs.getBool(_prefKeyTelemetry) ?? _telemetry;

      final cloudSyncStr = prefs.getString(_prefKeyCloudLastSync);
      if (cloudSyncStr != null) {
        _lastCloudSyncTime = DateTime.tryParse(cloudSyncStr);
      }
      _cloudSyncRecordsCount = prefs.getInt(_prefKeyCloudRecordsCount) ?? 0;

      final cachedWeather = prefs.getString(_prefKeyWeatherCache);
      if (cachedWeather != null) {
        try {
          _weatherData = WeatherData.fromJson(
            jsonDecode(cachedWeather) as Map<String, dynamic>,
          );
        } catch (_) {}
      }

      notifyListeners();

      // Refresh live weather telemetry in the background
      refreshWeather();
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

