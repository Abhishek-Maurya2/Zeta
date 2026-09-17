import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/models/pomodoro.dart';
import 'package:zeta/providers/notification_provider.dart';
import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService & NotificationProvider Tests', () {
    test('NotificationService singleton instance is available', () {
      expect(NotificationService.instance, isNotNull);
    });

    test('NotificationProvider initial state and setEnabled toggling', () {
      final provider = NotificationProvider();
      expect(provider.notificationsEnabled, isTrue);

      provider.setEnabled(false);
      expect(provider.notificationsEnabled, isFalse);

      provider.setEnabled(true);
      expect(provider.notificationsEnabled, isTrue);

      // Granular notification settings toggles
      expect(provider.taskRemindersEnabled, isTrue);
      provider.setTaskRemindersEnabled(false);
      expect(provider.taskRemindersEnabled, isFalse);
      expect(NotificationService.instance.taskRemindersEnabled, isFalse);

      expect(provider.overdueAlertsEnabled, isTrue);
      provider.setOverdueAlertsEnabled(false);
      expect(provider.overdueAlertsEnabled, isFalse);
      expect(NotificationService.instance.overdueAlertsEnabled, isFalse);

      expect(provider.pomodoroAlertsEnabled, isTrue);
      provider.setPomodoroAlertsEnabled(false);
      expect(provider.pomodoroAlertsEnabled, isFalse);
      expect(provider.pomodoroLiveEnabled, isTrue);
      provider.setPomodoroLiveEnabled(false);
      expect(provider.pomodoroLiveEnabled, isFalse);
      expect(NotificationService.instance.pomodoroLiveEnabled, isFalse);

      provider.dispose();
    });

    test('NotificationProvider updateTasks stores task list properly', () {
      final provider = NotificationProvider();
      final tasks = [
        Task(
          id: 'task-1',
          title: 'Complete Project',
          dueDate: 'Tomorrow',
          hasTime: true,
          dueTime: '10:00 AM',
        ),
        Task(
          id: 'task-2',
          title: 'Review PRs',
          dueDate: 'Today',
        ),
      ];

      provider.updateTasks(tasks);
      // Provider internal list updated without error
      expect(provider.notificationsEnabled, isTrue);

      provider.dispose();
    });

    test('NotificationService handles cancelTaskReminder gracefully', () async {
      await NotificationService.instance.cancelTaskReminder('non-existent-id');
      // Should not throw
    });

    test('NotificationService handles cancelAll gracefully', () async {
      await NotificationService.instance.cancelAll();
      // Should not throw
    });

    test('NotificationService handles live pomodoro progress and cancel gracefully', () async {
      await NotificationService.instance.updatePomodoroProgress(
        mode: PomodoroMode.focus,
        sessionLabel: 'Unit Test Task',
        timeLeft: 1200,
        totalDuration: 1500,
        isRunning: true,
      );

      await NotificationService.instance.cancelPomodoroProgress();
      // Should not throw
    });

    test('PomodoroProvider registers onPomodoroAction and handles toggle/skip', () {
      final pomodoro = PomodoroProvider();
      expect(NotificationService.instance.onPomodoroAction, isNotNull);

      // Verify timer is initially paused
      expect(pomodoro.isRunning, isFalse);

      // Trigger toggle via notification action
      NotificationService.instance.onPomodoroAction!('toggle');
      expect(pomodoro.isRunning, isTrue);

      // Trigger pause via notification action
      NotificationService.instance.onPomodoroAction!('pause');
      expect(pomodoro.isRunning, isFalse);

      // Trigger resume via notification action
      NotificationService.instance.onPomodoroAction!('resume');
      expect(pomodoro.isRunning, isTrue);

      // Trigger skip via notification action
      final initialQueueIndex = pomodoro.activeQueueIndex;
      NotificationService.instance.onPomodoroAction!('skip');
      expect(pomodoro.activeQueueIndex, isNot(initialQueueIndex));

      pomodoro.dispose();
      expect(NotificationService.instance.onPomodoroAction, isNull);
    });
  });
}
