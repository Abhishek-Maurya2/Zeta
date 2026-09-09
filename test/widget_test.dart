import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/main.dart';
import 'package:zeta/navigation/app_scaffold.dart';
import 'package:zeta/navigation/top_app_bar.dart';
import 'package:zeta/pages/tasks_page.dart';
import 'package:zeta/pages/bin_page.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/components/tasks/task_edit_pane.dart';

void main() {
  testWidgets('ZetaApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    expect(find.byType(AppScaffold), findsOneWidget);
    expect(find.byType(TopAppBarWidget), findsOneWidget);
  });

  testWidgets('TasksPage navigation, items, and FAB test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(AppScaffold));
    context.read<NavigationProvider>().setActivePage(PageId.tasks);
    await tester.pumpAndSettle();

    // Verify TasksPage rendered
    expect(find.byType(TasksPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TasksPage),
        matching: find.text('Tasks'),
      ),
      findsOneWidget,
    );

    // Verify tasks
    expect(find.text('Answer writting'), findsOneWidget);
    expect(find.text('Society Indian Society'), findsOneWidget);
    expect(find.text('Society'), findsOneWidget);
    expect(find.text('Population'), findsOneWidget);

    // Verify Completed section
    expect(find.text('COMPLETED (2)'), findsOneWidget);
    expect(find.text('Women Organisation'), findsOneWidget);
    expect(find.text('Role of Women'), findsOneWidget);

    // Verify Add Task FAB
    expect(find.text('Add Task'), findsOneWidget);
  });

  testWidgets('Right-click context menu on tasks (pending and completed)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(AppScaffold));
    context.read<NavigationProvider>().setActivePage(PageId.tasks);
    await tester.pumpAndSettle();

    // 1. Right-click on a pending task ('Answer writting')
    final pendingTaskFinder = find.text('Answer writting');
    expect(pendingTaskFinder, findsOneWidget);
    await tester.tap(pendingTaskFinder, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    // Context menu options should appear
    expect(find.text('Mark as Complete'), findsOneWidget);
    expect(find.text('Edit Details'), findsOneWidget);
    expect(find.text('Move to Bin'), findsOneWidget);

    // Tap 'Move to Bin'
    await tester.tap(find.text('Move to Bin'));
    await tester.pumpAndSettle();

    // 'Answer writting' should now be moved to bin
    expect(find.text('Answer writting'), findsNothing);

    // 2. Right-click on a completed task ('Role of Women')
    final completedTaskFinder = find.text('Role of Women');
    expect(completedTaskFinder, findsOneWidget);
    await tester.tap(completedTaskFinder, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    // For completed tasks, 'Mark as Incomplete' should appear
    expect(find.text('Mark as Incomplete'), findsOneWidget);
    expect(find.text('Edit Details'), findsOneWidget);
    expect(find.text('Move to Bin'), findsOneWidget);

    // Dismiss menu
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets('TaskEditPane opens on FAB tap and creates new task with subtasks',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(AppScaffold));
    context.read<NavigationProvider>().setActivePage(PageId.tasks);
    await tester.pumpAndSettle();

    // Tap FAB to open TaskEditPane
    await tester.tap(find.text('Add Task'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskEditFormContent), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TaskEditFormContent),
        matching: find.text('New Task'),
      ),
      findsOneWidget,
    );

    // Enter title
    final titleField = find.descendant(
      of: find.byType(TaskEditFormContent),
      matching: find.byType(TextField),
    ).first;
    await tester.enterText(titleField, 'Build Modern UI Architecture');

    // Tap 'Create Task'
    await tester.tap(find.text('Create Task'));
    await tester.pumpAndSettle();

    // New task should appear in the task list
    expect(find.text('Build Modern UI Architecture'), findsOneWidget);
  });

  testWidgets('BinPage renders deleted items, restore, and empty bin flow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    // Navigate to Bin Page
    final BuildContext context = tester.element(find.byType(AppScaffold));
    context.read<NavigationProvider>().setActivePage(PageId.bin);
    await tester.pumpAndSettle();

    // Verify BinPage rendered
    expect(find.byType(BinPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BinPage),
        matching: find.text('Bin'),
      ),
      findsOneWidget,
    );

    // Verify initial sample bin items
    expect(find.text('Geography Map Practice'), findsOneWidget);
    expect(find.text('Modern History Timeline'), findsOneWidget);

    // Verify bin header buttons
    expect(find.text('Restore All'), findsOneWidget);
    expect(find.text('Empty Bin'), findsOneWidget);

    // Right-click on a bin item ('Geography Map Practice')
    await tester.tap(find.text('Geography Map Practice'), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    // Context menu options for bin items
    expect(find.text('Restore Task'), findsOneWidget);
    expect(find.text('Delete Permanently'), findsOneWidget);

    // Restore via context menu
    await tester.tap(find.text('Restore Task'));
    await tester.pumpAndSettle();

    // 'Geography Map Practice' restored, 'Modern History Timeline' remains
    expect(find.text('Geography Map Practice'), findsNothing);
    expect(find.text('Modern History Timeline'), findsOneWidget);

    // Test Empty Bin
    await tester.tap(find.text('Empty Bin'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Empty Bin Permanently?'), findsOneWidget);
    // Confirm empty bin
    final emptyBtn = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Empty Bin'),
    );
    await tester.tap(emptyBtn);
    await tester.pumpAndSettle();

    // Empty state should be visible
    expect(find.text('Bin is Empty'), findsOneWidget);
    expect(find.text('Go to Tasks'), findsOneWidget);
  });

  testWidgets('TasksPage filter and sort layout responds to compact view',
      (WidgetTester tester) async {
    // 1. Wide view (1200x800)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(AppScaffold));
    context.read<NavigationProvider>().setActivePage(PageId.tasks);
    await tester.pumpAndSettle();

    final filterFinder = find.byType(M3EToggleButtonGroup);
    final sortFinder = find.byType(M3ESplitButton<TaskSortOption>);

    expect(filterFinder, findsOneWidget);
    expect(sortFinder, findsOneWidget);

    final wideFilterPos = tester.getTopLeft(filterFinder);
    final wideSortPos = tester.getTopLeft(sortFinder);

    // In wide view, sort button is in the same row as filter button group
    expect((wideSortPos.dy - wideFilterPos.dy).abs(), lessThan(10.0));
    // And to the right
    expect(wideSortPos.dx, greaterThan(wideFilterPos.dx));

    // 2. Compact view (400x800)
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();

    final compactFilterBottom = tester.getBottomLeft(filterFinder);
    final compactSortTop = tester.getTopLeft(sortFinder);

    // In compact view, sort button is below the filter buttons
    expect(compactSortTop.dy, greaterThan(compactFilterBottom.dy));

    // And aligned to the right side (justify-end)
    final compactSortRight = tester.getTopRight(sortFinder);
    expect(compactSortRight.dx, closeTo(400 - 16, 2.0));
  });
}

