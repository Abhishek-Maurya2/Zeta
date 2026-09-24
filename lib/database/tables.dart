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
  TextColumn get userId => text().nullable()();
  TextColumn get mode => text()();
  IntColumn get minutes => integer()();
  IntColumn get completedAtMs => integer()();
  IntColumn get lastSyncedAtMs => integer().nullable()();

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
  IntColumn get lastSyncedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for Revision Subjects.
class RevisionSubjectsTable extends Table {
  @override
  String get tableName => 'revision_subjects';

  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get iconName =>
      text().withDefault(const Constant('menu_book_rounded'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF6750A4))();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite table for Revision Topics.
class RevisionTopicsTable extends Table {
  @override
  String get tableName => 'revision_topics';

  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get subjectId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get revisionStage => integer().withDefault(const Constant(0))();
  IntColumn get lastRevisedAtMs => integer().nullable()();
  IntColumn get nextRevisionDateMs => integer().nullable()();
  TextColumn get associatedTaskId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
