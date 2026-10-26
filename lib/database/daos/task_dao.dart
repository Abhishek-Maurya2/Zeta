import 'package:drift/drift.dart';

import '../../models/task.dart';
import '../app_database.dart';
import '../tables.dart';
import '../account_scope.dart';
import 'sync_outbox_dao.dart';

/// Data Access Object for the [TasksTable].
///
/// All reads/writes go through here so the provider layer stays storage-agnostic.
class TaskDao {
  final AppDatabase _db;

  TaskDao(this._db);

  Expression<bool> _owner(GeneratedColumn<String> userId) =>
      AccountScope.userId == null
      ? userId.isNull()
      : userId.equals(AccountScope.userId!);

  // ─── Reads ─────────────────────────────────────────────────────────────────

  /// Returns all active tasks (not deleted), ordered by creation date descending.
  Future<List<Task>> getActiveTasks() async {
    final rows =
        await (_db.select(_db.tasksTable)
              ..where((t) => t.deletedAtMs.isNull() & _owner(t.userId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]))
            .get();
    return rows.map(AppDatabase.rowToTask).toList();
  }

  /// Returns all bin tasks (deleted_at is set), ordered by deletion date descending.
  Future<List<Task>> getBinTasks() async {
    final rows =
        await (_db.select(_db.tasksTable)
              ..where((t) => t.deletedAtMs.isNotNull() & _owner(t.userId))
              ..orderBy([(t) => OrderingTerm.desc(t.deletedAtMs)]))
            .get();
    return rows.map(AppDatabase.rowToTask).toList();
  }

  Future<List<Task>> getActiveTasksPage({
    int limit = 50,
    int offset = 0,
    String? search,
    bool? completed,
  }) => _getTaskPage(
    deleted: false,
    limit: limit,
    offset: offset,
    search: search,
    completed: completed,
  );

  Future<List<Task>> getBinTasksPage({int limit = 50, int offset = 0}) =>
      _getTaskPage(deleted: true, limit: limit, offset: offset);

  Future<int> countActiveTasks({bool? completed, String? search}) async {
    final query = _db.selectOnly(_db.tasksTable)
      ..addColumns([_db.tasksTable.id.count()])
      ..where(
        _db.tasksTable.deletedAtMs.isNull() & _owner(_db.tasksTable.userId),
      );
    _applyTaskFilters(query, search: search, completed: completed);
    final row = await query.getSingle();
    return row.read(_db.tasksTable.id.count()) ?? 0;
  }

  Future<int> countBinTasks() async {
    final query = _db.selectOnly(_db.tasksTable)
      ..addColumns([_db.tasksTable.id.count()])
      ..where(
        _db.tasksTable.deletedAtMs.isNotNull() & _owner(_db.tasksTable.userId),
      );
    final row = await query.getSingle();
    return row.read(_db.tasksTable.id.count()) ?? 0;
  }

  Future<List<Task>> _getTaskPage({
    required bool deleted,
    required int limit,
    required int offset,
    String? search,
    bool? completed,
  }) async {
    final query = _db.select(_db.tasksTable)
      ..where(
        (t) =>
            (deleted ? t.deletedAtMs.isNotNull() : t.deletedAtMs.isNull()) &
            _owner(t.userId),
      )
      ..orderBy([
        (t) => deleted
            ? OrderingTerm.desc(t.deletedAtMs)
            : OrderingTerm.desc(t.createdAtMs),
      ])
      ..limit(limit.clamp(1, 200), offset: offset < 0 ? 0 : offset);
    _applyTaskFilters(query, search: search, completed: completed);
    final rows = await query.get();
    return rows
        .map((row) => AppDatabase.rowToTask(row, decodeDetails: false))
        .toList();
  }

  void _applyTaskFilters(dynamic query, {String? search, bool? completed}) {
    if (completed != null) {
      query.where(_db.tasksTable.completed.equals(completed));
    }
    final normalizedSearch = search?.trim();
    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      final pattern = '%${normalizedSearch.replaceAll('%', r'\%')}%';
      query.where(
        _db.tasksTable.title.like(pattern) |
            _db.tasksTable.description.like(pattern) |
            _db.tasksTable.dueDate.like(pattern),
      );
    }
  }

  Future<Task?> getTask(String taskId) async {
    final row =
        await (_db.select(_db.tasksTable)
              ..where((task) => task.id.equals(taskId) & _owner(task.userId)))
            .getSingleOrNull();
    return row == null ? null : AppDatabase.rowToTask(row);
  }

  Future<Task?> getTaskById(String taskId) => getTask(taskId);

  /// Reactive stream of active tasks (emits whenever SQLite tasks table changes).
  Stream<List<Task>> watchActiveTasks() {
    return (_db.select(_db.tasksTable)
          ..where((t) => t.deletedAtMs.isNull() & _owner(t.userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]))
        .watch()
        .map((rows) => rows.map(AppDatabase.rowToTask).toList());
  }

  /// Reactive stream of bin tasks.
  Stream<List<Task>> watchBinTasks() {
    return (_db.select(_db.tasksTable)
          ..where((t) => t.deletedAtMs.isNotNull() & _owner(t.userId))
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAtMs)]))
        .watch()
        .map((rows) => rows.map(AppDatabase.rowToTask).toList());
  }

  /// Returns all tasks modified offline that have not yet been synced to Supabase
  /// (i.e. lastSyncedAtMs is null or updatedAtMs > lastSyncedAtMs).
  Future<List<Task>> getUnsyncedTasks() async {
    final rows =
        await (_db.select(_db.tasksTable)..where(
              (t) =>
                  (t.lastSyncedAtMs.isNull() |
                      t.updatedAtMs.isBiggerThan(t.lastSyncedAtMs)) &
                  _owner(t.userId),
            ))
            .get();
    return rows.map(AppDatabase.rowToTask).toList();
  }

  /// Marks a task row as synced at [syncedAt].
  Future<bool> markTaskSynced(
    String taskId,
    DateTime syncedAt, {
    required DateTime expectedUpdatedAt,
  }) async {
    final changed =
        await (_db.update(_db.tasksTable)..where(
              (t) =>
                  t.id.equals(taskId) &
                  t.updatedAtMs.equals(
                    expectedUpdatedAt.millisecondsSinceEpoch,
                  ) &
                  _owner(t.userId),
            ))
            .write(
              TasksTableCompanion(
                lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
              ),
            );
    return changed > 0;
  }

  // ─── Writes ────────────────────────────────────────────────────────────────

  /// Upserts a single task. Used for every create/update/delete mutation.
  Future<void> upsertTask(Task task) async {
    await _db
        .into(_db.tasksTable)
        .insertOnConflictUpdate(AppDatabase.taskToCompanion(task));
  }

  Future<void> upsertTaskAndQueue(Task task) async {
    await _db.transaction(() async {
      await upsertTask(task);
      await _queueTask(task.id);
    });
  }

  /// Batch-upserts multiple tasks, such as when applying a cloud sync result.
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

  Future<void> upsertAllAndQueue(List<Task> tasks) async {
    await _db.transaction(() async {
      await upsertAll(tasks);
      for (final task in tasks) {
        await _queueTask(task.id);
      }
    });
  }

  Future<void> _queueTask(String taskId) async {
    final userId = AccountScope.userId;
    if (userId == null) return;
    await SyncOutboxDao(_db).enqueue(
      userId: userId,
      feature: 'tasks',
      entityType: 'task',
      entityId: taskId,
      operation: 'upsert',
    );
  }

  /// Hard-deletes a task row by ID (used for permanent bin deletion).
  Future<void> hardDelete(String taskId) async {
    await (_db.delete(
      _db.tasksTable,
    )..where((t) => t.id.equals(taskId) & _owner(t.userId))).go();
  }

  /// Hard-deletes multiple task rows by ID.
  Future<int> hardDeleteMany(Iterable<String> taskIds) async {
    if (taskIds.isEmpty) return 0;
    return (_db.delete(
      _db.tasksTable,
    )..where((t) => t.id.isIn(taskIds) & _owner(t.userId))).go();
  }

  /// Hard-deletes all tasks currently in the bin (deleted_at_ms IS NOT NULL).
  Future<int> clearBin() async {
    return (_db.delete(
      _db.tasksTable,
    )..where((t) => t.deletedAtMs.isNotNull() & _owner(t.userId))).go();
  }

  /// Evicts bin tasks older than [retentionDays] days (local 90-day purge).
  Future<int> evictOldBinTasks({int retentionDays = 90}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    return (_db.delete(_db.tasksTable)..where(
          (t) =>
              t.deletedAtMs.isNotNull() &
              t.deletedAtMs.isSmallerThanValue(cutoff) &
              _owner(t.userId),
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
    return (_db.update(_db.tasksTable)..where(
          (t) =>
              t.completed.equals(true) &
              t.deletedAtMs.isNull() &
              t.updatedAtMs.isSmallerThanValue(cutoff) &
              _owner(t.userId),
        ))
        .write(
          TasksTableCompanion(deletedAtMs: Value(now), updatedAtMs: Value(now)),
        );
  }

  /// Clears all rows (for testing or account sign-out).
  Future<void> clearAll() async {
    await (_db.delete(_db.tasksTable)..where((t) => _owner(t.userId))).go();
  }
}
