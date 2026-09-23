import 'dart:async';
import '../models/task.dart';
import '../database/daos/task_dao.dart';
import '../database/database_provider.dart';
import '../services/supabase_sync_service.dart';
import '../utils/app_logger.dart';

/// Repository that coordinates local SQLite task storage with remote Supabase synchronization.
class TaskRepository {
  final TaskDao _taskDao;
  final SupabaseSyncService _syncService;

  TaskRepository({
    TaskDao? taskDao,
    SupabaseSyncService? syncService,
  })  : _taskDao = taskDao ?? DatabaseProvider.instance.taskDao,
        _syncService = syncService ?? SupabaseSyncService();

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

  Future<List<Task>> getUnsyncedTasks() => _taskDao.getUnsyncedTasks();

  // ─── Local Mutations ───────────────────────────────────────────────────────
  Future<void> saveTask(Task task, {bool pushToCloud = true}) async {
    await _taskDao.upsertTask(task);
    if (pushToCloud) {
      unawaited(_syncService.pushTask(task));
    }
  }

  Future<void> saveTasksBatch(List<Task> tasks, {bool pushToCloud = true}) async {
    await _taskDao.upsertAll(tasks);
    if (pushToCloud) {
      for (final t in tasks) {
        unawaited(_syncService.pushTask(t));
      }
    }
  }

  Future<void> deleteTask(String taskId, {bool pushToCloud = true}) async {
    await _taskDao.hardDelete(taskId);
    if (pushToCloud) {
      unawaited(_syncService.deleteTask(taskId, soft: false));
    }
  }

  Future<void> deleteMultipleTasks(Iterable<String> taskIds, {bool pushToCloud = true}) async {
    await _taskDao.hardDeleteMany(taskIds);
    if (pushToCloud) {
      for (final id in taskIds) {
        unawaited(_syncService.deleteTask(id, soft: false));
      }
    }
  }

  Future<int> clearBin({bool pushToCloud = true}) async {
    final binTasks = await _taskDao.getBinTasks();
    final count = await _taskDao.clearBin();
    if (pushToCloud) {
      for (final t in binTasks) {
        unawaited(_syncService.deleteTask(t.id, soft: false));
      }
    }
    return count;
  }

  Future<int> archiveOldCompletedTasks({int retentionDays = 90}) {
    return _taskDao.archiveOldCompletedTasks(retentionDays: retentionDays);
  }

  // ─── Cloud Sync Operations ─────────────────────────────────────────────────
  Future<void> syncWithCloud({bool force = false}) async {
    try {
      await _syncService.processPendingQueue();
      final remoteTasks = await _syncService.pullTasks();
      if (remoteTasks.isNotEmpty) {
        await _taskDao.upsertAll(remoteTasks);
      }
    } catch (e, st) {
      AppLogger.error('TaskRepository sync failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
