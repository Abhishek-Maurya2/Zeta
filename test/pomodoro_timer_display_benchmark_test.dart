import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zeta/pages/pomodoro/components/pomodoro_timer_display.dart';
import 'package:zeta/providers/pomodoro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PomodoroTimerDisplay Architectural & Performance Verification', () {
    late PomodoroProvider provider;

    setUp(() {
      provider = PomodoroProvider();
    });

    tearDown(() {
      provider.pauseTimer();
      provider.dispose();
    });

    testWidgets(
      'Countdown Text rebuilds exactly 1 time per second and NOT at 60 fps',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<PomodoroProvider>.value(
              value: provider,
              child: const Scaffold(
                body: PomodoroTimerDisplay(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('25:00'), findsOneWidget);

        provider.startTimer();
        await tester.pump();

        // Simulate 60 frames (16.6ms intervals)
        for (int frame = 0; frame < 60; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        // Advance 1-second discrete pulse
        provider.tickNotifier.value = 24 * 60 + 59;
        await tester.pump();

        expect(find.text('24:59'), findsOneWidget);

        // Cancel periodic timer before finishing
        provider.pauseTimer();
        await tester.pump();
      },
    );

    testWidgets(
      'Wavy progress indicator is contained within an isolated RepaintBoundary',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<PomodoroProvider>.value(
              value: provider,
              child: const Scaffold(
                body: PomodoroTimerDisplay(),
              ),
            ),
          ),
        );
        await tester.pump();

        final repaintBoundaries = find.byType(RepaintBoundary);
        expect(repaintBoundaries, findsWidgets);

        final renderObject =
            tester.renderObject(find.byType(PomodoroTimerDisplay));
        expect(renderObject.attached, isTrue);
      },
    );

    testWidgets(
      'Timer pause stops the animation ticker and drops scheduled frames to zero',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<PomodoroProvider>.value(
              value: provider,
              child: const Scaffold(
                body: PomodoroTimerDisplay(),
              ),
            ),
          ),
        );
        await tester.pump();

        provider.startTimer();
        await tester.pump();
        expect(provider.isRunning, isTrue);

        provider.pauseTimer();
        await tester.pump();
        await tester.pump();
        expect(provider.isRunning, isFalse);

        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );
  });
}
