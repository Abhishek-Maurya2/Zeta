import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/attachment.dart';
import '../utils/task_date_formatter.dart';
import '../utils/haptics.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../database/daos/task_dao.dart';
import '../services/supabase_sync_service.dart';
import '../repositories/task_repository.dart';

enum TaskFilter { all, completed, pending, revision }

enum TaskSortOption { creationDesc, creationAsc, dueDate, az, za }

class TaskProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _soundEffectsKey = PreferencesService.keySoundEffects;
  static const String _sortByPrefKey = PreferencesService.keyTaskSortBy;

  final TaskRepository _repository;

  bool _isSyncing = false;
  bool _isDisposed = false;

  bool get isSyncing => _isSyncing || _repository.isSyncing;
  DateTime? get lastSyncedAt => _repository.lastSyncedAt;
  String? get syncError => _repository.syncError;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  TaskProvider({
    TaskRepository? repository,
    TaskDao? taskDao,
    SupabaseSyncService? syncService,
  }) : _repository = repository ??
            TaskRepository(
              taskDao: taskDao,
              syncService: syncService,
            ) {
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
  String? _editingInitialDescription;
  String? _editingInitialDueDate;
  String? _editingInitialDueTime;
  bool? _editingInitialHasTime;
  List<Subtask>? _editingInitialSubtasks;
  bool _isEditPaneOpen = false;

  Map<String, dynamic>? _taskFormDraft;
  Map<String, dynamic>? get taskFormDraft => _taskFormDraft;

  Task? get editingTask => _editingTask;
  String? get editingInitialTitle => _editingInitialTitle;
  String? get editingInitialDescription => _editingInitialDescription;
  String? get editingInitialDueDate => _editingInitialDueDate;
  String? get editingInitialDueTime => _editingInitialDueTime;
  bool? get editingInitialHasTime => _editingInitialHasTime;
  List<Subtask>? get editingInitialSubtasks => _editingInitialSubtasks;
  bool get isEditPaneOpen => _isEditPaneOpen;

  void updateTaskDraft({
    String? title,
    String? description,
    String? dueDate,
    String? dueTime,
    bool? hasTime,
    List<String>? subtasks,
    String? editingTaskId,
    bool? isCreating,
  }) {
    _taskFormDraft = {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'hasTime': hasTime,
      'subtasks': subtasks,
      'editingTaskId': editingTaskId,
      'isCreating': isCreating ?? (editingTaskId == null),
    };
    notifyListeners();
  }

  void clearTaskDraft() {
    if (_taskFormDraft != null) {
      _taskFormDraft = null;
      notifyListeners();
    }
  }

  void openEditPane({
    Task? task,
    String? initialTitle,
    String? initialDescription,
    String? initialDueDate,
    String? initialDueTime,
    bool? initialHasTime,
    List<Subtask>? initialSubtasks,
  }) {
    _editingTask = task;
    _editingInitialTitle = initialTitle;
    _editingInitialDescription = initialDescription;
    _editingInitialDueDate = initialDueDate;
    _editingInitialDueTime = initialDueTime;
    _editingInitialHasTime = initialHasTime;
    _editingInitialSubtasks = initialSubtasks;
    _isEditPaneOpen = true;
    notifyListeners();
  }

  void closeEditPane() {
    if (_isEditPaneOpen) {
      _isEditPaneOpen = false;
      _editingTask = null;
      _editingInitialTitle = null;
      _editingInitialDescription = null;
      _editingInitialDueDate = null;
      _editingInitialDueTime = null;
      _editingInitialHasTime = null;
      _editingInitialSubtasks = null;
      _taskFormDraft = null;
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
      final prefs = PreferencesService.instance;
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
      final prefs = PreferencesService.instance;
      final savedSort = prefs.getString(_sortByPrefKey);
      if (savedSort != null) {
        _sortBy = TaskSortOption.values.firstWhere(
          (e) => e.name == savedSort,
          orElse: () => TaskSortOption.creationDesc,
        );
      }

      // ── Load tasks from SQLite (drift) ──────────────────────────────────────
      final activeTasks = await _repository.getActiveTasks();
      final binTaskList = await _repository.getBinTasks();

      _tasks.clear();
      _tasks.addAll(activeTasks.where((t) => t.title.trim().isNotEmpty));

      _binTasks.clear();
      _binTasks.addAll(binTaskList.where((t) => t.title.trim().isNotEmpty));

      // ── 90-day bin eviction ─────────────────────────────────────────────────
      // Only bin tasks (already soft-deleted by the user) are evicted.
      // Completed tasks are intentionally kept so analytics remain accurate.
      final evicted = await _repository.evictOldBinTasks(retentionDays: 90);
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
    _repository.subscribeToRealtime(onChange: _handleRemoteTaskChange);

    // Initial background cloud sync (full, paginated reconciliation)
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
      unawaited(_repository.deleteTask(remoteTask.id, pushToCloud: false));
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
      unawaited(_repository.saveTask(remoteTask, pushToCloud: false));
    }
    notifyListeners();
  }

  /// Synchronize all tasks with Supabase backend.
  ///
  /// Reconciles a complete paginated remote snapshot with local SQLite state.
  Future<void> syncWithCloud({bool force = false}) async {
    final masterSync = PreferencesService.instance.getBool('zeta_master_sync_enabled') ?? true;
    if (!masterSync && !force) return;

    _repository.subscribeToRealtime(onChange: _handleRemoteTaskChange);

    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      // The repository drains its durable outbox before returning a remote
      // snapshot. Null means the pull failed and cannot be used to reconcile.
      final remoteSnapshot = await _repository.pullRemoteSnapshot();
      if (remoteSnapshot == null) return;
      final persistedTasks = <Task>[
        ...await _repository.getActiveTasks(),
        ...await _repository.getBinTasks(),
      ];
      final persistedById = {for (final task in persistedTasks) task.id: task};
      for (final task in [..._tasks, ..._binTasks]) {
        final persisted = persistedById[task.id];
        if (persisted != null &&
            persisted.updatedAt.millisecondsSinceEpoch ==
                task.updatedAt.millisecondsSinceEpoch) {
          task.lastSyncedAt = persisted.lastSyncedAt;
        }
      }

      // Use a complete paginated snapshot: the last local push timestamp is
      // not a safe remote change cursor across devices or clock skew.
      final remoteTasks = remoteSnapshot;
      remoteTasks.removeWhere((t) => t.title.trim().isEmpty);

      final remoteIds = remoteTasks.map((t) => t.id).toSet();
      bool isLocallyDirty(Task task) =>
          task.lastSyncedAt == null || task.updatedAt.isAfter(task.lastSyncedAt!);
      final localDirtyIds = <String>{
        ..._tasks.where(isLocallyDirty).map((task) => task.id),
        ..._binTasks.where(isLocallyDirty).map((task) => task.id),
      };
      // Local unsynced edits take precedence until their outbox retry succeeds.
      remoteTasks.removeWhere((task) => localDirtyIds.contains(task.id));

      // 1. Reconcile Bin tasks. Keep local rows that have never synced.
      final binTasksToPrune = _binTasks
          .where((t) =>
              !localDirtyIds.contains(t.id) && !remoteIds.contains(t.id))
          .toList();
      if (binTasksToPrune.isNotEmpty) {
        final pruneIds = binTasksToPrune.map((t) => t.id).toSet();
        _binTasks.removeWhere((t) => pruneIds.contains(t.id));
        await _repository.deleteMultipleTasks(pruneIds, pushToCloud: false);
        debugPrint(
          'TaskProvider: Pruned ${pruneIds.length} bin tasks absent from remote DB.',
        );
      }

      // 2. Reconcile active tasks. A synced local row absent remotely was
      // permanently deleted on another device.
      final activeTasksToPrune = _tasks
          .where((t) =>
              !localDirtyIds.contains(t.id) && !remoteIds.contains(t.id))
          .toList();
      if (activeTasksToPrune.isNotEmpty) {
        final pruneIds = activeTasksToPrune.map((t) => t.id).toSet();
        _tasks.removeWhere((t) => pruneIds.contains(t.id));
        await _repository.deleteMultipleTasks(pruneIds, pushToCloud: false);
        debugPrint(
          'TaskProvider: Pruned ${pruneIds.length} active tasks absent from remote DB.',
        );
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
        await _repository.saveTasksBatch(remoteTasks, pushToCloud: false);
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
    try {
      await _repository.saveTasksBatch([..._tasks, ..._binTasks], pushToCloud: false);
    } catch (e) {
      debugPrint('TaskProvider: saveTasks error - $e');
    }
  }

  void _playSoundIfEnabled() async {
    try {
      final soundEnabled = PreferencesService.instance.getBool(_soundEffectsKey) ?? true;
      if (soundEnabled) {
        await SystemSound.play(SystemSoundType.click);
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
      unawaited(_repository.saveTask(task));
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
        unawaited(_repository.saveTask(_tasks[taskIndex]));
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
    List<AttachmentItem>? attachments,
  }) async {
    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      hasTime: hasTime,
      dueTime: dueTime,
      subtasks: subtasks ?? [],
      attachments: attachments ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks.insert(0, newTask);
    _invalidateCache();
    notifyListeners();
    unawaited(_repository.saveTask(newTask));
    // Schedule a system notification if the task has a due time.
    unawaited(NotificationService.instance.scheduleTaskReminder(newTask));
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
    List<AttachmentItem>? attachments,
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
      if (attachments != null) task.attachments = attachments;
      if (completed != null) task.completed = completed;
      _invalidateCache();
      notifyListeners();
      unawaited(_repository.saveTask(task));
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
      unawaited(_repository.softDeleteTask(task));
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
        NotificationService.instance.cancelTaskReminder(task.id);
      }
    }

    _invalidateCache();
    notifyListeners();
    if (tasksToBin.isNotEmpty) {
      unawaited(_repository.saveTasksBatch(tasksToBin));
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
      if (targetState) {
        NotificationService.instance.cancelTaskReminder(task.id);
        onTaskCompletedCallback?.call(task.id);
      } else {
        NotificationService.instance.scheduleTaskReminder(task);
      }
    }

    if (targetState) {
      _playSoundIfEnabled();
    }

    _selectedTaskIds.clear();
    _invalidateCache();
    notifyListeners();
    if (selectedTasks.isNotEmpty) {
      unawaited(_repository.saveTasksBatch(selectedTasks));
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
      if (!task.completed) {
        NotificationService.instance.scheduleTaskReminder(task);
      }
      _invalidateCache();
      notifyListeners();
      unawaited(_repository.saveTask(task));
    }
  }

  /// Permanently removes task from bin
  Future<void> permanentlyDeleteTask(String id) async {
    if (_binTasks.any((t) => t.id == id)) {
      _binTasks.removeWhere((t) => t.id == id);
    }
    await _repository.deleteTask(id);
    notifyListeners();
  }

  /// Permanently removes all tasks from bin
  Future<void> emptyBin() async {
    _binTasks.clear();
    notifyListeners();
    await _repository.clearBin();
  }

  /// Restores all tasks from bin back to active tasks
  void restoreAllFromBin() {
    final restored = List<Task>.from(_binTasks);
    for (final task in restored) {
      task.deletedAt = null;
      task.updatedAt = DateTime.now();
      _tasks.insert(0, task);
      if (!task.completed) {
        NotificationService.instance.scheduleTaskReminder(task);
      }
    }
    _binTasks.clear();
    _invalidateCache();
    notifyListeners();
    if (restored.isNotEmpty) {
      unawaited(_repository.saveTasksBatch(restored));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }
}
