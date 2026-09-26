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
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
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
    attachmentsJson,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
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
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
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
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
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
  final String attachmentsJson;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;
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
    required this.attachmentsJson,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
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
    map['attachments_json'] = Variable<String>(attachmentsJson);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
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
      attachmentsJson: Value(attachmentsJson),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
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
      attachmentsJson: serializer.fromJson<String>(json['attachmentsJson']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
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
      'attachmentsJson': serializer.toJson<String>(attachmentsJson),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
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
    String? attachmentsJson,
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
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
    attachmentsJson: attachmentsJson ?? this.attachmentsJson,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
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
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
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
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
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
    attachmentsJson,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
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
          other.attachmentsJson == this.attachmentsJson &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.deletedAtMs == this.deletedAtMs &&
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
  final Value<String> attachmentsJson;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> deletedAtMs;
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
    this.attachmentsJson = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
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
    this.attachmentsJson = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.deletedAtMs = const Value.absent(),
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
    Expression<String>? attachmentsJson,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? deletedAtMs,
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
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
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
    Value<String>? attachmentsJson,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? deletedAtMs,
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
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
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
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
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
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    mode,
    minutes,
    completedAtMs,
    lastSyncedAtMs,
  ];
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
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
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
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
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
      lastSyncedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at_ms'],
      ),
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
  final String? userId;
  final String mode;
  final int minutes;
  final int completedAtMs;
  final int? lastSyncedAtMs;
  const PomodoroSessionsTableData({
    required this.id,
    this.userId,
    required this.mode,
    required this.minutes,
    required this.completedAtMs,
    this.lastSyncedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['mode'] = Variable<String>(mode);
    map['minutes'] = Variable<int>(minutes);
    map['completed_at_ms'] = Variable<int>(completedAtMs);
    if (!nullToAbsent || lastSyncedAtMs != null) {
      map['last_synced_at_ms'] = Variable<int>(lastSyncedAtMs);
    }
    return map;
  }

  PomodoroSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return PomodoroSessionsTableCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      mode: Value(mode),
      minutes: Value(minutes),
      completedAtMs: Value(completedAtMs),
      lastSyncedAtMs: lastSyncedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAtMs),
    );
  }

  factory PomodoroSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PomodoroSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      mode: serializer.fromJson<String>(json['mode']),
      minutes: serializer.fromJson<int>(json['minutes']),
      completedAtMs: serializer.fromJson<int>(json['completedAtMs']),
      lastSyncedAtMs: serializer.fromJson<int?>(json['lastSyncedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'mode': serializer.toJson<String>(mode),
      'minutes': serializer.toJson<int>(minutes),
      'completedAtMs': serializer.toJson<int>(completedAtMs),
      'lastSyncedAtMs': serializer.toJson<int?>(lastSyncedAtMs),
    };
  }

  PomodoroSessionsTableData copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? mode,
    int? minutes,
    int? completedAtMs,
    Value<int?> lastSyncedAtMs = const Value.absent(),
  }) => PomodoroSessionsTableData(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    mode: mode ?? this.mode,
    minutes: minutes ?? this.minutes,
    completedAtMs: completedAtMs ?? this.completedAtMs,
    lastSyncedAtMs: lastSyncedAtMs.present
        ? lastSyncedAtMs.value
        : this.lastSyncedAtMs,
  );
  PomodoroSessionsTableData copyWithCompanion(
    PomodoroSessionsTableCompanion data,
  ) {
    return PomodoroSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      mode: data.mode.present ? data.mode.value : this.mode,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      completedAtMs: data.completedAtMs.present
          ? data.completedAtMs.value
          : this.completedAtMs,
      lastSyncedAtMs: data.lastSyncedAtMs.present
          ? data.lastSyncedAtMs.value
          : this.lastSyncedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PomodoroSessionsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mode: $mode, ')
          ..write('minutes: $minutes, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, mode, minutes, completedAtMs, lastSyncedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PomodoroSessionsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.mode == this.mode &&
          other.minutes == this.minutes &&
          other.completedAtMs == this.completedAtMs &&
          other.lastSyncedAtMs == this.lastSyncedAtMs);
}

class PomodoroSessionsTableCompanion
    extends UpdateCompanion<PomodoroSessionsTableData> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> mode;
  final Value<int> minutes;
  final Value<int> completedAtMs;
  final Value<int?> lastSyncedAtMs;
  final Value<int> rowid;
  const PomodoroSessionsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.mode = const Value.absent(),
    this.minutes = const Value.absent(),
    this.completedAtMs = const Value.absent(),
    this.lastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PomodoroSessionsTableCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String mode,
    required int minutes,
    required int completedAtMs,
    this.lastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mode = Value(mode),
       minutes = Value(minutes),
       completedAtMs = Value(completedAtMs);
  static Insertable<PomodoroSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? mode,
    Expression<int>? minutes,
    Expression<int>? completedAtMs,
    Expression<int>? lastSyncedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (mode != null) 'mode': mode,
      if (minutes != null) 'minutes': minutes,
      if (completedAtMs != null) 'completed_at_ms': completedAtMs,
      if (lastSyncedAtMs != null) 'last_synced_at_ms': lastSyncedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PomodoroSessionsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? mode,
    Value<int>? minutes,
    Value<int>? completedAtMs,
    Value<int?>? lastSyncedAtMs,
    Value<int>? rowid,
  }) {
    return PomodoroSessionsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      minutes: minutes ?? this.minutes,
      completedAtMs: completedAtMs ?? this.completedAtMs,
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
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (completedAtMs.present) {
      map['completed_at_ms'] = Variable<int>(completedAtMs.value);
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
    return (StringBuffer('PomodoroSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mode: $mode, ')
          ..write('minutes: $minutes, ')
          ..write('completedAtMs: $completedAtMs, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTableTable extends ProfilesTable
    with TableInfo<$ProfilesTableTable, ProfilesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarImageMeta = const VerificationMeta(
    'avatarImage',
  );
  @override
  late final GeneratedColumn<String> avatarImage = GeneratedColumn<String>(
    'avatar_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    displayName,
    email,
    avatarImage,
    updatedAtMs,
    lastSyncedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfilesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('avatar_image')) {
      context.handle(
        _avatarImageMeta,
        avatarImage.isAcceptableOrUnknown(
          data['avatar_image']!,
          _avatarImageMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
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
  ProfilesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfilesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      avatarImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_image'],
      ),
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      ),
      lastSyncedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at_ms'],
      ),
    );
  }

  @override
  $ProfilesTableTable createAlias(String alias) {
    return $ProfilesTableTable(attachedDatabase, alias);
  }
}

class ProfilesTableData extends DataClass
    implements Insertable<ProfilesTableData> {
  final String id;
  final String displayName;
  final String email;
  final String? avatarImage;
  final int? updatedAtMs;
  final int? lastSyncedAtMs;
  const ProfilesTableData({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarImage,
    this.updatedAtMs,
    this.lastSyncedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || avatarImage != null) {
      map['avatar_image'] = Variable<String>(avatarImage);
    }
    if (!nullToAbsent || updatedAtMs != null) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs);
    }
    if (!nullToAbsent || lastSyncedAtMs != null) {
      map['last_synced_at_ms'] = Variable<int>(lastSyncedAtMs);
    }
    return map;
  }

  ProfilesTableCompanion toCompanion(bool nullToAbsent) {
    return ProfilesTableCompanion(
      id: Value(id),
      displayName: Value(displayName),
      email: Value(email),
      avatarImage: avatarImage == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarImage),
      updatedAtMs: updatedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAtMs),
      lastSyncedAtMs: lastSyncedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAtMs),
    );
  }

  factory ProfilesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfilesTableData(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      email: serializer.fromJson<String>(json['email']),
      avatarImage: serializer.fromJson<String?>(json['avatarImage']),
      updatedAtMs: serializer.fromJson<int?>(json['updatedAtMs']),
      lastSyncedAtMs: serializer.fromJson<int?>(json['lastSyncedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'email': serializer.toJson<String>(email),
      'avatarImage': serializer.toJson<String?>(avatarImage),
      'updatedAtMs': serializer.toJson<int?>(updatedAtMs),
      'lastSyncedAtMs': serializer.toJson<int?>(lastSyncedAtMs),
    };
  }

  ProfilesTableData copyWith({
    String? id,
    String? displayName,
    String? email,
    Value<String?> avatarImage = const Value.absent(),
    Value<int?> updatedAtMs = const Value.absent(),
    Value<int?> lastSyncedAtMs = const Value.absent(),
  }) => ProfilesTableData(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    avatarImage: avatarImage.present ? avatarImage.value : this.avatarImage,
    updatedAtMs: updatedAtMs.present ? updatedAtMs.value : this.updatedAtMs,
    lastSyncedAtMs: lastSyncedAtMs.present
        ? lastSyncedAtMs.value
        : this.lastSyncedAtMs,
  );
  ProfilesTableData copyWithCompanion(ProfilesTableCompanion data) {
    return ProfilesTableData(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      avatarImage: data.avatarImage.present
          ? data.avatarImage.value
          : this.avatarImage,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      lastSyncedAtMs: data.lastSyncedAtMs.present
          ? data.lastSyncedAtMs.value
          : this.lastSyncedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesTableData(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('avatarImage: $avatarImage, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    email,
    avatarImage,
    updatedAtMs,
    lastSyncedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfilesTableData &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.avatarImage == this.avatarImage &&
          other.updatedAtMs == this.updatedAtMs &&
          other.lastSyncedAtMs == this.lastSyncedAtMs);
}

class ProfilesTableCompanion extends UpdateCompanion<ProfilesTableData> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> email;
  final Value<String?> avatarImage;
  final Value<int?> updatedAtMs;
  final Value<int?> lastSyncedAtMs;
  final Value<int> rowid;
  const ProfilesTableCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarImage = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.lastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesTableCompanion.insert({
    required String id,
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarImage = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.lastSyncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ProfilesTableData> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<String>? avatarImage,
    Expression<int>? updatedAtMs,
    Expression<int>? lastSyncedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
      if (avatarImage != null) 'avatar_image': avatarImage,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (lastSyncedAtMs != null) 'last_synced_at_ms': lastSyncedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? email,
    Value<String?>? avatarImage,
    Value<int?>? updatedAtMs,
    Value<int?>? lastSyncedAtMs,
    Value<int>? rowid,
  }) {
    return ProfilesTableCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarImage: avatarImage ?? this.avatarImage,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
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
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatarImage.present) {
      map['avatar_image'] = Variable<String>(avatarImage.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
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
    return (StringBuffer('ProfilesTableCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('avatarImage: $avatarImage, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('lastSyncedAtMs: $lastSyncedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RevisionSubjectsTableTable extends RevisionSubjectsTable
    with TableInfo<$RevisionSubjectsTableTable, RevisionSubjectsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RevisionSubjectsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('menu_book_rounded'),
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF6750A4),
  );
  static const VerificationMeta _notesJsonMeta = const VerificationMeta(
    'notesJson',
  );
  @override
  late final GeneratedColumn<String> notesJson = GeneratedColumn<String>(
    'notes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    iconName,
    colorValue,
    notesJson,
    attachmentsJson,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revision_subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevisionSubjectsTableData> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('notes_json')) {
      context.handle(
        _notesJsonMeta,
        notesJson.isAcceptableOrUnknown(data['notes_json']!, _notesJsonMeta),
      );
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RevisionSubjectsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevisionSubjectsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      notesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes_json'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $RevisionSubjectsTableTable createAlias(String alias) {
    return $RevisionSubjectsTableTable(attachedDatabase, alias);
  }
}

class RevisionSubjectsTableData extends DataClass
    implements Insertable<RevisionSubjectsTableData> {
  final String id;
  final String? userId;
  final String name;
  final String iconName;
  final int colorValue;
  final String notesJson;
  final String attachmentsJson;
  final int createdAtMs;
  const RevisionSubjectsTableData({
    required this.id,
    this.userId,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.notesJson,
    required this.attachmentsJson,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    map['icon_name'] = Variable<String>(iconName);
    map['color_value'] = Variable<int>(colorValue);
    map['notes_json'] = Variable<String>(notesJson);
    map['attachments_json'] = Variable<String>(attachmentsJson);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  RevisionSubjectsTableCompanion toCompanion(bool nullToAbsent) {
    return RevisionSubjectsTableCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      name: Value(name),
      iconName: Value(iconName),
      colorValue: Value(colorValue),
      notesJson: Value(notesJson),
      attachmentsJson: Value(attachmentsJson),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory RevisionSubjectsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevisionSubjectsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      notesJson: serializer.fromJson<String>(json['notesJson']),
      attachmentsJson: serializer.fromJson<String>(json['attachmentsJson']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'iconName': serializer.toJson<String>(iconName),
      'colorValue': serializer.toJson<int>(colorValue),
      'notesJson': serializer.toJson<String>(notesJson),
      'attachmentsJson': serializer.toJson<String>(attachmentsJson),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  RevisionSubjectsTableData copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? name,
    String? iconName,
    int? colorValue,
    String? notesJson,
    String? attachmentsJson,
    int? createdAtMs,
  }) => RevisionSubjectsTableData(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorValue: colorValue ?? this.colorValue,
    notesJson: notesJson ?? this.notesJson,
    attachmentsJson: attachmentsJson ?? this.attachmentsJson,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  RevisionSubjectsTableData copyWithCompanion(
    RevisionSubjectsTableCompanion data,
  ) {
    return RevisionSubjectsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      notesJson: data.notesJson.present ? data.notesJson.value : this.notesJson,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionSubjectsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('notesJson: $notesJson, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    iconName,
    colorValue,
    notesJson,
    attachmentsJson,
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionSubjectsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.iconName == this.iconName &&
          other.colorValue == this.colorValue &&
          other.notesJson == this.notesJson &&
          other.attachmentsJson == this.attachmentsJson &&
          other.createdAtMs == this.createdAtMs);
}

class RevisionSubjectsTableCompanion
    extends UpdateCompanion<RevisionSubjectsTableData> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String> iconName;
  final Value<int> colorValue;
  final Value<String> notesJson;
  final Value<String> attachmentsJson;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const RevisionSubjectsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.notesJson = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RevisionSubjectsTableCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String name,
    this.iconName = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.notesJson = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAtMs = Value(createdAtMs);
  static Insertable<RevisionSubjectsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? iconName,
    Expression<int>? colorValue,
    Expression<String>? notesJson,
    Expression<String>? attachmentsJson,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (iconName != null) 'icon_name': iconName,
      if (colorValue != null) 'color_value': colorValue,
      if (notesJson != null) 'notes_json': notesJson,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RevisionSubjectsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? name,
    Value<String>? iconName,
    Value<int>? colorValue,
    Value<String>? notesJson,
    Value<String>? attachmentsJson,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return RevisionSubjectsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      notesJson: notesJson ?? this.notesJson,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      createdAtMs: createdAtMs ?? this.createdAtMs,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (notesJson.present) {
      map['notes_json'] = Variable<String>(notesJson.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionSubjectsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('notesJson: $notesJson, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RevisionTopicsTableTable extends RevisionTopicsTable
    with TableInfo<$RevisionTopicsTableTable, RevisionTopicsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RevisionTopicsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _notesJsonMeta = const VerificationMeta(
    'notesJson',
  );
  @override
  late final GeneratedColumn<String> notesJson = GeneratedColumn<String>(
    'notes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  @override
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _revisionStageMeta = const VerificationMeta(
    'revisionStage',
  );
  @override
  late final GeneratedColumn<int> revisionStage = GeneratedColumn<int>(
    'revision_stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastRevisedAtMsMeta = const VerificationMeta(
    'lastRevisedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastRevisedAtMs = GeneratedColumn<int>(
    'last_revised_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextRevisionDateMsMeta =
      const VerificationMeta('nextRevisionDateMs');
  @override
  late final GeneratedColumn<int> nextRevisionDateMs = GeneratedColumn<int>(
    'next_revision_date_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _associatedTaskIdMeta = const VerificationMeta(
    'associatedTaskId',
  );
  @override
  late final GeneratedColumn<String> associatedTaskId = GeneratedColumn<String>(
    'associated_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    subjectId,
    title,
    description,
    notesJson,
    attachmentsJson,
    isCompleted,
    revisionStage,
    lastRevisedAtMs,
    nextRevisionDateMs,
    associatedTaskId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revision_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevisionTopicsTableData> instance, {
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
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
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
    if (data.containsKey('notes_json')) {
      context.handle(
        _notesJsonMeta,
        notesJson.isAcceptableOrUnknown(data['notes_json']!, _notesJsonMeta),
      );
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('revision_stage')) {
      context.handle(
        _revisionStageMeta,
        revisionStage.isAcceptableOrUnknown(
          data['revision_stage']!,
          _revisionStageMeta,
        ),
      );
    }
    if (data.containsKey('last_revised_at_ms')) {
      context.handle(
        _lastRevisedAtMsMeta,
        lastRevisedAtMs.isAcceptableOrUnknown(
          data['last_revised_at_ms']!,
          _lastRevisedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('next_revision_date_ms')) {
      context.handle(
        _nextRevisionDateMsMeta,
        nextRevisionDateMs.isAcceptableOrUnknown(
          data['next_revision_date_ms']!,
          _nextRevisionDateMsMeta,
        ),
      );
    }
    if (data.containsKey('associated_task_id')) {
      context.handle(
        _associatedTaskIdMeta,
        associatedTaskId.isAcceptableOrUnknown(
          data['associated_task_id']!,
          _associatedTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RevisionTopicsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevisionTopicsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      notesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes_json'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      revisionStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_stage'],
      )!,
      lastRevisedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_revised_at_ms'],
      ),
      nextRevisionDateMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_revision_date_ms'],
      ),
      associatedTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}associated_task_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $RevisionTopicsTableTable createAlias(String alias) {
    return $RevisionTopicsTableTable(attachedDatabase, alias);
  }
}

class RevisionTopicsTableData extends DataClass
    implements Insertable<RevisionTopicsTableData> {
  final String id;
  final String? userId;
  final String subjectId;
  final String title;
  final String? description;
  final String notesJson;
  final String attachmentsJson;
  final bool isCompleted;
  final int revisionStage;
  final int? lastRevisedAtMs;
  final int? nextRevisionDateMs;
  final String? associatedTaskId;
  final int sortOrder;
  const RevisionTopicsTableData({
    required this.id,
    this.userId,
    required this.subjectId,
    required this.title,
    this.description,
    required this.notesJson,
    required this.attachmentsJson,
    required this.isCompleted,
    required this.revisionStage,
    this.lastRevisedAtMs,
    this.nextRevisionDateMs,
    this.associatedTaskId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['subject_id'] = Variable<String>(subjectId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['notes_json'] = Variable<String>(notesJson);
    map['attachments_json'] = Variable<String>(attachmentsJson);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['revision_stage'] = Variable<int>(revisionStage);
    if (!nullToAbsent || lastRevisedAtMs != null) {
      map['last_revised_at_ms'] = Variable<int>(lastRevisedAtMs);
    }
    if (!nullToAbsent || nextRevisionDateMs != null) {
      map['next_revision_date_ms'] = Variable<int>(nextRevisionDateMs);
    }
    if (!nullToAbsent || associatedTaskId != null) {
      map['associated_task_id'] = Variable<String>(associatedTaskId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  RevisionTopicsTableCompanion toCompanion(bool nullToAbsent) {
    return RevisionTopicsTableCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      subjectId: Value(subjectId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      notesJson: Value(notesJson),
      attachmentsJson: Value(attachmentsJson),
      isCompleted: Value(isCompleted),
      revisionStage: Value(revisionStage),
      lastRevisedAtMs: lastRevisedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRevisedAtMs),
      nextRevisionDateMs: nextRevisionDateMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRevisionDateMs),
      associatedTaskId: associatedTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(associatedTaskId),
      sortOrder: Value(sortOrder),
    );
  }

  factory RevisionTopicsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevisionTopicsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      notesJson: serializer.fromJson<String>(json['notesJson']),
      attachmentsJson: serializer.fromJson<String>(json['attachmentsJson']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      revisionStage: serializer.fromJson<int>(json['revisionStage']),
      lastRevisedAtMs: serializer.fromJson<int?>(json['lastRevisedAtMs']),
      nextRevisionDateMs: serializer.fromJson<int?>(json['nextRevisionDateMs']),
      associatedTaskId: serializer.fromJson<String?>(json['associatedTaskId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'subjectId': serializer.toJson<String>(subjectId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'notesJson': serializer.toJson<String>(notesJson),
      'attachmentsJson': serializer.toJson<String>(attachmentsJson),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'revisionStage': serializer.toJson<int>(revisionStage),
      'lastRevisedAtMs': serializer.toJson<int?>(lastRevisedAtMs),
      'nextRevisionDateMs': serializer.toJson<int?>(nextRevisionDateMs),
      'associatedTaskId': serializer.toJson<String?>(associatedTaskId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  RevisionTopicsTableData copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? subjectId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? notesJson,
    String? attachmentsJson,
    bool? isCompleted,
    int? revisionStage,
    Value<int?> lastRevisedAtMs = const Value.absent(),
    Value<int?> nextRevisionDateMs = const Value.absent(),
    Value<String?> associatedTaskId = const Value.absent(),
    int? sortOrder,
  }) => RevisionTopicsTableData(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    subjectId: subjectId ?? this.subjectId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    notesJson: notesJson ?? this.notesJson,
    attachmentsJson: attachmentsJson ?? this.attachmentsJson,
    isCompleted: isCompleted ?? this.isCompleted,
    revisionStage: revisionStage ?? this.revisionStage,
    lastRevisedAtMs: lastRevisedAtMs.present
        ? lastRevisedAtMs.value
        : this.lastRevisedAtMs,
    nextRevisionDateMs: nextRevisionDateMs.present
        ? nextRevisionDateMs.value
        : this.nextRevisionDateMs,
    associatedTaskId: associatedTaskId.present
        ? associatedTaskId.value
        : this.associatedTaskId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  RevisionTopicsTableData copyWithCompanion(RevisionTopicsTableCompanion data) {
    return RevisionTopicsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      notesJson: data.notesJson.present ? data.notesJson.value : this.notesJson,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      revisionStage: data.revisionStage.present
          ? data.revisionStage.value
          : this.revisionStage,
      lastRevisedAtMs: data.lastRevisedAtMs.present
          ? data.lastRevisedAtMs.value
          : this.lastRevisedAtMs,
      nextRevisionDateMs: data.nextRevisionDateMs.present
          ? data.nextRevisionDateMs.value
          : this.nextRevisionDateMs,
      associatedTaskId: data.associatedTaskId.present
          ? data.associatedTaskId.value
          : this.associatedTaskId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionTopicsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('notesJson: $notesJson, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('revisionStage: $revisionStage, ')
          ..write('lastRevisedAtMs: $lastRevisedAtMs, ')
          ..write('nextRevisionDateMs: $nextRevisionDateMs, ')
          ..write('associatedTaskId: $associatedTaskId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    subjectId,
    title,
    description,
    notesJson,
    attachmentsJson,
    isCompleted,
    revisionStage,
    lastRevisedAtMs,
    nextRevisionDateMs,
    associatedTaskId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionTopicsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.subjectId == this.subjectId &&
          other.title == this.title &&
          other.description == this.description &&
          other.notesJson == this.notesJson &&
          other.attachmentsJson == this.attachmentsJson &&
          other.isCompleted == this.isCompleted &&
          other.revisionStage == this.revisionStage &&
          other.lastRevisedAtMs == this.lastRevisedAtMs &&
          other.nextRevisionDateMs == this.nextRevisionDateMs &&
          other.associatedTaskId == this.associatedTaskId &&
          other.sortOrder == this.sortOrder);
}

class RevisionTopicsTableCompanion
    extends UpdateCompanion<RevisionTopicsTableData> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> subjectId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> notesJson;
  final Value<String> attachmentsJson;
  final Value<bool> isCompleted;
  final Value<int> revisionStage;
  final Value<int?> lastRevisedAtMs;
  final Value<int?> nextRevisionDateMs;
  final Value<String?> associatedTaskId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const RevisionTopicsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.notesJson = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.revisionStage = const Value.absent(),
    this.lastRevisedAtMs = const Value.absent(),
    this.nextRevisionDateMs = const Value.absent(),
    this.associatedTaskId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RevisionTopicsTableCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String subjectId,
    required String title,
    this.description = const Value.absent(),
    this.notesJson = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.revisionStage = const Value.absent(),
    this.lastRevisedAtMs = const Value.absent(),
    this.nextRevisionDateMs = const Value.absent(),
    this.associatedTaskId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subjectId = Value(subjectId),
       title = Value(title);
  static Insertable<RevisionTopicsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? subjectId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? notesJson,
    Expression<String>? attachmentsJson,
    Expression<bool>? isCompleted,
    Expression<int>? revisionStage,
    Expression<int>? lastRevisedAtMs,
    Expression<int>? nextRevisionDateMs,
    Expression<String>? associatedTaskId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (subjectId != null) 'subject_id': subjectId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (notesJson != null) 'notes_json': notesJson,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (revisionStage != null) 'revision_stage': revisionStage,
      if (lastRevisedAtMs != null) 'last_revised_at_ms': lastRevisedAtMs,
      if (nextRevisionDateMs != null)
        'next_revision_date_ms': nextRevisionDateMs,
      if (associatedTaskId != null) 'associated_task_id': associatedTaskId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RevisionTopicsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? subjectId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? notesJson,
    Value<String>? attachmentsJson,
    Value<bool>? isCompleted,
    Value<int>? revisionStage,
    Value<int?>? lastRevisedAtMs,
    Value<int?>? nextRevisionDateMs,
    Value<String?>? associatedTaskId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return RevisionTopicsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      notesJson: notesJson ?? this.notesJson,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      isCompleted: isCompleted ?? this.isCompleted,
      revisionStage: revisionStage ?? this.revisionStage,
      lastRevisedAtMs: lastRevisedAtMs ?? this.lastRevisedAtMs,
      nextRevisionDateMs: nextRevisionDateMs ?? this.nextRevisionDateMs,
      associatedTaskId: associatedTaskId ?? this.associatedTaskId,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (notesJson.present) {
      map['notes_json'] = Variable<String>(notesJson.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (revisionStage.present) {
      map['revision_stage'] = Variable<int>(revisionStage.value);
    }
    if (lastRevisedAtMs.present) {
      map['last_revised_at_ms'] = Variable<int>(lastRevisedAtMs.value);
    }
    if (nextRevisionDateMs.present) {
      map['next_revision_date_ms'] = Variable<int>(nextRevisionDateMs.value);
    }
    if (associatedTaskId.present) {
      map['associated_task_id'] = Variable<String>(associatedTaskId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionTopicsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('notesJson: $notesJson, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('revisionStage: $revisionStage, ')
          ..write('lastRevisedAtMs: $lastRevisedAtMs, ')
          ..write('nextRevisionDateMs: $nextRevisionDateMs, ')
          ..write('associatedTaskId: $associatedTaskId, ')
          ..write('sortOrder: $sortOrder, ')
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
  late final $ProfilesTableTable profilesTable = $ProfilesTableTable(this);
  late final $RevisionSubjectsTableTable revisionSubjectsTable =
      $RevisionSubjectsTableTable(this);
  late final $RevisionTopicsTableTable revisionTopicsTable =
      $RevisionTopicsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasksTable,
    pomodoroSessionsTable,
    profilesTable,
    revisionSubjectsTable,
    revisionTopicsTable,
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
  Value<String> attachmentsJson,
  required int createdAtMs,
  required int updatedAtMs,
  Value<int?> deletedAtMs,
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
  Value<String> attachmentsJson,
  Value<int> createdAtMs,
  Value<int> updatedAtMs,
  Value<int?> deletedAtMs,
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

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
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

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
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

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
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
                Value<String> attachmentsJson = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
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
                attachmentsJson: attachmentsJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
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
                Value<String> attachmentsJson = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
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
                attachmentsJson: attachmentsJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
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
      Value<String?> userId,
      required String mode,
      required int minutes,
      required int completedAtMs,
      Value<int?> lastSyncedAtMs,
      Value<int> rowid,
    });
typedef $$PomodoroSessionsTableTableUpdateCompanionBuilder =
    PomodoroSessionsTableCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> mode,
      Value<int> minutes,
      Value<int> completedAtMs,
      Value<int?> lastSyncedAtMs,
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
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

  ColumnFilters<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
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

  ColumnOrderings<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
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

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get completedAtMs => $composableBuilder(
    column: $table.completedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
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
                Value<String?> userId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<int> completedAtMs = const Value.absent(),
                Value<int?> lastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSessionsTableCompanion(
                id: id,
                userId: userId,
                mode: mode,
                minutes: minutes,
                completedAtMs: completedAtMs,
                lastSyncedAtMs: lastSyncedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String mode,
                required int minutes,
                required int completedAtMs,
                Value<int?> lastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PomodoroSessionsTableCompanion.insert(
                id: id,
                userId: userId,
                mode: mode,
                minutes: minutes,
                completedAtMs: completedAtMs,
                lastSyncedAtMs: lastSyncedAtMs,
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
typedef $$ProfilesTableTableCreateCompanionBuilder =
    ProfilesTableCompanion Function({
      required String id,
      Value<String> displayName,
      Value<String> email,
      Value<String?> avatarImage,
      Value<int?> updatedAtMs,
      Value<int?> lastSyncedAtMs,
      Value<int> rowid,
    });
typedef $$ProfilesTableTableUpdateCompanionBuilder =
    ProfilesTableCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> email,
      Value<String?> avatarImage,
      Value<int?> updatedAtMs,
      Value<int?> lastSyncedAtMs,
      Value<int> rowid,
    });

class $$ProfilesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTableTable> {
  $$ProfilesTableTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarImage => $composableBuilder(
    column: $table.avatarImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTableTable> {
  $$ProfilesTableTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarImage => $composableBuilder(
    column: $table.avatarImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTableTable> {
  $$ProfilesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatarImage => $composableBuilder(
    column: $table.avatarImage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAtMs => $composableBuilder(
    column: $table.lastSyncedAtMs,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTableTable,
          ProfilesTableData,
          $$ProfilesTableTableFilterComposer,
          $$ProfilesTableTableOrderingComposer,
          $$ProfilesTableTableAnnotationComposer,
          $$ProfilesTableTableCreateCompanionBuilder,
          $$ProfilesTableTableUpdateCompanionBuilder,
          (
            ProfilesTableData,
            BaseReferences<
              _$AppDatabase,
              $ProfilesTableTable,
              ProfilesTableData
            >,
          ),
          ProfilesTableData,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableTableManager(_$AppDatabase db, $ProfilesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> avatarImage = const Value.absent(),
                Value<int?> updatedAtMs = const Value.absent(),
                Value<int?> lastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesTableCompanion(
                id: id,
                displayName: displayName,
                email: email,
                avatarImage: avatarImage,
                updatedAtMs: updatedAtMs,
                lastSyncedAtMs: lastSyncedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> displayName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> avatarImage = const Value.absent(),
                Value<int?> updatedAtMs = const Value.absent(),
                Value<int?> lastSyncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesTableCompanion.insert(
                id: id,
                displayName: displayName,
                email: email,
                avatarImage: avatarImage,
                updatedAtMs: updatedAtMs,
                lastSyncedAtMs: lastSyncedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTableTable, ProfilesTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProfilesTableTable,
                    ProfilesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTableTable,
      ProfilesTableData,
      $$ProfilesTableTableFilterComposer,
      $$ProfilesTableTableOrderingComposer,
      $$ProfilesTableTableAnnotationComposer,
      $$ProfilesTableTableCreateCompanionBuilder,
      $$ProfilesTableTableUpdateCompanionBuilder,
      (
        ProfilesTableData,
        BaseReferences<_$AppDatabase, $ProfilesTableTable, ProfilesTableData>,
      ),
      ProfilesTableData,
      PrefetchHooks Function()
    >;
typedef $$RevisionSubjectsTableTableCreateCompanionBuilder =
    RevisionSubjectsTableCompanion Function({
      required String id,
      Value<String?> userId,
      required String name,
      Value<String> iconName,
      Value<int> colorValue,
      Value<String> notesJson,
      Value<String> attachmentsJson,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$RevisionSubjectsTableTableUpdateCompanionBuilder =
    RevisionSubjectsTableCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> name,
      Value<String> iconName,
      Value<int> colorValue,
      Value<String> notesJson,
      Value<String> attachmentsJson,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

class $$RevisionSubjectsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RevisionSubjectsTableTable> {
  $$RevisionSubjectsTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notesJson => $composableBuilder(
    column: $table.notesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RevisionSubjectsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RevisionSubjectsTableTable> {
  $$RevisionSubjectsTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notesJson => $composableBuilder(
    column: $table.notesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RevisionSubjectsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RevisionSubjectsTableTable> {
  $$RevisionSubjectsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notesJson =>
      $composableBuilder(column: $table.notesJson, builder: (column) => column);

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$RevisionSubjectsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RevisionSubjectsTableTable,
          RevisionSubjectsTableData,
          $$RevisionSubjectsTableTableFilterComposer,
          $$RevisionSubjectsTableTableOrderingComposer,
          $$RevisionSubjectsTableTableAnnotationComposer,
          $$RevisionSubjectsTableTableCreateCompanionBuilder,
          $$RevisionSubjectsTableTableUpdateCompanionBuilder,
          (
            RevisionSubjectsTableData,
            BaseReferences<
              _$AppDatabase,
              $RevisionSubjectsTableTable,
              RevisionSubjectsTableData
            >,
          ),
          RevisionSubjectsTableData,
          PrefetchHooks Function()
        > {
  $$RevisionSubjectsTableTableTableManager(
    _$AppDatabase db,
    $RevisionSubjectsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RevisionSubjectsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RevisionSubjectsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RevisionSubjectsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> notesJson = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionSubjectsTableCompanion(
                id: id,
                userId: userId,
                name: name,
                iconName: iconName,
                colorValue: colorValue,
                notesJson: notesJson,
                attachmentsJson: attachmentsJson,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String name,
                Value<String> iconName = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> notesJson = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => RevisionSubjectsTableCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                iconName: iconName,
                colorValue: colorValue,
                notesJson: notesJson,
                attachmentsJson: attachmentsJson,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RevisionSubjectsTableTable,
                    RevisionSubjectsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RevisionSubjectsTableTable,
                    RevisionSubjectsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RevisionSubjectsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RevisionSubjectsTableTable,
      RevisionSubjectsTableData,
      $$RevisionSubjectsTableTableFilterComposer,
      $$RevisionSubjectsTableTableOrderingComposer,
      $$RevisionSubjectsTableTableAnnotationComposer,
      $$RevisionSubjectsTableTableCreateCompanionBuilder,
      $$RevisionSubjectsTableTableUpdateCompanionBuilder,
      (
        RevisionSubjectsTableData,
        BaseReferences<
          _$AppDatabase,
          $RevisionSubjectsTableTable,
          RevisionSubjectsTableData
        >,
      ),
      RevisionSubjectsTableData,
      PrefetchHooks Function()
    >;
typedef $$RevisionTopicsTableTableCreateCompanionBuilder =
    RevisionTopicsTableCompanion Function({
      required String id,
      Value<String?> userId,
      required String subjectId,
      required String title,
      Value<String?> description,
      Value<String> notesJson,
      Value<String> attachmentsJson,
      Value<bool> isCompleted,
      Value<int> revisionStage,
      Value<int?> lastRevisedAtMs,
      Value<int?> nextRevisionDateMs,
      Value<String?> associatedTaskId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$RevisionTopicsTableTableUpdateCompanionBuilder =
    RevisionTopicsTableCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> subjectId,
      Value<String> title,
      Value<String?> description,
      Value<String> notesJson,
      Value<String> attachmentsJson,
      Value<bool> isCompleted,
      Value<int> revisionStage,
      Value<int?> lastRevisedAtMs,
      Value<int?> nextRevisionDateMs,
      Value<String?> associatedTaskId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$RevisionTopicsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RevisionTopicsTableTable> {
  $$RevisionTopicsTableTableFilterComposer({
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

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
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

  ColumnFilters<String> get notesJson => $composableBuilder(
    column: $table.notesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revisionStage => $composableBuilder(
    column: $table.revisionStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRevisedAtMs => $composableBuilder(
    column: $table.lastRevisedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextRevisionDateMs => $composableBuilder(
    column: $table.nextRevisionDateMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get associatedTaskId => $composableBuilder(
    column: $table.associatedTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RevisionTopicsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RevisionTopicsTableTable> {
  $$RevisionTopicsTableTableOrderingComposer({
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

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
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

  ColumnOrderings<String> get notesJson => $composableBuilder(
    column: $table.notesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisionStage => $composableBuilder(
    column: $table.revisionStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRevisedAtMs => $composableBuilder(
    column: $table.lastRevisedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextRevisionDateMs => $composableBuilder(
    column: $table.nextRevisionDateMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get associatedTaskId => $composableBuilder(
    column: $table.associatedTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RevisionTopicsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RevisionTopicsTableTable> {
  $$RevisionTopicsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notesJson =>
      $composableBuilder(column: $table.notesJson, builder: (column) => column);

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revisionStage => $composableBuilder(
    column: $table.revisionStage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRevisedAtMs => $composableBuilder(
    column: $table.lastRevisedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextRevisionDateMs => $composableBuilder(
    column: $table.nextRevisionDateMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get associatedTaskId => $composableBuilder(
    column: $table.associatedTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$RevisionTopicsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RevisionTopicsTableTable,
          RevisionTopicsTableData,
          $$RevisionTopicsTableTableFilterComposer,
          $$RevisionTopicsTableTableOrderingComposer,
          $$RevisionTopicsTableTableAnnotationComposer,
          $$RevisionTopicsTableTableCreateCompanionBuilder,
          $$RevisionTopicsTableTableUpdateCompanionBuilder,
          (
            RevisionTopicsTableData,
            BaseReferences<
              _$AppDatabase,
              $RevisionTopicsTableTable,
              RevisionTopicsTableData
            >,
          ),
          RevisionTopicsTableData,
          PrefetchHooks Function()
        > {
  $$RevisionTopicsTableTableTableManager(
    _$AppDatabase db,
    $RevisionTopicsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RevisionTopicsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RevisionTopicsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RevisionTopicsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> notesJson = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> revisionStage = const Value.absent(),
                Value<int?> lastRevisedAtMs = const Value.absent(),
                Value<int?> nextRevisionDateMs = const Value.absent(),
                Value<String?> associatedTaskId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionTopicsTableCompanion(
                id: id,
                userId: userId,
                subjectId: subjectId,
                title: title,
                description: description,
                notesJson: notesJson,
                attachmentsJson: attachmentsJson,
                isCompleted: isCompleted,
                revisionStage: revisionStage,
                lastRevisedAtMs: lastRevisedAtMs,
                nextRevisionDateMs: nextRevisionDateMs,
                associatedTaskId: associatedTaskId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                required String subjectId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> notesJson = const Value.absent(),
                Value<String> attachmentsJson = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> revisionStage = const Value.absent(),
                Value<int?> lastRevisedAtMs = const Value.absent(),
                Value<int?> nextRevisionDateMs = const Value.absent(),
                Value<String?> associatedTaskId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RevisionTopicsTableCompanion.insert(
                id: id,
                userId: userId,
                subjectId: subjectId,
                title: title,
                description: description,
                notesJson: notesJson,
                attachmentsJson: attachmentsJson,
                isCompleted: isCompleted,
                revisionStage: revisionStage,
                lastRevisedAtMs: lastRevisedAtMs,
                nextRevisionDateMs: nextRevisionDateMs,
                associatedTaskId: associatedTaskId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RevisionTopicsTableTable,
                    RevisionTopicsTableData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RevisionTopicsTableTable,
                    RevisionTopicsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RevisionTopicsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RevisionTopicsTableTable,
      RevisionTopicsTableData,
      $$RevisionTopicsTableTableFilterComposer,
      $$RevisionTopicsTableTableOrderingComposer,
      $$RevisionTopicsTableTableAnnotationComposer,
      $$RevisionTopicsTableTableCreateCompanionBuilder,
      $$RevisionTopicsTableTableUpdateCompanionBuilder,
      (
        RevisionTopicsTableData,
        BaseReferences<
          _$AppDatabase,
          $RevisionTopicsTableTable,
          RevisionTopicsTableData
        >,
      ),
      RevisionTopicsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableTableManager get tasksTable =>
      $$TasksTableTableTableManager(_db, _db.tasksTable);
  $$PomodoroSessionsTableTableTableManager get pomodoroSessionsTable =>
      $$PomodoroSessionsTableTableTableManager(_db, _db.pomodoroSessionsTable);
  $$ProfilesTableTableTableManager get profilesTable =>
      $$ProfilesTableTableTableManager(_db, _db.profilesTable);
  $$RevisionSubjectsTableTableTableManager get revisionSubjectsTable =>
      $$RevisionSubjectsTableTableTableManager(_db, _db.revisionSubjectsTable);
  $$RevisionTopicsTableTableTableManager get revisionTopicsTable =>
      $$RevisionTopicsTableTableTableManager(_db, _db.revisionTopicsTable);
}
