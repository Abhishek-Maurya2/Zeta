import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro.dart';
import '../services/pomodoro_sync_service.dart';
import '../utils/haptics.dart';

class PomodoroProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _settingsKey = 'zeta_pomodoro_settings_v1';
  static const String _sessionLogKey = 'zeta_pomodoro_session_log_v1';
  static const int _maxLogEntries = 1000;

  final PomodoroSyncService _syncService = PomodoroSyncService();

  PomodoroSettings _settings = const PomodoroSettings();
  List<PomodoroSessionItem> _queue = [];
  int _activeQueueIndex = 0;
  int _timeLeft = 25 * 60; // in seconds
  int _totalDuration = 25 * 60; // in seconds
  bool _isRunning = false;
  List<PomodoroSessionLog> _sessionLog = [];
  DateTime? _targetEndTime;

  Timer? _timer;

  PomodoroProvider() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
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
  bool get isSyncing => _syncService.isSyncing;
  DateTime? get lastSyncedAt => _syncService.lastSyncedAt;
  String? get syncError => _syncService.lastError;

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
    _subscribeToRealtime();
    unawaited(syncWithCloud());
  }

  void _subscribeToRealtime() {
    _syncService.subscribeToRealtime(
      onSessionChange: (session, eventType) {
        if (eventType == 'DELETE') {
          _sessionLog.removeWhere((s) => s.id == session.id);
        } else {
          final idx = _sessionLog.indexWhere((s) => s.id == session.id);
          if (idx != -1) {
            _sessionLog[idx] = session;
          } else {
            _sessionLog.add(session);
            _sessionLog.sort((a, b) => a.completedAt.compareTo(b.completedAt));
            if (_sessionLog.length > _maxLogEntries) {
              _sessionLog = _sessionLog.sublist(_sessionLog.length - _maxLogEntries);
            }
          }
        }
        _saveSessionLog();
        notifyListeners();
      },
    );
  }

  /// Synchronizes local sessions with Supabase database.
  Future<void> syncWithCloud({bool force = false}) async {
    try {
      final remoteSessions = await _syncService.pullSessions();

      final existingIds = _sessionLog.map((s) => s.id).toSet();
      final remoteIds = remoteSessions.map((s) => s.id).toSet();

      bool changed = false;
      for (final remote in remoteSessions) {
        if (!existingIds.contains(remote.id)) {
          _sessionLog.add(remote);
          existingIds.add(remote.id);
          changed = true;
        }
      }

      if (changed) {
        _sessionLog.sort((a, b) => a.completedAt.compareTo(b.completedAt));
        if (_sessionLog.length > _maxLogEntries) {
          _sessionLog = _sessionLog.sublist(_sessionLog.length - _maxLogEntries);
        }
        await _saveSessionLog();
      }

      // Batch push any local sessions not yet present in Supabase
      if (_syncService.lastError == null) {
        final unpushed =
            _sessionLog.where((s) => !remoteIds.contains(s.id)).toList();
        if (unpushed.isNotEmpty) {
          await _syncService.batchPushSessions(unpushed);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('PomodoroProvider: Cloud sync note: $e');
    }
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
            .where((e) => !e.id.startsWith('sample-'))
            .toList();
        _sessionLog = loaded;
        // Save cleaned log back to storage if legacy sample entries were removed
        if (loaded.length != list.length) {
          await _saveSessionLog();
        }
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
    _targetEndTime = DateTime.now().add(Duration(seconds: _timeLeft));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _isRunning = false;
    _targetEndTime = null;
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
    if (!_isRunning || _targetEndTime == null) return;
    final remaining = _targetEndTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timeLeft = 0;
      notifyListeners();
      _onSessionComplete();
    } else {
      if (_timeLeft != remaining) {
        _timeLeft = remaining;
        notifyListeners();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning && _targetEndTime != null) {
      _tick();
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
      unawaited(_syncService.pushSession(logEntry));
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
    unawaited(_syncService.pushSession(logEntry));
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
    unawaited(_syncService.clearSessions());
    notifyListeners();
  }



  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _timer?.cancel();
    _syncService.dispose();
    super.dispose();
  }
}
