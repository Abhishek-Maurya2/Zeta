import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_client.dart';
import '../domain/task_filter.dart';

/// Scoped preferences for Tasks domain.
class TaskPreferences {
  static const String keyTaskFilter = 'zeta_task_filter_v1';
  static const String keyTaskSortBy = 'zeta_task_sort_by_v1';
  static const String keyCompletedTaskSortBy = 'zeta_completed_task_sort_by_v1';
  static const String keySwapSwipeActions = 'zeta_swap_swipe_actions';
  static const String keySoundEffects = 'zeta_sound_effects';

  final PreferencesClient _client;

  TaskPreferences(this._client);

  TaskFilter getFilter() {
    final raw = _client.getString(keyTaskFilter);
    if (raw == null) return TaskFilter.all;
    return TaskFilter.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => TaskFilter.all,
    );
  }

  Future<void> setFilter(TaskFilter filter) async {
    await _client.setString(keyTaskFilter, filter.name);
  }

  TaskSortOption getSortOption() {
    final raw = _client.getString(keyTaskSortBy);
    if (raw == null) return TaskSortOption.creationDesc;
    return TaskSortOption.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => TaskSortOption.creationDesc,
    );
  }

  Future<void> setSortOption(TaskSortOption sort) async {
    await _client.setString(keyTaskSortBy, sort.name);
  }

  bool get swapSwipeActions => _client.getBool(keySwapSwipeActions) ?? false;
  Future<void> setSwapSwipeActions(bool value) async {
    await _client.setBool(keySwapSwipeActions, value);
  }

  bool get soundEffectsEnabled => _client.getBool(keySoundEffects) ?? true;
  Future<void> setSoundEffectsEnabled(bool value) async {
    await _client.setBool(keySoundEffects, value);
  }
}

final taskPreferencesProvider = Provider<TaskPreferences>((ref) {
  final client = ref.watch(preferencesClientProvider);
  return TaskPreferences(client);
});
