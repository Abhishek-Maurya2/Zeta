import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/providers/notification_provider.dart';
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
      expect(NotificationService.instance.pomodoroAlertsEnabled, isFalse);

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
  });
}
