import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tasks/data/task_repository.dart';
import '../../features/tasks/data/task_preferences.dart';
import '../../features/pomodoro/data/pomodoro_repository.dart';
import '../../features/pomodoro/data/pomodoro_preferences.dart';
import '../../features/revision/data/revision_repository.dart';
import '../../features/revision/data/revision_preferences.dart';
import '../../features/theme/data/theme_preferences.dart';
import '../../features/weather/data/weather_preferences.dart';
import '../../features/tasks/presentation/state/task_providers.dart';
import '../../models/task.dart';
import '../../features/profile/data/profile_repository.dart';
import '../pane/active_pane_coordinator.dart';
import '../sync/sync_coordinator.dart';

/// Ergonomic hooks for WidgetRef to directly access repositories, preferences, and services.
extension ZetaWidgetRefX on WidgetRef {
  // ─── Repositories ──────────────────────────────────────────────────────────
  TaskRepository get taskRepo => read(taskRepositoryProvider);
  PomodoroRepository get pomodoroRepo => read(pomodoroRepositoryProvider);
  RevisionRepository get revisionRepo => read(revisionRepositoryProvider);
  ProfileRepository get profileRepo => read(profileRepositoryProvider);

  // ─── Scoped Preferences ────────────────────────────────────────────────────
  TaskPreferences get taskPrefs => read(taskPreferencesProvider);
  PomodoroPreferences get pomodoroPrefs => read(pomodoroPreferencesProvider);
  RevisionPreferences get revisionPrefs => read(revisionPreferencesProvider);
  ThemePreferences get themePrefs => read(themePreferencesProvider);
  WeatherPreferences get weatherPrefs => read(weatherPreferencesProvider);

  // ─── Sync ──────────────────────────────────────────────────────────────────
  SyncCoordinator get syncCoordinator => read(syncCoordinatorProvider.notifier);
  SyncState get syncState => watch(syncCoordinatorProvider);

  // ─── Active Pane Coordinator ──────────────────────────────────────────────
  ActivePaneCoordinator get activePaneCoordinator =>
      read(activePaneProvider.notifier);
  ActivePaneConfig? get activePane => watch(activePaneProvider);

  // ─── Task Reactive Hooks ──────────────────────────────────────────────────
  List<Task> get pendingTasks => watch(pendingTasksProvider);
  List<Task> get pendingNonRevisionTasks => watch(pendingNonRevisionTasksProvider);
  List<Task> get completedTasks => watch(completedTasksProvider);
  List<Task> get revisionTasks => watch(revisionTasksProvider);
  ({int total, int pending, int completed, int revision}) get taskCounts =>
      watch(taskCountsProvider);
  List<Subtask> subtasksFor(String taskId) => watch(subtasksProvider(taskId));
  Task? taskById(String taskId) => watch(taskByIdProvider(taskId));
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
