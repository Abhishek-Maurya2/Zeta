import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/providers/theme_provider.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/pages/pomodoro_page.dart';
import 'package:zeta/components/pomodoro/pomodoro_timer_pane.dart';
import 'package:zeta/components/pomodoro/pomodoro_queue_pane.dart';
import 'package:zeta/components/pomodoro/pomodoro_analysis_pane.dart';
import 'package:zeta/components/pomodoro/pomodoro_settings_sheet.dart';
import 'package:zeta/components/pomodoro/m3_pane_divider.dart';
import 'package:zeta/widgets/segmented_column.dart';
import 'package:zeta/pages/pomodoro_ambient_page.dart';
import 'package:zeta/services/ambient_mode_service.dart';
import 'package:flutter/services.dart';

Widget createPomodoroTestWidget({
  PomodoroProvider? pomodoroProvider,
  Size size = const Size(1200, 900),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ChangeNotifierProvider(create: (_) => TaskProvider()),
      ChangeNotifierProvider(
        create: (_) => pomodoroProvider ?? PomodoroProvider(),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const Scaffold(
          body: PomodoroPage(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PomodoroPage renders split pane on wide screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createPomodoroTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Timer pane is present
    expect(find.byType(PomodoroTimerPane), findsOneWidget);
    // Verify Up next queue pane is present on the right
    expect(find.byType(PomodoroQueuePane), findsOneWidget);
    // Verify initial time 25:00 is displayed
    expect(find.text('25:00'), findsAtLeastNWidgets(1));
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('Focus'), findsAtLeastNWidgets(1));
  });

  testWidgets('Timer toggles between running and paused',
      (WidgetTester tester) async {
    final provider = PomodoroProvider();

    await tester.pumpWidget(
      createPomodoroTestWidget(pomodoroProvider: provider),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(provider.isRunning, isFalse);

    // Tap the play button in the timer pane
    final playBtn = find.descendant(
      of: find.byType(PomodoroTimerPane),
      matching: find.byIcon(Icons.play_arrow_rounded),
    );
    expect(playBtn, findsOneWidget);
    await tester.tap(playBtn);
    await tester.pump();

    expect(provider.isRunning, isTrue);
    expect(find.text('RUNNING'), findsOneWidget);

    // Tap pause button
    final pauseBtn = find.descendant(
      of: find.byType(PomodoroTimerPane),
      matching: find.byIcon(Icons.pause_rounded),
    );
    expect(pauseBtn, findsOneWidget);
    await tester.tap(pauseBtn);
    await tester.pump();

    expect(provider.isRunning, isFalse);
    expect(find.text('PAUSED'), findsOneWidget);
  });

  testWidgets('Secondary pane switches to Analysis tab',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createPomodoroTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Find and tap Analysis in toolbar
    final analysisBtn = find.text('Analysis').first;
    await tester.tap(analysisBtn);
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Analysis pane is displayed
    expect(find.byType(PomodoroAnalysisPane), findsOneWidget);
    expect(find.text('Total Focus'), findsOneWidget);
    expect(find.text('Sessions Done'), findsOneWidget);
    expect(find.text('Goal Hit'), findsOneWidget);
  });

  testWidgets('PomodoroSettingsSheet opens and updates cycle durations',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = PomodoroProvider();

    await tester.pumpWidget(
      createPomodoroTestWidget(pomodoroProvider: provider),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Configure
    final configureBtn = find.text('Configure').first;
    await tester.tap(configureBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify settings sheet opened
    expect(find.byType(PomodoroSettingsSheet), findsOneWidget);
    expect(find.text('Pomodoro Settings'), findsOneWidget);
    expect(find.text('Focus Duration'), findsOneWidget);

    // Tap 30m chip
    final chip30 = find.text('30m').first;
    await tester.tap(chip30);
    await tester.pump(const Duration(milliseconds: 100));

    expect(provider.settings.focusDuration, equals(30));
  });

  testWidgets('M3PaneDivider is rendered on wide screen and can be dragged to resize',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createPomodoroTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify M3PaneDivider is rendered
    final divider = find.byType(M3PaneDivider);
    expect(divider, findsOneWidget);

    final initialRightPaneWidth = tester.getSize(find.byType(PomodoroQueuePane)).width;

    // Drag divider to the left (delta: -60px) to widen the right pane
    await tester.drag(divider, const Offset(-60, 0));
    await tester.pump(const Duration(milliseconds: 100));

    final widenedRightPaneWidth = tester.getSize(find.byType(PomodoroQueuePane)).width;
    expect(widenedRightPaneWidth, greaterThan(initialRightPaneWidth));

    // Double tap the divider to trigger M3 canonical reset / toggle
    await tester.tap(divider);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(divider);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Supporting pane can be collapsed and expanded',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createPomodoroTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PomodoroQueuePane), findsOneWidget);

    // Find collapse button
    final collapseBtn = find.byTooltip('Collapse supporting pane');
    expect(collapseBtn, findsOneWidget);
    await tester.tap(collapseBtn);
    await tester.pump(const Duration(milliseconds: 100));

    // Supporting pane should now be collapsed
    expect(find.byType(PomodoroQueuePane), findsNothing);

    // Expand affordance should be visible
    final expandBtn = find.byTooltip('Expand Up next pane');
    expect(expandBtn, findsOneWidget);

    // Tap expand affordance to restore
    await tester.tap(expandBtn);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PomodoroQueuePane), findsOneWidget);
  });

  testWidgets(
      'PomodoroAnalysisPane displays centered range selector [D, W, M, 3M, Y] and standard navigation button group',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createPomodoroTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to Analysis pane
    final analysisBtn = find.text('Analysis').first;
    await tester.tap(analysisBtn);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PomodoroAnalysisPane), findsOneWidget);

    // Verify all range options exist
    expect(find.text('D'), findsAtLeastNWidgets(1));
    expect(find.text('W'), findsAtLeastNWidgets(1));
    expect(find.text('M'), findsAtLeastNWidgets(1));
    expect(find.text('3M'), findsAtLeastNWidgets(1));
    expect(find.text('Y'), findsAtLeastNWidgets(1));

    // Verify navigation buttons exist
    expect(find.byTooltip('Previous period'), findsOneWidget);
    expect(find.byTooltip('Next period'), findsOneWidget);
    expect(find.byTooltip('Jump to current'), findsOneWidget);

    // Tap 3M
    await tester.tap(find.text('3M').first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Past 3 months'), findsOneWidget);

    // Tap Y
    await tester.tap(find.text('Y').first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('This year'), findsOneWidget);

    // Tap Previous period
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pump(const Duration(milliseconds: 100));
    final currentYear = DateTime.now().year;
    expect(find.text('${currentYear - 1}'), findsOneWidget);

    // Tap Jump to current
    await tester.tap(find.byTooltip('Jump to current'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('This year'), findsOneWidget);
  });

  testWidgets(
      'PomodoroAnalysisPane displays Recent Sessions in segmented list matching queue pane',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());


    final provider = PomodoroProvider();

    await tester.pumpWidget(
      createPomodoroTestWidget(pomodoroProvider: provider),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Switch to Analysis pane
    final analysisBtn = find.text('Analysis').first;
    await tester.tap(analysisBtn);
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Analysis pane is displayed with Recent Sessions header
    expect(find.byType(PomodoroAnalysisPane), findsOneWidget);
    expect(find.text('Recent Sessions'), findsOneWidget);

    // Verify M3ESegmentedColumn is rendered inside PomodoroAnalysisPane
    final analysisSegmentedColumn = find.descendant(
      of: find.byType(PomodoroAnalysisPane),
      matching: find.byType(M3ESegmentedColumn),
    );
    expect(analysisSegmentedColumn, findsOneWidget);

    final segmentedWidget =
        tester.widget<M3ESegmentedColumn>(analysisSegmentedColumn);
    expect(
      segmentedWidget.padding,
      equals(const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
    );
    expect(segmentedWidget.children.isNotEmpty, isTrue);

    // Verify empty state when logs are cleared
    provider.clearSessionLog();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No sessions recorded yet'), findsOneWidget);
  });

  testWidgets(
      'PomodoroAmbientPage opens on fullscreen button tap, takes over screen, and enables wakelock/ambient mode',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = PomodoroProvider();

    await tester.pumpWidget(
      createPomodoroTestWidget(pomodoroProvider: provider),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(AmbientModeService.isActive, isFalse);

    // Find and tap the Always-on display (fullscreen) button in PomodoroTimerPane
    final aodBtn = find.byTooltip('Always-on display');
    expect(aodBtn, findsOneWidget);
    await tester.tap(aodBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify PomodoroAmbientPage is rendered as a top-level route
    expect(find.byType(PomodoroAmbientPage), findsOneWidget);
    expect(AmbientModeService.isActive, isTrue);

    // Verify ambient mode displays formatted time, mode badge, and status
    expect(find.text('25:00'), findsAtLeastNWidgets(1));
    expect(find.text('FOCUS'), findsOneWidget);
    expect(find.text('RUNNING'), findsOneWidget);
    expect(provider.isRunning, isTrue);

    // Verify exit button is present and tap it to exit
    final exitBtn = find.byTooltip('Exit full screen (Esc)');
    expect(exitBtn, findsOneWidget);
    await tester.tap(exitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Verify ambient mode exited, wakelock disabled, and returned to PomodoroPage
    expect(find.byType(PomodoroAmbientPage), findsNothing);
    expect(AmbientModeService.isActive, isFalse);
    expect(find.byType(PomodoroPage), findsOneWidget);
  });

  testWidgets(
      'PomodoroAmbientPage interactions: screen tap toggles pause/resume and Esc key exits',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = PomodoroProvider();

    await tester.pumpWidget(
      createPomodoroTestWidget(pomodoroProvider: provider),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final aodBtn = find.byTooltip('Always-on display');
    await tester.tap(aodBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PomodoroAmbientPage), findsOneWidget);
    expect(provider.isRunning, isTrue);

    // Tap screen to pause
    await tester.tap(find.byType(PomodoroAmbientPage));
    await tester.pump();
    expect(provider.isRunning, isFalse);
    expect(find.text('PAUSED'), findsOneWidget);

    // Tap screen again to resume
    await tester.tap(find.byType(PomodoroAmbientPage));
    await tester.pump();
    expect(provider.isRunning, isTrue);
    expect(find.text('RUNNING'), findsOneWidget);

    // Press Escape key to exit fullscreen
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byType(PomodoroAmbientPage), findsNothing);
    expect(AmbientModeService.isActive, isFalse);
  });
}
