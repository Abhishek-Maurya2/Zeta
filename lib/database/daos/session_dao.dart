import 'package:drift/drift.dart';
import '../../models/pomodoro.dart';
import '../app_database.dart';

/// Data Access Object for the [PomodoroSessionsTable].
class SessionDao {
  final AppDatabase _db;

  SessionDao(this._db);

  // ─── Reads ─────────────────────────────────────────────────────────────────

  /// Returns recent sessions up to [limit], ordered by completedAt descending.
  /// Pass [since] to fetch only sessions after a given timestamp (incremental load).
  Future<List<PomodoroSessionLog>> getSessions({
    int limit = 200,
    DateTime? since,
  }) async {
    final query = _db.select(_db.pomodoroSessionsTable)
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
    final rows = await (_db.select(_db.pomodoroSessionsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.completedAtMs)]))
        .get();
    return rows.map(AppDatabase.rowToSession).toList();
  }

  /// Returns all sessions completed offline that haven't been synced to Supabase yet.
  Future<List<PomodoroSessionLog>> getUnsyncedSessions() async {
    final rows = await (_db.select(_db.pomodoroSessionsTable)
          ..where((t) => t.lastSyncedAtMs.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.completedAtMs)]))
        .get();
    return rows.map(AppDatabase.rowToSession).toList();
  }

  /// Marks a session as synced at [syncedAt].
  Future<void> markSessionSynced(String sessionId, DateTime syncedAt) async {
    await (_db.update(_db.pomodoroSessionsTable)
          ..where((t) => t.id.equals(sessionId)))
        .write(PomodoroSessionsTableCompanion(
      lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
    ));
  }

  /// Marks multiple sessions as synced at [syncedAt].
  Future<void> markSessionsSynced(
    Iterable<String> sessionIds,
    DateTime syncedAt,
  ) async {
    if (sessionIds.isEmpty) return;
    await (_db.update(_db.pomodoroSessionsTable)
          ..where((t) => t.id.isIn(sessionIds)))
        .write(PomodoroSessionsTableCompanion(
      lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
    ));
  }

  // ─── Writes ────────────────────────────────────────────────────────────────

  /// Upserts a single session.
  Future<void> upsertSession(PomodoroSessionLog session) async {
    await _db.into(_db.pomodoroSessionsTable).insertOnConflictUpdate(
      AppDatabase.sessionToCompanion(session),
    );
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

  /// Hard-deletes a session by ID.
  Future<void> deleteSession(String sessionId) async {
    await (_db.delete(_db.pomodoroSessionsTable)
          ..where((t) => t.id.equals(sessionId)))
        .go();
  }

  /// Clears all session rows (used when user clears session log).
  Future<void> clearAll() async {
    await _db.delete(_db.pomodoroSessionsTable).go();
  }
}
