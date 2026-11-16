import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/components/standard_chips.dart';
import 'package:zeta/components/task_card_item.dart';
import 'package:zeta/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTask = Task(
    id: 'task_1',
    title: 'This is a very long task title that should use ellipses when displayed on large screens',
    description: 'This is the description of the task',
    dueDate: '2026-11-20',
    hasTime: true,
    dueTime: '10:00 AM',
    completed: false,
    createdAt: DateTime.now(),
    subtasks: [
      Subtask(id: 'sub_1', title: 'Subtask 1', completed: false),
      Subtask(id: 'sub_2', title: 'Subtask 2', completed: true),
    ],
  );

  Widget buildTestCard({required double width, required Task task, bool? moveChipsToTrailing}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: MediaQueryData(size: Size(width, 800)),
              child: TaskCardItem(
                task: task,
                moveChipsToTrailing: moveChipsToTrailing ?? true,
                onToggleExpand: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Subtasks badge follows focus card design with chevron icon and no subtasks label',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestCard(width: 1000, task: sampleTask));
    await tester.pumpAndSettle();

    // Check that '1/2' is shown and 'Subtasks' is NOT shown
    expect(find.text('1/2'), findsOneWidget);
    expect(find.textContaining('Subtasks'), findsNothing);

    // Check that chevron icon is present
    expect(find.byIcon(Symbols.expand_more_rounded), findsOneWidget);
  });

  testWidgets('Clock icon in due date chip is outline (fill: 0) and not filled',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestCard(width: 1000, task: sampleTask));
    await tester.pumpAndSettle();

    // Find the clock icon inside TaskDueDateChip
    final clockIconFinder = find.descendant(
      of: find.byType(TaskDueDateChip),
      matching: find.byType(Icon),
    );
    expect(clockIconFinder, findsOneWidget);
    final clockIcon = tester.widget<Icon>(clockIconFinder);
    expect(clockIcon.fill, 0.0);
  });

  testWidgets('Hovering over chips cancels task tile hover/focus state',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestCard(width: 1000, task: sampleTask));
    await tester.pumpAndSettle();

    final cardInkWellFinder = find.byType(InkWell).first;
    var inkWell = tester.widget<InkWell>(cardInkWellFinder);
    expect(inkWell.hoverColor, isNull);

    // Move pointer over the subtasks chip
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    final chipLocation = tester.getCenter(find.byType(TaskSubtasksBadge));
    await gesture.moveTo(chipLocation);
    await tester.pumpAndSettle();

    // While hovering over chips, card hoverColor should be transparent and canRequestFocus false
    inkWell = tester.widget<InkWell>(cardInkWellFinder);
    expect(inkWell.hoverColor, Colors.transparent);
    expect(inkWell.canRequestFocus, isFalse);

    // Move pointer away from chips to title
    final titleLocation = tester.getCenter(find.text(sampleTask.title));
    await gesture.moveTo(titleLocation);
    await tester.pumpAndSettle();

    // Hovering on title restores normal card hover
    inkWell = tester.widget<InkWell>(cardInkWellFinder);
    expect(inkWell.hoverColor, isNull);
    expect(inkWell.canRequestFocus, isTrue);
  });

  testWidgets('Compact screen (< 600dp) keeps chips below description and does not force title ellipsis',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestCard(width: 400, task: sampleTask));
    await tester.pumpAndSettle();

    final titleText = tester.widget<Text>(find.text(sampleTask.title));
    expect(titleText.maxLines, isNull);
    expect(titleText.overflow, isNull);

    // Both dueDate chip and subtask badge should be rendered
    expect(find.byType(TaskDueDateChip), findsOneWidget);
    expect(find.byType(TaskSubtasksBadge), findsOneWidget);

    // In compact mode, chips are inside a Wrap below description
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('Large screen (>= 840dp) moves chips to trailing and uses ellipsis on title',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestCard(width: 1000, task: sampleTask));
    await tester.pumpAndSettle();

    final titleText = tester.widget<Text>(find.text(sampleTask.title));
    expect(titleText.maxLines, 1);
    expect(titleText.overflow, TextOverflow.ellipsis);

    // In large screen mode, chips are in trailing, so the Wrap below description is not rendered
    expect(find.byType(Wrap), findsNothing);

    // Chips are rendered in trailing
    expect(find.byType(TaskDueDateChip), findsOneWidget);
    expect(find.byType(TaskSubtasksBadge), findsOneWidget);

    // Title and chips share the Header row
    final titleRect = tester.getRect(find.text(sampleTask.title));
    final chipRect = tester.getRect(find.byType(TaskDueDateChip));

    // Chip should be trailing (to the right of the title)
    expect(chipRect.left, greaterThan(titleRect.right));
  });
}
