import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/pages/tasks/tasks_page.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/services/cross_device_service.dart';
import 'package:zeta/services/preferences_service.dart';

import 'package:zeta/utils/app_snackbar.dart';
import 'package:zeta/services/app_exit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyCrossDeviceEnabled: false,
    });
    await PreferencesService.instance.init();
    await PreferencesService.instance.setCrossDeviceEnabled(false);
    addTearDown(() {
      CrossDeviceService.instance.dispose();
    });
  });

  testWidgets('auto-completes task after 3 seconds when all subtasks done and shows toast',
      (tester) async {
    final taskProvider = TaskProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ],
        child: MaterialApp(
          navigatorKey: AppExitService.navigatorKey,
          scaffoldMessengerKey: AppSnackbar.scaffoldMessengerKey,
          home: const Scaffold(
            body: TasksPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final taskId = await taskProvider.addTask(
      title: 'Parent Task',
      subtasks: [
        Subtask(id: 'st1', title: 'Subtask 1', completed: false),
        Subtask(id: 'st2', title: 'Subtask 2', completed: false),
      ],
    );
    // Expand task so subtasks are rendered
    taskProvider.toggleTaskExpanded(taskId);
    await tester.pumpAndSettle();

    expect(find.text('Subtask 1'), findsOneWidget);
    expect(find.text('Subtask 2'), findsOneWidget);

    // Tap subtask 1
    await tester.tap(find.text('Subtask 1'));
    await tester.pumpAndSettle();

    final taskAfter1 = taskProvider.allTasks.firstWhere((t) => t.id == taskId);
    expect(taskAfter1.completed, isFalse);

    // Tap subtask 2
    await tester.tap(find.text('Subtask 2'));
    await tester.pumpAndSettle();

    // Advance 1 second - still not complete
    await tester.pump(const Duration(seconds: 1));
    final taskAfter2Sec1 = taskProvider.allTasks.firstWhere((t) => t.id == taskId);
    expect(taskAfter2Sec1.completed, isFalse);

    // Advance 2.5 more seconds (total 3.5 seconds)
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    final taskAfter3Sec = taskProvider.allTasks.firstWhere((t) => t.id == taskId);
    expect(taskAfter3Sec.completed, isTrue);

    // Check if Undo is visible
    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    final taskAfterUndo = taskProvider.allTasks.firstWhere((t) => t.id == taskId);
    expect(taskAfterUndo.completed, isFalse);
  });
}
