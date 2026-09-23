import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pomodoro.dart';
import '../services/pomodoro_sync_service.dart';
import '../services/notification_service.dart';
import '../utils/haptics.dart';
import '../database/database_provider.dart';
import '../database/daos/session_dao.dart';

class PomodoroProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _settingsKey = 'zeta_pomodoro_settings_v1';
  static const int _maxLogEntries = 1000;

  final PomodoroSyncService _syncService = PomodoroSyncService();
  late final SessionDao _sessionDao;

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
    _sessionDao = DatabaseProvider.instance.sessionDao;
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
  ///
  /// Uses incremental sync: passes the timestamp of the most recent local
  /// session as [since], so only new remote sessions are fetched.
  Future<void> syncWithCloud({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final masterSync = prefs.getBool('zeta_master_sync_enabled') ?? true;
      if (!masterSync && !force) return;

      // Determine cursor: most recent session timestamp in local SQLite.
      final since = force ? null : await _sessionDao.getLastSessionTimestamp();

      final remoteSessions = await _syncService.pullSessions(since: since);

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

      // Load sessions from SQLite (drift)
      final sessions = await _sessionDao.getSessions(limit: 1000);
      _sessionLog = sessions
          .where((s) => !s.id.startsWith('sample-'))
          .toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

      // Re-generate queue with restored settings
      _queue = generateQueue(_settings);
      _activeQueueIndex = 0;
      _syncWithCurrentQueueItem();
      notifyListeners();
    } catch (e) {
      debugPrint('PomodoroProvider: _loadFromStorage error - $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (_) {}
  }

  Future<void> _saveSessionLog() async {
    // Persist to SQLite via drift DAO.
    // The DAO handles upserts efficiently and avoids the SharedPreferences blob overhead.
    try {
      await _sessionDao.upsertAll(_sessionLog);
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
      unawaited(_sessionDao.upsertSession(logEntry));
      unawaited(_syncService.pushSession(logEntry));
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
    unawaited(_sessionDao.upsertSession(logEntry));
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
    _updateLiveNotification(force: true);
    notifyListeners();
  }

  void resetToDefaultSettings() {
    updateSettings(const PomodoroSettings());
  }

  Future<void> clearSessionLog() async {
    _sessionLog.clear();
    await _sessionDao.clearAll();
    unawaited(_syncService.clearSessions());
    notifyListeners();
  }



  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _timer?.cancel();
    if (NotificationService.instance.onPomodoroAction != null) {
      NotificationService.instance.onPomodoroAction = null;
    }
    NotificationService.instance.cancelPomodoroProgress();
    _syncService.dispose();
    super.dispose();
  }
}
