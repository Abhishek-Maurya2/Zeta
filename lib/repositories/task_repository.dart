import 'dart:async';
import '../models/task.dart';
import '../database/daos/task_dao.dart';
import '../database/database_provider.dart';
import '../services/supabase_sync_service.dart';

/// Repository that coordinates local SQLite task storage with remote Supabase synchronization.
class TaskRepository {
  final TaskDao _taskDao;
  final SupabaseSyncService _syncService;

  TaskRepository({
    TaskDao? taskDao,
    SupabaseSyncService? syncService,
  })  : _taskDao = taskDao ?? DatabaseProvider.instance.taskDao,
        _syncService = syncService ?? SupabaseSyncService() {
    _syncService.onTaskSynced = _markTaskSynced;
    _syncService.onNetworkReconnect = processPendingSync;
  }

  Future<void> _markTaskSynced(Task task, DateTime syncedAt) async {
    final marker = task.updatedAt.isAfter(syncedAt) ? task.updatedAt : syncedAt;
    final marked = await _taskDao.markTaskSynced(
      task.id,
      marker,
      expectedUpdatedAt: task.updatedAt,
    );
    if (marked) task.lastSyncedAt = marker;
  }

  TaskDao get taskDao => _taskDao;
  SupabaseSyncService get syncService => _syncService;

  bool get isSyncing => _syncService.isSyncing;
  DateTime? get lastSyncedAt => _syncService.lastSyncedAt;
  String? get syncError => _syncService.lastError;

  void setRemoteChangeListener(void Function(Task task, String eventType)? listener) {
    _syncService.onRemoteChange = listener;
  }

  // ─── Local Reads ───────────────────────────────────────────────────────────
  Future<List<Task>> getActiveTasks() => _taskDao.getActiveTasks();

  Future<List<Task>> getBinTasks() => _taskDao.getBinTasks();

  Future<void> processPendingSync() async {
    await _syncService.processPendingQueue();
    final unsynced = await _taskDao.getUnsyncedTasks();
    for (final task in unsynced) {
      if (task.title.trim().isNotEmpty) {
        await _syncService.pushTask(task);
      }
    }
  }

  // ─── Local Mutations ───────────────────────────────────────────────────────
  Future<void> saveTask(Task task, {bool pushToCloud = true}) async {
    if (!pushToCloud) {
      final now = DateTime.now();
      task.lastSyncedAt = task.updatedAt.isAfter(now) ? task.updatedAt : now;
    }
    await _taskDao.upsertTask(task);
    if (pushToCloud) {
      unawaited(_syncService.pushTask(task));
    }
  }

  Future<void> saveTasksBatch(List<Task> tasks, {bool pushToCloud = true}) async {
    if (!pushToCloud && tasks.isNotEmpty) {
      final now = DateTime.now();
      for (final task in tasks) {
        task.lastSyncedAt = task.updatedAt.isAfter(now) ? task.updatedAt : now;
      }
    }
    await _taskDao.upsertAll(tasks);
    if (pushToCloud) {
      for (final t in tasks) {
        unawaited(_syncService.pushTask(t));
      }
    }
  }

  Future<void> softDeleteTask(Task task, {bool pushToCloud = true}) async {
    final updatedTask = task.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _taskDao.upsertTask(updatedTask);
    if (pushToCloud) {
      unawaited(_syncService.pushTask(updatedTask));
    }
  }

  Future<void> deleteTask(String taskId, {bool pushToCloud = true}) async {
    await _taskDao.hardDelete(taskId);
    if (pushToCloud) {
      await _syncService.queuePermanentDeletions([taskId]);
    }
  }

  Future<void> deleteMultipleTasks(Iterable<String> taskIds, {bool pushToCloud = true}) async {
    final ids = taskIds.toSet();
    await _taskDao.hardDeleteMany(ids);
    if (pushToCloud) {
      await _syncService.queuePermanentDeletions(ids);
    }
  }

  Future<int> clearBin({bool pushToCloud = true}) async {
    final binTasks = await _taskDao.getBinTasks();
    final count = await _taskDao.clearBin();
    if (pushToCloud) {
      await _syncService.queuePermanentDeletions(binTasks.map((task) => task.id));
    }
    return count;
  }

  Future<int> evictOldBinTasks({int retentionDays = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final expired = (await _taskDao.getBinTasks())
        .where((task) => task.deletedAt != null && task.deletedAt!.isBefore(cutoff))
        .toList();
    final count = await _taskDao.evictOldBinTasks(retentionDays: retentionDays);
    await _syncService.queuePermanentDeletions(expired.map((task) => task.id));
    return count;
  }

  Future<int> archiveOldCompletedTasks({int retentionDays = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final eligible = (await _taskDao.getActiveTasks())
        .where((task) => task.completed && task.updatedAt.isBefore(cutoff))
        .toList();
    final now = DateTime.now();
    final count = await _taskDao.archiveOldCompletedTasks(
      retentionDays: retentionDays,
      archivedAt: now,
    );
    for (final task in eligible) {
      unawaited(_syncService.pushTask(task.copyWith(
        deletedAt: now,
        updatedAt: now,
      )));
    }
    return count;
  }

  // ─── Cloud Sync Operations ─────────────────────────────────────────────────
  Future<List<Task>?> pullRemoteSnapshot() async {
    await processPendingSync();
    final tasks = await _syncService.pullTasks();
    return _syncService.lastError == null ? tasks : null;
  }

  Future<bool> pushTask(Task task) => _syncService.pushTask(task);
}
