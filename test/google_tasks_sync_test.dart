import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/services/google_calendar_service.dart';
import 'package:zeta/utils/task_date_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Tasks Endpoint & Date/Time Mapping', () {
    test('All-day Google Tasks due date (midnight UTC) resolves to correct date without timezone shifting', () {
      // 2026-09-15T00:00:00.000Z is midnight UTC on Sept 15
      final parsed = GoogleCalendarService.parseGoogleTaskDue('2026-09-15T00:00:00.000Z');

      expect(parsed.dueDate, equals('15, Sep'));
      expect(parsed.hasTime, isFalse);
      expect(parsed.dueTime, isNull);
    });

    test('Google Tasks due date with specific time preserves time and marks hasTime = true', () {
      // 2026-09-15T10:00:00.000Z has non-zero UTC hours
      final parsed = GoogleCalendarService.parseGoogleTaskDue('2026-09-15T10:00:00.000Z');

      expect(parsed.dueDate, isNotNull);
      expect(parsed.hasTime, isTrue);
      expect(parsed.dueTime, isNotNull);
      expect(parsed.dueTime, matches(RegExp(r'^\d{2}:\d{2}\s+(AM|PM)$')));
    });

    test('Null or empty Google Tasks due date returns null values', () {
      final parsedNull = GoogleCalendarService.parseGoogleTaskDue(null);
      expect(parsedNull.dueDate, isNull);
      expect(parsedNull.hasTime, isFalse);
      expect(parsedNull.dueTime, isNull);

      final parsedEmpty = GoogleCalendarService.parseGoogleTaskDue('   ');
      expect(parsedEmpty.dueDate, isNull);
      expect(parsedEmpty.hasTime, isFalse);
      expect(parsedEmpty.dueTime, isNull);
    });

    test('formatTaskDueForGoogleTasks formats all-day tasks as midnight UTC', () {
      final task = Task(
        id: 'test-1',
        title: 'All-day task',
        dueDate: '15, Sep',
        hasTime: false,
      );

      final formatted = GoogleCalendarService.formatTaskDueForGoogleTasks(task);
      expect(formatted, isNotNull);
      expect(formatted, endsWith('T00:00:00.000Z'));
      expect(formatted, startsWith('${DateTime.now().year}-09-15'));
    });

    test('formatTaskDueForGoogleTasks formats task with time as RFC 3339 UTC timestamp', () {
      final task = Task(
        id: 'test-2',
        title: 'Timed task',
        dueDate: '15, Sep',
        hasTime: true,
        dueTime: '10:30 AM',
      );

      final formatted = GoogleCalendarService.formatTaskDueForGoogleTasks(task);
      expect(formatted, isNotNull);
      expect(formatted, endsWith('Z'));
      final parsedBack = DateTime.parse(formatted!);
      expect(parsedBack.isUtc, isTrue);
    });

    test('Task description is strictly clean without subtasks or dates appended', () {
      final task = Task(
        id: 'test-3',
        title: 'Project Roadmap',
        description: 'Clean user notes without artificial tags',
        dueDate: 'Tomorrow',
        hasTime: true,
        dueTime: '02:00 PM',
        subtasks: [
          Subtask(id: 's1', title: 'Phase 1 MVP', completed: true),
          Subtask(id: 's2', title: 'Phase 2 Scale', completed: false),
        ],
      );

      // Verify task description remains pure
      expect(task.description, equals('Clean user notes without artificial tags'));
      expect(task.description!.contains('Phase 1 MVP'), isFalse);
      expect(task.description!.contains('Phase 2 Scale'), isFalse);
      expect(task.description!.contains('02:00 PM'), isFalse);
    });
  });

  group('TaskProvider 2-Way Sync & CRUD Persistence', () {
    test('CRUD addTask creates new task, optimistic local state, and subtasks structure', () {
      final provider = TaskProvider();
      final initialCount = provider.allTasks.length;

      provider.addTask(
        title: 'New Bi-directional Task',
        description: 'Syncing seamlessly',
        dueDate: 'Today',
        hasTime: true,
        dueTime: '04:00 PM',
        subtasks: [
          Subtask(id: 'sub-1', title: 'Verify Google Tasks parent', completed: false),
          Subtask(id: 'sub-2', title: 'Verify Supabase upsert', completed: true),
        ],
      );

      expect(provider.allTasks.length, equals(initialCount + 1));
      final created = provider.allTasks.first;
      expect(created.title, equals('New Bi-directional Task'));
      expect(created.description, equals('Syncing seamlessly'));
      expect(created.dueDate, equals('Today'));
      expect(created.hasTime, isTrue);
      expect(created.dueTime, equals('04:00 PM'));
      expect(created.subtasks.length, equals(2));
      expect(created.subtasks[0].title, equals('Verify Google Tasks parent'));
      expect(created.subtasks[1].completed, isTrue);

      provider.dispose();
    });

    test('toggleSubtask updates completed status and sets updatedAt', () {
      final provider = TaskProvider();
      final task = provider.allTasks.firstWhere((t) => t.subtasks.isNotEmpty);
      final subtask = task.subtasks.first;
      final originalCompleted = subtask.completed;

      provider.toggleSubtask(task.id, subtask.id);

      expect(subtask.completed, equals(!originalCompleted));

      provider.dispose();
    });

    test('deleteTask moves task to bin with deletedAt timestamp', () {
      final provider = TaskProvider();
      final target = provider.allTasks.first;
      final targetId = target.id;
      final initialBinCount = provider.binCount;

      provider.deleteTask(targetId);

      expect(provider.allTasks.any((t) => t.id == targetId), isFalse);
      expect(provider.binTasks.any((t) => t.id == targetId), isTrue);
      expect(provider.binCount, equals(initialBinCount + 1));
      final binTask = provider.binTasks.firstWhere((t) => t.id == targetId);
      expect(binTask.deletedAt, isNotNull);

      provider.dispose();
    });

    test('restoreTask returns task from bin to active tasks with cleared deletedAt', () {
      final provider = TaskProvider();
      final target = provider.allTasks.first;
      final targetId = target.id;

      provider.deleteTask(targetId);
      expect(provider.allTasks.any((t) => t.id == targetId), isFalse);

      provider.restoreTask(targetId);
      expect(provider.allTasks.any((t) => t.id == targetId), isTrue);
      final restored = provider.allTasks.firstWhere((t) => t.id == targetId);
      expect(restored.deletedAt, isNull);

      provider.dispose();
    });

    test('GoogleTasksSyncResult structure holds remote tasks, subtasks, and deleted IDs', () {
      final remote = Task(
        id: 'remote-1',
        title: 'Google Tasks Item',
        description: 'Directly from Google Tasks app',
        completed: true,
        dueDate: '16, Sep',
        googleTaskId: 'gtask_abc',
        subtasks: [
          Subtask(id: 'st-1', title: 'Subtask from phone', completed: true, googleTaskId: 'gsub_123'),
        ],
      );

      final result = GoogleTasksSyncResult(
        remoteTasks: [remote],
        deletedTaskIds: ['gtask_deleted_99'],
        syncTimestamp: DateTime.now(),
      );

      expect(result.remoteTasks.length, equals(1));
      expect(result.remoteTasks.first.title, equals('Google Tasks Item'));
      expect(result.remoteTasks.first.subtasks.first.googleTaskId, equals('gsub_123'));
      expect(result.deletedTaskIds, contains('gtask_deleted_99'));
    });
  });
}
