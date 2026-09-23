import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../utils/task_date_formatter.dart';
import '../utils/haptics.dart';
import '../services/supabase_sync_service.dart';
import '../services/notification_service.dart';
import '../database/database_provider.dart';
import '../database/daos/task_dao.dart';

enum TaskFilter { all, completed, pending, revision }

enum TaskSortOption { creationDesc, creationAsc, dueDate, az, za }

class TaskProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _soundEffectsKey = 'zeta_sound_effects';
  static const String _sortByPrefKey = 'zeta_task_sort_by_v1';

  final SupabaseSyncService _syncService = SupabaseSyncService();
  late final TaskDao _taskDao;

  bool _isSyncing = false;

  bool _isDisposed = false;

  bool get isSyncing => _isSyncing || _syncService.isSyncing;
  DateTime? get lastSyncedAt => _syncService.lastSyncedAt;
  String? get syncError => _syncService.lastError;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  TaskProvider() {
    _taskDao = DatabaseProvider.instance.taskDao;
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _loadFromStorage();
  }

  final Completer<void> _loadCompleter = Completer<void>();
  Future<void> get loadFuture => _loadCompleter.future;

  final List<Task> _tasks = [];
  final List<Task> _binTasks = [];

  TaskFilter _filter = TaskFilter.all;
  TaskSortOption _sortBy = TaskSortOption.creationDesc;
  String _searchQuery = '';
  final Set<String> _expandedTaskIds = {};
  final Set<String> _selectedTaskIds = {};

  Task? _editingTask;
  String? _editingInitialTitle;
  bool _isEditPaneOpen = false;

  Task? get editingTask => _editingTask;
  String? get editingInitialTitle => _editingInitialTitle;
  bool get isEditPaneOpen => _isEditPaneOpen;

  void openEditPane({Task? task, String? initialTitle}) {
    _editingTask = task;
    _editingInitialTitle = initialTitle;
    _isEditPaneOpen = true;
    notifyListeners();
  }

  void closeEditPane() {
    if (_isEditPaneOpen) {
      _isEditPaneOpen = false;
      _editingTask = null;
      _editingInitialTitle = null;
      notifyListeners();
    }
  }

  List<Task> get allTasks => List.unmodifiable(_tasks);
  List<Task> get binTasks => List.unmodifiable(_binTasks);
  TaskFilter get filter => _filter;
  TaskSortOption get sortBy => _sortBy;
  String get searchQuery => _searchQuery;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.completed).length;
  int get pendingCount => _tasks.where((t) => !t.completed).length;
  int get binCount => _binTasks.length;

  bool isTaskExpanded(String taskId) => _expandedTaskIds.contains(taskId);

  List<Task>? _cachedFilteredAndSortedTasks;
  List<Task>? _cachedPendingTasks;
  List<Task>? _cachedCompletedTasks;
  List<Task>? _cachedRevisionTasks;

  void _invalidateCache() {
    _cachedFilteredAndSortedTasks = null;
    _cachedPendingTasks = null;
    _cachedCompletedTasks = null;
    _cachedRevisionTasks = null;
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    _invalidateCache();
    notifyListeners();
  }

  void clearSearchQuery() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    _invalidateCache();
    notifyListeners();
  }

  // ─── Multi-Selection Support ───────────────────────────────────────────────

  bool get isSelectionMode => _selectedTaskIds.isNotEmpty;
  Set<String> get selectedTaskIds => Set.unmodifiable(_selectedTaskIds);
  int get selectedCount => _selectedTaskIds.length;

  bool isTaskSelected(String taskId) => _selectedTaskIds.contains(taskId);

  void toggleTaskSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void selectTask(String taskId) {
    if (!_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.add(taskId);
      notifyListeners();
    }
  }

  void selectAllTasks() {
    final visible = filteredAndSortedTasks;
    _selectedTaskIds.addAll(visible.map((t) => t.id));
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedTaskIds.isNotEmpty) {
      _selectedTaskIds.clear();
      notifyListeners();
    }
  }

  void toggleTaskExpanded(String taskId) {
    if (_expandedTaskIds.contains(taskId)) {
      _expandedTaskIds.remove(taskId);
    } else {
      _expandedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    _invalidateCache();
    notifyListeners();
  }

  void setSortBy(TaskSortOption sortBy) {
    if (_sortBy == sortBy) return;
    _sortBy = sortBy;
    _invalidateCache();
    notifyListeners();
    _persistSortOption();
  }

  void cycleSortOption() {
    const values = TaskSortOption.values;
    final nextIndex = (values.indexOf(_sortBy) + 1) % values.length;
    _sortBy = values[nextIndex];
    _invalidateCache();
    notifyListeners();
    _persistSortOption();
  }

  Future<void> _persistSortOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sortByPrefKey, _sortBy.name);
    } catch (_) {}
  }

  String getSortLabel(TaskSortOption sort) {
    switch (sort) {
      case TaskSortOption.creationDesc:
        return 'Newest';
      case TaskSortOption.creationAsc:
        return 'Oldest';
      case TaskSortOption.dueDate:
        return 'Due Date';
      case TaskSortOption.az:
        return 'A \u2192 Z';
      case TaskSortOption.za:
        return 'Z \u2192 A';
    }
  }

  IconData getSortIcon(TaskSortOption sort) {
    switch (sort) {
      case TaskSortOption.creationDesc:
        return Icons.schedule_rounded;
      case TaskSortOption.creationAsc:
        return Icons.history_rounded;
      case TaskSortOption.dueDate:
        return Icons.event_rounded;
      case TaskSortOption.az:
        return Icons.arrow_downward_rounded;
      case TaskSortOption.za:
        return Icons.arrow_upward_rounded;
    }
  }

  /// Helper to check if a task is a revision task
  static bool isRevisionTask(Task task) {
    if (task.title.toLowerCase().contains('revise:')) return true;
    if (task.description != null &&
        task.description!.toLowerCase().contains('#revision')) {
      return true;
    }
    return false;
  }

  /// Optional callback invoked when a task is completed (for bi-directional sync)
  void Function(String taskId)? onTaskCompletedCallback;

  /// Returns true if [task] matches the given search query [query].
  static bool matchesSearch(Task task, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (task.title.toLowerCase().contains(q)) return true;
    if (task.description != null &&
        task.description!.toLowerCase().contains(q)) {
      return true;
    }
    if (task.dueDate != null && task.dueDate!.toLowerCase().contains(q)) {
      return true;
    }
    for (final subtask in task.subtasks) {
      if (subtask.title.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  /// Searches active tasks directly by [query].
  List<Task> searchTasks(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];
    return _tasks.where((t) => matchesSearch(t, q)).toList();
  }

  /// Searches bin tasks directly by [query].
  List<Task> searchBinTasks(String query) {
    final q = query.trim();
    if (q.isEmpty) return [];
    return _binTasks.where((t) => matchesSearch(t, q)).toList();
  }

  void _sortTaskList(List<Task> list) {
    list.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      if (a.completed && b.completed) {
        // By default, completed tasks are sorted newest first (most recently completed/updated, then created)
        final updateComp = b.updatedAt.compareTo(a.updatedAt);
        if (updateComp != 0) return updateComp;
        return b.createdAt.compareTo(a.createdAt);
      }
      switch (_sortBy) {
        case TaskSortOption.creationDesc:
          return b.createdAt.compareTo(a.createdAt);
        case TaskSortOption.creationAsc:
          return a.createdAt.compareTo(b.createdAt);
        case TaskSortOption.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            return b.createdAt.compareTo(a.createdAt);
          }
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          final dateA = TaskDateFormatter.parse(a.dueDate!);
          final dateB = TaskDateFormatter.parse(b.dueDate!);
          if (dateA != null && dateB != null) {
            final dateComp = dateA.compareTo(dateB);
            if (dateComp != 0) return dateComp;
          }
          return a.dueDate!.compareTo(b.dueDate!);
        case TaskSortOption.az:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case TaskSortOption.za:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });
  }

  List<Task> get filteredAndSortedTasks {
    if (_cachedFilteredAndSortedTasks != null) {
      return _cachedFilteredAndSortedTasks!;
    }
    final list = _tasks.where((task) {
      if (_filter == TaskFilter.pending && task.completed) return false;
      if (_filter == TaskFilter.completed && !task.completed) return false;
      if (_filter == TaskFilter.revision && !isRevisionTask(task)) return false;
      if (_searchQuery.isNotEmpty && !matchesSearch(task, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    _sortTaskList(list);

    _cachedFilteredAndSortedTasks = List.unmodifiable(list);
    return _cachedFilteredAndSortedTasks!;
  }

  List<Task> get pendingTasks {
    if (_cachedPendingTasks != null) return _cachedPendingTasks!;
    final list = _tasks.where((task) {
      if (task.completed) return false;
      if (_filter == TaskFilter.revision && !isRevisionTask(task)) return false;
      if (_searchQuery.isNotEmpty && !matchesSearch(task, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();
    _sortTaskList(list);
    _cachedPendingTasks = List.unmodifiable(list);
    return _cachedPendingTasks!;
  }

  List<Task> get completedTasks {
    if (_cachedCompletedTasks != null) return _cachedCompletedTasks!;
    final list = _tasks.where((task) {
      if (!task.completed) return false;
      if (_filter == TaskFilter.revision && !isRevisionTask(task)) return false;
      if (_searchQuery.isNotEmpty && !matchesSearch(task, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();
    _sortTaskList(list);
    _cachedCompletedTasks = List.unmodifiable(list);
    return _cachedCompletedTasks!;
  }

  List<Task> get revisionTasks {
    if (_cachedRevisionTasks != null) return _cachedRevisionTasks!;
    final list = _tasks.where((task) => isRevisionTask(task)).toList();
    _sortTaskList(list);
    _cachedRevisionTasks = List.unmodifiable(list);
    return _cachedRevisionTasks!;
  }

  Future<void> _loadFromStorage() async {
    try {
      // ── Load sort preference ────────────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final savedSort = prefs.getString(_sortByPrefKey);
      if (savedSort != null) {
        _sortBy = TaskSortOption.values.firstWhere(
          (e) => e.name == savedSort,
          orElse: () => TaskSortOption.creationDesc,
        );
      }

      // ── Load tasks from SQLite (drift) ──────────────────────────────────────
      final activeTasks = await _taskDao.getActiveTasks();
      final binTaskList = await _taskDao.getBinTasks();

      _tasks.clear();
      _tasks.addAll(activeTasks.where((t) => t.title.trim().isNotEmpty));

      _binTasks.clear();
      _binTasks.addAll(binTaskList.where((t) => t.title.trim().isNotEmpty));

      // ── 90-day bin eviction ─────────────────────────────────────────────────
      // Only bin tasks (already soft-deleted by the user) are evicted.
      // Completed tasks are intentionally kept so analytics remain accurate.
      final evicted = await _taskDao.evictOldBinTasks(retentionDays: 90);
      if (evicted > 0) {
        _binTasks.removeWhere((t) =>
            t.deletedAt != null &&
            t.deletedAt!.isBefore(
              DateTime.now().subtract(const Duration(days: 90)),
            ));
        debugPrint('TaskProvider: Evicted $evicted bin tasks older than 90 days.');
      }

      _invalidateCache();
      notifyListeners();
    } catch (e) {
      debugPrint('TaskProvider: _loadFromStorage error - $e');
    }

    // Subscribe to real-time changes from other clients
    _syncService.subscribeToRealtime(onChange: _handleRemoteTaskChange);

    // Initial background cloud sync (incremental — only fetches delta)
    await syncWithCloud();
    if (!_loadCompleter.isCompleted) {
      _loadCompleter.complete();
    }
  }

  void _handleRemoteTaskChange(Task remoteTask, String eventType) {
    _invalidateCache();
    if (eventType == 'DELETE') {
      _tasks.removeWhere((t) => t.id == remoteTask.id);
      _binTasks.removeWhere((t) => t.id == remoteTask.id);
      _taskDao.hardDelete(remoteTask.id);
    } else {
      if (remoteTask.title.trim().isEmpty) return; // Discard empty tasks

      if (remoteTask.deletedAt != null) {
        _tasks.removeWhere((t) => t.id == remoteTask.id);
        final binIdx = _binTasks.indexWhere((t) => t.id == remoteTask.id);
        if (binIdx != -1) {
          _binTasks[binIdx] = remoteTask;
        } else {
          _binTasks.insert(0, remoteTask);
        }
      } else {
        _binTasks.removeWhere((t) => t.id == remoteTask.id);
        final taskIdx = _tasks.indexWhere((t) => t.id == remoteTask.id);
        if (taskIdx != -1) {
          _tasks[taskIdx] = remoteTask;
        } else {
          _tasks.insert(0, remoteTask);
        }
      }
      _taskDao.upsertTask(remoteTask);
    }
    notifyListeners();
  }

  /// Synchronize all tasks with Supabase backend.
  ///
  /// Uses incremental sync: only fetches tasks updated since [_syncService.lastSyncedAt]
  /// to avoid pulling the entire task list on every sync cycle.
  Future<void> syncWithCloud({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final masterSync = prefs.getBool('zeta_master_sync_enabled') ?? true;
    if (!masterSync && !force) return;

    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      // First, push any offline modified or created tasks from SQLite
      final unsynced = await _taskDao.getUnsyncedTasks();
      for (final local in unsynced) {
        if (local.title.trim().isNotEmpty) {
          unawaited(_syncService.pushTask(local));
        }
      }

      // Incremental pull: only fetch tasks changed since last sync.
      // On force (or first run when lastSyncedAt is null), fetch everything.
      final since = force ? null : _syncService.lastSyncedAt;
      final remoteTasks = await _syncService.pullTasks(since: since);
      remoteTasks.removeWhere((t) => t.title.trim().isEmpty);

      final isFullPull = since == null;
      if (isFullPull) {
        final remoteIds = remoteTasks.map((t) => t.id).toSet();

        // 1. Reconcile Bin tasks:
        // Any local bin task absent from the remote DB was permanently deleted in Supabase.
        // It must be pruned from _binTasks and hard-deleted from SQLite.
        final binTasksToPrune =
            _binTasks.where((t) => !remoteIds.contains(t.id)).toList();
        if (binTasksToPrune.isNotEmpty) {
          final pruneIds = binTasksToPrune.map((t) => t.id).toSet();
          _binTasks.removeWhere((t) => pruneIds.contains(t.id));
          await _taskDao.hardDeleteMany(pruneIds);
          debugPrint(
            'TaskProvider: Pruned ${pruneIds.length} bin tasks absent from remote DB.',
          );
        }

        // 2. Reconcile Active tasks:
        // Any active task that was already synced previously (lastSyncedAt != null)
        // but no longer exists in remote DB was deleted remotely.
        final activeTasksToPrune = _tasks
            .where((t) => t.lastSyncedAt != null && !remoteIds.contains(t.id))
            .toList();
        if (activeTasksToPrune.isNotEmpty) {
          final pruneIds = activeTasksToPrune.map((t) => t.id).toSet();
          _tasks.removeWhere((t) => pruneIds.contains(t.id));
          await _taskDao.hardDeleteMany(pruneIds);
          debugPrint(
            'TaskProvider: Pruned ${pruneIds.length} active tasks absent from remote DB.',
          );
        }
      }

      if (remoteTasks.isNotEmpty) {
        for (final remote in remoteTasks) {
          if (remote.deletedAt != null) {
            final idx = _binTasks.indexWhere((t) => t.id == remote.id);
            if (idx != -1) {
              _binTasks[idx] = remote;
            } else {
              _binTasks.add(remote);
            }
            _tasks.removeWhere((t) => t.id == remote.id);
          } else {
            final idx = _tasks.indexWhere((t) => t.id == remote.id);
            if (idx != -1) {
              _tasks[idx] = remote;
            } else {
              _tasks.add(remote);
            }
            _binTasks.removeWhere((t) => t.id == remote.id);
          }
        }
        // Persist merged remote tasks to local SQLite
        await _taskDao.upsertAll(remoteTasks);
        await saveTasks();
      } else if (isFullPull) {
        await saveTasks();
      }

      // Clean up any empty tasks that may exist locally
      _tasks.removeWhere((t) => t.title.trim().isEmpty);
      _binTasks.removeWhere((t) => t.title.trim().isEmpty);
    } catch (e) {
      debugPrint('TaskProvider: syncWithCloud error - $e');
    } finally {
      _isSyncing = false;
      _invalidateCache();
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncWithCloud();
    }
  }

  Future<void> saveTasks() async {
    // Persist to SQLite via drift DAO (replaces SharedPreferences JSON blob).
    // The DAO handles upserts efficiently — only changed rows are rewritten.
    try {
      await _taskDao.upsertAll([..._tasks, ..._binTasks]);
    } catch (e) {
      debugPrint('TaskProvider: saveTasks error - $e');
    }
  }

  void _playSoundIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool(_soundEffectsKey) ?? true;
      if (soundEnabled) {
        SystemSound.play(SystemSoundType.click);
        ZetaHaptics.light();
      }
    } catch (_) {}
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      task.completed = !task.completed;
      task.updatedAt = DateTime.now();
      if (task.completed) {
        _playSoundIfEnabled();
        // Cancel any pending reminder when task is completed.
        NotificationService.instance.cancelTaskReminder(task.id);
        onTaskCompletedCallback?.call(task.id);
      } else {
        // Re-schedule if un-completing a task that has a due time.
        NotificationService.instance.scheduleTaskReminder(task);
      }
      _invalidateCache();
      notifyListeners();
      unawaited(_taskDao.upsertTask(task));
      unawaited(_syncService.pushTask(task));
    }
  }

  void toggleSubtask(String taskId, String subtaskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final subtaskIndex =
          _tasks[taskIndex].subtasks.indexWhere((s) => s.id == subtaskId);
      if (subtaskIndex != -1) {
        final isNowComplete =
            !_tasks[taskIndex].subtasks[subtaskIndex].completed;
        _tasks[taskIndex].subtasks[subtaskIndex].completed = isNowComplete;
        _tasks[taskIndex].updatedAt = DateTime.now();
        if (isNowComplete) {
          _playSoundIfEnabled();
        }
        _invalidateCache();
        notifyListeners();
        unawaited(_taskDao.upsertTask(_tasks[taskIndex]));
        unawaited(_syncService.pushTask(_tasks[taskIndex]));
      }
    }
  }

  Future<String> addTask({
    required String title,
    String? description,
    String? dueDate,
    bool hasTime = false,
    String? dueTime,
    List<Subtask>? subtasks,
  }) async {
    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      hasTime: hasTime,
      dueTime: dueTime,
      subtasks: subtasks ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks.insert(0, newTask);
    _invalidateCache();
    notifyListeners();
    unawaited(_taskDao.upsertTask(newTask));
    unawaited(_syncService.pushTask(newTask));
    // Schedule a system notification if the task has a due time.
    NotificationService.instance.scheduleTaskReminder(newTask);
    return newTask.id;
  }

  void updateTask(
    String id, {
    required String title,
    String? description,
    String? dueDate,
    bool hasTime = false,
    String? dueTime,
    List<Subtask>? subtasks,
    bool? completed,
  }) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      task.title = title;
      task.description = description;
      task.dueDate = dueDate;
      task.hasTime = hasTime;
      task.dueTime = dueTime;
      task.updatedAt = DateTime.now();
      if (subtasks != null) task.subtasks = subtasks;
      if (completed != null) task.completed = completed;
      _invalidateCache();
      notifyListeners();
      unawaited(_taskDao.upsertTask(task));
      unawaited(_syncService.pushTask(task));
      // Re-schedule (or cancel) reminder based on updated due time.
      NotificationService.instance.scheduleTaskReminder(task);
    }
  }

  /// Moves active task to bin
  void deleteTask(String id) {
    _selectedTaskIds.remove(id);
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks.removeAt(index);
      task.deletedAt = DateTime.now();
      task.updatedAt = DateTime.now();
      _binTasks.insert(0, task);
      _invalidateCache();
      notifyListeners();
      unawaited(_taskDao.upsertTask(task));
      unawaited(_syncService.pushTask(task));
      // Cancel scheduled reminder when task is deleted.
      NotificationService.instance.cancelTaskReminder(task.id);
    }
  }

  /// Batch deletes all currently selected tasks into the bin
  void deleteSelectedTasks() {
    if (_selectedTaskIds.isEmpty) return;
    final idsToDelete = _selectedTaskIds.toList();
    _selectedTaskIds.clear();

    final tasksToBin = <Task>[];
    for (final id in idsToDelete) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final task = _tasks.removeAt(index);
        task.deletedAt = DateTime.now();
        task.updatedAt = DateTime.now();
        _binTasks.insert(0, task);
        tasksToBin.add(task);
      }
    }

    _invalidateCache();
    notifyListeners();
    if (tasksToBin.isNotEmpty) {
      unawaited(_taskDao.upsertAll(tasksToBin));
      for (final t in tasksToBin) {
        unawaited(_syncService.pushTask(t));
      }
    }
    ZetaHaptics.medium();
  }

  /// Batch marks all currently selected tasks as complete (or incomplete)
  void completeSelectedTasks({bool? markAs}) {
    if (_selectedTaskIds.isEmpty) return;
    final idsToToggle = _selectedTaskIds.toList();
    final selectedTasks =
        _tasks.where((t) => idsToToggle.contains(t.id)).toList();

    // If markAs is null, determine target: if any are incomplete, mark all complete; else incomplete
    final targetState = markAs ?? selectedTasks.any((t) => !t.completed);

    for (final task in selectedTasks) {
      task.completed = targetState;
      task.updatedAt = DateTime.now();
    }

    if (targetState) {
      _playSoundIfEnabled();
    }

    _selectedTaskIds.clear();
    _invalidateCache();
    notifyListeners();
    if (selectedTasks.isNotEmpty) {
      unawaited(_taskDao.upsertAll(selectedTasks));
      for (final task in selectedTasks) {
        unawaited(_syncService.pushTask(task));
      }
    }
    ZetaHaptics.medium();
  }

  /// Restores task from bin back to active tasks
  void restoreTask(String id) {
    final index = _binTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _binTasks.removeAt(index);
      task.deletedAt = null;
      task.updatedAt = DateTime.now();
      _tasks.insert(0, task);
      _invalidateCache();
      notifyListeners();
      unawaited(_taskDao.upsertTask(task));
      unawaited(_syncService.pushTask(task));
    }
  }

  /// Permanently removes task from bin
  Future<void> permanentlyDeleteTask(String id) async {
    if (_binTasks.any((t) => t.id == id)) {
      _binTasks.removeWhere((t) => t.id == id);
    }
    await _taskDao.hardDelete(id);
    _syncService.deleteTask(id, soft: false);
    notifyListeners();
  }

  /// Permanently removes all tasks from bin
  Future<void> emptyBin() async {
    final tasksToDelete = List<Task>.from(_binTasks);
    _binTasks.clear();
    notifyListeners();

    for (final task in tasksToDelete) {
      _syncService.deleteTask(task.id, soft: false);
    }
    await _taskDao.clearBin();
  }

  /// Restores all tasks from bin back to active tasks
  void restoreAllFromBin() {
    final restored = List<Task>.from(_binTasks);
    for (final task in restored) {
      task.deletedAt = null;
      task.updatedAt = DateTime.now();
      _tasks.insert(0, task);
    }
    _binTasks.clear();
    _invalidateCache();
    notifyListeners();
    if (restored.isNotEmpty) {
      unawaited(_taskDao.upsertAll(restored));
      for (final task in restored) {
        unawaited(_syncService.pushTask(task));
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _syncService.dispose();
    super.dispose();
  }
}
