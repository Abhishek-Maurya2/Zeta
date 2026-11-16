import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:drift/drift.dart';

import '../models/task.dart';
import '../models/pomodoro.dart';
import '../models/attachment.dart';
import '../pages/space/models/mindmap.dart';
import '../pages/space/models/mindmap_node.dart';
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
    MindmapsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 14;

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
        'CREATE INDEX IF NOT EXISTS idx_pomodoro_user_completed ON pomodoro_sessions (user_id, completed_at_ms DESC);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_mindmaps_user_updated ON mindmaps (user_id, deleted_at_ms, updated_at_ms DESC);',
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

      if (from < 13) {
        await m.createTable(mindmapsTable);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_mindmaps_user_updated ON mindmaps (user_id, deleted_at_ms, updated_at_ms DESC);',
        );
      }

      // Unconditionally ensure sync_outbox table and all performance indexes exist
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
        'CREATE INDEX IF NOT EXISTS idx_pomodoro_user_completed ON pomodoro_sessions (user_id, completed_at_ms DESC);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_mindmaps_user_updated ON mindmaps (user_id, deleted_at_ms, updated_at_ms DESC);',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
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
      if (row.subtasksJson.isNotEmpty && row.subtasksJson != '[]') {
        try {
          final decoded = jsonDecode(row.subtasksJson);
          if (decoded is List) {
            final parsedSubtasks = <Subtask>[];
            for (var i = 0; i < decoded.length; i++) {
              final item = decoded[i];
              if (item is Map) {
                try {
                  final map = Map<String, dynamic>.from(item);
                  parsedSubtasks.add(Subtask.fromJson(map));
                } catch (e, stack) {
                  debugPrint(
                    '[AppDatabase] Failed to parse subtask $i for task ${row.id}: $e\n$stack',
                  );
                  try {
                    final map = Map<String, dynamic>.from(item);
                    parsedSubtasks.add(
                      Subtask(
                        id: map['id']?.toString() ?? '${row.id}_subtask_$i',
                        title: map['title']?.toString() ?? 'Subtask $i',
                        completed: map['completed'] == true,
                      ),
                    );
                  } catch (fallbackError) {
                    debugPrint(
                      '[AppDatabase] Subtask recovery fallback failed: $fallbackError',
                    );
                  }
                }
              }
            }
            subtasks = parsedSubtasks;
          }
        } catch (e, stack) {
          debugPrint(
            '[AppDatabase] Corrupted subtasksJson in task ${row.id}: $e\n$stack',
          );
        }
      }

      if (row.attachmentsJson.isNotEmpty && row.attachmentsJson != '[]') {
        try {
          final decoded = jsonDecode(row.attachmentsJson);
          if (decoded is List) {
            final parsedAttachments = <AttachmentItem>[];
            for (var i = 0; i < decoded.length; i++) {
              final item = decoded[i];
              if (item is Map) {
                try {
                  final map = Map<String, dynamic>.from(item);
                  parsedAttachments.add(AttachmentItem.fromJson(map));
                } catch (e, stack) {
                  debugPrint(
                    '[AppDatabase] Failed to parse attachment $i for task ${row.id}: $e\n$stack',
                  );
                }
              }
            }
            attachments = parsedAttachments;
          }
        } catch (e, stack) {
          debugPrint(
            '[AppDatabase] Corrupted attachmentsJson in task ${row.id}: $e\n$stack',
          );
        }
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

  // ─── Mindmap helpers ────────────────────────────────────────────────────────

  static MindMap rowToMindMap(MindmapsTableData row) {
    List<MindMapNode> nodes = const [];
    if (row.nodesJson.isNotEmpty && row.nodesJson != '[]') {
      try {
        final decoded = jsonDecode(row.nodesJson);
        if (decoded is List) {
          final parsedNodes = <MindMapNode>[];
          for (var i = 0; i < decoded.length; i++) {
            final item = decoded[i];
            if (item is Map) {
              try {
                final map = Map<String, dynamic>.from(item);
                parsedNodes.add(MindMapNode.fromJson(map));
              } catch (e, stack) {
                debugPrint(
                  '[AppDatabase] Failed to parse mindmap node $i for map ${row.id}: $e\n$stack',
                );
                try {
                  final map = Map<String, dynamic>.from(item);
                  parsedNodes.add(
                    MindMapNode(
                      id: map['id']?.toString() ?? '${row.id}_node_$i',
                      parentId: map['parentId']?.toString(),
                      orderIndex: (map['orderIndex'] as num?)?.toDouble() ??
                          (i.toDouble()),
                      content: map['content']?.toString() ?? '',
                    ),
                  );
                } catch (fallbackError) {
                  debugPrint(
                    '[AppDatabase] Mindmap node recovery fallback failed: $fallbackError',
                  );
                }
              }
            }
          }
          if (parsedNodes.isNotEmpty) {
            nodes = parsedNodes;
          }
        }
      } catch (e, stack) {
        debugPrint(
          '[AppDatabase] Corrupted nodesJson in mindmap ${row.id}: $e\n$stack',
        );
      }
    }

    if (nodes.isEmpty) {
      nodes = [
        MindMapNode(
          id: '${row.id}_root',
          parentId: null,
          orderIndex: 0.0,
          content: row.title,
        ),
      ];
    }

    return MindMap(
      id: row.id,
      title: row.title,
      createdAtMs: row.createdAtMs,
      updatedAtMs: row.updatedAtMs,
      layoutType: row.layoutType,
      nodes: nodes,
    );
  }

  static MindmapsTableCompanion mindMapToCompanion(
    MindMap map, {
    String? userId,
    DateTime? deletedAt,
    DateTime? lastSyncedAt,
  }) {
    return MindmapsTableCompanion(
      id: Value(map.id),
      userId: Value(userId ?? AccountScope.userId),
      title: Value(map.title),
      layoutType: Value(map.layoutType),
      nodesJson: Value(
        jsonEncode(map.nodes.map((n) => n.toJson()).toList()),
      ),
      createdAtMs: Value(map.createdAtMs),
      updatedAtMs: Value(map.updatedAtMs),
      deletedAtMs: deletedAt != null
          ? Value(deletedAt.millisecondsSinceEpoch)
          : const Value.absent(),
      lastSyncedAtMs: lastSyncedAt != null
          ? Value(lastSyncedAt.millisecondsSinceEpoch)
          : const Value.absent(),
    );
  }
}

/// Opens the SQLite connection using drift_flutter's default path resolution,
/// or an in-memory database when running in Flutter test environments.
QueryExecutor _openConnection() => openConnection();
