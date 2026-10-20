import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/pages/home/components/recent_tasks_section.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/providers/task_provider.dart';

class MockTaskProvider extends ChangeNotifier implements TaskProvider {
  @override
  bool isTaskExpanded(String id) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestWidget({
    required TaskProvider taskProvider,
    required NavigationProvider navProvider,
    required List<Task> tasks,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UpNextSection(
              tasks: tasks,
              totalCount: tasks.length,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('UpNext shows at most 3 tasks initially and does not show footer when count <= 3',
      (tester) async {
    final taskProvider = MockTaskProvider();
    final navProvider = NavigationProvider();

    final tasks = [
      Task(id: '1', title: 'Task 1'),
      Task(id: '2', title: 'Task 2'),
      Task(id: '3', title: 'Task 3'),
    ];

    await tester.pumpWidget(
      buildTestWidget(
        taskProvider: taskProvider,
        navProvider: navProvider,
        tasks: tasks,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('Task 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('up_next_load_more_footer')), findsNothing);
  });

  testWidgets('UpNext shows maximum of 3 tasks initially with footer and loads 3 more after loading indicator',
      (tester) async {
    final taskProvider = MockTaskProvider();
    final navProvider = NavigationProvider();

    final tasks = List.generate(
      7,
      (i) => Task(id: '$i', title: 'Task ${i + 1}'),
    );

    await tester.pumpWidget(
      buildTestWidget(
        taskProvider: taskProvider,
        navProvider: navProvider,
        tasks: tasks,
      ),
    );
    await tester.pumpAndSettle();

    // First 3 tasks are visible
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('Task 3'), findsOneWidget);
    expect(find.text('Task 4'), findsNothing);

    // Footer listitem should be present with "3 More Tasks"
    final footerFinder = find.byKey(const ValueKey('up_next_load_more_footer'));
    expect(footerFinder, findsOneWidget);
    expect(find.text('3 More Tasks'), findsOneWidget);

    // Tap the load more footer
    await tester.ensureVisible(footerFinder);
    await tester.tap(find.text('3 More Tasks'));
    await tester.pump(); // Triggers setState for loading indicator

    // Loading indicator is shown
    expect(find.byType(M3ELoadingIndicator), findsOneWidget);

    // Advance timer past the 350ms delay
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Tasks 1 to 6 are now visible
    expect(find.text('Task 4'), findsOneWidget);
    expect(find.text('Task 5'), findsOneWidget);
    expect(find.text('Task 6'), findsOneWidget);
    expect(find.text('Task 7'), findsNothing);

    // Footer now shows "1 More Task" since only 1 is left
    expect(find.text('1 More Task'), findsOneWidget);

    // Tap to load the last task
    await tester.tap(find.text('1 More Task'));
    await tester.pump();
    expect(find.byType(M3ELoadingIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // All 7 tasks are now visible
    expect(find.text('Task 7'), findsOneWidget);

    // Footer is now gone
    expect(find.byKey(const ValueKey('up_next_load_more_footer')), findsNothing);
  });
}
