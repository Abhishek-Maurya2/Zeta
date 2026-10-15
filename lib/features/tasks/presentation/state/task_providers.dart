import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/task.dart';
import '../../domain/task_filter.dart';
import '../../data/task_repository.dart';

/// Stream of all active tasks from local SQLite.
/// Managed off-thread by Drift, zero memory leaks with autoDispose.
final activeTasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchActiveTasks();
});

/// Stream of bin tasks from local SQLite.
final binTasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchBinTasks();
});

/// Current active task filter (all, completed, pending, revision).
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

/// Current active task sort order.
final taskSortProvider =
    StateProvider<TaskSortOption>((ref) => TaskSortOption.creationDesc);

/// Search query string.
final taskSearchQueryProvider = StateProvider<String>((ref) => '');

/// Memoized filtered and sorted tasks.
/// Only recalculates when the underlying stream, filter, or query changes.
/// Prevents redundant widget rebuilds across the app.
final filteredTasksProvider = Provider.autoDispose<List<Task>>((ref) {
  final tasksAsync = ref.watch(activeTasksStreamProvider);
  final tasks = tasksAsync.value ?? const [];
  final filter = ref.watch(taskFilterProvider);
  final query = ref.watch(taskSearchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(taskSortProvider);

  // 1. Filter
  var list = tasks.where((t) {
    if (t.deletedAt != null) return false;
    switch (filter) {
      case TaskFilter.all:
        return true;
      case TaskFilter.completed:
        return t.completed;
      case TaskFilter.pending:
        return !t.completed;
      case TaskFilter.revision:
        final title = t.title.toLowerCase();
        final desc = t.description?.toLowerCase() ?? '';
        return title.contains('revise:') || desc.contains('#revision');
    }
  }).toList();

  // 2. Search query filter
  if (query.isNotEmpty) {
    list = list.where((t) {
      final titleMatch = t.title.toLowerCase().contains(query);
      final descMatch = t.description?.toLowerCase().contains(query) ?? false;
      return titleMatch || descMatch;
    }).toList();
  }

  // 3. Sort
  list.sort((a, b) {
    switch (sort) {
      case TaskSortOption.creationDesc:
        return b.createdAt.compareTo(a.createdAt);
      case TaskSortOption.creationAsc:
        return a.createdAt.compareTo(b.createdAt);
      case TaskSortOption.dueDate:
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      case TaskSortOption.az:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case TaskSortOption.za:
        return b.title.toLowerCase().compareTo(a.title.toLowerCase());
    }
  });

  return list;
});

/// Bulk task selection notifier.
class SelectedTasksNotifier extends StateNotifier<Set<String>> {
  SelectedTasksNotifier() : super(const {});

  void toggle(String id) {
    if (state.contains(id)) {
      state = Set.from(state)..remove(id);
    } else {
      state = Set.from(state)..add(id);
    }
  }

  void selectAll(Iterable<String> ids) {
    state = Set.from(ids);
  }

  void clear() {
    if (state.isNotEmpty) {
      state = const {};
    }
  }
}

final selectedTaskIdsProvider =
    StateNotifierProvider<SelectedTasksNotifier, Set<String>>((ref) {
  return SelectedTasksNotifier();
});

/// Currently selected task ID for editing in the Material 3 Expressive Supporting Pane.
final activeEditingTaskIdProvider = StateProvider<String?>((ref) => null);

/// Currently active editing task resolved from the active task stream.
final activeEditingTaskProvider = Provider.autoDispose<Task?>((ref) {
  final taskId = ref.watch(activeEditingTaskIdProvider);
  if (taskId == null) return null;
  final tasks = ref.watch(activeTasksStreamProvider).value ?? const [];
  try {
    return tasks.firstWhere((t) => t.id == taskId);
  } catch (_) {
    return null;
  }
});
