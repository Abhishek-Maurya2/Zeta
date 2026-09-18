import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/components/common/standard_chips.dart';

void main() {
  group('StandardChips Widget Tests', () {
    testWidgets('TaskDueDateChip renders calendar icon and formatted date', (tester) async {
      final task = Task(
        id: '1',
        title: 'Review PR',
        dueDate: 'Tomorrow',
        hasTime: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDueDateChip(task: task),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('TaskDueDateChip renders schedule icon when due today with time', (tester) async {
      final task = Task(
        id: '2',
        title: 'Standup',
        dueDate: 'Today',
        hasTime: true,
        dueTime: '11:00 AM',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDueDateChip(task: task),
          ),
        ),
      );

      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);
    });

    testWidgets('TaskDeletedDateChip renders correctly', (tester) async {
      final date = DateTime(2026, 9, 14, 14, 30);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskDeletedDateChip(timestamp: date),
          ),
        ),
      );

      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.text('Deleted 14, Sep at 14:30'), findsOneWidget);
    });

    testWidgets('StreakStatusChip renders active and ready states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StreakStatusChip(hasActiveStreak: true),
                StreakStatusChip(hasActiveStreak: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsNWidgets(2));
    });

    testWidgets('StreakPeriodChip renders calendar icon and range label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakPeriodChip(rangeLabel: 'Sep 10 – 16'),
          ),
        ),
      );

      expect(find.text('Streak Period:'), findsOneWidget);
      expect(find.text('Sep 10 – 16'), findsOneWidget);
      expect(find.byIcon(Icons.date_range_rounded), findsOneWidget);
    });

    testWidgets('FocusTaskDueDateChip renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FocusTaskDueDateChip(
              dueFormatted: 'Today • 4:00 PM',
              hasTime: true,
            ),
          ),
        ),
      );

      expect(find.text('Today • 4:00 PM'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    test('RevisionTagInfo strips tag and extracts stage info', () {
      final info1 = RevisionTagInfo.parse('#Revision  •  Stage 2 Spaced Repetition');
      expect(info1.isRevision, isTrue);
      expect(info1.label, equals('Revision • Stage 2'));
      expect(info1.cleanedDescription, isNull);

      final info2 = RevisionTagInfo.parse('#Revision Revise emergency provisions');
      expect(info2.isRevision, isTrue);
      expect(info2.label, equals('Revision'));
      expect(info2.cleanedDescription, equals('Revise emergency provisions'));

      final info3 = RevisionTagInfo.parse('Regular notes without tag');
      expect(info3.isRevision, isFalse);
      expect(info3.cleanedDescription, equals('Regular notes without tag'));
    });

    testWidgets('TaskRevisionChip renders icon and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TaskRevisionChip(label: 'Revision • Stage 3'),
          ),
        ),
      );

      expect(find.text('Revision • Stage 3'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    });
  });
}
