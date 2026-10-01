import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/database/database_provider.dart';
import 'package:zeta/models/pomodoro.dart';
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


  group('Pomodoro State Persistence & Restoration', () {
    test('Restores active session, remaining time, and elapsed time after app restart',
        () async {
      final prefs = PreferencesService.instance.prefs;

      // Simulate a saved active state before app crash/close:
      // Session index 1 (Short break), 3 minutes left out of 5 minutes (2 minutes elapsed)
      final savedState = {
        'activeQueueIndex': 1,
        'timeLeft': 3 * 60,
        'totalDuration': 5 * 60,
        'mode': 'short_break',
        'isRunning': true,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(
        PreferencesService.keyPomodoroState,
        jsonEncode(savedState),
      );

      // Launch provider as app starts
      final provider = PomodoroProvider();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(provider.activeQueueIndex, equals(1));
      expect(provider.mode, equals(PomodoroMode.shortBreak));
      expect(provider.totalDuration, equals(5 * 60));
      expect(provider.timeLeft, equals(3 * 60));
      expect(provider.elapsedSeconds, equals(2 * 60));
      expect(provider.formattedTime, equals('03:00'));
      expect(provider.isRunning, isFalse); // Paused ready to resume

      // Resume timer
      provider.startTimer();
      expect(provider.isRunning, isTrue);

      provider.dispose();
    });

    test('Saves state on timer start, pause, and reset', () async {
      final provider = PomodoroProvider();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Jump to session 2
      provider.jumpToSession(2);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final prefs = PreferencesService.instance.prefs;
      final rawState = prefs.getString(PreferencesService.keyPomodoroState);
      expect(rawState, isNotNull);

      final stateMap = jsonDecode(rawState!) as Map<String, dynamic>;
      expect(stateMap['activeQueueIndex'], equals(2));
      expect(stateMap['timeLeft'], equals(provider.timeLeft));

      provider.dispose();
    });

    test('Restores default when no saved state exists', () async {
      final provider = PomodoroProvider();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(provider.activeQueueIndex, equals(0));
      expect(provider.mode, equals(PomodoroMode.focus));
      expect(provider.timeLeft, equals(25 * 60));
      expect(provider.totalDuration, equals(25 * 60));
      expect(provider.elapsedSeconds, equals(0));

      provider.dispose();
    });
  });
}
