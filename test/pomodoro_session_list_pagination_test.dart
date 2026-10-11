import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/models/pomodoro.dart';
import 'package:zeta/pages/pomodoro/components/pomodoro_session_list.dart';
import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.instance.init();
  });

  testWidgets('PomodoroSessionList paginates by 5 entire days at once', (
    tester,
  ) async {
    final provider = PomodoroProvider();
    // Allow provider._init() to complete
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Create sessions across 7 distinct days
    final now = DateTime.now();
    final logs = <PomodoroSessionLog>[];

    for (int dayOffset = 6; dayOffset >= 0; dayOffset--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: dayOffset));
      // Add 3 sessions per day
      for (int s = 0; s < 3; s++) {
        final sessionTime = day.add(Duration(hours: 9 + s * 2));
        logs.add(
          PomodoroSessionLog(
            id: 'test-$dayOffset-$s',
            completedAt: sessionTime.millisecondsSinceEpoch,
            minutes: 25,
            mode: PomodoroMode.focus,
          ),
        );
      }
    }

    // Populate logs on provider
    provider.sessionLog.clear();
    provider.sessionLog.addAll(logs);

    await tester.pumpWidget(
      ChangeNotifierProvider<PomodoroProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PomodoroSessionList()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Out of 7 days, initially exactly 5 days should be displayed
    expect(find.byType(M3EList), findsWidgets);

    // The load icon button should be present because 7 days > 5 days
    final loadButton = find.ancestor(
      of: find.byIcon(Icons.expand_more_rounded),
      matching: find.byType(M3EIconButton),
    );
    expect(loadButton, findsOneWidget);

    // Tap the load more icon button to load next 5 days (which covers the remaining 2 days)
    await tester.tap(loadButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // After loading all 7 days, the load more icon button should disappear
    final remainingLoadButton = find.ancestor(
      of: find.byIcon(Icons.expand_more_rounded),
      matching: find.byType(M3EIconButton),
    );
    expect(remainingLoadButton, findsNothing);

    provider.dispose();
  });
}
