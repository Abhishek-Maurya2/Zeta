import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/pomodoro.dart';
import '../../data/pomodoro_preferences.dart';
import '../../data/pomodoro_repository.dart';
import 'pomodoro_notifier.dart';

export 'pomodoro_notifier.dart';

/// Riverpod provider for the Pomodoro StateNotifier.
final pomodoroNotifierProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  final prefs = ref.watch(pomodoroPreferencesProvider);
  final repo = ref.watch(pomodoroRepositoryProvider);
  return PomodoroNotifier(prefs, repo);
});

/// Riverpod stream provider for reactive SQLite session history.
final pomodoroRecentSessionsProvider =
    StreamProvider.autoDispose<List<PomodoroSessionLog>>((ref) {
  final repo = ref.watch(pomodoroRepositoryProvider);
  return repo.watchRecentSessions();
});

/// Riverpod selector for time left in seconds.
final pomodoroTimeLeftProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(pomodoroNotifierProvider.select((s) => s.timeLeft));
});

/// Riverpod selector for formatted countdown string.
final pomodoroFormattedTimeProvider = Provider.autoDispose<String>((ref) {
  return ref.watch(pomodoroNotifierProvider.select((s) => s.formattedTime));
});

/// Riverpod selector for progress (0.0 to 1.0).
final pomodoroProgressProvider = Provider.autoDispose<double>((ref) {
  return ref.watch(pomodoroNotifierProvider.select((s) => s.progress));
});

/// Riverpod selector for running state.
final pomodoroIsRunningProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(pomodoroNotifierProvider.select((s) => s.isRunning));
});

/// Riverpod selector for active Pomodoro mode.
final pomodoroModeProvider = Provider.autoDispose<PomodoroMode>((ref) {
  return ref.watch(pomodoroNotifierProvider.select((s) => s.mode));
});
