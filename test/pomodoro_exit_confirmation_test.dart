import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zeta/pages/pomodoro/components/pomodoro_exit_dialog.dart';
import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/services/app_exit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pomodoro Exit Confirmation Tests', () {
    testWidgets('confirmExitIfPomodoroRunning returns true when timer is not running', (tester) async {
      final pomodoroProvider = PomodoroProvider();

      bool? result;
      await tester.pumpWidget(
        ChangeNotifierProvider<PomodoroProvider>.value(
          value: pomodoroProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await confirmExitIfPomodoroRunning(context);
                  },
                  child: const Text('Check Exit'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Exit'));
      await tester.pumpAndSettle();

      // No dialog shown because timer is not running
      expect(find.text('Session in Progress'), findsNothing);
      expect(result, isTrue);

      pomodoroProvider.dispose();
    });

    testWidgets('confirmExitIfPomodoroRunning shows dialog and cancels exit', (tester) async {
      final pomodoroProvider = PomodoroProvider();
      pomodoroProvider.startTimer();
      expect(pomodoroProvider.isRunning, isTrue);

      bool? result;
      await tester.pumpWidget(
        ChangeNotifierProvider<PomodoroProvider>.value(
          value: pomodoroProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await confirmExitIfPomodoroRunning(context);
                  },
                  child: const Text('Check Exit'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Exit'));
      await tester.pumpAndSettle();

      // Dialog is shown
      expect(find.text('Session in Progress'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit Session'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('Session in Progress'), findsNothing);

      pomodoroProvider.dispose();
    });

    testWidgets('confirmExitIfPomodoroRunning confirms exit and pauses timer', (tester) async {
      final pomodoroProvider = PomodoroProvider();
      pomodoroProvider.startTimer();
      expect(pomodoroProvider.isRunning, isTrue);

      bool? result;
      await tester.pumpWidget(
        ChangeNotifierProvider<PomodoroProvider>.value(
          value: pomodoroProvider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await confirmExitIfPomodoroRunning(context);
                  },
                  child: const Text('Check Exit'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Exit'));
      await tester.pumpAndSettle();

      // Dialog is shown
      expect(find.text('Session in Progress'), findsOneWidget);

      // Tap Exit Session
      await tester.tap(find.text('Exit Session'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(pomodoroProvider.isRunning, isFalse);

      pomodoroProvider.dispose();
    });

    test('AppExitService detects running state via custom checker', () {
      final exitService = AppExitService.instance;
      exitService.init();

      bool fakeRunning = false;
      exitService.setCustomRunningChecker(() => fakeRunning);

      expect(exitService.isPomodoroRunning, isFalse);

      fakeRunning = true;
      expect(exitService.isPomodoroRunning, isTrue);

      exitService.setCustomRunningChecker(null);
    });
  });
}
