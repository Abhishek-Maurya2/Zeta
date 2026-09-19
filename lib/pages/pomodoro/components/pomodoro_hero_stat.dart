import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/pomodoro.dart';
import 'pomodoro_chart_canvas.dart';

/// Hero stat widget displaying large total focus time, label, and detailed period breakdown.
class PomodoroHeroStat extends StatelessWidget {
  final ChartRange range;
  final int offset;
  final List<PomodoroSessionLog> sessionLog;

  const PomodoroHeroStat({
    super.key,
    required this.range,
    required this.offset,
    required this.sessionLog,
  });

  static String formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static String toLocalDateStr(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final todayStr = toLocalDateStr(now);

    int minutesToDisplay = 0;
    String subtitle = 'focus today';
    String? detailText;

    if (range == ChartRange.day) {
      final target = now.add(Duration(days: offset));
      final ds = toLocalDateStr(target);
      final entries = sessionLog.where(
        (e) =>
            toLocalDateStr(
                  DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                ) ==
                ds &&
            e.mode == PomodoroMode.focus,
      );
      minutesToDisplay = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      subtitle = ds == todayStr ? 'focus today' : 'focus recorded';
      if (minutesToDisplay > 0) {
        detailText =
            'Total ${formatDuration(minutesToDisplay)} focus recorded on this day';
      } else {
        detailText = 'No focus sessions recorded on this day';
      }
    } else if (range == ChartRange.week) {
      final startOfWeek = now
          .subtract(Duration(days: now.weekday % 7))
          .add(Duration(days: offset * 7));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return !d.isBefore(
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
            ) &&
            !d.isAfter(
              DateTime(
                endOfWeek.year,
                endOfWeek.month,
                endOfWeek.day,
                23,
                59,
                59,
              ),
            ) &&
            e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final daysCount = offset == 0 ? ((now.weekday % 7) + 1) : 7;
      minutesToDisplay = (total / math.max(1, daysCount)).round();
      subtitle = '/ day (avg)';

      int maxDayFocus = 0;
      for (int i = 0; i < 7; i++) {
        final d = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day + i,
        );
        final ds = toLocalDateStr(d);
        final dayMins = sessionLog
            .where(
              (e) =>
                  toLocalDateStr(
                        DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                      ) ==
                      ds &&
                  e.mode == PomodoroMode.focus,
            )
            .fold<int>(0, (s, e) => s + e.minutes);
        maxDayFocus = math.max(maxDayFocus, dayMins);
      }

      detailText =
          'Focused a total of ${formatDuration(total)} this week (Peak day: ${formatDuration(maxDayFocus)})';
    } else if (range == ChartRange.month) {
      final target = DateTime(now.year, now.month + offset, 1);
      final lastDay = DateTime(target.year, target.month + 1, 0).day;
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == target.year &&
            d.month == target.month &&
            e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final divisor = offset == 0 ? now.day : lastDay;
      minutesToDisplay = (total / math.max(1, divisor)).round();
      subtitle = 'per day (avg)';
      detailText =
          'Total ${formatDuration(total)} focus recorded in ${monthName(target.month)}';
    } else if (range == ChartRange.year) {
      final targetYear = now.year + offset;
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == targetYear && e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final daysCount = offset == 0
          ? math.max(1, now.difference(DateTime(now.year, 1, 1)).inDays + 1)
          : (DateTime(
                  targetYear,
                  12,
                  31,
                ).difference(DateTime(targetYear, 1, 1)).inDays +
                1);
      minutesToDisplay = (total / math.max(1, daysCount)).round();
      subtitle = 'per day (avg)';
      detailText =
          'Total ${formatDuration(total)} focus recorded in $targetYear';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              formatDuration(minutesToDisplay),
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (detailText != null) ...[
          const SizedBox(height: 6),
          Text(
            detailText,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
