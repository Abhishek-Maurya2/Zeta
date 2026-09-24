import 'package:drift/drift.dart';

import '../../models/pomodoro.dart';
import '../app_database.dart';
import '../account_scope.dart';
import 'sync_outbox_dao.dart';

/// Data Access Object for the [PomodoroSessionsTable].
class SessionDao {
  final AppDatabase _db;

  SessionDao(this._db);

  Expression<bool> _owner(GeneratedColumn<String> userId) =>
      AccountScope.userId == null
      ? userId.isNull()
      : userId.equals(AccountScope.userId!);

  // ─── Reads ─────────────────────────────────────────────────────────────────

  /// Returns recent sessions up to [limit], ordered by completedAt descending.
  /// Pass [since] to fetch only sessions after a given timestamp (incremental load).
  Future<List<PomodoroSessionLog>> getSessions({
    int limit = 200,
    DateTime? since,
  }) async {
    final query = _db.select(_db.pomodoroSessionsTable)
      ..where((t) => _owner(t.userId))
      ..orderBy([(t) => OrderingTerm.desc(t.completedAtMs)])
      ..limit(limit);

    if (since != null) {
      query.where(
        (t) => t.completedAtMs.isBiggerThanValue(since.millisecondsSinceEpoch),
      );
    }

    final rows = await query.get();
    return rows.map(AppDatabase.rowToSession).toList();
  }

  /// Returns all sessions ever stored (for full sync reconciliation).
  Future<List<PomodoroSessionLog>> getAllSessions() async {
    final rows =
        await (_db.select(_db.pomodoroSessionsTable)
              ..where((t) => _owner(t.userId))
              ..orderBy([(t) => OrderingTerm.asc(t.completedAtMs)]))
            .get();
    return rows.map(AppDatabase.rowToSession).toList();
  }

  Future<PomodoroSessionLog?> getSession(String sessionId) async {
    final row =
        await (_db.select(_db.pomodoroSessionsTable)..where(
              (session) =>
                  session.id.equals(sessionId) & _owner(session.userId),
            ))
            .getSingleOrNull();
    return row == null ? null : AppDatabase.rowToSession(row);
  }

  /// Returns all sessions completed offline that haven't been synced to Supabase yet.
  Future<List<PomodoroSessionLog>> getUnsyncedSessions() async {
    final rows =
        await (_db.select(_db.pomodoroSessionsTable)
              ..where((t) => t.lastSyncedAtMs.isNull() & _owner(t.userId))
              ..orderBy([(t) => OrderingTerm.asc(t.completedAtMs)]))
            .get();
    return rows.map(AppDatabase.rowToSession).toList();
  }

  /// Marks a session as synced at [syncedAt].
  Future<void> markSessionSynced(String sessionId, DateTime syncedAt) async {
    await (_db.update(
      _db.pomodoroSessionsTable,
    )..where((t) => t.id.equals(sessionId) & _owner(t.userId))).write(
      PomodoroSessionsTableCompanion(
        lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
      ),
    );
  }

  /// Marks multiple sessions as synced at [syncedAt].
  Future<void> markSessionsSynced(
    Iterable<String> sessionIds,
    DateTime syncedAt,
  ) async {
    if (sessionIds.isEmpty) return;
    await (_db.update(
      _db.pomodoroSessionsTable,
    )..where((t) => t.id.isIn(sessionIds) & _owner(t.userId))).write(
      PomodoroSessionsTableCompanion(
        lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
      ),
    );
  }

  // ─── Writes ────────────────────────────────────────────────────────────────

  /// Upserts a single session.
  Future<void> upsertSession(PomodoroSessionLog session) async {
    await _db
        .into(_db.pomodoroSessionsTable)
        .insertOnConflictUpdate(AppDatabase.sessionToCompanion(session));
  }

  Future<void> upsertSessionAndQueue(PomodoroSessionLog session) async {
    await _db.transaction(() async {
      await upsertSession(session);
      await _queueSession(session.id, 'upsert');
    });
  }

  /// Batch-upserts multiple sessions (initial migration or cloud pull).
  Future<void> upsertAll(List<PomodoroSessionLog> sessions) async {
    await _db.batch((batch) {
      for (final s in sessions) {
        batch.insert(
          _db.pomodoroSessionsTable,
          AppDatabase.sessionToCompanion(s),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> upsertAllAndQueue(List<PomodoroSessionLog> sessions) async {
    await _db.transaction(() async {
      await upsertAll(sessions);
      for (final session in sessions) {
        await _queueSession(session.id, 'upsert');
      }
    });
  }

  /// Hard-deletes a session by ID.
  Future<void> deleteSession(String sessionId) async {
    await (_db.delete(
      _db.pomodoroSessionsTable,
    )..where((t) => t.id.equals(sessionId) & _owner(t.userId))).go();
  }

  Future<void> deleteSessionAndQueue(String sessionId) async {
    await _db.transaction(() async {
      await _queueSession(sessionId, 'delete');
      await deleteSession(sessionId);
    });
  }

  /// Clears all session rows (used when user clears session log).
  Future<void> clearAll() async {
    await (_db.delete(
      _db.pomodoroSessionsTable,
    )..where((t) => _owner(t.userId))).go();
  }

  Future<void> clearAllAndQueue() async {
    await _db.transaction(() async {
      final userId = AccountScope.userId;
      if (userId != null) {
        final outbox = SyncOutboxDao(_db);
        await outbox.removeAll(
          userId: userId,
          feature: 'pomodoro',
          entityType: 'session',
        );
        await outbox.enqueue(
          userId: userId,
          feature: 'pomodoro',
          entityType: 'session',
          entityId: '_all',
          operation: 'clear',
        );
      }
      await clearAll();
    });
  }

  Future<void> _queueSession(String sessionId, String operation) async {
    final userId = AccountScope.userId;
    if (userId == null) return;
    await SyncOutboxDao(_db).enqueue(
      userId: userId,
      feature: 'pomodoro',
      entityType: 'session',
      entityId: sessionId,
      operation: operation,
    );
  }
}
