class Subtask {
  final String id;
  final String title;
  bool completed;

  Subtask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'dueDate': dueDate,
        'hasTime': hasTime,
        'dueTime': dueTime,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        completed: json['completed'] as bool? ?? false,
        dueDate: json['dueDate'] as String?,
        hasTime: json['hasTime'] as bool? ?? false,
        dueTime: json['dueTime'] as String?,
        subtasks: (json['subtasks'] as List<dynamic>?)
            ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        deletedAt: json['deletedAt'] != null
            ? DateTime.tryParse(json['deletedAt'] as String)
            : null,
      );

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
