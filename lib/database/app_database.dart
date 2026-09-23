import 'dart:convert';
import 'package:flutter/widgets.dart' hide Table;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/task.dart';
import '../models/pomodoro.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The application's local SQLite database backed by drift.
///
/// Replaces the SharedPreferences JSON-blob approach with a proper relational
/// store, enabling incremental reads, partial writes, and indexed queries
/// instead of re-serializing the entire task list on every mutation.
@DriftDatabase(tables: [TasksTable, PomodoroSessionsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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
      googleEventId: row.googleEventId,
      googleTaskId: row.googleTaskId,
      googleEtag: row.googleEtag,
      lastSyncedAt: row.lastSyncedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAtMs!)
          : null,
    );
  }

  /// Converts a domain [Task] into a drift [TasksTableCompanion].
  static TasksTableCompanion taskToCompanion(Task t) {
    return TasksTableCompanion(
      id: Value(t.id),
      userId: Value(t.userId),
      title: Value(t.title),
      description: Value(t.description),
      completed: Value(t.completed),
      dueDate: Value(t.dueDate),
      hasTime: Value(t.hasTime),
      dueTime: Value(t.dueTime),
      subtasksJson: Value(jsonEncode(t.subtasks.map((s) => s.toJson()).toList())),
      createdAtMs: Value(t.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(t.updatedAt.millisecondsSinceEpoch),
      deletedAtMs: Value(t.deletedAt?.millisecondsSinceEpoch),
      googleEventId: Value(t.googleEventId),
      googleTaskId: Value(t.googleTaskId),
      googleEtag: Value(t.googleEtag),
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
    );
  }

  static PomodoroSessionsTableCompanion sessionToCompanion(PomodoroSessionLog s) {
    return PomodoroSessionsTableCompanion(
      id: Value(s.id),
      mode: Value(s.mode.toJsonString()),
      minutes: Value(s.minutes),
      completedAtMs: Value(s.completedAt),
    );
  }
}

/// Opens the SQLite connection using drift_flutter's default path resolution,
/// or an in-memory database when running in Flutter test environments.
QueryExecutor _openConnection() {
  final isTest =
      WidgetsBinding.instance.runtimeType.toString().contains('Test');
  if (isTest) {
    return NativeDatabase.memory();
  }
  return driftDatabase(
    name: 'zeta_app_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
