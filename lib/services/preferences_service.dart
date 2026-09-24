import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../database/database_provider.dart';
import '../models/task.dart';

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
      AppLogger.error(
        'Failed to initialize PreferencesService',
        error: e,
        stackTrace: st,
      );
    }
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'PreferencesService must be initialized before access. Call PreferencesService.instance.init() first.',
      );
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
  static const String keyPendingPermanentDeletions =
      'zeta_pending_permanent_deletions_v1';
  static const String keyPendingSubjectDeletions =
      'zeta_pending_subject_deletions_v1';
  static const String keyPendingTopicDeletions =
      'zeta_pending_topic_deletions_v1';
  static const String keyPendingRevisionSubjectUpserts =
      'zeta_pending_revision_subject_upserts_v1';
  static const String keyPendingRevisionTopicUpserts =
      'zeta_pending_revision_topic_upserts_v1';
  static const String keyPendingPomodoroClear =
      'zeta_pending_pomodoro_clear_v1';

  static String accountScopedKey(String key, String userId) => '$key.$userId';

  /// Moves pre-auth offline operations into the first account's durable queue.
  Future<void> claimLegacySyncQueues(String userId) async {
    final dao = DatabaseProvider.instance.syncOutboxDao;
    final queueDefinitions =
        <({String key, String feature, String entity, String operation})>[
          (
            key: keyPendingRevisionSubjectUpserts,
            feature: 'revisions',
            entity: 'subject',
            operation: 'upsert',
          ),
          (
            key: keyPendingRevisionTopicUpserts,
            feature: 'revisions',
            entity: 'topic',
            operation: 'upsert',
          ),
          (
            key: keyPendingPermanentDeletions,
            feature: 'tasks',
            entity: 'task',
            operation: 'delete',
          ),
          (
            key: keyPendingSubjectDeletions,
            feature: 'revisions',
            entity: 'subject',
            operation: 'delete',
          ),
          (
            key: keyPendingTopicDeletions,
            feature: 'revisions',
            entity: 'topic',
            operation: 'delete',
          ),
        ];
    for (final definition in queueDefinitions) {
      final scopedKey = accountScopedKey(definition.key, userId);
      final ids = <String>{
        ...?getStringList(definition.key),
        ...?getStringList(scopedKey),
      };
      for (final id in ids) {
        await dao.enqueue(
          userId: userId,
          feature: definition.feature,
          entityType: definition.entity,
          entityId: definition.feature == 'tasks' ? Task.supabaseIdFor(id) : id,
          operation: definition.operation,
        );
      }
      await remove(definition.key);
      await remove(scopedKey);
    }
    final clearKeys = [
      keyPendingPomodoroClear,
      accountScopedKey(keyPendingPomodoroClear, userId),
    ];
    if (clearKeys.any((key) => getBool(key) == true)) {
      await dao.enqueue(
        userId: userId,
        feature: 'pomodoro',
        entityType: 'session',
        entityId: '_all',
        operation: 'clear',
      );
    }
    for (final key in clearKeys) {
      await remove(key);
    }
  }

  // ─── Generic Helpers ───────────────────────────────────────────────────────
  String? getString(String key) => _prefs?.getString(key);
  Future<bool> setString(String key, String value) async =>
      _prefs?.setString(key, value) ?? false;

  List<String>? getStringList(String key) => _prefs?.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) async =>
      _prefs?.setStringList(key, value) ?? false;

  bool? getBool(String key) => _prefs?.getBool(key);
  Future<bool> setBool(String key, bool value) async =>
      _prefs?.setBool(key, value) ?? false;

  int? getInt(String key) => _prefs?.getInt(key);
  Future<bool> setInt(String key, int value) async =>
      _prefs?.setInt(key, value) ?? false;

  double? getDouble(String key) => _prefs?.getDouble(key);
  Future<bool> setDouble(String key, double value) async =>
      _prefs?.setDouble(key, value) ?? false;

  Future<bool> remove(String key) async => _prefs?.remove(key) ?? false;
}
