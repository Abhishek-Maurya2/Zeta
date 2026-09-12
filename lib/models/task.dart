import '../utils/task_date_formatter.dart';

class Subtask {
  final String id;
  final String title;
  bool completed;
  String? googleTaskId;

  Subtask({
    required this.id,
    required this.title,
    this.completed = false,
    this.googleTaskId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        if (googleTaskId != null) 'google_task_id': googleTaskId,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        googleTaskId: (json['google_task_id'] ?? json['googleTaskId']) as String?,
      );

  Subtask copyWith({
    String? id,
    String? title,
    bool? completed,
    String? googleTaskId,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      googleTaskId: googleTaskId ?? this.googleTaskId,
    );
  }
}

class Task {
  final String id;
  String? userId;
  String title;
  String? description;
  bool completed;
  String? dueDate;
  bool hasTime;
  String? dueTime;
  List<Subtask> subtasks;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  String? googleEventId;
  String? googleTaskId;
  String? googleEtag;
  DateTime? lastSyncedAt;

  Task({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    this.completed = false,
    this.dueDate,
    this.hasTime = false,
    this.dueTime,
    List<Subtask>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.googleEventId,
    this.googleTaskId,
    this.googleEtag,
    this.lastSyncedAt,
  })  : subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'completed': completed,
        'dueDate': dueDate,
        'hasTime': hasTime,
        'dueTime': dueTime,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'googleEventId': googleEventId,
        'googleTaskId': googleTaskId,
        'googleEtag': googleEtag,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String?,
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
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
            : (json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
                : DateTime.now()),
        deletedAt: json['deletedAt'] != null
            ? DateTime.tryParse(json['deletedAt'] as String)
            : null,
        googleEventId: json['googleEventId'] as String?,
        googleTaskId: json['googleTaskId'] as String?,
        googleEtag: json['googleEtag'] as String?,
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.tryParse(json['lastSyncedAt'] as String)
            : null,
      );

  /// Converts the task to a PostgreSQL row for the Supabase `public.tasks` table.
  Map<String, dynamic> toSupabaseRow({String? defaultUserId}) {
    DateTime? parsedDueDate;
    final effectiveHasTime =
        hasTime || (dueTime != null && dueTime!.trim().isNotEmpty);

    if (dueDate != null && dueDate!.trim().isNotEmpty) {
      final baseDate = TaskDateFormatter.parse(dueDate!);
      if (baseDate != null) {
        final localBase = baseDate.isUtc ? baseDate.toLocal() : baseDate;
        if (effectiveHasTime && dueTime != null && dueTime!.trim().isNotEmpty) {
          final timeStr = dueTime!.trim();
          final match = RegExp(
            r'^\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?\s*$',
            caseSensitive: false,
          ).firstMatch(timeStr);
          if (match != null) {
            int h = int.parse(match.group(1)!);
            final m = int.parse(match.group(2)!);
            final period = match.group(3)?.toUpperCase();
            if (period == 'PM' && h < 12) h += 12;
            if (period == 'AM' && h == 12) h = 0;
            parsedDueDate = DateTime(localBase.year, localBase.month, localBase.day, h, m);
          } else {
            parsedDueDate = localBase;
          }
        } else {
          // Store pure date at noon UTC so timezone conversions anywhere in the world keep the exact same day
          parsedDueDate = DateTime.utc(localBase.year, localBase.month, localBase.day, 12, 0, 0);
        }
      }
    }

    // Ensure id is a valid UUID for PostgreSQL uuid column
    String supabaseId = id;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (!uuidRegex.hasMatch(supabaseId)) {
      // Deterministically create UUID from legacy ID
      final padded = id.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').padRight(32, '0').substring(0, 32);
      supabaseId = '${padded.substring(0, 8)}-${padded.substring(8, 12)}-4${padded.substring(13, 16)}-8${padded.substring(17, 20)}-${padded.substring(20, 32)}';
    }

    return {
      'id': supabaseId,
      'user_id': userId ?? defaultUserId ?? 'singleton',
      'title': title,
      'description': description ?? '',
      'completed': completed,
      'due_date': parsedDueDate?.toUtc().toIso8601String(),
      'has_time': effectiveHasTime,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'google_event_id': googleEventId,
      'google_task_id': googleTaskId,
      'google_etag': googleEtag,
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Reconstructs a task from a Supabase PostgreSQL row.
  factory Task.fromSupabaseRow(Map<String, dynamic> row) {
    String? localDueDate;
    String? localDueTime;
    bool hasTime = row['has_time'] == true;

    if (row['due_date'] != null) {
      final parsed = DateTime.tryParse(row['due_date'].toString());
      if (parsed != null) {
        final local = parsed.toLocal();
        localDueDate = TaskDateFormatter.format(local);

        final isNoonUtcPlaceholder = parsed.isUtc && parsed.hour == 12 && parsed.minute == 0;
        final hasNonMidnightTime = local.hour != 0 || local.minute != 0;

        if (hasTime || (!isNoonUtcPlaceholder && hasNonMidnightTime)) {
          hasTime = true;
          final hour = local.hour > 12
              ? local.hour - 12
              : (local.hour == 0 ? 12 : local.hour);
          final period = local.hour >= 12 ? 'PM' : 'AM';
          final minuteStr = local.minute.toString().padLeft(2, '0');
          localDueTime = '${hour.toString().padLeft(2, '0')}:$minuteStr $period';
        }
      }
    }

    final subtasksList = (row['subtasks'] as List<dynamic>?)
            ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return Task(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String?,
      title: row['title'] as String? ?? '',
      description: (row['description'] as String?)?.isNotEmpty == true
          ? row['description'] as String?
          : null,
      completed: row['completed'] as bool? ?? false,
      dueDate: localDueDate,
      hasTime: hasTime,
      dueTime: localDueTime,
      subtasks: subtasksList,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      deletedAt: row['deleted_at'] != null
          ? DateTime.tryParse(row['deleted_at'].toString())?.toLocal()
          : null,
      googleEventId: row['google_event_id'] as String?,
      googleTaskId: row['google_task_id'] as String?,
      googleEtag: row['google_etag'] as String?,
      lastSyncedAt: row['last_synced_at'] != null
          ? DateTime.tryParse(row['last_synced_at'].toString())?.toLocal()
          : null,
    );
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? completed,
    String? dueDate,
    bool? hasTime,
    String? dueTime,
    List<Subtask>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? googleEventId,
    String? googleTaskId,
    String? googleEtag,
    DateTime? lastSyncedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
      dueTime: dueTime ?? this.dueTime,
      subtasks: subtasks ?? this.subtasks.map((s) => s.copyWith()).toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      googleEventId: googleEventId ?? this.googleEventId,
      googleTaskId: googleTaskId ?? this.googleTaskId,
      googleEtag: googleEtag ?? this.googleEtag,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

