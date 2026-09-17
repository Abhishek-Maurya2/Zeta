import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/notification_service.dart';

/// Provider that drives periodic reminders and overdue task scans.
///
/// Depends on [NotificationService.instance] being initialized before use.
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  Timer? _pollingTimer;

  /// Snapshot of all tasks - updated by callers via [updateTasks].
  List<Task> _tasks = [];

  /// Whether the user has been shown the overdue summary this session.
  bool _overdueShownThisSession = false;

  bool _notificationsEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;

  NotificationProvider() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _startPolling();
  }

  // --- Public API ------------------------------------------------------------

  /// Call this whenever tasks change so the provider has an up-to-date list.
  void updateTasks(List<Task> tasks) {
    _tasks = tasks;
  }

  void setEnabled(bool value) {
    _notificationsEnabled = value;
    if (!value) {
      NotificationService.instance.cancelAll();
    }
    notifyListeners();
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
      if (_notificationsEnabled) {
        NotificationService.instance.tickWebWindowsReminders(_tasks);
      }
    });
  }

  // --- Overdue Scan ----------------------------------------------------------

  void _runOverdueScan() {
    if (!_notificationsEnabled) return;
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
