import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/components/task_card_item.dart';
import 'package:zeta/components/task_subtasks_list.dart';
import 'package:zeta/models/task.dart';

void main() {
  group('TaskCardItem Collapsible Subtasks Animation Tests', () {
    final subtasks = [
      Subtask(id: 's1', title: 'Subtask 1', completed: false),
      Subtask(id: 's2', title: 'Subtask 2', completed: true),
    ];

    final task = Task(
      id: 'task-1',
      title: 'Parent Task',
      subtasks: subtasks,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('Subtasks list is collapsed initially when isExpanded is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCardItem(
              task: task,
              isExpanded: false,
            ),
          ),
        ),
      );

      // Initially collapsed: sizeFactor is 0 and subtasks list is hidden
      final sizeTransitionFinder = find.byType(SizeTransition);
      expect(sizeTransitionFinder, findsNothing);
      expect(find.text('Subtask 1'), findsNothing);
    });

    testWidgets('Subtasks list animates open when isExpanded changes to true', (tester) async {
      bool isExpanded = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    TaskCardItem(
                      task: task,
                      isExpanded: isExpanded,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => isExpanded = !isExpanded),
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Subtask 1'), findsNothing);

      // Trigger expand
      await tester.tap(find.text('Toggle'));
      await tester.pump(); // Start animation

      // SizeTransition is now in tree animating
      final sizeTransitionFinder = find.byType(SizeTransition);
      expect(sizeTransitionFinder, findsOneWidget);

      // Mid-animation:
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(TaskSubtasksList), findsOneWidget);

      // Complete animation:
      await tester.pumpAndSettle();
      expect(find.text('Subtask 1'), findsOneWidget);
      expect(find.text('Subtask 2'), findsOneWidget);

      // Now toggle back to collapse
      await tester.tap(find.text('Toggle'));
      await tester.pump(); // Start collapse

      // Mid-collapse:
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(SizeTransition), findsOneWidget);

      // Fully settled:
      await tester.pumpAndSettle();
      expect(find.byType(SizeTransition), findsNothing);
      expect(find.text('Subtask 1'), findsNothing);
    });
  });
}
