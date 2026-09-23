import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/database/database_provider.dart';
import 'package:zeta/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bin Persistence & Cloud Reconciliation Tests', () {
    late TaskProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'zeta_master_sync_enabled': false});
      await DatabaseProvider.instance.taskDao.clearAll();
      provider = TaskProvider();
      await provider.loadFuture;
      provider.clearSelection();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Moving task to bin saves with deletedAt in memory and SQLite', () async {
      final taskId = await provider.addTask(title: 'Bin Test Task');
      expect(provider.allTasks.any((t) => t.id == taskId), isTrue);
      expect(provider.binTasks.any((t) => t.id == taskId), isFalse);

      provider.deleteTask(taskId);
      expect(provider.allTasks.any((t) => t.id == taskId), isFalse);
      expect(provider.binTasks.any((t) => t.id == taskId), isTrue);

      await provider.saveTasks();
      final binRows = await DatabaseProvider.instance.taskDao.getBinTasks();
      expect(binRows.any((t) => t.id == taskId), isTrue);
    });

    test('permanentlyDeleteTask removes task from memory and hard-deletes from SQLite', () async {
      final taskId = await provider.addTask(title: 'Task To Permanently Delete');
      provider.deleteTask(taskId);
      await provider.saveTasks();

      var binRows = await DatabaseProvider.instance.taskDao.getBinTasks();
      expect(binRows.any((t) => t.id == taskId), isTrue);

      // Permanently delete
      await provider.permanentlyDeleteTask(taskId);

      // Verify memory
      expect(provider.binTasks.any((t) => t.id == taskId), isFalse);

      // Verify SQLite is clean
      binRows = await DatabaseProvider.instance.taskDao.getBinTasks();
      expect(binRows.any((t) => t.id == taskId), isFalse);
    });

    test('emptyBin purges all bin tasks from memory and hard-deletes from SQLite', () async {
      final id1 = await provider.addTask(title: 'Bin Item 1');
      final id2 = await provider.addTask(title: 'Bin Item 2');
      provider.deleteTask(id1);
      provider.deleteTask(id2);
      await provider.saveTasks();

      expect(provider.binCount, 2);
      var binRows = await DatabaseProvider.instance.taskDao.getBinTasks();
      expect(binRows.length, greaterThanOrEqualTo(2));

      // Empty bin
      await provider.emptyBin();

      // Memory is empty
      expect(provider.binCount, 0);
      expect(provider.binTasks, isEmpty);

      // SQLite bin is empty
      binRows = await DatabaseProvider.instance.taskDao.getBinTasks();
      expect(binRows, isEmpty);
    });

    test('syncWithCloud prunes local bin tasks not present in remote DB', () async {
      final id = await provider.addTask(title: 'Ghost Bin Task');
      provider.deleteTask(id);
      await provider.saveTasks();

      expect(provider.binTasks.any((t) => t.id == id), isTrue);

      // When syncWithCloud runs with force: true (full sync / refresh),
      // remote DB returns [] (or only active tasks). Ghost bin task must be pruned.
      await provider.syncWithCloud(force: true);

      expect(provider.binTasks.any((t) => t.id == id), isFalse);
      final binRows = await DatabaseProvider.instance.taskDao.getBinTasks();
      expect(binRows.any((t) => t.id == id), isFalse);
    });

    test('completedTasks sorts completed tasks as newest first by default', () async {
      final id1 = await provider.addTask(title: 'Task A');
      final id2 = await provider.addTask(title: 'Task B');

      // Complete Task A first, then wait 50ms, then complete Task B
      provider.toggleTask(id1);
      await Future.delayed(const Duration(milliseconds: 50));
      provider.toggleTask(id2);

      // Task B was completed newest, so it must appear first
      expect(provider.completedTasks.map((t) => t.id).toList(), [id2, id1]);

      // Even when sortBy is changed to Oldest (creationAsc) or A-Z, completed tasks stay newest first
      provider.setSortBy(TaskSortOption.creationAsc);
      expect(provider.completedTasks.map((t) => t.id).toList(), [id2, id1]);

      provider.setSortBy(TaskSortOption.az);
      expect(provider.completedTasks.map((t) => t.id).toList(), [id2, id1]);
    });
  });
}
