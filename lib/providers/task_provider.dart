import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../utils/task_date_formatter.dart';
import '../services/supabase_sync_service.dart';
import '../services/google_calendar_service.dart';

enum TaskFilter { all, completed, pending }

enum TaskSortOption { creationDesc, creationAsc, dueDate, az, za }

class TaskProvider extends ChangeNotifier {
  static const String _tasksKey = 'zeta_tasks_v1';
  static const String _binTasksKey = 'zeta_bin_tasks_v1';
  static const String _autoSaveKey = 'zeta_auto_save';
  static const String _soundEffectsKey = 'zeta_sound_effects';

  final SupabaseSyncService _syncService = SupabaseSyncService();
  final GoogleCalendarService _googleService = GoogleCalendarService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing || _syncService.isSyncing;
  DateTime? get lastSyncedAt => _syncService.lastSyncedAt;
  String? get syncError => _syncService.lastError;

  TaskProvider() {
    _loadFromStorage();
  }

  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Answer writting',
      description: 'Society Indian Society',
      dueDate: 'Yesterday',
      completed: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Task(
      id: '2',
      title: 'Society',
      dueDate: '15, Sep',
      completed: false,
      subtasks: [
        Subtask(id: 's1', title: 'Read chapter 3', completed: false),
        Subtask(id: 's2', title: 'Prepare notes', completed: false),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Task(
      id: '3',
      title: 'Population',
      dueDate: 'Today',
      hasTime: true,
      dueTime: '10:00 AM',
      completed: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Task(
      id: '4',
      title: 'Women Organisation',
      dueDate: 'Tomorrow',
      completed: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Task(
      id: '5',
      title: 'Role of Women',
      dueDate: '13, Sep',
      hasTime: true,
      dueTime: '02:30 PM',
      completed: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  final List<Task> _binTasks = [
    Task(
      id: 'b1',
      title: 'Geography Map Practice',
      description: 'Rivers and mountain passes revision',
      dueDate: '5, Sep',
      completed: false,
      deletedAt: DateTime.now().subtract(const Duration(hours: 4)),
      subtasks: [
        Subtask(id: 'bs1', title: 'Himalayan rivers', completed: true),
        Subtask(id: 'bs2', title: 'Peninsular rivers', completed: false),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Task(
      id: 'b2',
      title: 'Modern History Timeline',
      description: '1857 to 1947 important events and acts',
      dueDate: '4, Sep',
      hasTime: true,
      dueTime: '11:15 AM',
      completed: true,
      deletedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  TaskFilter _filter = TaskFilter.all;
  TaskSortOption _sortBy = TaskSortOption.creationDesc;
  final Set<String> _expandedTaskIds = {};

  List<Task> get allTasks => List.unmodifiable(_tasks);
  List<Task> get binTasks => List.unmodifiable(_binTasks);
  TaskFilter get filter => _filter;
  TaskSortOption get sortBy => _sortBy;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.completed).length;
  int get pendingCount => _tasks.where((t) => !t.completed).length;
  int get binCount => _binTasks.length;

  bool isTaskExpanded(String taskId) => _expandedTaskIds.contains(taskId);

  void toggleTaskExpanded(String taskId) {
    if (_expandedTaskIds.contains(taskId)) {
      _expandedTaskIds.remove(taskId);
    } else {
      _expandedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSortBy(TaskSortOption sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void cycleSortOption() {
    const values = TaskSortOption.values;
    final nextIndex = (values.indexOf(_sortBy) + 1) % values.length;
    _sortBy = values[nextIndex];
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

  List<Task> get filteredAndSortedTasks {
    final list = _tasks.where((task) {
      if (_filter == TaskFilter.pending && task.completed) return false;
      if (_filter == TaskFilter.completed && !task.completed) return false;
      return true;
    }).toList();

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

    return list;
  }

  List<Task> get pendingTasks =>
      filteredAndSortedTasks.where((t) => !t.completed).toList();

  List<Task> get completedTasks =>
      filteredAndSortedTasks.where((t) => t.completed).toList();

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksRaw = prefs.getString(_tasksKey);
      if (tasksRaw != null) {
        final list = jsonDecode(tasksRaw) as List<dynamic>;
        final loaded = list
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty) {
          _tasks.clear();
          _tasks.addAll(loaded);
        }
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
      notifyListeners();
    } catch (_) {}

    // Subscribe to real-time changes from other clients
    _syncService.subscribeToRealtime(onChange: _handleRemoteTaskChange);

    // Initial background cloud sync
    syncWithCloud();
  }

  void _handleRemoteTaskChange(Task remoteTask, String eventType) {
    if (eventType == 'DELETE') {
      _tasks.removeWhere((t) => t.id == remoteTask.id);
      _binTasks.removeWhere((t) => t.id == remoteTask.id);
    } else {
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

  /// Synchronize all tasks with Supabase backend and Google Calendar/Tasks.
  Future<void> syncWithCloud({bool force = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      await _googleService.loadTokens(forceReload: force);
      final remoteTasks = await _syncService.pullTasks();

      if (remoteTasks.isNotEmpty) {
        // If local tasks are only initial placeholder mocks, replace with remote
        final hasOnlyLegacyMocks = _tasks.isNotEmpty && _tasks.every((t) => t.id.length < 5);
        if (hasOnlyLegacyMocks) {
          _tasks.clear();
          _binTasks.clear();
        }

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
    } catch (e) {
      debugPrint('TaskProvider: syncWithCloud error - $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
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
        HapticFeedback.lightImpact();
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
      }
      notifyListeners();
      _autoSaveTasksIfEnabled();
      _syncService.scheduleDebouncedPush(task);
      _syncToGoogleServices(task);
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
        notifyListeners();
        _autoSaveTasksIfEnabled();
        _syncService.scheduleDebouncedPush(_tasks[taskIndex]);
        _syncToGoogleServices(_tasks[taskIndex]);
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
    notifyListeners();
    _autoSaveTasksIfEnabled();
    _syncService.scheduleDebouncedPush(newTask);
    _syncToGoogleServices(newTask);
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
      notifyListeners();
      _autoSaveTasksIfEnabled();
      _syncService.scheduleDebouncedPush(task);
      _syncToGoogleServices(task);
    }
  }

  /// Moves active task to bin
  void deleteTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks.removeAt(index);
      task.deletedAt = DateTime.now();
      task.updatedAt = DateTime.now();
      _binTasks.insert(0, task);
      notifyListeners();
      _autoSaveTasksIfEnabled();
      _syncService.scheduleDebouncedPush(task);
      _deleteFromGoogleServices(task);
    }
  }

  /// Restores task from bin back to active tasks
  void restoreTask(String id) {
    final index = _binTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _binTasks.removeAt(index);
      task.deletedAt = null;
      task.updatedAt = DateTime.now();
      _tasks.insert(0, task);
      notifyListeners();
      _autoSaveTasksIfEnabled();
      _syncService.scheduleDebouncedPush(task);
      _syncToGoogleServices(task);
    }
  }

  /// Permanently removes task from bin
  void permanentlyDeleteTask(String id) {
    final taskIndex = _binTasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = _binTasks.removeAt(taskIndex);
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
      _tasks.insert(0, task);
      _syncService.scheduleDebouncedPush(task);
      _syncToGoogleServices(task);
    }
    _binTasks.clear();
    notifyListeners();
    _autoSaveTasksIfEnabled();
  }

  Future<void> _syncToGoogleServices(Task task) async {
    try {
      if (_googleService.syncCalendarEnabled && task.dueDate != null) {
        final calId = await _googleService.syncTaskToCalendar(task);
        if (calId != null && calId != task.googleEventId) {
          task.googleEventId = calId;
          _syncService.scheduleDebouncedPush(task);
          _autoSaveTasksIfEnabled();
        }
      }
      if (_googleService.syncTasksEnabled) {
        final gTaskId = await _googleService.syncTaskToGoogleTasks(task);
        if (gTaskId != null && gTaskId != task.googleTaskId) {
          task.googleTaskId = gTaskId;
          _syncService.scheduleDebouncedPush(task);
          _autoSaveTasksIfEnabled();
        }
      }
    } catch (e) {
      debugPrint('TaskProvider: _syncToGoogleServices note - $e');
    }
  }

  Future<void> _deleteFromGoogleServices(Task task) async {
    try {
      if (task.googleEventId != null) {
        await _googleService.deleteCalendarEvent(task.googleEventId!);
      }
      if (task.googleTaskId != null) {
        await _googleService.deleteGoogleTask(task.googleTaskId!);
      }
    } catch (e) {
      debugPrint('TaskProvider: _deleteFromGoogleServices note - $e');
    }
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
