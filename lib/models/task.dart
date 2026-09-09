class Subtask {
  final String id;
  final String title;
  bool completed;

  Subtask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? completed,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

class Task {
  final String id;
  String title;
  String? description;
  bool completed;
  String? dueDate;
  bool hasTime;
  String? dueTime;
  List<Subtask> subtasks;
  DateTime createdAt;
  DateTime? deletedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.dueDate,
    this.hasTime = false,
    this.dueTime,
    List<Subtask>? subtasks,
    DateTime? createdAt,
    this.deletedAt,
  })  : subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    String? dueDate,
    bool? hasTime,
    String? dueTime,
    List<Subtask>? subtasks,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
      dueTime: dueTime ?? this.dueTime,
      subtasks: subtasks ?? this.subtasks.map((s) => s.copyWith()).toList(),
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
