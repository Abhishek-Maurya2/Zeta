import 'dart:async';

import '../models/task.dart';
import '../database/daos/task_dao.dart';
import '../database/database_provider.dart';
import '../database/account_scope.dart';
import '../services/supabase_sync_service.dart';

/// Repository that coordinates local SQLite task storage with remote Supabase synchronization.
class TaskRepository {
  final TaskDao _taskDao;
  final SupabaseSyncService _syncService;

  TaskRepository({TaskDao? taskDao, SupabaseSyncService? syncService})
    : _taskDao = taskDao ?? DatabaseProvider.instance.taskDao,
      _syncService = syncService ?? SupabaseSyncService() {
    _syncService.onTaskSynced = _markTaskSynced;
    _syncService.getTaskForSync = _taskDao.getTask;
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

  void setRemoteChangeListener(
    void Function(Task task, String eventType)? listener,
  ) {
    _syncService.onRemoteChange = listener;
  }

  void subscribeToRealtime({
    void Function(Task task, String eventType)? onChange,
  }) {
    _syncService.subscribeToRealtime(onChange: onChange);
  }

  // ─── Local Reads ───────────────────────────────────────────────────────────
  Future<List<Task>> getActiveTasks() => _taskDao.getActiveTasks();

  Future<List<Task>> getBinTasks() => _taskDao.getBinTasks();

  Future<void> processPendingSync() async {
    await _syncService.processPendingQueue();
    final unsynced = await _taskDao.getUnsyncedTasks();
    for (final task in unsynced) {
      final userId = AccountScope.userId;
      final queued =
          userId != null &&
          await DatabaseProvider.instance.syncOutboxDao.hasPending(
            userId: userId,
            feature: 'tasks',
            entityType: 'task',
            entityId: task.id,
          );
      if (!queued && task.title.trim().isNotEmpty) {
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
    if (pushToCloud) {
      await _taskDao.upsertTaskAndQueue(task);
    } else {
      await _taskDao.upsertTask(task);
    }
    if (pushToCloud) {
      unawaited(_syncService.processPendingQueue());
    }
  }

  Future<void> saveTasksBatch(
    List<Task> tasks, {
    bool pushToCloud = true,
  }) async {
    if (!pushToCloud && tasks.isNotEmpty) {
      final now = DateTime.now();
      for (final task in tasks) {
        task.lastSyncedAt = task.updatedAt.isAfter(now) ? task.updatedAt : now;
      }
    }
    if (pushToCloud) {
      await _taskDao.upsertAllAndQueue(tasks);
    } else {
      await _taskDao.upsertAll(tasks);
    }
    if (pushToCloud) {
      unawaited(_syncService.processPendingQueue());
    }
  }

  Future<void> softDeleteTask(Task task, {bool pushToCloud = true}) async {
    final updatedTask = task.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveTask(updatedTask, pushToCloud: pushToCloud);
  }

  Future<void> deleteTask(String taskId, {bool pushToCloud = true}) async {
    if (pushToCloud) {
      await DatabaseProvider.instance.db.transaction(() async {
        await _syncService.queuePermanentDeletions([taskId]);
        await _taskDao.hardDelete(taskId);
      });
      await _syncService.processPendingQueue();
    } else {
      await _taskDao.hardDelete(taskId);
    }
  }

  Future<void> deleteMultipleTasks(
    Iterable<String> taskIds, {
    bool pushToCloud = true,
  }) async {
    final ids = taskIds.toSet();
    if (pushToCloud) {
      await DatabaseProvider.instance.db.transaction(() async {
        await _syncService.queuePermanentDeletions(ids);
        await _taskDao.hardDeleteMany(ids);
      });
      await _syncService.processPendingQueue();
    } else {
      await _taskDao.hardDeleteMany(ids);
    }
  }

  Future<int> clearBin({bool pushToCloud = true}) async {
    final binTasks = await _taskDao.getBinTasks();
    if (pushToCloud) {
      late final int count;
      await DatabaseProvider.instance.db.transaction(() async {
        await _syncService.queuePermanentDeletions(
          binTasks.map((task) => task.id),
        );
        count = await _taskDao.clearBin();
      });
      await _syncService.processPendingQueue();
      return count;
    }
    return _taskDao.clearBin();
  }

  Future<int> evictOldBinTasks({int retentionDays = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final expired = (await _taskDao.getBinTasks())
        .where(
          (task) => task.deletedAt != null && task.deletedAt!.isBefore(cutoff),
        )
        .toList();
    late final int count;
    await DatabaseProvider.instance.db.transaction(() async {
      await _syncService.queuePermanentDeletions(
        expired.map((task) => task.id),
      );
      count = await _taskDao.evictOldBinTasks(retentionDays: retentionDays);
    });
    await _syncService.processPendingQueue();
    return count;
  }

  Future<int> archiveOldCompletedTasks({int retentionDays = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final eligible = (await _taskDao.getActiveTasks())
        .where((task) => task.completed && task.updatedAt.isBefore(cutoff))
        .toList();
    final now = DateTime.now();
    final count = await DatabaseProvider.instance.db.transaction(() async {
      final updated = eligible
          .map((task) => task.copyWith(deletedAt: now, updatedAt: now))
          .toList();
      if (updated.isNotEmpty) await _taskDao.upsertAllAndQueue(updated);
      return updated.length;
    });
    if (count > 0) unawaited(_syncService.processPendingQueue());
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
