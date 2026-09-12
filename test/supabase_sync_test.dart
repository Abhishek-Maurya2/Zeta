import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/models/task.dart';
import 'package:zeta/utils/task_date_formatter.dart';

void main() {
  group('Supabase Task Row Serialization & Deserialization', () {
    test('Task correctly maps to Supabase PostgreSQL row', () {
      final task = Task(
        id: '12345678-1234-4234-8234-123456789abc',
        title: 'Complete Supabase Integration',
        description: 'Bi-directional sync and Google Calendar mapping',
        completed: false,
        dueDate: 'Today',
        hasTime: true,
        dueTime: '10:30 AM',
        subtasks: [
          Subtask(id: 's1', title: 'Connect Realtime', completed: true),
          Subtask(id: 's2', title: 'Verify Google Tasks', completed: false),
        ],
        googleEventId: 'abc123event',
        googleTaskId: 'xyz456gtask',
      );

      final row = task.toSupabaseRow(defaultUserId: 'singleton');

      expect(row['id'], equals('12345678-1234-4234-8234-123456789abc'));
      expect(row['user_id'], equals('singleton'));
      expect(row['title'], equals('Complete Supabase Integration'));
      expect(row['description'], equals('Bi-directional sync and Google Calendar mapping'));
      expect(row['completed'], isFalse);
      expect(row['has_time'], isTrue);
      expect(row['google_event_id'], equals('abc123event'));
      expect(row['google_task_id'], equals('xyz456gtask'));

      final subtasks = row['subtasks'] as List<dynamic>;
      expect(subtasks.length, equals(2));
      expect(subtasks[0]['title'], equals('Connect Realtime'));
      expect(subtasks[0]['completed'], isTrue);
      expect(subtasks[1]['title'], equals('Verify Google Tasks'));
      expect(subtasks[1]['completed'], isFalse);
    });

    test('Non-UUID task ID is safely converted to valid UUID format in toSupabaseRow', () {
      final task = Task(
        id: '1',
        title: 'Short legacy id',
      );

      final row = task.toSupabaseRow();
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      expect(uuidRegex.hasMatch(row['id'] as String), isTrue);
    });

    test('Task is correctly reconstructed from Supabase PostgreSQL row', () {
      final sampleRow = {
        'id': 'b249b552-b407-4e8d-aa8a-ba32c61a0311',
        'user_id': 'singleton',
        'title': 'Population Study',
        'description': 'Chapter 4 demographics notes',
        'completed': true,
        'due_date': '2026-09-12T04:30:00.000Z',
        'has_time': true,
        'subtasks': [
          {'id': 'sub-1', 'title': 'Demographic dividend', 'completed': true},
          {'id': 'sub-2', 'title': 'Census indicators', 'completed': true},
        ],
        'deleted_at': null,
        'created_at': '2026-09-10T12:00:00.000Z',
        'updated_at': '2026-09-12T04:35:00.000Z',
        'google_event_id': 'gcal_123',
        'google_task_id': 'gtask_456',
        'google_etag': 'etag_abc',
        'last_synced_at': '2026-09-12T04:35:00.000Z',
      };

      final task = Task.fromSupabaseRow(sampleRow);

      expect(task.id, equals('b249b552-b407-4e8d-aa8a-ba32c61a0311'));
      expect(task.userId, equals('singleton'));
      expect(task.title, equals('Population Study'));
      expect(task.description, equals('Chapter 4 demographics notes'));
      expect(task.completed, isTrue);
      expect(task.hasTime, isTrue);
      expect(task.subtasks.length, equals(2));
      expect(task.subtasks.first.title, equals('Demographic dividend'));
      expect(task.subtasks.first.completed, isTrue);
      expect(task.googleEventId, equals('gcal_123'));
      expect(task.googleTaskId, equals('gtask_456'));
      expect(task.deletedAt, isNull);
    });

    test('Soft deleted task retains deletedAt timestamp from Supabase', () {
      final deletedRow = {
        'id': '8c3101da-05ad-40bd-a2b9-1fad300c54d9',
        'user_id': 'singleton',
        'title': 'Bin task',
        'completed': false,
        'deleted_at': '2026-09-11T10:00:00.000Z',
      };

      final task = Task.fromSupabaseRow(deletedRow);

      expect(task.id, equals('8c3101da-05ad-40bd-a2b9-1fad300c54d9'));
      expect(task.deletedAt, isNotNull);
    });

    test('TaskDateFormatter correctly parses varied formats', () {
      final today = TaskDateFormatter.parse('Today');
      expect(today, isNotNull);

      final tomorrow = TaskDateFormatter.parse('Tomorrow');
      expect(tomorrow, isNotNull);
      expect(tomorrow!.isAfter(today!), isTrue);

      final calendarDate = TaskDateFormatter.parse('15, Sep');
      expect(calendarDate, isNotNull);
      expect(calendarDate!.day, equals(15));
      expect(calendarDate.month, equals(9));
    });
  });
}
