import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../utils/task_date_formatter.dart';
import '../utils/haptics.dart';
import '../services/supabase_sync_service.dart';
import '../services/google_calendar_service.dart';
import '../services/notification_service.dart';

enum TaskFilter { all, completed, pending }

enum TaskSortOption { creationDesc, creationAsc, dueDate, az, za }

class TaskProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _tasksKey = 'zeta_tasks_v1';
  static const String _binTasksKey = 'zeta_bin_tasks_v1';
  static const String _autoSaveKey = 'zeta_auto_save';
  static const String _soundEffectsKey = 'zeta_sound_effects';

  final SupabaseSyncService _syncService = SupabaseSyncService();
  final GoogleCalendarService _googleService = GoogleCalendarService();

  bool _isSyncing = false;
  bool _isGoogleSyncing = false;
  DateTime? _lastGoogleSyncTime;
  Timer? _googlePollingTimer;

  bool _isDisposed = false;

  bool get isSyncing => _isSyncing || _syncService.isSyncing || _isGoogleSyncing;
  DateTime? get lastSyncedAt => _syncService.lastSyncedAt;
  String? get syncError => _syncService.lastError;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  TaskProvider() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _loadFromStorage();
    _startGooglePollingTimer();
  }

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
  Timer? _saveDebounceTimer;

  void _invalidateCache() {
    _cachedFilteredAndSortedTasks = null;
  }

  void _scheduleSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _autoSaveTasksIfEnabled();
    });
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
  }

  void cycleSortOption() {
    const values = TaskSortOption.values;
    final nextIndex = (values.indexOf(_sortBy) + 1) % values.length;
    _sortBy = values[nextIndex];
    _invalidateCache();
    notifyListeners();
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
    final list = _tasks.where((task) {
      if (task.completed) return false;
      if (_searchQuery.isNotEmpty && !matchesSearch(task, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();
    _sortTaskList(list);
    return list;
  }

  List<Task> get completedTasks {
    final list = _tasks.where((task) {
      if (!task.completed) return false;
      if (_searchQuery.isNotEmpty && !matchesSearch(task, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();
    _sortTaskList(list);
    return list;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksRaw = prefs.getString(_tasksKey);
      if (tasksRaw != null) {
        final list = jsonDecode(tasksRaw) as List<dynamic>;
        final loaded = list
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
        _tasks.clear();
        _tasks.addAll(loaded);
      }

      final binRaw = prefs.getString(_binTasksKey);
      if (binRaw != null) {
        final list = jsonDecode(binRaw) as List<dynamic>;
        final loaded = list
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
        _binTasks.clear();
        _binTasks.addAll(loaded);
      }

      // Purge any corrupted or empty tasks from local cache
      _tasks.removeWhere((t) => t.title.trim().isEmpty);
      _binTasks.removeWhere((t) => t.title.trim().isEmpty);

      _invalidateCache();
      notifyListeners();
    } catch (_) {}

    // Subscribe to real-time changes from other clients
    _syncService.subscribeToRealtime(onChange: _handleRemoteTaskChange);

    // Initial background cloud sync
    syncWithCloud();
  }

  void _handleRemoteTaskChange(Task remoteTask, String eventType) {
    _invalidateCache();
    if (eventType == 'DELETE') {
      _tasks.removeWhere((t) => t.id == remoteTask.id);
      _binTasks.removeWhere((t) => t.id == remoteTask.id);
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
    }
    saveTasks();
    notifyListeners();
  }

  /// Synchronize all tasks with Supabase backend and Google Tasks.
  Future<void> syncWithCloud({bool force = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      await _googleService.loadTokens(forceReload: force);
      _startGooglePollingTimer();
      final remoteTasks = await _syncService.pullTasks();
      remoteTasks.removeWhere((t) => t.title.trim().isEmpty);

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
        await saveTasks();
      }

      // Clean up any empty tasks that may exist locally
      _tasks.removeWhere((t) => t.title.trim().isEmpty);
      _binTasks.removeWhere((t) => t.title.trim().isEmpty);

      // Perform bidirectional synchronization with Google Tasks
      if (_googleService.syncTasksEnabled && _googleService.isConnected) {
        await syncGoogleTasks(force: force);
      }
    } catch (e) {
      debugPrint('TaskProvider: syncWithCloud error - $e');
    } finally {
      _isSyncing = false;
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Pulls remote changes from Google Tasks and reconciles them bidirectionally with Zeta.
  Future<void> syncGoogleTasks({bool force = false}) async {
    if (_isGoogleSyncing) return;
    if (!_googleService.syncTasksEnabled || !_googleService.isConnected) return;

    _isGoogleSyncing = true;
    try {
      final result = await _googleService.pullGoogleTasks(
        since: force ? null : _lastGoogleSyncTime,
      );

      if (result == null) return;
      _lastGoogleSyncTime = result.syncTimestamp;

      bool hasChanges = false;

      // 1. Handle deleted tasks and subtasks from Google Tasks
      for (final deletedGId in result.deletedTaskIds) {
        final activeIdx = _tasks.indexWhere((t) => t.googleTaskId == deletedGId);
        if (activeIdx != -1) {
          final task = _tasks.removeAt(activeIdx);
          task.deletedAt = DateTime.now();
          task.updatedAt = DateTime.now();
          _binTasks.insert(0, task);
          hasChanges = true;
          _syncService.pushTask(task);
          continue;
        }

        // Check active tasks for deleted subtasks
        for (final task in _tasks) {
          final subIdx = task.subtasks.indexWhere((s) => s.googleTaskId == deletedGId);
          if (subIdx != -1) {
            task.subtasks.removeAt(subIdx);
            task.updatedAt = DateTime.now();
            hasChanges = true;
            _syncService.pushTask(task);
            break;
          }
        }
      }

      // 2. Handle remote tasks (created or updated in Google Tasks)
      for (final remote in result.remoteTasks) {
        // Discard any empty-titled tasks
        if (remote.title.trim().isEmpty) continue;

        final activeIdx = _tasks.indexWhere((t) => t.googleTaskId == remote.googleTaskId);
        final binIdx = _binTasks.indexWhere((t) => t.googleTaskId == remote.googleTaskId);

        if (activeIdx != -1) {
          final local = _tasks[activeIdx];
          if (remote.deletedAt != null) {
            _tasks.removeAt(activeIdx);
            local.deletedAt = remote.deletedAt;
            local.updatedAt = DateTime.now();
            _binTasks.insert(0, local);
            hasChanges = true;
            _syncService.pushTask(local);
          } else {
            final changed = _reconcileTaskFromGoogle(local, remote, isFullSync: result.isFullSync);
            if (changed) {
              hasChanges = true;
              _syncService.pushTask(local);
            }
          }
        } else if (binIdx != -1) {
          final local = _binTasks[binIdx];
          if (remote.deletedAt == null) {
            // Task un-deleted in Google Tasks
            _binTasks.removeAt(binIdx);
            local.deletedAt = null;
            local.updatedAt = DateTime.now();
            _reconcileTaskFromGoogle(local, remote, isFullSync: result.isFullSync);
            _tasks.insert(0, local);
            hasChanges = true;
            _syncService.pushTask(local);
          }
        } else if (remote.deletedAt == null) {
          // Check for existing local task matching title that has no googleTaskId
          final matchTitleIdx = _tasks.indexWhere(
            (t) => t.googleTaskId == null &&
                t.title.trim().isNotEmpty &&
                t.title.trim().toLowerCase() == remote.title.trim().toLowerCase(),
          );
          if (matchTitleIdx != -1) {
            final local = _tasks[matchTitleIdx];
            local.googleTaskId = remote.googleTaskId;
            local.googleEtag = remote.googleEtag;
            _reconcileTaskFromGoogle(local, remote, isFullSync: result.isFullSync);
            hasChanges = true;
            _syncService.pushTask(local);
          } else {
            // New task created in Google Tasks
            _tasks.insert(0, remote);
            hasChanges = true;
            _syncService.pushTask(remote);
          }
        }
      }

      // 3. Handle remote subtasks (especially child tasks updated in Google Tasks while parent was unmodified)
      for (final update in result.remoteSubtasks) {
        final parentGId = update.parentGoogleTaskId;
        final remoteSub = update.subtask;

        Task? parentTask = _tasks.where((t) => t.googleTaskId == parentGId).firstOrNull;
        parentTask ??= _tasks.where((t) => t.subtasks.any((s) => s.googleTaskId == remoteSub.googleTaskId)).firstOrNull;
        parentTask ??= _binTasks.where((t) => t.googleTaskId == parentGId).firstOrNull;

        if (parentTask != null) {
          final localSubIdx = parentTask.subtasks.indexWhere(
            (s) => (s.googleTaskId != null && s.googleTaskId == remoteSub.googleTaskId) ||
                   (s.googleTaskId == null && s.title.trim().toLowerCase() == remoteSub.title.trim().toLowerCase()),
          );

          if (localSubIdx != -1) {
            final localSub = parentTask.subtasks[localSubIdx];
            bool subChanged = false;
            if (localSub.googleTaskId == null && remoteSub.googleTaskId != null) {
              localSub.googleTaskId = remoteSub.googleTaskId;
              subChanged = true;
            }
            if (localSub.title != remoteSub.title) {
              localSub.title = remoteSub.title;
              subChanged = true;
            }
            if (localSub.completed != remoteSub.completed) {
              localSub.completed = remoteSub.completed;
              subChanged = true;
            }
            if (subChanged) {
              parentTask.updatedAt = DateTime.now();
              parentTask.lastSyncedAt = DateTime.now();
              hasChanges = true;
              _syncService.pushTask(parentTask);
            }
          } else {
            // New subtask added under this parent in Google Tasks
            parentTask.subtasks.add(remoteSub);
            parentTask.updatedAt = DateTime.now();
            parentTask.lastSyncedAt = DateTime.now();
            hasChanges = true;
            _syncService.pushTask(parentTask);
          }
        }
      }

      // 4. Mirror any local tasks that don't have a googleTaskId to Google Tasks
      for (final local in _tasks) {
        if (local.googleTaskId == null &&
            local.deletedAt == null &&
            local.title.trim().isNotEmpty) {
          final gId = await _googleService.syncTaskToGoogleTasks(local);
          if (gId != null) {
            local.googleTaskId = gId;
            hasChanges = true;
            _syncService.pushTask(local);
          }
        }
      }

      if (hasChanges) {
        await saveTasks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TaskProvider: syncGoogleTasks error - $e');
    } finally {
      _isGoogleSyncing = false;
    }
  }

  /// Reconciles fields from remote Google Task into local Task.
  /// Returns true if changes occurred.
  bool _reconcileTaskFromGoogle(Task local, Task remote, {bool isFullSync = false}) {
    bool changed = false;

    if (local.title != remote.title && remote.title.isNotEmpty) {
      local.title = remote.title;
      changed = true;
    }
    if (local.description != remote.description) {
      local.description = remote.description;
      changed = true;
    }
    if (local.completed != remote.completed) {
      local.completed = remote.completed;
      changed = true;
    }
    // Reconcile due date from Google Tasks (date only — Tasks API never carries time).
    // Time is preserved from the local task and rehydrated from Google Calendar separately.
    if (remote.dueDate != null && remote.dueDate!.isNotEmpty) {
      final localDate = TaskDateFormatter.parse(local.dueDate ?? '');
      final remoteDate = TaskDateFormatter.parse(remote.dueDate!);

      final isSameDay = localDate != null &&
          remoteDate != null &&
          localDate.year == remoteDate.year &&
          localDate.month == remoteDate.month &&
          localDate.day == remoteDate.day;

      if (!isSameDay) {
        local.dueDate = remote.dueDate;
        changed = true;
      }
      // Note: hasTime and dueTime are intentionally NOT reconciled from the Google Tasks
      // remote object. Google Tasks API always strips time — it is date-only by design.
      // Time is rehydrated from the linked Google Calendar event in syncGoogleTasks.
    } else if (local.dueDate != null) {
      // Remote cleared the due date entirely
      local.dueDate = null;
      local.hasTime = false;
      local.dueTime = null;
      changed = true;
    }

    // Reconcile subtasks natively
    for (final remoteSub in remote.subtasks) {
      final localSubIdx = local.subtasks.indexWhere(
        (s) => (s.googleTaskId != null && s.googleTaskId == remoteSub.googleTaskId) ||
               (s.googleTaskId == null && s.title.trim().toLowerCase() == remoteSub.title.trim().toLowerCase()),
      );
      if (localSubIdx != -1) {
        final localSub = local.subtasks[localSubIdx];
        if (localSub.googleTaskId == null && remoteSub.googleTaskId != null) {
          localSub.googleTaskId = remoteSub.googleTaskId;
          changed = true;
        }
        if (localSub.title != remoteSub.title) {
          localSub.title = remoteSub.title;
          changed = true;
        }
        if (localSub.completed != remoteSub.completed) {
          localSub.completed = remoteSub.completed;
          changed = true;
        }
      } else {
        local.subtasks.add(remoteSub);
        changed = true;
      }
    }

    // Clean up local subtasks removed remotely ONLY on full sync!
    // On incremental sync, remote.subtasks only contains subtasks modified since last sync.
    if (isFullSync && remote.subtasks.isNotEmpty) {
      final remoteGTaskIds = remote.subtasks.map((s) => s.googleTaskId).whereType<String>().toSet();
      final toRemove = local.subtasks
          .where((s) => s.googleTaskId != null && !remoteGTaskIds.contains(s.googleTaskId))
          .map((s) => s.id)
          .toList();
      if (toRemove.isNotEmpty) {
        local.subtasks.removeWhere((s) => toRemove.contains(s.id));
        changed = true;
      }
    }

    if (remote.googleEtag != null) {
      local.googleEtag = remote.googleEtag;
    }
    if (changed) {
      local.updatedAt = DateTime.now();
      local.lastSyncedAt = DateTime.now();
    }

    return changed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User switched back to Zeta app/window: restart polling & trigger immediate sync
      _startGooglePollingTimer();
      syncGoogleTasks();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // Pause background network requests while app is minimized
      _googlePollingTimer?.cancel();
      _googlePollingTimer = null;
    }
  }

  void _startGooglePollingTimer() {
    _googlePollingTimer?.cancel();
    _googlePollingTimer = null;
    if (!_googleService.syncTasksEnabled || !_googleService.isConnected) {
      return;
    }
    _googlePollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_googleService.syncTasksEnabled && _googleService.isConnected) {
        syncGoogleTasks();
      }
    });
  }

  Future<void> saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksSerialized = _tasks.map((t) => t.toJson()).toList();
      final binSerialized = _binTasks.map((t) => t.toJson()).toList();
      await prefs.setString(_tasksKey, jsonEncode(tasksSerialized));
      await prefs.setString(_binTasksKey, jsonEncode(binSerialized));
    } catch (_) {}
  }

  Future<void> _autoSaveTasksIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoSave = prefs.getBool(_autoSaveKey) ?? true;
      if (autoSave) {
        await saveTasks();
      }
    } catch (_) {}
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
      } else {
        // Re-schedule if un-completing a task that has a due time.
        NotificationService.instance.scheduleTaskReminder(task);
      }
      _invalidateCache();
      notifyListeners();
      _scheduleSave();
      _syncService.pushTask(task);
      _syncTaskPipeline(task);
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
        _scheduleSave();
        _syncService.pushTask(_tasks[taskIndex]);
        _syncTaskPipeline(_tasks[taskIndex]);
      }
    }
  }

  void addTask({
    required String title,
    String? description,
    String? dueDate,
    bool hasTime = false,
    String? dueTime,
    List<Subtask>? subtasks,
  }) {
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
    _scheduleSave();
    _syncService.pushTask(newTask);
    _syncTaskPipeline(newTask);
    // Schedule a system notification if the task has a due time.
    NotificationService.instance.scheduleTaskReminder(newTask);
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
      _scheduleSave();
      _syncService.pushTask(task);
      _syncTaskPipeline(task);
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
      _scheduleSave();
      _syncService.pushTask(task);
      _deleteFromGoogleServices(task);
      // Cancel scheduled reminder when task is deleted.
      NotificationService.instance.cancelTaskReminder(task.id);
    }
  }

  /// Batch deletes all currently selected tasks into the bin
  void deleteSelectedTasks() {
    if (_selectedTaskIds.isEmpty) return;
    final idsToDelete = _selectedTaskIds.toList();
    _selectedTaskIds.clear();

    for (final id in idsToDelete) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final task = _tasks.removeAt(index);
        task.deletedAt = DateTime.now();
        task.updatedAt = DateTime.now();
        _binTasks.insert(0, task);
        _syncService.pushTask(task);
        _deleteFromGoogleServices(task);
      }
    }

    notifyListeners();
    _autoSaveTasksIfEnabled();
    ZetaHaptics.medium();
  }

  /// Batch marks all currently selected tasks as complete (or incomplete)
  void completeSelectedTasks({bool? markAs}) {
    if (_selectedTaskIds.isEmpty) return;
    final idsToToggle = _selectedTaskIds.toList();
    final selectedTasks = _tasks.where((t) => idsToToggle.contains(t.id)).toList();

    // If markAs is null, determine target: if any are incomplete, mark all complete; else incomplete
    final targetState = markAs ?? selectedTasks.any((t) => !t.completed);

    for (final task in selectedTasks) {
      task.completed = targetState;
      task.updatedAt = DateTime.now();
      _syncService.pushTask(task);
      _syncTaskPipeline(task);
    }

    if (targetState) {
      _playSoundIfEnabled();
    }

    _selectedTaskIds.clear();
    notifyListeners();
    _autoSaveTasksIfEnabled();
    ZetaHaptics.medium();
  }

  /// Restores task from bin back to active tasks
  void restoreTask(String id) {
    final index = _binTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _binTasks.removeAt(index);
      task.deletedAt = null;
      task.updatedAt = DateTime.now();
      // Clear stale Google IDs so the task and its subtasks are freshly inserted
      // rather than failing with 404 on deleted IDs
      task.googleTaskId = null;
      task.googleEventId = null;
      task.googleEtag = null;
      for (final sub in task.subtasks) {
        sub.googleTaskId = null;
      }
      _tasks.insert(0, task);
      notifyListeners();
      _autoSaveTasksIfEnabled();
      _syncService.pushTask(task);
      _syncTaskPipeline(task);
    }
  }

  /// Permanently removes task from bin
  void permanentlyDeleteTask(String id) {
    final taskIndex = _binTasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = _binTasks.removeAt(taskIndex);
      // If task still had google IDs, make sure they are cleaned up
      _deleteFromGoogleServices(task);
    }
    _syncService.deleteTask(id, soft: false);
    notifyListeners();
    _autoSaveTasksIfEnabled();
  }

  /// Permanently removes all tasks from bin
  void emptyBin() {
    for (final task in _binTasks) {
      _deleteFromGoogleServices(task);
      _syncService.deleteTask(task.id, soft: false);
    }
    _binTasks.clear();
    notifyListeners();
    _autoSaveTasksIfEnabled();
  }

  /// Restores all tasks from bin back to active tasks
  void restoreAllFromBin() {
    for (final task in _binTasks) {
      task.deletedAt = null;
      task.updatedAt = DateTime.now();
      task.googleTaskId = null;
      task.googleEventId = null;
      task.googleEtag = null;
      for (final sub in task.subtasks) {
        sub.googleTaskId = null;
      }
      _tasks.insert(0, task);
      _syncService.pushTask(task);
      _syncTaskPipeline(task);
    }
    _binTasks.clear();
    notifyListeners();
    _autoSaveTasksIfEnabled();
  }

  Future<void> _syncTaskPipeline(Task task) async {
    try {
      if (task.title.trim().isEmpty) return;

      // 1. Sync with Google Tasks (natively maps subtasks & due dates)
      if (_googleService.syncTasksEnabled && _googleService.isConnected) {
        final gTaskId = await _googleService.syncTaskToGoogleTasks(task);
        if (gTaskId != null && gTaskId != task.googleTaskId) {
          task.googleTaskId = gTaskId;
        }
      }

      // 2. Immediately persist updated task to local storage AND Supabase DB simultaneously
      await _autoSaveTasksIfEnabled();
      await _syncService.pushTask(task);
    } catch (e) {
      debugPrint('TaskProvider: _syncTaskPipeline note - $e');
      _syncService.pushTask(task);
    }
  }

  Future<void> _deleteFromGoogleServices(Task task) async {
    try {
      if (task.googleTaskId != null) {
        await _googleService.deleteGoogleTask(task.googleTaskId!);
      }
    } catch (e) {
      debugPrint('TaskProvider: _deleteFromGoogleServices note - $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _saveDebounceTimer?.cancel();
    _googlePollingTimer?.cancel();
    _syncService.dispose();
    super.dispose();
  }
}
