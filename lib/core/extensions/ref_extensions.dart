import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tasks/data/task_repository.dart';
import '../../features/tasks/data/task_preferences.dart';
import '../../features/pomodoro/data/pomodoro_repository.dart';
import '../../features/pomodoro/data/pomodoro_preferences.dart';
import '../../features/revision/data/revision_repository.dart';
import '../../features/revision/data/revision_preferences.dart';
import '../../features/theme/data/theme_preferences.dart';
import '../../features/weather/data/weather_preferences.dart';
import '../sync/sync_coordinator.dart';

/// Ergonomic hooks for WidgetRef to directly access repositories, preferences, and services.
extension ZetaWidgetRefX on WidgetRef {
  // ─── Repositories ──────────────────────────────────────────────────────────
  TaskRepository get taskRepo => read(taskRepositoryProvider);
  PomodoroRepository get pomodoroRepo => read(pomodoroRepositoryProvider);
  RevisionRepository get revisionRepo => read(revisionRepositoryProvider);

  // ─── Scoped Preferences ────────────────────────────────────────────────────
  TaskPreferences get taskPrefs => read(taskPreferencesProvider);
  PomodoroPreferences get pomodoroPrefs => read(pomodoroPreferencesProvider);
  RevisionPreferences get revisionPrefs => read(revisionPreferencesProvider);
  ThemePreferences get themePrefs => read(themePreferencesProvider);
  WeatherPreferences get weatherPrefs => read(weatherPreferencesProvider);

  // ─── Sync ──────────────────────────────────────────────────────────────────
  SyncCoordinator get syncCoordinator => read(syncCoordinatorProvider.notifier);
  SyncState get syncState => watch(syncCoordinatorProvider);
}

/// Ergonomic hooks for Ref inside providers.
extension ZetaRefX on Ref {
  TaskRepository get taskRepo => read(taskRepositoryProvider);
  PomodoroRepository get pomodoroRepo => read(pomodoroRepositoryProvider);
  RevisionRepository get revisionRepo => read(revisionRepositoryProvider);

  TaskPreferences get taskPrefs => read(taskPreferencesProvider);
  PomodoroPreferences get pomodoroPrefs => read(pomodoroPreferencesProvider);
  RevisionPreferences get revisionPrefs => read(revisionPreferencesProvider);
  ThemePreferences get themePrefs => read(themePreferencesProvider);
  WeatherPreferences get weatherPrefs => read(weatherPreferencesProvider);

  SyncCoordinator get syncCoordinator => read(syncCoordinatorProvider.notifier);
}
