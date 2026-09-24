import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/task.dart';
import '../models/pomodoro.dart';
import '../models/revision.dart';
import 'connection/connection.dart';
import 'tables.dart';
import 'account_scope.dart';

part 'app_database.g.dart';

/// The application's local SQLite database backed by drift.
///
/// Replaces the SharedPreferences JSON-blob approach with a proper relational
/// store, enabling incremental reads, partial writes, and indexed queries
/// instead of re-serializing the entire task list on every mutation.
@DriftDatabase(
  tables: [
    TasksTable,
    PomodoroSessionsTable,
    ProfilesTable,
    RevisionSubjectsTable,
    RevisionTopicsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE TABLE IF NOT EXISTS sync_outbox (id TEXT PRIMARY KEY NOT NULL, user_id TEXT NOT NULL, feature TEXT NOT NULL, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL, created_at_ms INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT NULL);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_outbox_account_order ON sync_outbox (user_id, created_at_ms);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_deleted_created ON tasks (deleted_at_ms, created_at_ms DESC);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_sync_check ON tasks (last_synced_at_ms, updated_at_ms);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_revision_topics_subject ON revision_topics (subject_id, sort_order);',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _safeCreateTable(m, profilesTable);
      }
      if (from < 3) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tasks_deleted_created ON tasks (deleted_at_ms, created_at_ms DESC);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tasks_sync_check ON tasks (last_synced_at_ms, updated_at_ms);',
        );
      }
      if (from < 4) {
        await _safeCreateTable(m, revisionSubjectsTable);
        await _safeCreateTable(m, revisionTopicsTable);
        await _safeAddColumn(
          m,
          pomodoroSessionsTable,
          pomodoroSessionsTable.lastSyncedAtMs,
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_revision_topics_subject ON revision_topics (subject_id, sort_order);',
        );
      }
      if (from < 5) {
        await _safeAddColumn(
          m,
          pomodoroSessionsTable,
          pomodoroSessionsTable.userId,
        );
        if (from >= 4) {
          await _safeAddColumn(
            m,
            revisionSubjectsTable,
            revisionSubjectsTable.userId,
          );
          await _safeAddColumn(
            m,
            revisionTopicsTable,
            revisionTopicsTable.userId,
          );
        }
      }
      if (from >= 2 && from < 6) {
        await _safeAddColumn(m, profilesTable, profilesTable.lastSyncedAtMs);
      }
      if (from < 7) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS sync_outbox (id TEXT PRIMARY KEY NOT NULL, user_id TEXT NOT NULL, feature TEXT NOT NULL, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL, created_at_ms INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT NULL);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_outbox_account_order ON sync_outbox (user_id, created_at_ms);',
        );
      }
    },
  );

  Future<bool> _columnExists(String tableName, String columnName) async {
    try {
      final rows = await customSelect('PRAGMA table_info("$tableName")').get();
      return rows.any((r) => r.data['name'] == columnName);
    } catch (_) {
      return false;
    }
  }

  Future<void> _safeAddColumn(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    try {
      if (!await _columnExists(table.actualTableName, column.$name)) {
        await m.addColumn(table, column);
      }
    } catch (e) {
      if (!e.toString().contains('duplicate column name')) {
        rethrow;
      }
    }
  }

  Future<void> _safeCreateTable(Migrator m, TableInfo table) async {
    try {
      await m.createTable(table);
    } catch (e) {
      if (!e.toString().contains('already exists')) {
        rethrow;
      }
    }
  }

  // ─── Task helpers ───────────────────────────────────────────────────────────

  /// Converts a drift [TasksTableData] row into a domain [Task].
  static Task rowToTask(TasksTableData row) {
    final subtasks = (jsonDecode(row.subtasksJson) as List<dynamic>)
        .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
        .toList();
    return Task(
      id: row.id,
      userId: row.userId,
      title: row.title,
      description: row.description,
      completed: row.completed,
      dueDate: row.dueDate,
      hasTime: row.hasTime,
      dueTime: row.dueTime,
      subtasks: subtasks,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs),
      deletedAt: row.deletedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAtMs!)
          : null,
      lastSyncedAt: row.lastSyncedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAtMs!)
          : null,
    );
  }

  /// Converts a domain [Task] into a drift [TasksTableCompanion].
  static TasksTableCompanion taskToCompanion(Task t) {
    return TasksTableCompanion(
      id: Value(t.id),
      userId: Value(AccountScope.userId ?? t.userId),
      title: Value(t.title),
      description: Value(t.description),
      completed: Value(t.completed),
      dueDate: Value(t.dueDate),
      hasTime: Value(t.hasTime),
      dueTime: Value(t.dueTime),
      subtasksJson: Value(
        jsonEncode(t.subtasks.map((s) => s.toJson()).toList()),
      ),
      createdAtMs: Value(t.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(t.updatedAt.millisecondsSinceEpoch),
      deletedAtMs: Value(t.deletedAt?.millisecondsSinceEpoch),
      lastSyncedAtMs: Value(t.lastSyncedAt?.millisecondsSinceEpoch),
    );
  }

  // ─── Session helpers ────────────────────────────────────────────────────────

  static PomodoroSessionLog rowToSession(PomodoroSessionsTableData row) {
    return PomodoroSessionLog(
      id: row.id,
      mode: PomodoroMode.fromString(row.mode),
      minutes: row.minutes,
      completedAt: row.completedAtMs,
      lastSyncedAt: row.lastSyncedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAtMs!)
          : null,
    );
  }

  static PomodoroSessionsTableCompanion sessionToCompanion(
    PomodoroSessionLog s,
  ) {
    return PomodoroSessionsTableCompanion(
      id: Value(s.id),
      userId: Value(AccountScope.userId),
      mode: Value(s.mode.toJsonString()),
      minutes: Value(s.minutes),
      completedAtMs: Value(s.completedAt),
      lastSyncedAtMs: s.lastSyncedAt != null
          ? Value(s.lastSyncedAt!.millisecondsSinceEpoch)
          : const Value.absent(),
    );
  }

  // ─── Revision helpers ───────────────────────────────────────────────────────

  static Subject rowToSubject(RevisionSubjectsTableData row) {
    return Subject(
      id: row.id,
      name: row.name,
      iconName: row.iconName,
      colorValue: row.colorValue,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
    );
  }

  static RevisionSubjectsTableCompanion subjectToCompanion(Subject s) {
    return RevisionSubjectsTableCompanion(
      id: Value(s.id),
      userId: Value(AccountScope.userId),
      name: Value(s.name),
      iconName: Value(s.iconName),
      colorValue: Value(s.colorValue),
      createdAtMs: Value(s.createdAt.millisecondsSinceEpoch),
    );
  }

  static ChapterTopic rowToTopic(RevisionTopicsTableData row) {
    return ChapterTopic(
      id: row.id,
      subjectId: row.subjectId,
      title: row.title,
      description: row.description,
      isCompleted: row.isCompleted,
      revisionStage: row.revisionStage,
      lastRevisedAt: row.lastRevisedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastRevisedAtMs!)
          : null,
      nextRevisionDate: row.nextRevisionDateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.nextRevisionDateMs!)
          : null,
      associatedTaskId: row.associatedTaskId,
      sortOrder: row.sortOrder,
    );
  }

  static RevisionTopicsTableCompanion topicToCompanion(ChapterTopic t) {
    return RevisionTopicsTableCompanion(
      id: Value(t.id),
      userId: Value(AccountScope.userId),
      subjectId: Value(t.subjectId),
      title: Value(t.title),
      description: Value(t.description),
      isCompleted: Value(t.isCompleted),
      revisionStage: Value(t.revisionStage),
      lastRevisedAtMs: Value(t.lastRevisedAt?.millisecondsSinceEpoch),
      nextRevisionDateMs: Value(t.nextRevisionDate?.millisecondsSinceEpoch),
      associatedTaskId: Value(t.associatedTaskId),
      sortOrder: Value(t.sortOrder),
    );
  }
}

/// Opens the SQLite connection using drift_flutter's default path resolution,
/// or an in-memory database when running in Flutter test environments.
QueryExecutor _openConnection() => openConnection();
