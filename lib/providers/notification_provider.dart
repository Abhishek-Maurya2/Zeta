import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/notification_service.dart';

/// Provider that drives periodic reminders and overdue task scans.
///
/// Depends on [NotificationService.instance] being initialized before use.
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _prefKeyMaster = 'zeta_notif_master';
  static const String _prefKeyTaskReminders = 'zeta_notif_task_reminders';
  static const String _prefKeyOverdue = 'zeta_notif_overdue';
  static const String _prefKeyPomodoro = 'zeta_notif_pomodoro';
  static const String _prefKeyPomodoroLive = 'zeta_notif_pomodoro_live';

  Timer? _pollingTimer;

  /// Snapshot of all tasks - updated by callers via [updateTasks].
  List<Task> _tasks = [];

  /// Whether the user has been shown the overdue summary this session.
  bool _overdueShownThisSession = false;

  bool _notificationsEnabled = true;
  bool _taskRemindersEnabled = true;
  bool _overdueAlertsEnabled = true;
  bool _pomodoroAlertsEnabled = true;
  bool _pomodoroLiveEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  bool get overdueAlertsEnabled => _overdueAlertsEnabled;
  bool get pomodoroAlertsEnabled => _pomodoroAlertsEnabled;
  bool get pomodoroLiveEnabled => _pomodoroLiveEnabled;

  NotificationProvider() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _loadPreferences();
    _startPolling();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_prefKeyMaster) ?? true;
      _taskRemindersEnabled = prefs.getBool(_prefKeyTaskReminders) ?? true;
      _overdueAlertsEnabled = prefs.getBool(_prefKeyOverdue) ?? true;
      _pomodoroAlertsEnabled = prefs.getBool(_prefKeyPomodoro) ?? true;
      _pomodoroLiveEnabled = prefs.getBool(_prefKeyPomodoroLive) ?? true;
      _syncService();
      notifyListeners();
    } catch (_) {}
  }

  void _syncService() {
    NotificationService.instance.masterEnabled = _notificationsEnabled;
    NotificationService.instance.taskRemindersEnabled = _taskRemindersEnabled;
    NotificationService.instance.overdueAlertsEnabled = _overdueAlertsEnabled;
    NotificationService.instance.pomodoroAlertsEnabled = _pomodoroAlertsEnabled;
    NotificationService.instance.pomodoroLiveEnabled = _pomodoroLiveEnabled;
  }

  // --- Public API ------------------------------------------------------------

  /// Call this whenever tasks change so the provider has an up-to-date list.
  void updateTasks(List<Task> tasks) {
    _tasks = tasks;
  }

  void setEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    _syncService();
    if (!value) {
      NotificationService.instance.cancelAll();
    } else {
      _rescheduleAllTasks();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyMaster, value);
    } catch (_) {}
  }

  void setTaskRemindersEnabled(bool value) async {
    if (_taskRemindersEnabled == value) return;
    _taskRemindersEnabled = value;
    _syncService();
    if (!value) {
      for (final task in _tasks) {
        NotificationService.instance.cancelTaskReminder(task.id);
      }
    } else if (_notificationsEnabled) {
      _rescheduleAllTasks();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyTaskReminders, value);
    } catch (_) {}
  }

  void setOverdueAlertsEnabled(bool value) async {
    if (_overdueAlertsEnabled == value) return;
    _overdueAlertsEnabled = value;
    _syncService();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyOverdue, value);
    } catch (_) {}
  }

  void setPomodoroAlertsEnabled(bool value) async {
    if (_pomodoroAlertsEnabled == value) return;
    _pomodoroAlertsEnabled = value;
    _syncService();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyPomodoro, value);
    } catch (_) {}
  }

  void setPomodoroLiveEnabled(bool value) async {
    if (_pomodoroLiveEnabled == value) return;
    _pomodoroLiveEnabled = value;
    _syncService();
    if (!value) {
      NotificationService.instance.cancelPomodoroProgress();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyPomodoroLive, value);
    } catch (_) {}
  }

  void _rescheduleAllTasks() {
    if (!_notificationsEnabled || !_taskRemindersEnabled) return;
    for (final task in _tasks) {
      if (!task.completed) {
        NotificationService.instance.scheduleTaskReminder(task);
      }
    }
  }

  /// Request system notification permission.
  Future<bool> requestPermission() =>
      NotificationService.instance.requestPermission();

  /// Whether notifications are currently permitted by the OS.
  Future<bool> hasPermission() => NotificationService.instance.hasPermission();

  // --- Lifecycle -------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runOverdueScan();
    }
  }

  // --- Polling ---------------------------------------------------------------

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_notificationsEnabled && _taskRemindersEnabled) {
        NotificationService.instance.tickWebWindowsReminders(_tasks);
      }
    });
  }

  // --- Overdue Scan ----------------------------------------------------------

  void _runOverdueScan() {
    if (!_notificationsEnabled || !_overdueAlertsEnabled) return;
    if (_overdueShownThisSession) return;

    final now = DateTime.now();
    int overdueCount = 0;

    for (final task in _tasks) {
      if (task.completed || task.dueDate == null) continue;
      // Only count tasks that are past due (date + optional time).
      final due = _resolveDue(task, now);
      if (due != null && due.isBefore(now)) {
        overdueCount++;
      }
    }

    if (overdueCount > 0) {
      _overdueShownThisSession = true;
      NotificationService.instance.showOverdueSummary(overdueCount);
    }
  }

  DateTime? _resolveDue(Task task, DateTime now) {
    if (task.dueDate == null) return null;
    try {
      final parts = task.dueDate!.trim().toLowerCase();
      DateTime? base;
      if (parts == 'today') {
        base = DateTime(now.year, now.month, now.day);
      } else if (parts == 'tomorrow') {
        base = DateTime(now.year, now.month, now.day + 1);
      } else if (parts == 'yesterday') {
        base = DateTime(now.year, now.month, now.day - 1);
      } else {
        base = DateTime.tryParse(task.dueDate!);
      }
      if (base == null) return null;

      if (task.hasTime && task.dueTime != null) {
        return base;
      }
      return DateTime(base.year, base.month, base.day, 23, 59);
    } catch (_) {
      return null;
    }
  }

  // --- Disposal --------------------------------------------------------------

  @override
  void dispose() {
    _pollingTimer?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }
}
