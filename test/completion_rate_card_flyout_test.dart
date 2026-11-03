import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:zeta/components/glass_surface.dart';
import 'package:zeta/models/pomodoro.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/pages/home/components/completion_rate_card.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/providers/theme_provider.dart';

class MockTaskProvider extends ChangeNotifier implements TaskProvider {
  final List<Task> _tasks;
  MockTaskProvider([this._tasks = const []]);

  @override
  List<Task> get allTasks => _tasks;

  @override
  void setFilter(TaskFilter filter) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPomodoroProvider extends ChangeNotifier implements PomodoroProvider {
  @override
  List<PomodoroSessionLog> get sessionLog => const [];

  @override
  PomodoroSettings get settings => const PomodoroSettings(dailyGoalMinutes: 60);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  bool isDarkMode(BuildContext context) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNavigationProvider extends ChangeNotifier implements NavigationProvider {
  @override
  void setActivePage(PageId page) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createTestWidget({
  required List<Task> tasks,
  bool? enableHoverFlyout,
  VoidCallback? onTasksPillTap,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TaskProvider>.value(
        value: MockTaskProvider(tasks),
      ),
      ChangeNotifierProvider<PomodoroProvider>.value(
        value: MockPomodoroProvider(),
      ),
      ChangeNotifierProvider<ThemeProvider>.value(
        value: MockThemeProvider(),
      ),
      ChangeNotifierProvider<NavigationProvider>.value(
        value: MockNavigationProvider(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            child: CompletionRateCard(
              enableHoverFlyout: enableHoverFlyout ?? true,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Hovering over Tasks metric capsule reveals GlassSurface flyout with M3EList workload tasks',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final tasks = [
        Task(
          id: 'task-1',
          title: 'Complete Project Report',
          dueDate: todayStr,
          completed: true,
          completedAt: now,
        ),
        Task(
          id: 'task-2',
          title: 'Review PR feedback',
          dueDate: todayStr,
          completed: false,
        ),
      ];

      await tester.pumpWidget(createTestWidget(tasks: tasks));
      await tester.pump();

      // Before hover: no GlassSurface flyout should be in the tree
      expect(find.byType(GlassSurface), findsNothing);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);

      // Perform hover over the Tasks metric capsule
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Tasks')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      // After hover: flyout styled with GlassSurface should be revealed
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.text("Today's Workload"), findsOneWidget);
      expect(find.text('1 of 2 completed'), findsOneWidget);

      // Verify M3EList and M3EListItem rendering
      expect(find.byType(M3EList), findsOneWidget);
      expect(find.byType(M3EListItem), findsNWidgets(2));

      // Verify tasks title and status
      expect(find.text('Complete Project Report'), findsOneWidget);
      expect(find.text('Review PR feedback'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Symbols.check_circle_rounded), findsOneWidget);
      expect(
        find.byIcon(Symbols.radio_button_unchecked_rounded),
        findsOneWidget,
      );

      // Cleanup gesture
      await gesture.removePointer();
    },
  );

  testWidgets(
    'Flyout remains visible while pointer is over capsule or flyout, and dismisses when pointer exits both',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final tasks = [
        Task(
          id: 'task-1',
          title: 'Design Mockup',
          dueDate: todayStr,
          completed: false,
        ),
      ];

      await tester.pumpWidget(createTestWidget(tasks: tasks));
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // 1. Hover on capsule -> opens flyout
      await gesture.moveTo(tester.getCenter(find.text('Tasks')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.byType(GlassSurface), findsOneWidget);

      // 2. The expanded pill remains open while the pointer stays over it.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GlassSurface), findsOneWidget);

      // 3. Move pointer far away outside both capsule and flyout -> dismisses
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSurface), findsNothing);

      await gesture.removePointer();
    },
  );

  testWidgets(
    'Flyout task list is view-only and does not mutate task state on tap',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final task = Task(
        id: 'task-view-only',
        title: 'Immutable Workload Task',
        dueDate: todayStr,
        completed: false,
      );

      await tester.pumpWidget(createTestWidget(tasks: [task]));
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Tasks')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.text('Immutable Workload Task'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Tap on the task item in the flyout
      await tester.tap(find.text('Immutable Workload Task'));
      await tester.pump();

      // State remains view-only and pending
      expect(task.completed, isFalse);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);

      await gesture.removePointer();
    },
  );

  testWidgets(
    'Empty workload renders empty state M3EListItem inside flyout',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(tasks: []));
      await tester.pump();

      expect(find.text('0/0'), findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Tasks')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.text('0 of 0 completed'), findsOneWidget);
      expect(find.text('No workload tasks for today'), findsOneWidget);
      expect(find.byType(M3EList), findsOneWidget);
      expect(find.byType(M3EListItem), findsOneWidget);

      await gesture.removePointer();
    },
  );

  testWidgets(
    'Hover does not open flyout when enableHoverFlyout is false',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final tasks = [
        Task(
          id: 'task-1',
          title: 'Task 1',
          dueDate: todayStr,
          completed: false,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(tasks: tasks, enableHoverFlyout: false),
      );
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Tasks')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GlassSurface), findsNothing);

      await gesture.removePointer();
    },
  );
}
