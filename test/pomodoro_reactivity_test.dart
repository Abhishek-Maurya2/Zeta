import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/database/database_provider.dart';
import 'package:zeta/models/pomodoro.dart';
import 'package:zeta/pages/pomodoro/pomodoro_ambient_page.dart';
import 'package:zeta/pages/pomodoro/pomodoro_analysis_pane.dart';
import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.instance.init();
    await PreferencesService.instance.prefs.clear();
    try {
      final db = DatabaseProvider.instance.db;
      await db.delete(db.pomodoroSessionsTable).go();
    } catch (_) {}
  });

  testWidgets(
      'PomodoroAnalysisPane immediately updates chart goal line when goal is changed',
      (WidgetTester tester) async {
    final provider = PomodoroProvider();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Initially 60 min goal
    expect(provider.settings.dailyGoalMinutes, equals(60));

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<PomodoroProvider>.value(
          value: provider,
          child: const Material(
            child: PomodoroAnalysisPane(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify initial goal text exists (e.g., '1h' in chart/legend)
    expect(find.text('1h'), findsWidgets);

    // Update daily goal to 120 minutes (2h)
    provider.updateSettings(
      provider.settings.copyWith(dailyGoalMinutes: 120),
    );
    await tester.pump();

    // Immediately shows 2h without reopening or navigating
    expect(find.text('2h'), findsWidgets);

    provider.dispose();
  });

  testWidgets(
      'PomodoroAmbientPage immediately updates minutes on tickNotifier update without mouse movement',
      (WidgetTester tester) async {
    final provider = PomodoroProvider();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Start with 25 minutes = 1500 seconds
    provider.tickNotifier.value = 25 * 60;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<PomodoroProvider>.value(
          value: provider,
          child: const Material(
            child: PomodoroAmbientPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('25'), findsOneWidget);

    // Simulate countdown tick to 20 minutes (1200 seconds) without any mouse input
    provider.tickNotifier.value = 20 * 60;
    await tester.pump();

    expect(find.text('20'), findsOneWidget);

    // Simulate countdown tick to 5 minutes (300 seconds)
    provider.tickNotifier.value = 5 * 60;
    await tester.pump();

    expect(find.text('5'), findsOneWidget);

    provider.dispose();
  });
}
