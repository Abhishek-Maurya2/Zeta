import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:drift/drift.dart';

import '../models/task.dart';
import '../models/pomodoro.dart';
import '../models/revision.dart';
import '../models/attachment.dart';
import '../models/note_item.dart';
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
  int get schemaVersion => 12;

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
        'CREATE INDEX IF NOT EXISTS idx_tasks_user_active ON tasks (user_id, deleted_at_ms, created_at_ms DESC);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tasks_sync_check ON tasks (last_synced_at_ms, updated_at_ms);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_revision_topics_subject ON revision_topics (subject_id, sort_order);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_revision_topics_user_subject ON revision_topics (user_id, subject_id, sort_order);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pomodoro_user_completed ON pomodoro_sessions (user_id, completed_at_ms DESC);',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 10) {
        await m.addColumn(tasksTable, tasksTable.completedAtMs);
      }
      if (from < 12) {
        // Restore the one-time legacy completion-date backfill. Runtime task
        // edits and subtask updates never copy updated_at into completed_at.
        await customStatement(
          'UPDATE tasks SET completed_at_ms = updated_at_ms '
          'WHERE completed = 1 AND completed_at_ms IS NULL;',
        );
      }
    },
    beforeOpen: (details) async {
      if (!kIsWeb) {
        try {
          await customStatement('PRAGMA journal_mode = WAL;');
          await customStatement('PRAGMA synchronous = NORMAL;');
          await customStatement('PRAGMA cache_size = -2000;');
          await customStatement('PRAGMA temp_store = MEMORY;');
        } catch (_) {}
      }
    },
  );

  // ─── Task helpers ───────────────────────────────────────────────────────────

  /// Converts a drift [TasksTableData] row into a domain [Task].
  static Task rowToTask(TasksTableData row, {bool decodeDetails = true}) {
    List<Subtask> subtasks = const [];
    List<AttachmentItem> attachments = const [];
    if (decodeDetails) {
      subtasks = (row.subtasksJson.isEmpty || row.subtasksJson == '[]')
          ? <Subtask>[]
          : (jsonDecode(row.subtasksJson) as List<dynamic>)
                .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
                .toList();

      if (row.attachmentsJson.isNotEmpty && row.attachmentsJson != '[]') {
        try {
          attachments = (jsonDecode(row.attachmentsJson) as List<dynamic>)
              .map((a) => AttachmentItem.fromJson(a as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }

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
      attachments: attachments,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs),
      completedAt: row.completedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.completedAtMs!)
          : null,
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
      attachmentsJson: Value(
        jsonEncode(t.attachments.map((a) => a.toJson()).toList()),
      ),
      createdAtMs: Value(t.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(t.updatedAt.millisecondsSinceEpoch),
      completedAtMs: Value(t.completedAt?.millisecondsSinceEpoch),
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
    NoteItem? note;
    if (row.notesJson.isNotEmpty && row.notesJson != '{}') {
      try {
        final decoded = jsonDecode(row.notesJson);
        if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
          note = NoteItem.fromJson(decoded);
        }
      } catch (_) {}
    }

    List<AttachmentItem> attachments = const [];
    if (row.attachmentsJson.isNotEmpty && row.attachmentsJson != '[]') {
      try {
        attachments = (jsonDecode(row.attachmentsJson) as List<dynamic>)
            .map((a) => AttachmentItem.fromJson(a as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return Subject(
      id: row.id,
      name: row.name,
      iconName: row.iconName,
      colorValue: row.colorValue,
      note: note,
      attachments: attachments,
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
      notesJson: Value(s.note != null ? jsonEncode(s.note!.toJson()) : '{}'),
      attachmentsJson: Value(
        jsonEncode(s.attachments.map((a) => a.toJson()).toList()),
      ),
      createdAtMs: Value(s.createdAt.millisecondsSinceEpoch),
    );
  }

  static ChapterTopic rowToTopic(RevisionTopicsTableData row) {
    NoteItem? note;
    if (row.notesJson.isNotEmpty && row.notesJson != '{}') {
      try {
        final decoded = jsonDecode(row.notesJson);
        if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
          note = NoteItem.fromJson(decoded);
        }
      } catch (_) {}
    }

    List<AttachmentItem> attachments = const [];
    if (row.attachmentsJson.isNotEmpty && row.attachmentsJson != '[]') {
      try {
        attachments = (jsonDecode(row.attachmentsJson) as List<dynamic>)
            .map((a) => AttachmentItem.fromJson(a as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

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
      note: note,
      attachments: attachments,
    );
  }

  static RevisionTopicsTableCompanion topicToCompanion(ChapterTopic t) {
    return RevisionTopicsTableCompanion(
      id: Value(t.id),
      userId: Value(AccountScope.userId),
      subjectId: Value(t.subjectId),
      title: Value(t.title),
      description: Value(t.description),
      notesJson: Value(t.note != null ? jsonEncode(t.note!.toJson()) : '{}'),
      attachmentsJson: Value(
        jsonEncode(t.attachments.map((a) => a.toJson()).toList()),
      ),
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
