import 'package:drift/drift.dart';
import '../../models/task.dart';
import '../app_database.dart';
import '../tables.dart';

/// Data Access Object for the [TasksTable].
///
/// All reads/writes go through here so the provider layer stays storage-agnostic.
class TaskDao {
  final AppDatabase _db;

  TaskDao(this._db);

  // ─── Reads ─────────────────────────────────────────────────────────────────

  /// Returns all active tasks (not deleted), ordered by creation date descending.
  Future<List<Task>> getActiveTasks() async {
    final rows = await (_db.select(_db.tasksTable)
          ..where((t) => t.deletedAtMs.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]))
        .get();
    return rows.map(AppDatabase.rowToTask).toList();
  }

  /// Returns all bin tasks (deleted_at is set), ordered by deletion date descending.
  Future<List<Task>> getBinTasks() async {
    final rows = await (_db.select(_db.tasksTable)
          ..where((t) => t.deletedAtMs.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAtMs)]))
        .get();
    return rows.map(AppDatabase.rowToTask).toList();
  }

  /// Returns all tasks modified offline that have not yet been synced to Supabase
  /// (i.e. lastSyncedAtMs is null or updatedAtMs > lastSyncedAtMs).
  Future<List<Task>> getUnsyncedTasks() async {
    final rows = await (_db.select(_db.tasksTable)
          ..where((t) =>
              t.lastSyncedAtMs.isNull() |
              t.updatedAtMs.isBiggerThan(t.lastSyncedAtMs)))
        .get();
    return rows.map(AppDatabase.rowToTask).toList();
  }

  /// Marks a task row as synced at [syncedAt].
  Future<bool> markTaskSynced(
    String taskId,
    DateTime syncedAt, {
    required DateTime expectedUpdatedAt,
  }) async {
    final changed = await (_db.update(_db.tasksTable)
          ..where((t) =>
              t.id.equals(taskId) &
              t.updatedAtMs.equals(expectedUpdatedAt.millisecondsSinceEpoch)))
        .write(TasksTableCompanion(
      lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
    ));
    return changed > 0;
  }

  // ─── Writes ────────────────────────────────────────────────────────────────

  /// Upserts a single task. Used for every create/update/delete mutation.
  Future<void> upsertTask(Task task) async {
    await _db.into(_db.tasksTable).insertOnConflictUpdate(
      AppDatabase.taskToCompanion(task),
    );
  }

  /// Batch-upserts multiple tasks (e.g. during cloud sync or migration).
  Future<void> upsertAll(List<Task> tasks) async {
    await _db.batch((batch) {
      for (final t in tasks) {
        batch.insert(
          _db.tasksTable,
          AppDatabase.taskToCompanion(t),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Hard-deletes a task row by ID (used for permanent bin deletion).
  Future<void> hardDelete(String taskId) async {
    await (_db.delete(_db.tasksTable)
          ..where((t) => t.id.equals(taskId)))
        .go();
  }

  /// Hard-deletes multiple task rows by ID.
  Future<int> hardDeleteMany(Iterable<String> taskIds) async {
    if (taskIds.isEmpty) return 0;
    return (_db.delete(_db.tasksTable)
          ..where((t) => t.id.isIn(taskIds)))
        .go();
  }

  /// Hard-deletes all tasks currently in the bin (deleted_at_ms IS NOT NULL).
  Future<int> clearBin() async {
    return (_db.delete(_db.tasksTable)
          ..where((t) => t.deletedAtMs.isNotNull()))
        .go();
  }

  /// Evicts bin tasks older than [retentionDays] days (local 90-day purge).
  Future<int> evictOldBinTasks({int retentionDays = 90}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    return (_db.delete(_db.tasksTable)
          ..where(
            (t) =>
                t.deletedAtMs.isNotNull() &
                t.deletedAtMs.isSmallerThanValue(cutoff),
          ))
        .go();
  }

  /// Archives (moves to bin) completed tasks older than [retentionDays] days.
  /// Returns the number of rows updated.
  Future<int> archiveOldCompletedTasks({
    int retentionDays = 90,
    DateTime? archivedAt,
  }) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    final now = (archivedAt ?? DateTime.now()).millisecondsSinceEpoch;
    return (_db.update(_db.tasksTable)
          ..where(
            (t) =>
                t.completed.equals(true) &
                t.deletedAtMs.isNull() &
                t.updatedAtMs.isSmallerThanValue(cutoff),
          ))
        .write(TasksTableCompanion(
          deletedAtMs: Value(now),
          updatedAtMs: Value(now),
        ));
  }

  /// Clears all rows (for testing or account sign-out).
  Future<void> clearAll() async {
    await _db.delete(_db.tasksTable).go();
  }
}
