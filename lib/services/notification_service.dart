import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_desktop_notifications/flutter_desktop_notifications.dart';
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
  static const String pomodoroLiveChannelId = 'zeta_pomodoro_live';
  static const String pomodoroLiveChannelName = 'Active Timer Progress';

  static const int overdueId = 99000;
  static const int pomodoroFocusId = 99001;
  static const int pomodoroBreakId = 99002;
  static const int pomodoroLiveId = 99003;

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

  /// User preference flags synced from NotificationProvider
  bool masterEnabled = true;
  bool taskRemindersEnabled = true;
  bool overdueAlertsEnabled = true;
  bool pomodoroAlertsEnabled = true;
  bool pomodoroLiveEnabled = true;

  /// Callback for interactive notification actions (e.g. 'toggle', 'pause', 'resume', 'skip')
  void Function(String action)? onPomodoroAction;

  /// Callback for cross-device resume notification activation (page, itemId)
  void Function(String page, String? itemId)? onResumeAction;

  /// Windows native notifications
  WindowsNotification? _winNotifier;

  /// Tracks if user explicitly closed/dismissed the Windows live progress toast
  bool _windowsUserDismissedLive = false;
  PomodoroMode? _lastWindowsMode;

  /// Windows live notification instance and update throttling
  LocalNotification? _windowsLiveNotification;
  DateTime? _lastWindowsLiveUpdate;
  bool? _lastWindowsRunningState;

  /// Map of task IDs to scheduled due DateTime, used for Web/Windows polling.
  final Map<String, DateTime> _pendingWebWindows = {};

  // --- Initialisation ---

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      if (Platform.isWindows) {
        try {
          await WindowsNotification.registerAumid(
            aumid: 'com.abhishek.zeta',
            displayName: 'Zeta',
          );
          _winNotifier = WindowsNotification(applicationId: 'com.abhishek.zeta');
          await _winNotifier!.init();
          await _winNotifier!.setCallback(_onWindowsNotificationEvent);
        } catch (e) {
          debugPrint('[NotificationService] WindowsNotification setup error: $e');
        }

        try {
          await localNotifier.setup(
            appName: 'Zeta',
            shortcutPolicy: ShortcutPolicy.ignore,
          );
        } catch (e2) {
          debugPrint('[NotificationService] Windows local_notifier fallback error: $e2');
        }
        _initialized = true;
        return;
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
          settings: settings,
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
    debugPrint(
        '[NotificationService] tapped: payload=${response.payload}, actionId=${response.actionId}');
    if (response.payload != null && response.payload!.startsWith('resume:')) {
      final payload = response.payload!.substring('resume:'.length);
      final parts = payload.split('|');
      final page = parts.isNotEmpty ? parts[0] : 'home';
      final itemId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      onResumeAction?.call(page, itemId);
      return;
    }
    if (response.actionId == 'action_toggle') {
      onPomodoroAction?.call('toggle');
    } else if (response.actionId == 'action_pause') {
      onPomodoroAction?.call('pause');
    } else if (response.actionId == 'action_resume') {
      onPomodoroAction?.call('resume');
    } else if (response.actionId == 'action_skip' ||
        response.actionId == 'action_next') {
      onPomodoroAction?.call('skip');
    }
  }

  Future<void> _onWindowsNotificationEvent(
      NotificationCallbackDetails details) async {
    debugPrint(
        '[NotificationService] Windows callback: event=${details.event}, args=${details.arguments}');
    if (details.event == NotificationEvent.dismissedByUser) {
      if (details.message.id == 'zeta_pomodoro_live') {
        _windowsUserDismissedLive = true;
      }
    } else if (details.event == NotificationEvent.activated) {
      try {
        await WindowsNotification.bringAppToForeground();
      } catch (_) {}

      final arg = details.arguments ?? '';
      if (arg.startsWith('action:resume:')) {
        final payload = arg.substring('action:resume:'.length);
        final parts = payload.split('|');
        final page = parts.isNotEmpty ? parts[0] : 'home';
        final itemId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
        onResumeAction?.call(page, itemId);
      } else if (arg == 'action:toggle' || arg == 'action_toggle') {
        onPomodoroAction?.call('toggle');
      } else if (arg == 'action:pause') {
        onPomodoroAction?.call('pause');
      } else if (arg == 'action:resume') {
        onPomodoroAction?.call('resume');
      } else if (arg == 'action:skip' ||
          arg == 'action_skip' ||
          arg == 'action:next') {
        onPomodoroAction?.call('skip');
      }
    }
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

  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isPomodoro = false,
  }) async {
    if (!_initialized) await init();

    if (kIsWeb) {
      showWebNotification(title, body);
      return true;
    }

    if (Platform.isWindows) {
      if (_winNotifier != null) {
        try {
          await _winNotifier!.showNotificationPluginTemplate(
            NotificationMessage.fromPluginTemplate(
              id.toString(),
              title,
              body,
            ),
          );
          return true;
        } catch (e) {
          debugPrint('[NotificationService] WindowsNotification showNow error: $e');
        }
      }
      try {
        final notification = LocalNotification(
          identifier: id.toString(),
          title: title,
          body: body,
        );
        await notification.show();
        return true;
      } catch (e) {
        debugPrint('[NotificationService] Windows showNow fallback error: $e');
        return false;
      }
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

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('[NotificationService] showNow error: $e');
      return false;
    }
  }

  // --- Task Reminders ---

  /// Schedules a reminder for [task] at its due date + time.
  /// No-op if the task has no dueDate, hasTime is false, or dueTime is null.
  Future<void> scheduleTaskReminder(Task task) async {
    if (!masterEnabled || !taskRemindersEnabled) return;
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
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDue,
        notificationDetails: const NotificationDetails(
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
        await _plugin.cancel(id: _NotifIds.forTask(taskId));
      } catch (_) {}
    }
  }

  // --- Pomodoro ---

  Future<void> showPomodoroComplete(PomodoroMode mode) async {
    if (!masterEnabled || !pomodoroAlertsEnabled) return;
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

  /// Updates live ongoing progress notification for the active Pomodoro session.
  ///
  /// - Android: uses native ongoing notification with real progress bar and live countdown.
  /// - Windows: updates Action Center toast with clean ASCII progress bar, throttled to prevent spam.
  Future<void> updatePomodoroProgress({
    required PomodoroMode mode,
    required String? sessionLabel,
    required int timeLeft,
    required int totalDuration,
    required bool isRunning,
    bool countUp = false,
    bool forceWindowsUpdate = false,
  }) async {
    if (!masterEnabled || !pomodoroAlertsEnabled || !pomodoroLiveEnabled) return;
    if (!_initialized) await init();

    final progress = totalDuration > 0
        ? ((totalDuration - timeLeft) / totalDuration).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progress * 100).round();

    final displaySeconds = countUp ? (totalDuration - timeLeft) : timeLeft;
    final mins = displaySeconds ~/ 60;
    final secs = displaySeconds % 60;
    final formattedTime =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final modeLabel = sessionLabel != null && sessionLabel.isNotEmpty
        ? sessionLabel
        : (mode == PomodoroMode.focus
            ? 'Focus Session'
            : (mode == PomodoroMode.shortBreak
                ? 'Short Break'
                : 'Long Break'));

    // --- 1. Android: Native ongoing notification with system progress bar & action buttons ---
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            _NotifIds.pomodoroLiveChannelId,
            _NotifIds.pomodoroLiveChannelName,
            channelDescription:
                'Live ongoing progress for active Pomodoro session',
            importance: Importance.low,
            priority: Priority.low,
            showProgress: true,
            maxProgress: 100,
            progress: progressPercent,
            indeterminate: false,
            ongoing: isRunning,
            autoCancel: false,
            onlyAlertOnce: true,
            playSound: false,
            enableVibration: false,
            icon: '@mipmap/ic_launcher',
            subText: formattedTime,
            category: AndroidNotificationCategory.progress,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'action_toggle',
                isRunning ? 'Pause' : 'Resume',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'action_skip',
                'Next',
                showsUserInterface: true,
              ),
            ],
          ),
        );

        await _plugin.show(
          id: _NotifIds.pomodoroLiveId,
          title: modeLabel,
          body: isRunning
              ? (countUp
                  ? '$formattedTime elapsed ($progressPercent%)'
                  : '$formattedTime remaining ($progressPercent%)')
              : 'Paused at $formattedTime ($progressPercent%)',
          notificationDetails: details,
        );
      } catch (e) {
        debugPrint('[NotificationService] Android live pomodoro error: $e');
      }
    }

    // --- 2. Windows: Persistent reminder toast with native OS progress bar & action buttons ---
    if (!kIsWeb && Platform.isWindows) {
      final now = DateTime.now();
      final runningStateChanged = _lastWindowsRunningState != isRunning;
      final modeChanged = _lastWindowsMode != mode;
      _lastWindowsRunningState = isRunning;
      _lastWindowsMode = mode;

      // If user toggled pause/resume, moved to next session, or forced an update,
      // clear any previous dismissal so the toast appears for the new state!
      if (runningStateChanged || modeChanged || forceWindowsUpdate) {
        _windowsUserDismissedLive = false;
      }

      // If user explicitly dismissed the toast for this state, do not resurrect it
      // until something changes (e.g. pause/resume, next session, reset).
      if (_windowsUserDismissedLive) {
        return;
      }

      final shouldUpdateWindows = forceWindowsUpdate ||
          runningStateChanged ||
          modeChanged ||
          _lastWindowsLiveUpdate == null ||
          now.difference(_lastWindowsLiveUpdate!).inSeconds >= 5 ||
          timeLeft == 300 || // 5m milestone
          timeLeft == 60; // 1m milestone

      if (shouldUpdateWindows) {
        _lastWindowsLiveUpdate = now;
        if (_winNotifier != null) {
          try {
            await _winNotifier!.showNotificationPluginTemplate(
              NotificationMessage.fromPluginTemplate(
                'zeta_pomodoro_live',
                '$modeLabel — $formattedTime',
                sessionLabel != null && sessionLabel.trim().isNotEmpty
                    ? sessionLabel
                    : (isRunning ? 'Pomodoro session active' : 'Session paused'),
                group: 'pomodoro',
                scenario: NotificationScenario.reminder,
                audio: const NotificationAudio.silent(),
                progress: NotificationProgress(
                  title: '$modeLabel Progress',
                  value: progress.clamp(0.0, 1.0),
                  valueStringOverride: countUp
                      ? '$formattedTime elapsed ($progressPercent%)'
                      : '$formattedTime left ($progressPercent%)',
                  status: isRunning ? 'In Progress' : 'Paused',
                ),
                actions: [
                  NotificationAction(
                    content: isRunning ? 'Pause' : 'Resume',
                    arguments: 'action:toggle',
                    activationType: NotificationActivationType.foreground,
                  ),
                  const NotificationAction(
                    content: 'Next',
                    arguments: 'action:skip',
                    activationType: NotificationActivationType.foreground,
                  ),
                ],
              ),
            );
          } catch (e) {
            debugPrint('[NotificationService] Windows native progress error: $e');
          }
        } else {
          try {
            final bar = _buildAsciiProgressBar(progress);
            final title = isRunning
                ? '$modeLabel — $formattedTime'
                : '$modeLabel (Paused)';
            final body = isRunning
                ? (countUp
                    ? '$bar $progressPercent%\n$formattedTime elapsed'
                    : '$bar $progressPercent%\n$formattedTime remaining')
                : '$bar $progressPercent%\nPaused at $formattedTime';

            _windowsLiveNotification = LocalNotification(
              identifier: 'zeta_pomodoro_live',
              title: title,
              body: body,
            );
            await _windowsLiveNotification?.show();
          } catch (e) {
            debugPrint('[NotificationService] Windows live pomodoro fallback error: $e');
          }
        }
      }
    }
  }

  /// Cancels live Pomodoro progress notification on all platforms.
  Future<void> cancelPomodoroProgress() async {
    _windowsUserDismissedLive = false;
    _lastWindowsLiveUpdate = null;
    _lastWindowsRunningState = null;
    _lastWindowsMode = null;

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        try {
          await _plugin.cancel(id: _NotifIds.pomodoroLiveId);
        } catch (_) {}
      }
      if (Platform.isWindows) {
        try {
          await _winNotifier?.removeNotificationId('zeta_pomodoro_live', 'pomodoro');
        } catch (_) {}
        try {
          await _windowsLiveNotification?.close();
          _windowsLiveNotification = null;
        } catch (_) {}
      }
    }
  }

  static String _buildAsciiProgressBar(double progress, {int length = 10}) {
    final filled = (progress * length).round().clamp(0, length);
    final empty = length - filled;
    return '[${'█' * filled}${'░' * empty}]';
  }

  Future<void> showOverdueSummary(int count) async {
    if (!masterEnabled || !overdueAlertsEnabled) return;
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
    if (!masterEnabled) return;
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
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        try {
          await _plugin.cancelAll();
        } catch (_) {}
      }
      if (Platform.isWindows) {
        try {
          await _winNotifier?.clearNotificationHistory();
        } catch (_) {}
      }
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
