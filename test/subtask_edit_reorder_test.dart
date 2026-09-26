import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/components/task_edit_pane.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/services/preferences_service.dart';
import 'package:zeta/services/cross_device_service.dart';

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

  Widget buildTestWidget({required List<Subtask> initialSubtasks}) {
    final taskProvider = TaskProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Material(
            child: TaskEditFormContent(
              initialTitle: 'Test Task',
              initialSubtasks: initialSubtasks,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'renders subtasks with edit buttons and touch-and-hold drag listeners without drag indicator icons',
      (tester) async {
    final subtasks = [
      Subtask(id: 'st-1', title: 'First Subtask'),
      Subtask(id: 'st-2', title: 'Second Subtask'),
    ];

    await tester.pumpWidget(buildTestWidget(initialSubtasks: subtasks));
    await tester.pumpAndSettle();

    expect(find.text('First Subtask'), findsOneWidget);
    expect(find.text('Second Subtask'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    // No drag indicator icons anywhere on the tiles
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
    // Drag listeners are attached to each tile
    expect(
      find.byType(SubtaskReorderListener),
      findsNWidgets(2),
    );

    CrossDeviceService.instance.dispose();
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('allows editing subtask title inline', (tester) async {
    final subtasks = [
      Subtask(id: 'st-1', title: 'Initial Name'),
    ];

    await tester.pumpWidget(buildTestWidget(initialSubtasks: subtasks));
    await tester.pumpAndSettle();

    // Tap edit button on the subtask
    await tester.tap(find.byTooltip('Edit subtask'));
    await tester.pumpAndSettle();

    // Confirm TextField appears with the initial text
    expect(find.byType(TextField), findsWidgets);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Enter new title
    final subtaskTextField = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byType(TextField),
    );
    await tester.enterText(subtaskTextField, 'Renamed Subtask');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Subtask should display updated title
    expect(find.text('Renamed Subtask'), findsOneWidget);
    expect(find.text('Initial Name'), findsNothing);

    CrossDeviceService.instance.dispose();
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('allows reordering subtasks with touch and hold drag', (tester) async {
    final subtasks = [
      Subtask(id: 'st-1', title: 'Alpha Subtask'),
      Subtask(id: 'st-2', title: 'Beta Subtask'),
    ];

    await tester.pumpWidget(buildTestWidget(initialSubtasks: subtasks));
    await tester.pumpAndSettle();

    final state =
        tester.state<TaskEditFormContentState>(find.byType(TaskEditFormContent));
    state.reorderSubtaskForTesting(0, 1);
    await tester.pumpAndSettle();

    // Verify order in widget tree: Beta Subtask now comes before Alpha Subtask
    final alphaFinder = find.text('Alpha Subtask');
    final betaFinder = find.text('Beta Subtask');
    expect(
      tester.getTopLeft(betaFinder).dy < tester.getTopLeft(alphaFinder).dy,
      isTrue,
    );

    CrossDeviceService.instance.dispose();
    await tester.pump(const Duration(minutes: 5));
  });
}
