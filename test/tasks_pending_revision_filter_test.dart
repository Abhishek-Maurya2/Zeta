import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/database/database_provider.dart';
import 'package:zeta/pages/tasks/tasks_page.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/services/cross_device_service.dart';
import 'package:zeta/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyCrossDeviceEnabled: false,
    });
    await PreferencesService.instance.init();
    await PreferencesService.instance.setCrossDeviceEnabled(false);
    try {
      final db = DatabaseProvider.instance.db;
      await db.delete(db.tasksTable).go();
    } catch (_) {}
    addTearDown(() {
      CrossDeviceService.instance.dispose();
    });
  });

  group('Revision tasks filtering', () {
    test('TaskProvider filters out revisions on TaskFilter.pending but keeps in all and revision', () async {
      final taskProvider = TaskProvider();
      await taskProvider.addTask(title: 'Regular Task');
      await taskProvider.addTask(title: 'Revise: Biology Chapter 1');
      await taskProvider.addTask(title: 'History Study', description: 'Exam #revision notes');

      // pendingTasks has all active pending tasks
      expect(taskProvider.pendingTasks.length, 3);
      expect(taskProvider.revisionTasks.length, 2);

      // In All filter
      taskProvider.setFilter(TaskFilter.all);
      expect(taskProvider.filteredAndSortedTasks.length, 3);

      // In Pending filter, revisions should not be included
      taskProvider.setFilter(TaskFilter.pending);
      expect(taskProvider.filteredAndSortedTasks.length, 1);
      expect(taskProvider.filteredAndSortedTasks.first.title, 'Regular Task');

      // In Revision filter, only revisions should be included
      taskProvider.setFilter(TaskFilter.revision);
      expect(taskProvider.filteredAndSortedTasks.length, 2);
    });

    testWidgets('TasksPage does not show revisions in pending section, only in all and revision', (tester) async {
      final taskProvider = TaskProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TasksPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await taskProvider.addTask(title: 'Regular Task 1');
      await taskProvider.addTask(title: 'Revise: Physics Notes');
      await tester.pumpAndSettle();

      // 1. In 'All' view: both should be present
      expect(taskProvider.filter, TaskFilter.all);
      expect(find.text('Regular Task 1'), findsOneWidget);
      expect(find.text('Revise: Physics Notes'), findsOneWidget);
      expect(find.text('Pending (1)'), findsWidgets);
      expect(find.text('Revisions (1)'), findsWidgets);

      // 2. Switch to 'Pending' view
      taskProvider.setFilter(TaskFilter.pending);
      await tester.pumpAndSettle();

      // Regular task is visible, revision task MUST NOT be visible in pending section
      expect(find.text('Regular Task 1'), findsOneWidget);
      expect(find.text('Revise: Physics Notes'), findsNothing);

      // 3. Switch to 'Revision' view
      taskProvider.setFilter(TaskFilter.revision);
      await tester.pumpAndSettle();

      // Revision task is visible, regular task is not visible
      expect(find.text('Revise: Physics Notes'), findsOneWidget);
      expect(find.text('Regular Task 1'), findsNothing);
    });
  });
}
