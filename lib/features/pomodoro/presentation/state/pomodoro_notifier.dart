import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/pomodoro.dart';
import '../../../../utils/haptics.dart';
import '../../data/pomodoro_preferences.dart';
import '../../data/pomodoro_repository.dart';

@immutable
class PomodoroState {
  final PomodoroSettings settings;
  final List<PomodoroSessionItem> queue;
  final int activeQueueIndex;
  final int timeLeft;
  final int totalDuration;
  final bool isRunning;
  final DateTime? targetEndTime;
  final String activeTab;

  const PomodoroState({
    this.settings = const PomodoroSettings(),
    this.queue = const [],
    this.activeQueueIndex = 0,
    this.timeLeft = 25 * 60,
    this.totalDuration = 25 * 60,
    this.isRunning = false,
    this.targetEndTime,
    this.activeTab = 'timer',
  });

  PomodoroSessionItem? get currentSession =>
      queue.isNotEmpty && activeQueueIndex < queue.length
          ? queue[activeQueueIndex]
          : null;

  PomodoroMode get mode => currentSession?.mode ?? PomodoroMode.focus;

  double get progress => totalDuration <= 0
      ? 0.0
      : ((totalDuration - timeLeft) / totalDuration).clamp(0.0, 1.0);

  bool get isCountUp => settings.countUp;

  int get elapsedSeconds =>
      (totalDuration - timeLeft).clamp(0, totalDuration);

  int get displaySeconds => isCountUp ? elapsedSeconds : timeLeft;

  String get formattedTime {
    final timeToDisplay = displaySeconds;
    final mins = timeToDisplay ~/ 60;
    final secs = timeToDisplay % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  PomodoroState copyWith({
    PomodoroSettings? settings,
    List<PomodoroSessionItem>? queue,
    int? activeQueueIndex,
    int? timeLeft,
    int? totalDuration,
    bool? isRunning,
    DateTime? targetEndTime,
    bool clearTargetEndTime = false,
    String? activeTab,
  }) {
    return PomodoroState(
      settings: settings ?? this.settings,
      queue: queue ?? this.queue,
      activeQueueIndex: activeQueueIndex ?? this.activeQueueIndex,
      timeLeft: timeLeft ?? this.timeLeft,
      totalDuration: totalDuration ?? this.totalDuration,
      isRunning: isRunning ?? this.isRunning,
      targetEndTime:
          clearTargetEndTime ? null : (targetEndTime ?? this.targetEndTime),
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

/// Unified Riverpod state notifier for Pomodoro countdown and session state.
/// Implements exact wall-clock synchronization across background suspension and app lifecycle changes.
class PomodoroNotifier extends StateNotifier<PomodoroState>
    with WidgetsBindingObserver {
  final PomodoroPreferences _preferences;
  final PomodoroRepository _repository;

  Timer? _tickerTimer;
  DateTime _lastDiskSaveTime = DateTime(2000);

  PomodoroNotifier(this._preferences, this._repository)
      : super(const PomodoroState()) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _init();
  }

  void _init() {
    final settings = _preferences.getSettings();
    final queue = generateQueue(settings);
    final initialDuration =
        queue.isNotEmpty ? queue.first.durationMinutes * 60 : 25 * 60;

    state = state.copyWith(
      settings: settings,
      queue: queue,
      activeQueueIndex: 0,
      totalDuration: initialDuration,
      timeLeft: initialDuration,
    );

    _restoreFromStorage();
  }

  void _restoreFromStorage() {
    try {
      final savedState = _preferences.getSavedActiveState();
      if (savedState == null) return;

      final savedIndex = savedState['activeQueueIndex'] as int? ?? 0;
      final savedTimeLeft = savedState['timeLeft'] as int?;
      final savedTotalDuration = savedState['totalDuration'] as int?;
      final wasRunning = savedState['isRunning'] as bool? ?? false;
      final targetEndTimeMs = savedState['targetEndTime'] as int?;

      final validIndex =
          (savedIndex >= 0 && savedIndex < state.queue.length) ? savedIndex : 0;
      final item = state.queue[validIndex];
      final itemDuration = item.durationMinutes * 60;
      final total = (savedTotalDuration != null && savedTotalDuration > 0)
          ? savedTotalDuration
          : itemDuration;

      int resolvedTimeLeft =
          (savedTimeLeft != null && savedTimeLeft > 0 && savedTimeLeft <= total)
              ? savedTimeLeft
              : total;
      bool resolvedRunning = false;
      DateTime? resolvedTargetEndTime;

      // Exact wall-clock resume calculation
      if (targetEndTimeMs != null && wasRunning) {
        final target = DateTime.fromMillisecondsSinceEpoch(targetEndTimeMs);
        final now = DateTime.now();
        final remaining = target.difference(now).inSeconds;

        if (remaining <= 0) {
          resolvedTimeLeft = 0;
          resolvedRunning = false;
          resolvedTargetEndTime = null;
        } else {
          resolvedTimeLeft = remaining;
          resolvedRunning = true;
          resolvedTargetEndTime = target;
        }
      }

      state = state.copyWith(
        activeQueueIndex: validIndex,
        totalDuration: total,
        timeLeft: resolvedTimeLeft,
        isRunning: resolvedRunning,
        targetEndTime: resolvedTargetEndTime,
      );

      if (resolvedRunning && resolvedTargetEndTime != null) {
        _startTicker();
      } else if (targetEndTimeMs != null && wasRunning && resolvedTimeLeft <= 0) {
        _handleSessionComplete();
      }
    } catch (e) {
      debugPrint('[PomodoroNotifier] Failed to restore active state: $e');
    }
  }

  /// App lifecycle listener for exact background resume synchronization.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      syncWallClock();
    } else if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.detached ||
        lifecycleState == AppLifecycleState.hidden) {
      _persistActiveState();
    }
  }

  /// Synchronize timer with real wall-clock time after background wake or sleep.
  void syncWallClock() {
    if (!state.isRunning || state.targetEndTime == null) return;
    final now = DateTime.now();
    final remaining = state.targetEndTime!.difference(now).inSeconds;

    if (remaining <= 0) {
      state = state.copyWith(
        timeLeft: 0,
        isRunning: false,
        clearTargetEndTime: true,
      );
      _tickerTimer?.cancel();
      _handleSessionComplete();
    } else {
      state = state.copyWith(timeLeft: remaining);
      // Restart ticker to cleanly align with current wall-clock seconds
      _startTicker();
    }
  }

  void startTimer() {
    if (state.isRunning) return;
    final target = DateTime.now().add(Duration(seconds: state.timeLeft));
    state = state.copyWith(
      isRunning: true,
      targetEndTime: target,
    );
    _startTicker();
    _persistActiveState();
  }

  void pauseTimer() {
    if (!state.isRunning) return;
    int remaining = state.timeLeft;
    if (state.targetEndTime != null) {
      remaining = state.targetEndTime!
          .difference(DateTime.now())
          .inSeconds
          .clamp(0, state.totalDuration);
    }
    _tickerTimer?.cancel();
    _tickerTimer = null;
    state = state.copyWith(
      isRunning: false,
      timeLeft: remaining,
      clearTargetEndTime: true,
    );
    _persistActiveState();
  }

  void toggleTimer() {
    if (state.isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void resetTimer() {
    _recordPartialSessionIfEligible();
    pauseTimer();
    _syncCurrentQueueItem();
    _persistActiveState();
  }

  void skipSession() {
    _recordPartialSessionIfEligible();
    pauseTimer();
    _advanceQueue(userInitiated: true);
  }

  void jumpToSession(int index) {
    if (index < 0 ||
        index >= state.queue.length ||
        index == state.activeQueueIndex) {
      return;
    }
    _recordPartialSessionIfEligible();
    pauseTimer();
    final item = state.queue[index];
    final duration = item.durationMinutes * 60;
    state = state.copyWith(
      activeQueueIndex: index,
      totalDuration: duration,
      timeLeft: duration,
    );
    _persistActiveState();
  }

  void setActiveTab(String tab) {
    if (state.activeTab != tab) {
      state = state.copyWith(activeTab: tab);
    }
  }

  void updateSettings(PomodoroSettings newSettings) {
    _preferences.saveSettings(newSettings);
    final newQueue = generateQueue(newSettings);
    final currentItem = state.currentSession;
    int newIndex = 0;
    if (currentItem != null) {
      final found = newQueue.indexWhere((q) => q.id == currentItem.id);
      if (found != -1) newIndex = found;
    }
    final itemDuration = newQueue[newIndex].durationMinutes * 60;
    state = state.copyWith(
      settings: newSettings,
      queue: newQueue,
      activeQueueIndex: newIndex,
      totalDuration: itemDuration,
      timeLeft: state.isRunning ? state.timeLeft : itemDuration,
    );
    _persistActiveState();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.isRunning || state.targetEndTime == null) return;
    final now = DateTime.now();
    final remaining = state.targetEndTime!.difference(now).inSeconds;

    if (remaining <= 0) {
      _tickerTimer?.cancel();
      _tickerTimer = null;
      state = state.copyWith(
        timeLeft: 0,
        isRunning: false,
        clearTargetEndTime: true,
      );
      _handleSessionComplete();
    } else {
      if (state.timeLeft != remaining) {
        state = state.copyWith(timeLeft: remaining);
        if (now.difference(_lastDiskSaveTime).inSeconds >= 50) {
          _lastDiskSaveTime = now;
          _persistActiveState();
        }
      }
    }
  }

  void _handleSessionComplete() {
    if (state.settings.soundNotification) {
      SystemSound.play(SystemSoundType.alert);
    }
    ZetaHaptics.heavy();

    final item = state.currentSession;
    if (item != null) {
      final log = PomodoroSessionLog(
        id: '${DateTime.now().millisecondsSinceEpoch}-${item.id}',
        mode: item.mode,
        minutes: item.durationMinutes,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _repository.logSession(log);
    }

    final nextIndex = (state.activeQueueIndex + 1) % state.queue.length;
    final nextItem = state.queue[nextIndex];
    final shouldAutoStart = nextItem.mode == PomodoroMode.focus
        ? state.settings.autoStartFocus
        : state.settings.autoStartBreaks;

    _advanceQueue(autoStart: shouldAutoStart);
  }

  void _advanceQueue({bool userInitiated = false, bool autoStart = false}) {
    if (state.queue.isEmpty) return;

    var nextIndex = state.activeQueueIndex + 1;
    var queue = state.queue;
    if (nextIndex >= queue.length) {
      queue = generateQueue(state.settings);
      nextIndex = 0;
    }

    final item = queue[nextIndex];
    final duration = item.durationMinutes * 60;

    state = state.copyWith(
      queue: queue,
      activeQueueIndex: nextIndex,
      totalDuration: duration,
      timeLeft: duration,
      clearTargetEndTime: true,
    );

    _persistActiveState();

    if (autoStart && !userInitiated) {
      startTimer();
    }
  }

  void _syncCurrentQueueItem() {
    if (state.queue.isEmpty) return;
    final index = state.activeQueueIndex.clamp(0, state.queue.length - 1);
    final item = state.queue[index];
    final duration = item.durationMinutes * 60;
    state = state.copyWith(
      activeQueueIndex: index,
      totalDuration: duration,
      timeLeft: duration,
      clearTargetEndTime: true,
    );
  }

  void _recordPartialSessionIfEligible() {
    final elapsedSeconds = state.totalDuration - state.timeLeft;
    if (elapsedSeconds < 60) return;
    final elapsedMinutes = (elapsedSeconds / 60).round();
    if (elapsedMinutes < 1) return;

    final log = PomodoroSessionLog(
      id: '${DateTime.now().millisecondsSinceEpoch}-partial',
      mode: state.mode,
      minutes: elapsedMinutes,
      completedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _repository.logSession(log);
  }

  void _persistActiveState() {
    final now = DateTime.now();
    final remaining = (state.isRunning && state.targetEndTime != null)
        ? state.targetEndTime!
            .difference(now)
            .inSeconds
            .clamp(0, state.totalDuration)
        : state.timeLeft;

    final data = <String, dynamic>{
      'activeQueueIndex': state.activeQueueIndex,
      'timeLeft': remaining,
      'totalDuration': state.totalDuration,
      'mode': state.mode.toJsonString(),
      'isRunning': state.isRunning,
      'savedAt': now.millisecondsSinceEpoch,
      if (state.targetEndTime != null)
        'targetEndTime': state.targetEndTime!.millisecondsSinceEpoch,
    };
    _preferences.saveActiveState(data);
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }
}
