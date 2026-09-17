import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../models/pomodoro.dart';
import '../utils/task_date_formatter.dart';
import 'web_notification_helper.dart';

/// Notification channel IDs and notification IDs.
class _NotifIds {
  static const String taskChannelId = 'zeta_task_reminders';
  static const String taskChannelName = 'Task Reminders';
  static const String pomodoroChannelId = 'zeta_pomodoro';
  static const String pomodoroChannelName = 'Focus Timer';

  static const int overdueId = 99000;
  static const int pomodoroFocusId = 99001;
  static const int pomodoroBreakId = 99002;

  /// Stable integer ID derived from a task UUID string.
  static int forTask(String taskId) => taskId.hashCode.abs() % 99000;
}

/// Cross-platform system notification service for Zeta.
///
/// - Android: uses `zonedSchedule` with exact alarms for due-time reminders.
/// - Windows: uses `local_notifier` desktop toast notifications and polling ticks.
/// - Web: uses Web Notification API and polling ticks.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Map of task IDs to scheduled due DateTime, used for Web/Windows polling.
  final Map<String, DateTime> _pendingWebWindows = {};

  // --- Initialisation ---

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      if (Platform.isWindows) {
        try {
          await localNotifier.setup(
            appName: 'Zeta',
            shortcutPolicy: ShortcutPolicy.requireCreate,
          );
          _initialized = true;
          return;
        } catch (e) {
          debugPrint('[NotificationService] Windows setup error: $e');
        }
      }

      // Android / iOS / Linux initialization
      try {
        tz.initializeTimeZones();
        try {
          final name = DateTime.now().timeZoneName;
          tz.setLocalLocation(tz.getLocation(name));
        } catch (_) {}
      } catch (_) {}

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);

      try {
        await _plugin.initialize(
          settings,
          onDidReceiveNotificationResponse: _onNotificationTap,
        );
        _initialized = true;
      } catch (e) {
        debugPrint('[NotificationService] plugin init failed: $e');
      }
    } else {
      // Web
      _initialized = true;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] tapped: ${response.payload}');
  }

  // --- Permission ---

  /// Requests notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return await requestWebNotificationPermission();
    }

    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? false;
      }
      if (Platform.isWindows) {
        return true;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
    }
    return false;
  }

  /// Returns whether notifications are currently enabled.
  Future<bool> hasPermission() async {
    if (kIsWeb) {
      return await hasWebNotificationPermission();
    }

    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      if (Platform.isWindows) {
        return true;
      }
    } catch (_) {}
    return true;
  }

  // --- Core Show ---

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isPomodoro = false,
  }) async {
    if (!_initialized) await init();

    if (kIsWeb) {
      showWebNotification(title, body);
      return;
    }

    if (Platform.isWindows) {
      try {
        final notification = LocalNotification(
          identifier: id.toString(),
          title: title,
          body: body,
        );
        await notification.show();
      } catch (e) {
        debugPrint('[NotificationService] Windows showNow error: $e');
      }
      return;
    }

    try {
      final channelId =
          isPomodoro ? _NotifIds.pomodoroChannelId : _NotifIds.taskChannelId;
      final channelName = isPomodoro
          ? _NotifIds.pomodoroChannelName
          : _NotifIds.taskChannelName;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      );

      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[NotificationService] showNow error: $e');
    }
  }

  // --- Task Reminders ---

  /// Schedules a reminder for [task] at its due date + time.
  /// No-op if the task has no dueDate, hasTime is false, or dueTime is null.
  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) await init();

    if (task.completed) {
      await cancelTaskReminder(task.id);
      return;
    }
    if (task.dueDate == null || !task.hasTime || task.dueTime == null) {
      await cancelTaskReminder(task.id);
      return;
    }

    final due = _parseDueDateTime(task);
    if (due == null) return;
    if (due.isBefore(DateTime.now())) return;

    final id = _NotifIds.forTask(task.id);
    final title = 'Task due: ${task.title}';
    const body = 'Your task is due now.';

    if (!kIsWeb && Platform.isAndroid) {
      await _scheduleAndroid(
        id: id,
        title: title,
        body: body,
        due: due,
        payload: task.id,
      );
    } else {
      _pendingWebWindows[task.id] = due;
    }
  }

  Future<void> _scheduleAndroid({
    required int id,
    required String title,
    required String body,
    required DateTime due,
    String? payload,
  }) async {
    try {
      final tzDue = tz.TZDateTime.from(due, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDue,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _NotifIds.taskChannelId,
            _NotifIds.taskChannelName,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleAndroid error: $e');
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    _pendingWebWindows.remove(taskId);
    if (!_initialized) return;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _plugin.cancel(_NotifIds.forTask(taskId));
      } catch (_) {}
    }
  }

  // --- Pomodoro ---

  Future<void> showPomodoroComplete(PomodoroMode mode) async {
    final isFocus = mode == PomodoroMode.focus;
    await showNow(
      id: isFocus ? _NotifIds.pomodoroFocusId : _NotifIds.pomodoroBreakId,
      title: isFocus ? 'Focus session complete!' : 'Break time is over',
      body: isFocus
          ? 'Time for a well-deserved break.'
          : 'Ready to get back to work?',
      isPomodoro: true,
    );
  }

  // --- Overdue Summary ---

  Future<void> showOverdueSummary(int count) async {
    if (count <= 0) return;
    await showNow(
      id: _NotifIds.overdueId,
      title: '$count overdue task${count == 1 ? '' : 's'}',
      body: count == 1
          ? 'You have 1 task past its deadline.'
          : 'You have $count tasks past their deadlines.',
    );
  }

  // --- Web / Windows Polling Tick ---

  /// Call this periodically (~60 seconds) from NotificationProvider.
  /// Fires any pending reminders whose due time has arrived.
  Future<void> tickWebWindowsReminders(List<Task> allTasks) async {
    if (!_initialized) await init();
    final now = DateTime.now();
    final fired = <String>[];

    for (final entry in _pendingWebWindows.entries) {
      if (entry.value.difference(now).inSeconds <= 30) {
        final task = allTasks.firstWhere(
          (t) => t.id == entry.key,
          orElse: () => Task(id: '', title: ''),
        );
        if (task.id.isNotEmpty && !task.completed) {
          await showNow(
            id: _NotifIds.forTask(task.id),
            title: 'Task due: ${task.title}',
            body: 'Your task is due now.',
            payload: task.id,
          );
        }
        fired.add(entry.key);
      }
    }
    for (final id in fired) {
      _pendingWebWindows.remove(id);
    }
  }

  // --- Cancel All ---

  Future<void> cancelAll() async {
    _pendingWebWindows.clear();
    if (!_initialized) return;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _plugin.cancelAll();
      } catch (_) {}
    }
  }

  // --- Helpers ---

  DateTime? _parseDueDateTime(Task task) {
    try {
      final baseDate = TaskDateFormatter.parse(task.dueDate!);
      if (baseDate == null) return null;

      if (task.dueTime != null && task.dueTime!.isNotEmpty) {
        final timeParts = task.dueTime!.trim().toUpperCase();
        int hour = 0;
        int minute = 0;

        if (timeParts.contains('AM') || timeParts.contains('PM')) {
          final isPm = timeParts.contains('PM');
          final cleaned =
              timeParts.replaceAll('AM', '').replaceAll('PM', '').trim();
          final parts = cleaned.split(':');
          hour = int.tryParse(parts[0]) ?? 0;
          minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          if (isPm && hour != 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
        } else {
          final parts = timeParts.split(':');
          hour = int.tryParse(parts[0]) ?? 0;
          minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        }

        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
          minute,
        );
      }

      return DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);
    } catch (_) {
      return null;
    }
  }
}
