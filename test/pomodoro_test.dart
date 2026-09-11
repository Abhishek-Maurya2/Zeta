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
}
