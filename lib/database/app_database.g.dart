// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTableTable extends TasksTable
    with TableInfo<$TasksTableTable, TasksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasTimeMeta = const VerificationMeta(
    'hasTime',
  );
  @override
  late final GeneratedColumn<bool> hasTime = GeneratedColumn<bool>(
    'has_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_time" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dueTimeMeta = const VerificationMeta(
    'dueTime',
  );
  @override
  late final GeneratedColumn<String> dueTime = GeneratedColumn<String>(
    'due_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtasksJsonMeta = const VerificationMeta(
    'subtasksJson',
  );
  @override
  late final GeneratedColumn<String> subtasksJson = GeneratedColumn<String>(
    'subtasks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMsMeta = const VerificationMeta(
    'deletedAtMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtMs = GeneratedColumn<int>(
    'deleted_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _googleEventIdMeta = const VerificationMeta(
    'googleEventId',
  );
  @override
  late final GeneratedColumn<String> googleEventId = GeneratedColumn<String>(
    'google_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _googleTaskIdMeta = const VerificationMeta(
    'googleTaskId',
  );
  @override
  late final GeneratedColumn<String> googleTaskId = GeneratedColumn<String>(
    'google_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _googleEtagMeta = const VerificationMeta(
    'googleEtag',
  );
  @override
  late final GeneratedColumn<String> googleEtag = GeneratedColumn<String>(
    'google_etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMsMeta = const VerificationMeta(
    'lastSyncedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAtMs = GeneratedColumn<int>(
    'last_synced_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    description,
    completed,
    dueDate,
    hasTime,
    dueTime,
    subtasksJson,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    googleEventId,
    googleTaskId,
    googleEtag,
    lastSyncedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('has_time')) {
      context.handle(
        _hasTimeMeta,
        hasTime.isAcceptableOrUnknown(data['has_time']!, _hasTimeMeta),
      );
    }
    if (data.containsKey('due_time')) {
      context.handle(
        _dueTimeMeta,
        dueTime.isAcceptableOrUnknown(data['due_time']!, _dueTimeMeta),
      );
    }
    if (data.containsKey('subtasks_json')) {
      context.handle(
        _subtasksJsonMeta,
        subtasksJson.isAcceptableOrUnknown(
          data['subtasks_json']!,
          _subtasksJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('deleted_at_ms')) {
      context.handle(
        _deletedAtMsMeta,
        deletedAtMs.isAcceptableOrUnknown(
          data['deleted_at_ms']!,
          _deletedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('google_event_id')) {
      context.handle(
        _googleEventIdMeta,
        googleEventId.isAcceptableOrUnknown(
          data['google_event_id']!,
          _googleEventIdMeta,
        ),
      );
    }
    if (data.containsKey('google_task_id')) {
      context.handle(
        _googleTaskIdMeta,
        googleTaskId.isAcceptableOrUnknown(
          data['google_task_id']!,
          _googleTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('google_etag')) {
      context.handle(
        _googleEtagMeta,
        googleEtag.isAcceptableOrUnknown(data['google_etag']!, _googleEtagMeta),
      );
    }
    if (data.containsKey('last_synced_at_ms')) {
      context.handle(
        _lastSyncedAtMsMeta,
        lastSyncedAtMs.isAcceptableOrUnknown(
          data['last_synced_at_ms']!,
          _lastSyncedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TasksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      hasTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_time'],
      )!,
      dueTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_time'],
      ),
      subtasksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtasks_json'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      deletedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_ms'],
      ),
      googleEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_event_id'],
      ),
      googleTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_task_id'],
      ),
      googleEtag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_etag'],
      ),
      lastSyncedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at_ms'],
      ),
    );
  }

  @override
  $TasksTableTable createAlias(String alias) {
    return $TasksTableTable(attachedDatabase, alias);
  }
}

class TasksTableData extends DataClass implements Insertable<TasksTableData> {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final bool completed;
  final String? dueDate;
  final bool hasTime;
  final String? dueTime;
  final String subtasksJson;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;
  final String? googleEventId;
  final String? googleTaskId;
  final String? googleEtag;
  final int? lastSyncedAtMs;
  const TasksTableData({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.completed,
    this.dueDate,
    required this.hasTime,
    this.dueTime,
    required this.subtasksJson,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
    this.googleEventId,
    this.googleTaskId,
    this.googleEtag,
    this.lastSyncedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    map['has_time'] = Variable<bool>(hasTime);
    if (!nullToAbsent || dueTime != null) {
      map['due_time'] = Variable<String>(dueTime);
    }
    map['subtasks_json'] = Variable<String>(subtasksJson);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
    }
    if (!nullToAbsent || googleEventId != null) {
      map['google_event_id'] = Variable<String>(googleEventId);
    }
    if (!nullToAbsent || googleTaskId != null) {
      map['google_task_id'] = Variable<String>(googleTaskId);
    }
    if (!nullToAbsent || googleEtag != null) {
      map['google_etag'] = Variable<String>(googleEtag);
    }
    if (!nullToAbsent || lastSyncedAtMs != null) {
      map['last_synced_at_ms'] = Variable<int>(lastSyncedAtMs);
    }
    return map;
  }

  TasksTableCompanion toCompanion(bool nullToAbsent) {
    return TasksTableCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      completed: Value(completed),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      hasTime: Value(hasTime),
      dueTime: dueTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTime),
      subtasksJson: Value(subtasksJson),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
      googleEventId: googleEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEventId),
      googleTaskId: googleTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleTaskId),
      googleEtag: googleEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEtag),
      lastSyncedAtMs: lastSyncedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAtMs),
    );
  }

  factory TasksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasksTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      completed: serializer.fromJson<bool>(json['completed']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      hasTime: serializer.fromJson<bool>(json['hasTime']),
      dueTime: serializer.fromJson<String?>(json['dueTime']),
      subtasksJson: serializer.fromJson<String>(json['subtasksJson']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
      googleEventId: serializer.fromJson<String?>(json['googleEventId']),
      googleTaskId: serializer.fromJson<String?>(json['googleTaskId']),
      googleEtag: serializer.fromJson<String?>(json['googleEtag']),
      lastSyncedAtMs: serializer.fromJson<int?>(json['lastSyncedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'completed': serializer.toJson<bool>(completed),
      'dueDate': serializer.toJson<String?>(dueDate),
      'hasTime': serializer.toJson<bool>(hasTime),
      'dueTime': serializer.toJson<String?>(dueTime),
      'subtasksJson': serializer.toJson<String>(subtasksJson),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
      'googleEventId': serializer.toJson<String?>(googleEventId),
      'googleTaskId': serializer.toJson<String?>(googleTaskId),
      'googleEtag': serializer.toJson<String?>(googleEtag),
      'lastSyncedAtMs': serializer.toJson<int?>(lastSyncedAtMs),
    };
  }

  TasksTableData copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    bool? completed,
    Value<String?> dueDate = const Value.absent(),
    bool? hasTime,
    Value<String?> dueTime = const Value.absent(),
    String? subtasksJson,
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
    Value<String?> googleEventId = const Value.absent(),
    Value<String?> googleTaskId = const Value.absent(),
    Value<String?> googleEtag = const Value.absent(),
    Value<int?> lastSyncedAtMs = const Value.absent(),
  }) => TasksTableData(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    completed: completed ?? this.completed,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    hasTime: hasTime ?? this.hasTime,
    dueTime: dueTime.present ? dueTime.value : this.dueTime,
    subtasksJson: subtasksJson ?? this.subtasksJson,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
    googleEventId: googleEventId.present
        ? googleEventId.value
        : this.googleEventId,
    googleTaskId: googleTaskId.present ? googleTaskId.value : this.googleTaskId,
    googleEtag: googleEtag.present ? googleEtag.value : this.googleEtag,
    lastSyncedAtMs: lastSyncedAtMs.present
        ? lastSyncedAtMs.value
        : this.lastSyncedAtMs,
  );
  TasksTableData copyWithCompanion(TasksTableCompanion data) {
    return TasksTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      completed: data.completed.present ? data.completed.value : this.completed,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      hasTime: data.hasTime.present ? data.hasTime.value : this.hasTime,
      dueTime: data.dueTime.present ? data.dueTime.value : this.dueTime,
      subtasksJson: data.subtasksJson.present
          ? data.subtasksJson.value
          : this.subtasksJson,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
      googleEventId: data.googleEventId.present
          ? data.googleEventId.value
          : this.googleEventId,
      googleTaskId: data.googleTaskId.present
          ? data.googleTaskId.value
          : this.googleTaskId,
      googleEtag: data.googleEtag.present
          ? data.googleEtag.value
          : this.googleEtag,
      lastSyncedAtMs: data.lastSyncedAtMs.present
          ? data.lastSyncedAtMs.value
          : this.lastSyncedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('completed: $completed, ')
          ..write('dueDate: $dueDate, ')
          ..write('hasTime: $hasTime, ')
          ..write('dueTime: $dueTime, ')
          ..write('subtasksJson: $subtasksJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('googleTaskId: $googleTaskId, ')
          ..write('googleEtag: $googleEtag, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    description,
    completed,
    dueDate,
    hasTime,
    dueTime,
    subtasksJson,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    googleEventId,
    googleTaskId,
    googleEtag,
    lastSyncedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasksTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.description == this.description &&
          other.completed == this.completed &&
          other.dueDate == this.dueDate &&
          other.hasTime == this.hasTime &&
          other.dueTime == this.dueTime &&
          other.subtasksJson == this.subtasksJson &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.deletedAtMs == this.deletedAtMs &&
          other.googleEventId == this.googleEventId &&
          other.googleTaskId == this.googleTaskId &&
          other.googleEtag == this.googleEtag &&
          other.lastSyncedAtMs == this.lastSyncedAtMs);
}

class TasksTableCompanion extends UpdateCompanion<TasksTableData> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> title;
  final Value<String?> description;
  final Value<bool> completed;
  final Value<String?> dueDate;
  final Value<bool> hasTime;
  final Value<String?> dueTime;
  final Value<String> subtasksJson;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> deletedAtMs;
  final Value<String?> googleEventId;
  final Value<String?> googleTaskId;
  final Value<String?> googleEtag;
  final Value<int?> lastSyncedAtMs;
  final Value<int> rowid;
  const TasksTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.completed = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.subtasksJson = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.googleTaskId = const Value.absent(),
    this.googleEtag = const Value.absent(),
    this.lastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksTableCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.completed = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.dueTime = const Value.absent(),
    this.subtasksJson = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.deletedAtMs = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.googleTaskId = const Value.absent(),
    this.googleEtag = const Value.absent(),
    this.lastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<TasksTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<bool>? completed,
    Expression<String>? dueDate,
    Expression<bool>? hasTime,
    Expression<String>? dueTime,
    Expression<String>? subtasksJson,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? deletedAtMs,
    Expression<String>? googleEventId,
    Expression<String>? googleTaskId,
    Expression<String>? googleEtag,
    Expression<int>? lastSyncedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (completed != null) 'completed': completed,
      if (dueDate != null) 'due_date': dueDate,
      if (hasTime != null) 'has_time': hasTime,
      if (dueTime != null) 'due_time': dueTime,
      if (subtasksJson != null) 'subtasks_json': subtasksJson,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
      if (googleEventId != null) 'google_event_id': googleEventId,
      if (googleTaskId != null) 'google_task_id': googleTaskId,
      if (googleEtag != null) 'google_etag': googleEtag,
      if (lastSyncedAtMs != null) 'last_synced_at_ms': lastSyncedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? title,
    Value<String?>? description,
    Value<bool>? completed,
    Value<String?>? dueDate,
    Value<bool>? hasTime,
    Value<String?>? dueTime,
    Value<String>? subtasksJson,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? deletedAtMs,
    Value<String?>? googleEventId,
    Value<String?>? googleTaskId,
    Value<String?>? googleEtag,
    Value<int?>? lastSyncedAtMs,
    Value<int>? rowid,
  }) {
    return TasksTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
      dueTime: dueTime ?? this.dueTime,
      subtasksJson: subtasksJson ?? this.subtasksJson,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      googleEventId: googleEventId ?? this.googleEventId,
      googleTaskId: googleTaskId ?? this.googleTaskId,
      googleEtag: googleEtag ?? this.googleEtag,
      lastSyncedAtMs: lastSyncedAtMs ?? this.lastSyncedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (hasTime.present) {
      map['has_time'] = Variable<bool>(hasTime.value);
    }
    if (dueTime.present) {
      map['due_time'] = Variable<String>(dueTime.value);
    }
    if (subtasksJson.present) {
      map['subtasks_json'] = Variable<String>(subtasksJson.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (deletedAtMs.present) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs.value);
    }
    if (googleEventId.present) {
      map['google_event_id'] = Variable<String>(googleEventId.value);
    }
    if (googleTaskId.present) {
      map['google_task_id'] = Variable<String>(googleTaskId.value);
    }
    if (googleEtag.present) {
      map['google_etag'] = Variable<String>(googleEtag.value);
    }
    if (lastSyncedAtMs.present) {
      map['last_synced_at_ms'] = Variable<int>(lastSyncedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('completed: $completed, ')
          ..write('dueDate: $dueDate, ')
          ..write('hasTime: $hasTime, ')
          ..write('dueTime: $dueTime, ')
          ..write('subtasksJson: $subtasksJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('googleTaskId: $googleTaskId, ')
          ..write('googleEtag: $googleEtag, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PomodoroSessionsTableTable extends PomodoroSessionsTable
    with TableInfo<$PomodoroSessionsTableTable, PomodoroSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PomodoroSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMsMeta = const VerificationMeta(
    'completedAtMs',
  );
  @override
  late final GeneratedColumn<int> completedAtMs = GeneratedColumn<int>(
    'completed_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, mode, minutes, completedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pomodoro_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PomodoroSessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('completed_at_ms')) {
      context.handle(
        _completedAtMsMeta,
        completedAtMs.isAcceptableOrUnknown(
          data['completed_at_ms']!,
          _completedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PomodoroSessionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PomodoroSessionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      completedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_ms'],
      )!,
    );
  }

  @override
  $PomodoroSessionsTableTable createAlias(String alias) {
    return $PomodoroSessionsTableTable(attachedDatabase, alias);
  }
}

class PomodoroSessionsTableData extends DataClass
    implements Insertable<PomodoroSessionsTableData> {
  final String id;
  final String mode;
  final int minutes;
  final int completedAtMs;
  const PomodoroSessionsTableData({
    required this.id,
    required this.mode,
    required this.minutes,
    required this.completedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mode'] = Variable<String>(mode);
    map['minutes'] = Variable<int>(minutes);
    map['completed_at_ms'] = Variable<int>(completedAtMs);
    return map;
  }

  PomodoroSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return PomodoroSessionsTableCompanion(
      id: Value(id),
      mode: Value(mode),
      minutes: Value(minutes),
      completedAtMs: Value(completedAtMs),
    );
  }

  factory PomodoroSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PomodoroSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      minutes: serializer.fromJson<int>(json['minutes']),
      completedAtMs: serializer.fromJson<int>(json['completedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mode': serializer.toJson<String>(mode),
      'minutes': serializer.toJson<int>(minutes),
      'completedAtMs': serializer.toJson<int>(completedAtMs),
    };
  }

  PomodoroSessionsTableData copyWith({
    String? id,
    String? mode,
    int? minutes,
    int? completedAtMs,
  }) => PomodoroSessionsTableData(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    minutes: minutes ?? this.minutes,
    completedAtMs: completedAtMs ?? this.completedAtMs,
  );
  PomodoroSessionsTableData copyWithCompanion(
    PomodoroSessionsTableCompanion data,
  ) {
    return PomodoroSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      completedAtMs: data.completedAtMs.present
          ? data.completedAtMs.value
          : this.completedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSessionsTableData(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('minutes: $minutes, ')
          ..write('completedAtMs: $completedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mode, minutes, completedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PomodoroSessionsTableData &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.minutes == this.minutes &&
          other.completedAtMs == this.completedAtMs);
}

class PomodoroSessionsTableCompanion
    extends UpdateCompanion<PomodoroSessionsTableData> {
  final Value<String> id;
  final Value<String> mode;
  final Value<int> minutes;
  final Value<int> completedAtMs;
  final Value<int> rowid;
  const PomodoroSessionsTableCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.minutes = const Value.absent(),
    this.completedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PomodoroSessionsTableCompanion.insert({
    required String id,
    required String mode,
    required int minutes,
    required int completedAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mode = Value(mode),
       minutes = Value(minutes),
       completedAtMs = Value(completedAtMs);
  static Insertable<PomodoroSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? mode,
    Expression<int>? minutes,
    Expression<int>? completedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (minutes != null) 'minutes': minutes,
      if (completedAtMs != null) 'completed_at_ms': completedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PomodoroSessionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? mode,
    Value<int>? minutes,
    Value<int>? completedAtMs,
    Value<int>? rowid,
  }) {
    return PomodoroSessionsTableCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      minutes: minutes ?? this.minutes,
      completedAtMs: completedAtMs ?? this.completedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (completedAtMs.present) {
      map['completed_at_ms'] = Variable<int>(completedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('minutes: $minutes, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTableTable tasksTable = $TasksTableTable(this);
  late final $PomodoroSessionsTableTable pomodoroSessionsTable =
      $PomodoroSessionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasksTable,
    pomodoroSessionsTable,
  ];
}

typedef $$TasksTableTableCreateCompanionBuilder = TasksTableCompanion Function({
  required String id,
  Value<String?> userId,
  required String title,
  Value<String?> description,
  Value<bool> completed,
  Value<String?> dueDate,
  Value<bool> hasTime,
  Value<String?> dueTime,
  Value<String> subtasksJson,
  required int createdAtMs,
  required int updatedAtMs,
  Value<int?> deletedAtMs,
  Value<String?> googleEventId,
  Value<String?> googleTaskId,
  Value<String?> googleEtag,
  Value<int?> lastSyncedAtMs,
  Value<int> rowid,
});
typedef $$TasksTableTableUpdateCompanionBuilder = TasksTableCompanion Function({
  Value<String> id,
  Value<String?> userId,
  Value<String> title,
  Value<String?> description,
  Value<bool> completed,
  Value<String?> dueDate,
  Value<bool> hasTime,
  Value<String?> dueTime,
  Value<String> subtasksJson,
  Value<int> createdAtMs,
  Value<int> updatedAtMs,
  Value<int?> deletedAtMs,
  Value<String?> googleEventId,
  Value<String?> googleTaskId,
  Value<String?> googleEtag,
  Value<int?> lastSyncedAtMs,
  Value<int> rowid,
});

class $$TasksTableTableFilterComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtasksJson => $composableBuilder(
    column: $table.subtasksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEtag => $composableBuilder(
    column: $table.googleEtag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueTime => $composableBuilder(
    column: $table.dueTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtasksJson => $composableBuilder(
    column: $table.subtasksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEtag => $composableBuilder(
    column: $table.googleEtag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTableTable> {
  $$TasksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get hasTime =>
      $composableBuilder(column: $table.hasTime, builder: (column) => column);

  GeneratedColumn<String> get dueTime =>
      $composableBuilder(column: $table.dueTime, builder: (column) => column);

  GeneratedColumn<String> get subtasksJson => $composableBuilder(
    column: $table.subtasksJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get googleTaskId => $composableBuilder(
    column: $table.googleTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get googleEtag => $composableBuilder(
    column: $table.googleEtag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => column,
  );
}

class $$TasksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTableTable,
          TasksTableData,
          $$TasksTableTableFilterComposer,
          $$TasksTableTableOrderingComposer,
          $$TasksTableTableAnnotationComposer,
          $$TasksTableTableCreateCompanionBuilder,
          $$TasksTableTableUpdateCompanionBuilder,
          (
            TasksTableData,
            BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
          ),
          TasksTableData,
          PrefetchHooks Function()
        > {
  $$TasksTableTableTableManager(_$AppDatabase db, $TasksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<bool> hasTime = const Value.absent(),
                Value<String?> dueTime = const Value.absent(),
                Value<String> subtasksJson = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
                Value<String?> googleEventId = const Value.absent(),
                Value<String?> googleTaskId = const Value.absent(),
                Value<String?> googleEtag = const Value.absent(),
                Value<int?> lastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksTableCompanion(
                id: id,
                userId: userId,
                title: title,
                description: description,
                completed: completed,
                dueDate: dueDate,
                hasTime: hasTime,
                dueTime: dueTime,
                subtasksJson: subtasksJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                googleEventId: googleEventId,
                googleTaskId: googleTaskId,
                googleEtag: googleEtag,
                lastSyncedAtMs: lastSyncedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<bool> hasTime = const Value.absent(),
                Value<String?> dueTime = const Value.absent(),
                Value<String> subtasksJson = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
                Value<String?> googleEventId = const Value.absent(),
                Value<String?> googleTaskId = const Value.absent(),
                Value<String?> googleEtag = const Value.absent(),
                Value<int?> lastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksTableCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                description: description,
                completed: completed,
                dueDate: dueDate,
                hasTime: hasTime,
                dueTime: dueTime,
                subtasksJson: subtasksJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                googleEventId: googleEventId,
                googleTaskId: googleTaskId,
                googleEtag: googleEtag,
                lastSyncedAtMs: lastSyncedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTableTable, TasksTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TasksTableTable,
                    TasksTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTableTable,
      TasksTableData,
      $$TasksTableTableFilterComposer,
      $$TasksTableTableOrderingComposer,
      $$TasksTableTableAnnotationComposer,
      $$TasksTableTableCreateCompanionBuilder,
      $$TasksTableTableUpdateCompanionBuilder,
      (
        TasksTableData,
        BaseReferences<_$AppDatabase, $TasksTableTable, TasksTableData>,
      ),
      TasksTableData,
      PrefetchHooks Function()
    >;
typedef $$PomodoroSessionsTableTableCreateCompanionBuilder =
    PomodoroSessionsTableCompanion Function({
      required String id,
      required String mode,
      required int minutes,
      required int completedAtMs,
      Value<int> rowid,
    });
typedef $$PomodoroSessionsTableTableUpdateCompanionBuilder =
    PomodoroSessionsTableCompanion Function({
      Value<String> id,
      Value<String> mode,
      Value<int> minutes,
      Value<int> completedAtMs,
      Value<int> rowid,
    });

class $$PomodoroSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTableTable> {
  $$PomodoroSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PomodoroSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTableTable> {
  $$PomodoroSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PomodoroSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PomodoroSessionsTableTable> {
  $$PomodoroSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => column,
  );
}

class $$PomodoroSessionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PomodoroSessionsTableTable,
          PomodoroSessionsTableData,
          $$PomodoroSessionsTableTableFilterComposer,
          $$PomodoroSessionsTableTableOrderingComposer,
          $$PomodoroSessionsTableTableAnnotationComposer,
          $$PomodoroSessionsTableTableCreateCompanionBuilder,
          $$PomodoroSessionsTableTableUpdateCompanionBuilder,
          (
            PomodoroSessionsTableData,
            BaseReferences<
              _$AppDatabase,
              $PomodoroSessionsTableTable,
              PomodoroSessionsTableData
            >,
          ),
          PomodoroSessionsTableData,
          PrefetchHooks Function()
        > {
  $$PomodoroSessionsTableTableTableManager(
    _$AppDatabase db,
    $PomodoroSessionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PomodoroSessionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PomodoroSessionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PomodoroSessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<int> completedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSessionsTableCompanion(
                id: id,
                mode: mode,
                minutes: minutes,
                completedAtMs: completedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mode,
                required int minutes,
                required int completedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSessionsTableCompanion.insert(
                id: id,
                mode: mode,
                minutes: minutes,
                completedAtMs: completedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PomodoroSessionsTableTable,
                    PomodoroSessionsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PomodoroSessionsTableTable,
                    PomodoroSessionsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PomodoroSessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PomodoroSessionsTableTable,
      PomodoroSessionsTableData,
      $$PomodoroSessionsTableTableFilterComposer,
      $$PomodoroSessionsTableTableOrderingComposer,
      $$PomodoroSessionsTableTableAnnotationComposer,
      $$PomodoroSessionsTableTableCreateCompanionBuilder,
      $$PomodoroSessionsTableTableUpdateCompanionBuilder,
      (
        PomodoroSessionsTableData,
        BaseReferences<
          _$AppDatabase,
          $PomodoroSessionsTableTable,
          PomodoroSessionsTableData
        >,
      ),
      PomodoroSessionsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db, _db.tasksTable);
  $$PomodoroSessionsTableTableTableManager get pomodoroSessionsTable =>
      $$PomodoroSessionsTableTableTableManager(_db, _db.pomodoroSessionsTable);
}
