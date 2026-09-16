import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/models/pomodoro.dart';

void main() {
  group('PomodoroSessionLog Supabase Row Serialization & Deserialization', () {
    test('PomodoroSessionLog correctly maps to Supabase PostgreSQL row', () {
      const completedAtMs = 1788846083470; // 2026-09-08T05:41:23.470Z
      const session = PomodoroSessionLog(
        id: '1788846083470-nmmx',
        mode: PomodoroMode.focus,
        minutes: 25,
        completedAt: completedAtMs,
      );

      final row = session.toSupabaseRow(defaultUserId: 'user-123');

      expect(row['id'], equals('1788846083470-nmmx'));
      expect(row['user_id'], equals('user-123'));
      expect(row['mode'], equals('focus'));
      expect(row['minutes'], equals(25));
      expect(
        row['completed_at'],
        equals(
          DateTime.fromMillisecondsSinceEpoch(completedAtMs, isUtc: true)
              .toIso8601String(),
        ),
      );
    });

    test('Short break and long break modes map to valid Supabase check constraint values', () {
      const shortSession = PomodoroSessionLog(
        id: 'session-short',
        mode: PomodoroMode.shortBreak,
        minutes: 5,
        completedAt: 1700000000000,
      );
      final shortRow = shortSession.toSupabaseRow();
      expect(shortRow['mode'], equals('short_break'));
      expect(shortRow['user_id'], equals('singleton'));

      const longSession = PomodoroSessionLog(
        id: 'session-long',
        mode: PomodoroMode.longBreak,
        minutes: 15,
        completedAt: 1700000000000,
      );
      final longRow = longSession.toSupabaseRow();
      expect(longRow['mode'], equals('long_break'));
    });

    test('PomodoroSessionLog correctly reconstructs from Supabase PostgreSQL row', () {
      final sampleRow = {
        'id': '1788846154325-yr7l',
        'user_id': 'singleton',
        'mode': 'short_break',
        'minutes': 5,
        'completed_at': '2026-09-08T05:42:34.325Z',
        'created_at': '2026-09-08T05:42:34.983819Z',
      };

      final session = PomodoroSessionLog.fromSupabaseRow(sampleRow);

      expect(session.id, equals('1788846154325-yr7l'));
      expect(session.mode, equals(PomodoroMode.shortBreak));
      expect(session.minutes, equals(5));
      expect(
        session.completedAt,
        equals(DateTime.parse('2026-09-08T05:42:34.325Z').millisecondsSinceEpoch),
      );
    });

    test('Deduplicates and merges remote and local sessions by ID', () {
      final localSessions = [
        const PomodoroSessionLog(
          id: 'local-1',
          mode: PomodoroMode.focus,
          minutes: 25,
          completedAt: 1000,
        ),
        const PomodoroSessionLog(
          id: 'shared-2',
          mode: PomodoroMode.shortBreak,
          minutes: 5,
          completedAt: 2000,
        ),
      ];

      final remoteSessions = [
        const PomodoroSessionLog(
          id: 'shared-2',
          mode: PomodoroMode.shortBreak,
          minutes: 5,
          completedAt: 2000,
        ),
        const PomodoroSessionLog(
          id: 'remote-3',
          mode: PomodoroMode.focus,
          minutes: 50,
          completedAt: 3000,
        ),
      ];

      final existingIds = localSessions.map((s) => s.id).toSet();
      final merged = List<PomodoroSessionLog>.from(localSessions);

      for (final remote in remoteSessions) {
        if (!existingIds.contains(remote.id)) {
          merged.add(remote);
          existingIds.add(remote.id);
        }
      }

      expect(merged.length, equals(3));
      expect(merged.map((s) => s.id).toList(), equals(['local-1', 'shared-2', 'remote-3']));
    });
  });
}
