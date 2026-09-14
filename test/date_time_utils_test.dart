import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/utils/date_time_utils.dart';
import 'package:zeta/utils/task_date_formatter.dart';

void main() {
  group('DateTimeUtils & TaskDateFormatter standardization tests', () {
    test('isSameDay correctly identifies same or different calendar days', () {
      final a = DateTime(2026, 9, 14, 10, 30);
      final b = DateTime(2026, 9, 14, 23, 59);
      final c = DateTime(2026, 9, 15, 0, 1);

      expect(DateTimeUtils.isSameDay(a, b), isTrue);
      expect(DateTimeUtils.isSameDay(a, c), isFalse);
    });

    test('formatDateYMD outputs standard YYYY-MM-DD', () {
      final d = DateTime(2026, 9, 5);
      expect(DateTimeUtils.formatDateYMD(d), '2026-09-05');
    });

    test('formatHeadline matches calendar strip format', () {
      // 2026-09-14 is Monday
      final d = DateTime(2026, 9, 14);
      expect(DateTimeUtils.formatHeadline(d), 'Monday, 14 Sep');
    });

    test('formatFocusDate matches TodaysFocusCard format', () {
      final d = DateTime(2026, 9, 14);
      expect(DateTimeUtils.formatFocusDate(d), 'Monday, Sep 14');
    });

    test('formatStreakRange formats same month, different months, and inactive', () {
      expect(
        DateTimeUtils.formatStreakRange(hasActiveStreak: false),
        'Start today',
      );

      final start1 = DateTime(2026, 9, 10);
      final end1 = DateTime(2026, 9, 16);
      expect(
        DateTimeUtils.formatStreakRange(
          hasActiveStreak: true,
          rangeStart: start1,
          rangeEnd: end1,
        ),
        'Sep 10 – 16',
      );

      final start2 = DateTime(2026, 9, 28);
      final end2 = DateTime(2026, 10, 3);
      expect(
        DateTimeUtils.formatStreakRange(
          hasActiveStreak: true,
          rangeStart: start2,
          rangeEnd: end2,
        ),
        'Sep 28 – Oct 3',
      );
    });

    test('formatSelectedDay handles today and non-today', () {
      final today = DateTime(2026, 9, 14);
      final other = DateTime(2026, 9, 20);

      expect(
        DateTimeUtils.formatSelectedDay(today, today),
        'Today, Sep 14',
      );
      expect(
        DateTimeUtils.formatSelectedDay(other, today),
        'Sep 20',
      );
    });

    test('formatDeletedDate produces correct Bin chip label', () {
      final deleted = DateTime(2026, 9, 14, 15, 8);
      expect(
        DateTimeUtils.formatDeletedDate(deleted),
        'Deleted 14, Sep at 15:08',
      );
      expect(
        DateTimeUtils.formatDeletedDate(null),
        'Deleted recently',
      );
    });

    test('getWeeklyCalendarStripDays generates 7 days starting from Monday', () {
      final today = DateTime(2026, 9, 16); // Wednesday
      final days = DateTimeUtils.getWeeklyCalendarStripDays(today, 0);

      expect(days.length, 7);
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
      expect(days.first.day, 14); // Monday 14 Sep
      expect(days.last.day, 20);  // Sunday 20 Sep
    });

    test('TaskDateFormatter maintains full backwards compatibility', () {
      final now = DateTime.now();
      expect(TaskDateFormatter.isToday(TaskDateFormatter.format(now)), isTrue);
      expect(TaskDateFormatter.months, equals(DateTimeUtils.monthsShort));
      expect(
        TaskDateFormatter.formatTaskListDate(
          dueDate: 'Today',
          hasTime: true,
          dueTime: '10:00 AM',
        ),
        '10:00 AM',
      );
    });
  });
}
