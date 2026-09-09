import 'package:material_ui/material_ui.dart';
import '../models/task.dart';

enum TaskFilter { all, completed, pending }

enum TaskSortOption { creationDesc, creationAsc, dueDate, az, za }

class TaskProvider extends ChangeNotifier {
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
      dueDate: '8, Sep',
      hasTime: true,
      dueTime: '10:00 AM',
      completed: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Task(
      id: '4',
      title: 'Women Organisation',
      dueDate: '7, Sep',
      completed: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Task(
      id: '5',
      title: 'Role of Women',
      dueDate: '6, Sep',
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

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].completed = !_tasks[index].completed;
      notifyListeners();
    }
  }

  void toggleSubtask(String taskId, String subtaskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final subtaskIndex =
          _tasks[taskIndex].subtasks.indexWhere((s) => s.id == subtaskId);
      if (subtaskIndex != -1) {
        _tasks[taskIndex].subtasks[subtaskIndex].completed =
            !_tasks[taskIndex].subtasks[subtaskIndex].completed;
        notifyListeners();
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      dueDate: dueDate,
      hasTime: hasTime,
      dueTime: dueTime,
      subtasks: subtasks ?? [],
      createdAt: DateTime.now(),
    );
    _tasks.insert(0, newTask);
    notifyListeners();
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
      if (subtasks != null) task.subtasks = subtasks;
      if (completed != null) task.completed = completed;
      notifyListeners();
    }
  }

  /// Moves active task to bin
  void deleteTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks.removeAt(index);
      task.deletedAt = DateTime.now();
      _binTasks.insert(0, task);
      notifyListeners();
    }
  }

  /// Restores task from bin back to active tasks
  void restoreTask(String id) {
    final index = _binTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _binTasks.removeAt(index);
      task.deletedAt = null;
      _tasks.insert(0, task);
      notifyListeners();
    }
  }

  /// Permanently removes task from bin
  void permanentlyDeleteTask(String id) {
    _binTasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Permanently removes all tasks from bin
  void emptyBin() {
    _binTasks.clear();
    notifyListeners();
  }

  /// Restores all tasks from bin back to active tasks
  void restoreAllFromBin() {
    for (final task in _binTasks) {
      task.deletedAt = null;
      _tasks.insert(0, task);
    }
    _binTasks.clear();
    notifyListeners();
  }
}
