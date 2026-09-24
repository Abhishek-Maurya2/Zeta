import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/pomodoro.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../utils/haptics.dart';
import '../repositories/pomodoro_repository.dart';

class PomodoroProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _settingsKey = 'zeta_pomodoro_settings_v1';
  static const int _maxLogEntries = 1000;

  final PomodoroRepository _repository;

  PomodoroSettings _settings = const PomodoroSettings();
  List<PomodoroSessionItem> _queue = [];
  int _activeQueueIndex = 0;
  int _timeLeft = 25 * 60; // in seconds
  int _totalDuration = 25 * 60; // in seconds
  bool _isRunning = false;
  List<PomodoroSessionLog> _sessionLog = [];
  DateTime? _targetEndTime;

  Timer? _timer;
  bool _isDisposed = false;
  bool _isCloudSyncing = false;

  PomodoroProvider({
    PomodoroRepository? repository,
  }) : _repository = repository ?? PomodoroRepository() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _init();
    NotificationService.instance.onPomodoroAction = (action) {
      switch (action) {
        case 'toggle':
          toggleTimer();
          break;
        case 'pause':
          pauseTimer();
          break;
        case 'resume':
          startTimer();
          break;
        case 'skip':
        case 'next':
          skipSession();
          break;
      }
    };
  }

  // ─── Getters ───────────────────────────────────────────────────────────────
  PomodoroSettings get settings => _settings;
  List<PomodoroSessionItem> get queue => _queue;
  int get activeQueueIndex => _activeQueueIndex;
  int get timeLeft => _timeLeft;
  int get totalDuration => _totalDuration;
  bool get isRunning => _isRunning;
  List<PomodoroSessionLog> get sessionLog => _sessionLog;
  bool get isSyncing => _isCloudSyncing || _repository.isSyncing;
  DateTime? get lastSyncedAt => _repository.lastSyncedAt;
  String? get syncError => _repository.syncError;

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

  bool get isCountUp => _settings.countUp;

  int get elapsedSeconds =>
      (_totalDuration - _timeLeft).clamp(0, _totalDuration);

  int get displaySeconds => _settings.countUp ? elapsedSeconds : _timeLeft;

  String get formattedTime {
    final timeToDisplay = displaySeconds;
    final mins = timeToDisplay ~/ 60;
    final secs = timeToDisplay % 60;
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
    _repository.subscribeToRealtime(
      onSessionChange: (session, eventType) {
        if (eventType == 'DELETE') {
          _sessionLog.removeWhere((s) => s.id == session.id);
          unawaited(_repository.deleteSession(session.id, pushToCloud: false));
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
        if (!_isDisposed) notifyListeners();
      },
    );
  }

  /// Synchronizes local sessions with Supabase database.
  ///
  /// The repository owns the complete paginated reconciliation. Completion
  /// time is not a reliable incremental cursor for backdated remote sessions.
  Future<void> syncWithCloud({bool force = false}) async {
    if (_isCloudSyncing) return;
    _isCloudSyncing = true;
    try {
      final masterSync = PreferencesService.instance.getBool('zeta_master_sync_enabled') ?? true;
      if (!masterSync && !force) return;
      await _repository.syncWithCloud(force: force);
      if (_repository.syncError != null) return;
      final sessions = await _repository.getRecentSessions(limit: _maxLogEntries);
      _sessionLog = sessions
          .where((s) => !s.id.startsWith('sample-'))
          .toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('PomodoroProvider: Cloud sync note: $e');
    } finally {
      _isCloudSyncing = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = PreferencesService.instance;

      // Load Settings
      final settingsRaw = prefs.getString(_settingsKey);
      if (settingsRaw != null) {
        final map = jsonDecode(settingsRaw) as Map<String, dynamic>;
        _settings = PomodoroSettings.fromJson(map);
      }

      // Load sessions from SQLite (drift)
      final sessions = await _repository.getRecentSessions(limit: 1000);
      _sessionLog = sessions
          .where((s) => !s.id.startsWith('sample-'))
          .toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

      // Re-generate queue with restored settings
      _queue = generateQueue(_settings);
      _activeQueueIndex = 0;
      _syncWithCurrentQueueItem();
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('PomodoroProvider: _loadFromStorage error - $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = PreferencesService.instance;
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (_) {}
  }

  Future<void> _saveSessionLog() async {
    // Persist to SQLite via repository.
    try {
      await _repository.saveSessionsBatch(_sessionLog, pushToCloud: false);
    } catch (e) {
      debugPrint('PomodoroProvider: _saveSessionLog error - $e');
    }
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
    _updateLiveNotification(force: true);
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _isRunning = false;
    _targetEndTime = null;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
    _updateLiveNotification(force: true);
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
    NotificationService.instance.cancelPomodoroProgress();
    notifyListeners();
  }

  void skipSession() {
    _recordPartialSessionIfEligible();
    pauseTimer();
    NotificationService.instance.cancelPomodoroProgress();
    _advanceQueue(userInitiated: true);
  }

  void jumpToSession(int index) {
    if (index < 0 || index >= _queue.length || index == _activeQueueIndex) {
      return;
    }
    _recordPartialSessionIfEligible();
    pauseTimer();
    NotificationService.instance.cancelPomodoroProgress();
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
        _updateLiveNotification();
      }
    }
  }

  void _updateLiveNotification({bool force = false}) {
    NotificationService.instance.updatePomodoroProgress(
      mode: mode,
      sessionLabel: currentSession?.label,
      timeLeft: _timeLeft,
      totalDuration: _totalDuration,
      isRunning: _isRunning,
      countUp: _settings.countUp,
      forceWindowsUpdate: force,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isRunning && _targetEndTime != null) {
        _tick();
      }
      syncWithCloud();
    }
  }

  void _onSessionComplete() {
    pauseTimer();

    // Haptic & Sound notification
    if (_settings.soundNotification) {
      SystemSound.play(SystemSoundType.alert);
    }
    ZetaHaptics.heavy();

    // Fire system notification.
    final completedMode = currentSession?.mode ?? PomodoroMode.focus;
    NotificationService.instance.cancelPomodoroProgress();
    NotificationService.instance.showPomodoroComplete(completedMode);

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
      unawaited(_repository.saveSession(logEntry));
    }

    // Determine auto-start for next session
    final nextIndex = (_activeQueueIndex + 1) % _queue.length;
    final nextItem = _queue[nextIndex];
    final shouldAutoStart = nextItem.mode == PomodoroMode.focus
        ? _settings.autoStartFocus
        : _settings.autoStartBreaks;

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
    unawaited(_repository.saveSession(logEntry));
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
    _updateLiveNotification(force: true);
    notifyListeners();
  }

  void resetToDefaultSettings() {
    updateSettings(const PomodoroSettings());
  }

  Future<void> clearSessionLog() async {
    _sessionLog.clear();
    await _repository.clearSessions();
    notifyListeners();
  }



  @override
  void dispose() {
    _isDisposed = true;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _timer?.cancel();
    if (NotificationService.instance.onPomodoroAction != null) {
      NotificationService.instance.onPomodoroAction = null;
    }
    NotificationService.instance.cancelPomodoroProgress();
    super.dispose();
  }
}
