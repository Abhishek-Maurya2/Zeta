import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro.dart';
import '../utils/haptics.dart';

class PomodoroProvider extends ChangeNotifier {
  static const String _settingsKey = 'zeta_pomodoro_settings_v1';
  static const String _sessionLogKey = 'zeta_pomodoro_session_log_v1';
  static const int _maxLogEntries = 1000;

  PomodoroSettings _settings = const PomodoroSettings();
  List<PomodoroSessionItem> _queue = [];
  int _activeQueueIndex = 0;
  int _timeLeft = 25 * 60; // in seconds
  int _totalDuration = 25 * 60; // in seconds
  bool _isRunning = false;
  List<PomodoroSessionLog> _sessionLog = generateSampleSessionLogs();

  Timer? _timer;

  PomodoroProvider() {
    _init();
  }

  // ─── Getters ───────────────────────────────────────────────────────────────
  PomodoroSettings get settings => _settings;
  List<PomodoroSessionItem> get queue => _queue;
  int get activeQueueIndex => _activeQueueIndex;
  int get timeLeft => _timeLeft;
  int get totalDuration => _totalDuration;
  bool get isRunning => _isRunning;
  List<PomodoroSessionLog> get sessionLog => _sessionLog;

  PomodoroSessionItem? get currentSession =>
      _queue.isNotEmpty && _activeQueueIndex < _queue.length
          ? _queue[_activeQueueIndex]
          : null;

  PomodoroMode get mode =>
      currentSession?.mode ?? PomodoroMode.focus;

  double get progress {
    if (_totalDuration <= 0) return 0.0;
    final elapsed = _totalDuration - _timeLeft;
    return (elapsed / _totalDuration).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final mins = _timeLeft ~/ 60;
    final secs = _timeLeft % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ─── Initialization ────────────────────────────────────────────────────────
  Future<void> _init() async {
    _queue = generateQueue(_settings);
    _syncWithCurrentQueueItem();
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Settings
      final settingsRaw = prefs.getString(_settingsKey);
      if (settingsRaw != null) {
        final map = jsonDecode(settingsRaw) as Map<String, dynamic>;
        _settings = PomodoroSettings.fromJson(map);
      }

      // Load Log
      final logRaw = prefs.getString(_sessionLogKey);
      if (logRaw != null) {
        final list = jsonDecode(logRaw) as List<dynamic>;
        final loaded = list
            .map((item) =>
                PomodoroSessionLog.fromJson(item as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty) {
          _sessionLog = loaded;
        }
      }

      if (_sessionLog.isEmpty) {
        _sessionLog = generateSampleSessionLogs();
        await _saveSessionLog();
      }

      // Re-generate queue with restored settings
      _queue = generateQueue(_settings);
      _activeQueueIndex = 0;
      _syncWithCurrentQueueItem();
      notifyListeners();
    } catch (_) {
      // Ignore parsing errors and fallback to defaults
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (_) {}
  }

  Future<void> _saveSessionLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = _sessionLog.map((e) => e.toJson()).toList();
      await prefs.setString(_sessionLogKey, jsonEncode(serialized));
    } catch (_) {}
  }

  void _syncWithCurrentQueueItem() {
    if (_queue.isEmpty) return;
    if (_activeQueueIndex >= _queue.length) {
      _activeQueueIndex = 0;
    }
    final item = _queue[_activeQueueIndex];
    _totalDuration = item.durationMinutes * 60;
    _timeLeft = _totalDuration;
  }

  // ─── Timer Controls ────────────────────────────────────────────────────────
  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void resetTimer() {
    _recordPartialSessionIfEligible();
    pauseTimer();
    _syncWithCurrentQueueItem();
    notifyListeners();
  }

  void skipSession() {
    _recordPartialSessionIfEligible();
    pauseTimer();
    _advanceQueue(userInitiated: true);
  }

  void jumpToSession(int index) {
    if (index < 0 || index >= _queue.length || index == _activeQueueIndex) {
      return;
    }
    _recordPartialSessionIfEligible();
    pauseTimer();
    _activeQueueIndex = index;
    _syncWithCurrentQueueItem();
    notifyListeners();
  }

  void _tick() {
    if (_timeLeft > 0) {
      _timeLeft--;
      notifyListeners();
      if (_timeLeft == 0) {
        _onSessionComplete();
      }
    }
  }

  void _onSessionComplete() {
    pauseTimer();

    // Haptic & Sound notification
    if (_settings.soundNotification) {
      SystemSound.play(SystemSoundType.alert);
    }
    ZetaHaptics.heavy();

    // Log the completed session
    final currentItem = currentSession;
    if (currentItem != null) {
      final logEntry = PomodoroSessionLog(
        id: '${DateTime.now().millisecondsSinceEpoch}-${currentItem.id}',
        mode: currentItem.mode,
        minutes: currentItem.durationMinutes,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _sessionLog.add(logEntry);
      if (_sessionLog.length > _maxLogEntries) {
        _sessionLog = _sessionLog.sublist(_sessionLog.length - _maxLogEntries);
      }
      _saveSessionLog();
    }

    // Determine auto-start for next session
    final nextIndex = (_activeQueueIndex + 1) % _queue.length;
    final nextItem = _queue[nextIndex];
    final shouldAutoStart = _settings.autoStartNext ||
        (nextItem.mode == PomodoroMode.focus
            ? _settings.autoStartFocus
            : _settings.autoStartBreaks);

    _advanceQueue(autoStart: shouldAutoStart);
  }

  void _advanceQueue({bool userInitiated = false, bool autoStart = false}) {
    if (_queue.isEmpty) return;

    final nextIndex = _activeQueueIndex + 1;
    if (nextIndex >= _queue.length) {
      // Cycle completed -> regenerate queue
      _queue = generateQueue(_settings);
      _activeQueueIndex = 0;
    } else {
      _activeQueueIndex = nextIndex;
    }

    _syncWithCurrentQueueItem();

    if (autoStart && !userInitiated) {
      startTimer();
    } else {
      notifyListeners();
    }
  }

  void _recordPartialSessionIfEligible() {
    final elapsedSeconds = _totalDuration - _timeLeft;
    // Require at least 60 seconds to count towards stats
    if (elapsedSeconds < 60) return;

    final elapsedMinutes = (elapsedSeconds / 60).round();
    if (elapsedMinutes < 1) return;

    final logEntry = PomodoroSessionLog(
      id: '${DateTime.now().millisecondsSinceEpoch}-partial',
      mode: mode,
      minutes: elapsedMinutes,
      completedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _sessionLog.add(logEntry);
    if (_sessionLog.length > _maxLogEntries) {
      _sessionLog = _sessionLog.sublist(_sessionLog.length - _maxLogEntries);
    }
    _saveSessionLog();
  }

  // ─── Settings & Management ────────────────────────────────────────────────
  void updateSettings(PomodoroSettings newSettings) {
    final oldSkipBreaks = _settings.skipBreaks;
    final oldInterval = _settings.longBreakInterval;
    final oldFocus = _settings.focusDuration;
    final oldShort = _settings.shortBreakDuration;
    final oldLong = _settings.longBreakDuration;

    _settings = newSettings;
    _saveSettings();

    // Re-generate queue if durations, intervals or break skipping changed
    if (oldSkipBreaks != newSettings.skipBreaks ||
        oldInterval != newSettings.longBreakInterval ||
        oldFocus != newSettings.focusDuration ||
        oldShort != newSettings.shortBreakDuration ||
        oldLong != newSettings.longBreakDuration) {
      _queue = generateQueue(_settings);
      if (_activeQueueIndex >= _queue.length) {
        _activeQueueIndex = 0;
      }
      if (!_isRunning) {
        _syncWithCurrentQueueItem();
      }
    }
    notifyListeners();
  }

  void resetToDefaultSettings() {
    updateSettings(const PomodoroSettings());
  }

  Future<void> clearSessionLog() async {
    _sessionLog.clear();
    await _saveSessionLog();
    notifyListeners();
  }

  Future<void> seedSampleData() async {
    _sessionLog = generateSampleSessionLogs();
    await _saveSessionLog();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
