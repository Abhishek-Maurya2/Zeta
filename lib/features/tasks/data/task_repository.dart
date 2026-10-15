import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/account_scope.dart';
import '../../../database/database_provider.dart';
import '../../../database/daos/task_dao.dart';
import '../../../models/task.dart';
import '../../../core/sync/sync_coordinator.dart';

/// Clean Architecture Repository for Tasks.
/// All writes are committed locally first with an atomic outbox entry,
/// and reads are streamed reactively from Drift SQLite.
class TaskRepository {
  final TaskDao _taskDao;
  final SyncCoordinator? _syncCoordinator;

  TaskRepository({
    TaskDao? taskDao,
    SyncCoordinator? syncCoordinator,
  })  : _taskDao = taskDao ?? DatabaseProvider.instance.taskDao,
        // ignore: prefer_initializing_formals
        _syncCoordinator = syncCoordinator;

  /// Watch active tasks from Drift SQLite.
  Stream<List<Task>> watchActiveTasks() {
    return _taskDao.watchActiveTasks();
  }

  /// Watch deleted/bin tasks from Drift SQLite.
  Stream<List<Task>> watchBinTasks() {
    return _taskDao.watchBinTasks();
  }

  /// Get single task by ID.
  Future<Task?> getTaskById(String id) {
    return _taskDao.getTask(id);
  }

  /// Add or update task locally and enqueue outbox sync.
  Future<void> saveTask(Task task) async {
    await _taskDao.upsertTask(task);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'tasks',
        entityType: 'task',
        entityId: task.id,
        operation: 'upsert',
      );
      _syncCoordinator?.triggerSync();
    }
  }

  /// Soft-delete task (move to bin).
  Future<void> moveToBin(String taskId) async {
    final task = await _taskDao.getTask(taskId);
    if (task != null) {
      final updated = task.copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveTask(updated);
    }
  }

  /// Permanently delete task.
  Future<void> permanentlyDeleteTask(String taskId) async {
    await _taskDao.hardDelete(taskId);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'tasks',
        entityType: 'task',
        entityId: taskId,
        operation: 'delete',
      );
      _syncCoordinator?.triggerSync();
    }
  }

  /// Restore task from bin.
  Future<void> restoreFromBin(String taskId) async {
    final task = await _taskDao.getTask(taskId);
    if (task != null) {
      final restored = task.copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      await saveTask(restored);
    }
  }
}

/// Riverpod provider for TaskRepository.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final syncCoordinator = ref.watch(syncCoordinatorProvider.notifier);
  return TaskRepository(syncCoordinator: syncCoordinator);
});
