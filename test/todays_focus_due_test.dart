import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/pages/home/components/todays_focus_card.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/providers/task_provider.dart';

class MockTaskProvider extends ChangeNotifier implements TaskProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TodaysFocusCard displays OVERDUE badge when task due date is past',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final overdueTask = Task(
      id: 'task-1',
      title: 'Review PR',
      dueDate:
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
      completed: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<TaskProvider>.value(
          value: MockTaskProvider(),
          child: Material(
            child: SingleChildScrollView(
              child: TodaysFocusCard(
                task: overdueTask,
                selectedDate: now,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('Review PR'), findsOneWidget);
  });

  testWidgets('TodaysFocusCard displays DUE TODAY badge when task is due today',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final todayTask = Task(
      id: 'task-2',
      title: 'Submit Expense Report',
      dueDate:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      completed: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<TaskProvider>.value(
          value: MockTaskProvider(),
          child: Material(
            child: SingleChildScrollView(
              child: TodaysFocusCard(
                task: todayTask,
                selectedDate: now,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('DUE TODAY'), findsOneWidget);
    expect(find.text('Submit Expense Report'), findsOneWidget);
  });

  testWidgets('TodaysFocusCard displays SCHEDULED badge when task is due in the future',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final futureTask = Task(
      id: 'task-3',
      title: 'Plan Sprint',
      dueDate:
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}',
      completed: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<TaskProvider>.value(
          value: MockTaskProvider(),
          child: Material(
            child: SingleChildScrollView(
              child: TodaysFocusCard(
                task: futureTask,
                selectedDate: now,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(find.text('Plan Sprint'), findsOneWidget);
  });
}
