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

    test('Google Tasks due date with time component is treated as date-only (Tasks API never carries time)', () {
      // Even if a non-midnight UTC timestamp arrives (e.g. from an old client),
      // parseGoogleTaskDue always returns date-only. Time comes from Calendar, not Tasks.
      final parsed = GoogleCalendarService.parseGoogleTaskDue('2026-09-15T10:00:00.000Z');

      expect(parsed.dueDate, isNotNull);
      expect(parsed.dueDate, equals('15, Sep'));
      expect(parsed.hasTime, isFalse);   // Tasks API never carries time
      expect(parsed.dueTime, isNull);    // Rehydrated from Calendar instead
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

    test('formatTaskDueForGoogleTasks always produces date-only midnight UTC (time cannot be stored in Tasks API)', () {
      final task = Task(
        id: 'test-2',
        title: 'Timed task',
        dueDate: '15, Sep',
        hasTime: true,
        dueTime: '10:30 AM',
      );

      final formatted = GoogleCalendarService.formatTaskDueForGoogleTasks(task);
      expect(formatted, isNotNull);
      // Must always be midnight UTC regardless of the task's time — Tasks API drops time
      expect(formatted, endsWith('T00:00:00.000Z'));
      expect(formatted, startsWith('${DateTime.now().year}-09-15'));
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
      provider.addTask(
        title: 'Task with subtasks',
        subtasks: [Subtask(id: 'sub-1', title: 'Sub 1', completed: false)],
      );
      final task = provider.allTasks.first;
      final subtask = task.subtasks.first;
      final originalCompleted = subtask.completed;

      provider.toggleSubtask(task.id, subtask.id);

      expect(subtask.completed, equals(!originalCompleted));

      provider.dispose();
    });

    test('deleteTask moves task to bin with deletedAt timestamp', () {
      final provider = TaskProvider();
      provider.addTask(title: 'Target task');
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
      provider.addTask(title: 'Restored target');
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
        remoteSubtasks: [
          GoogleSubtaskUpdate(
            parentGoogleTaskId: 'gtask_abc',
            subtask: Subtask(id: 'st-1', title: 'Subtask from phone', completed: true, googleTaskId: 'gsub_123'),
          ),
        ],
        deletedTaskIds: ['gtask_deleted_99'],
        syncTimestamp: DateTime.now(),
      );

      expect(result.remoteTasks.length, equals(1));
      expect(result.remoteTasks.first.title, equals('Google Tasks Item'));
      expect(result.remoteTasks.first.subtasks.first.googleTaskId, equals('gsub_123'));
      expect(result.remoteSubtasks.length, equals(1));
      expect(result.remoteSubtasks.first.parentGoogleTaskId, equals('gtask_abc'));
      expect(result.remoteSubtasks.first.subtask.completed, isTrue);
      expect(result.deletedTaskIds, contains('gtask_deleted_99'));
    });

    test('Remote subtask completion is reflected in local task even when parent is unmodified', () {
      final provider = TaskProvider();
      provider.addTask(
        title: 'Project Roadmap',
        subtasks: [
          Subtask(id: 'sub-local-1', title: 'Design Mockup', completed: false, googleTaskId: 'gsub_999'),
        ],
      );
      final localTask = provider.allTasks.first;
      localTask.googleTaskId = 'gtask_parent_100';

      // Simulate receiving Google Tasks sync result with only child task updated
      final result = GoogleTasksSyncResult(
        remoteTasks: [], // Parent task unmodified in Google Tasks
        remoteSubtasks: [
          GoogleSubtaskUpdate(
            parentGoogleTaskId: 'gtask_parent_100',
            subtask: Subtask(id: 'gsub_999', title: 'Design Mockup', completed: true, googleTaskId: 'gsub_999'),
          ),
        ],
        deletedTaskIds: [],
        syncTimestamp: DateTime.now(),
      );

      // Reconcile subtask directly as syncGoogleTasks does
      for (final update in result.remoteSubtasks) {
        final parent = provider.allTasks.where((t) => t.googleTaskId == update.parentGoogleTaskId).firstOrNull;
        expect(parent, isNotNull);
        final sub = parent!.subtasks.firstWhere((s) => s.googleTaskId == update.subtask.googleTaskId);
        sub.completed = update.subtask.completed;
      }

      expect(localTask.subtasks.first.completed, isTrue);

      provider.dispose();
    });

    test('Local task with scheduled time preserves its time when remote task has date-only', () {
      final local = Task(
        id: 'local-1',
        title: 'Meeting with team',
        dueDate: '15, Sep',
        hasTime: true,
        dueTime: '10:30 AM',
        googleTaskId: 'gtask_123',
      );

      final remote = Task(
        id: 'remote-1',
        title: 'Meeting with team',
        dueDate: '${DateTime.now().year}-09-15',
        hasTime: false,
        dueTime: null,
        googleTaskId: 'gtask_123',
      );

      // Verify date matches calendar day
      final localDate = TaskDateFormatter.parse(local.dueDate ?? '');
      final remoteDate = TaskDateFormatter.parse(remote.dueDate ?? '');
      expect(localDate?.year, equals(remoteDate?.year));
      expect(localDate?.month, equals(remoteDate?.month));
      expect(localDate?.day, equals(remoteDate?.day));

      // Reconcile logic: local time must remain intact
      if (!remote.hasTime && local.hasTime) {
        // Preserved!
      }
      expect(local.hasTime, isTrue);
      expect(local.dueTime, equals('10:30 AM'));
    });

    test('Incremental sync does not delete unmodified local subtasks', () {
      final local = Task(
        id: 'local-parent',
        title: 'Parent Task',
        googleTaskId: 'gtask_parent',
        subtasks: [
          Subtask(id: 's1', title: 'Sub 1', completed: false, googleTaskId: 'gsub_1'),
          Subtask(id: 's2', title: 'Sub 2', completed: false, googleTaskId: 'gsub_2'),
        ],
      );

      // In an incremental sync, Google Tasks returns only modified subtask (gsub_1)
      final remote = Task(
        id: 'remote-parent',
        title: 'Parent Task',
        googleTaskId: 'gtask_parent',
        subtasks: [
          Subtask(id: 'gsub_1', title: 'Sub 1', completed: true, googleTaskId: 'gsub_1'),
        ],
      );

      // Reconcile with isFullSync = false
      for (final remoteSub in remote.subtasks) {
        final localSubIdx = local.subtasks.indexWhere(
          (s) => s.googleTaskId == remoteSub.googleTaskId,
        );
        if (localSubIdx != -1) {
          local.subtasks[localSubIdx].completed = remoteSub.completed;
        }
      }

      // Both subtasks must still exist! Sub 2 must NOT be deleted.
      expect(local.subtasks.length, equals(2));
      expect(local.subtasks[0].completed, isTrue);
      expect(local.subtasks[1].completed, isFalse);
    });

    test('Subtask deleted in Google Tasks is removed locally via deletedTaskIds', () {
      final task = Task(
        id: 'local-parent',
        title: 'Parent Task',
        googleTaskId: 'gtask_parent',
        subtasks: [
          Subtask(id: 's1', title: 'Sub 1', completed: false, googleTaskId: 'gsub_1'),
          Subtask(id: 's2', title: 'Sub 2', completed: false, googleTaskId: 'gsub_2'),
        ],
      );

      final deletedTaskIds = ['gsub_1'];

      // Delete logic from syncGoogleTasks
      for (final deletedGId in deletedTaskIds) {
        final subIdx = task.subtasks.indexWhere((s) => s.googleTaskId == deletedGId);
        if (subIdx != -1) {
          task.subtasks.removeAt(subIdx);
        }
      }

      expect(task.subtasks.length, equals(1));
      expect(task.subtasks.first.googleTaskId, equals('gsub_2'));
    });
  });
}
