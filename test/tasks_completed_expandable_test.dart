import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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

  testWidgets('completed tasks section renders M3EExpandableList collapsed by default and expands on tap',
      (tester) async {
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

    // Add one pending task and one completed task after initial load completes
    await taskProvider.addTask(title: 'Active Task');
    final completedId = await taskProvider.addTask(title: 'Finished Task');
    taskProvider.toggleTask(completedId);
    await tester.pumpAndSettle();

    // Active task is visible
    expect(find.text('Active Task'), findsOneWidget);

    // M3EList should be rendered for completed tasks
    expect(find.byType(M3EList), findsWidgets);
    expect(find.text('Completed (1)'), findsOneWidget);

    // By default, the expandable list is collapsed (heightFactor = 0)
    // Tapping the completed header card toggles expansion
    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();

    // After expanding, the completed task title is revealed
    expect(find.text('Finished Task'), findsOneWidget);

    // Tapping again collapses it
    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();

    CrossDeviceService.instance.dispose();
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets(
      'loads only 5 completed tasks at a time and batches remaining 5 at a time on demand',
      (tester) async {
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

    // Create 12 completed tasks
    for (int i = 1; i <= 12; i++) {
      final id = await taskProvider.addTask(title: 'Done Task $i');
      taskProvider.toggleTask(id);
    }
    await tester.pumpAndSettle();

    expect(taskProvider.completedTasks.length, 12);

    // Expand the completed section
    await tester.tap(find.text('Completed (12)'));
    await tester.pumpAndSettle();

    // Only 5 should be visible initially
    final visibleCount = taskProvider.completedTasks
        .take(5)
        .where((t) => find.text(t.title).evaluate().isNotEmpty)
        .length;
    expect(visibleCount, 5);

    // Load more indicator / button should be present
    final loadMoreFinder = find.byType(M3EIconButton);
    expect(loadMoreFinder, findsOneWidget);

    // Tap to load the next 5
    await tester.tap(loadMoreFinder);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Now 10 tasks should be visible
    final visibleCount10 = taskProvider.completedTasks
        .take(10)
        .where((t) => find.text(t.title).evaluate().isNotEmpty)
        .length;
    expect(visibleCount10, 10);

    // Next batch button is still present
    final loadMoreFinder2 = find.byType(M3EIconButton);
    expect(loadMoreFinder2, findsOneWidget);

    // Tap to load the remaining 2
    await tester.ensureVisible(loadMoreFinder2);
    await tester.tap(loadMoreFinder2);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // All 12 are now rendered
    final visibleCount12 = taskProvider.completedTasks
        .where((t) => find.text(t.title).evaluate().isNotEmpty)
        .length;
    expect(visibleCount12, 12);

    // No more load button
    expect(find.byType(M3EIconButton), findsNothing);

    CrossDeviceService.instance.dispose();
    await tester.pump(const Duration(minutes: 5));
  });
}

