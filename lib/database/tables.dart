import 'package:drift/drift.dart';

/// SQLite table for active tasks and bin tasks (deleted_at IS NOT NULL = bin).
class TasksTable extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get dueDate => text().nullable()();
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
  TextColumn get dueTime => text().nullable()();
  TextColumn get subtasksJson => text().withDefault(const Constant('[]'))();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get deletedAtMs => integer().nullable()();
  IntColumn get lastSyncedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for Pomodoro session log entries.
class PomodoroSessionsTable extends Table {
  @override
  String get tableName => 'pomodoro_sessions';

  TextColumn get id => text()();
  TextColumn get mode => text()();
  IntColumn get minutes => integer()();
  IntColumn get completedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for user profile persistence.
class ProfilesTable extends Table {
  @override
  String get tableName => 'profiles';

  TextColumn get id => text()(); // 'singleton'
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get avatarImage => text().nullable()();
  IntColumn get updatedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
