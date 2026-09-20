import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../models/pomodoro.dart';
import 'pomodoro_chart_canvas.dart';

/// Hero stat widget displaying large total focus time, label, and detailed period breakdown chips.
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

    int? totalPeriodMinutes;
    int? peakDayMinutes;
    String? periodBadgeLabel;

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
      totalPeriodMinutes = minutesToDisplay;
      periodBadgeLabel = ds == todayStr ? 'Today' : '${target.day} ${monthName(target.month)}';
    } else if (range == ChartRange.week) {
      if (offset == 0) {
        final targetEndDay = DateTime(now.year, now.month, now.day);
        final startMs = DateTime(
          targetEndDay.year,
          targetEndDay.month,
          targetEndDay.day,
        ).subtract(const Duration(days: 6)).millisecondsSinceEpoch;
        final endMs = DateTime(
          targetEndDay.year,
          targetEndDay.month,
          targetEndDay.day,
          23,
          59,
          59,
        ).millisecondsSinceEpoch;

        final entries = sessionLog.where(
          (e) =>
              e.mode == PomodoroMode.focus &&
              e.completedAt >= startMs &&
              e.completedAt <= endMs,
        );
        totalPeriodMinutes = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        minutesToDisplay = (totalPeriodMinutes / 7).round();
        subtitle = '/ day (avg)';

        int maxDayMins = 0;
        for (int i = 0; i < 7; i++) {
          final d = targetEndDay.subtract(Duration(days: 6 - i));
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
          maxDayMins = math.max(maxDayMins, dayMins);
        }
        peakDayMinutes = maxDayMins;
        periodBadgeLabel = 'Last 7 days';
      } else {
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
        totalPeriodMinutes = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        minutesToDisplay = (totalPeriodMinutes / 7).round();
        subtitle = '/ day (avg)';

        int maxDayMins = 0;
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
          maxDayMins = math.max(maxDayMins, dayMins);
        }
        peakDayMinutes = maxDayMins;
        periodBadgeLabel = 'Last week';
      }
    } else if (range == ChartRange.month) {
      if (offset == 0) {
        final targetEndDay = DateTime(now.year, now.month, now.day);
        final startMs = DateTime(
          targetEndDay.year,
          targetEndDay.month,
          targetEndDay.day,
        ).subtract(const Duration(days: 27)).millisecondsSinceEpoch;
        final endMs = DateTime(
          targetEndDay.year,
          targetEndDay.month,
          targetEndDay.day,
          23,
          59,
          59,
        ).millisecondsSinceEpoch;

        final entries = sessionLog.where(
          (e) =>
              e.mode == PomodoroMode.focus &&
              e.completedAt >= startMs &&
              e.completedAt <= endMs,
        );
        totalPeriodMinutes = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        minutesToDisplay = (totalPeriodMinutes / 28).round();
        subtitle = 'per day (avg)';
        periodBadgeLabel = 'Last 4 weeks';
      } else {
        final target = DateTime(now.year, now.month + offset, 1);
        final lastDay = DateTime(target.year, target.month + 1, 0).day;
        final entries = sessionLog.where((e) {
          final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
          return d.year == target.year &&
              d.month == target.month &&
              e.mode == PomodoroMode.focus;
        });
        totalPeriodMinutes = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        minutesToDisplay = (totalPeriodMinutes / lastDay).round();
        subtitle = 'per day (avg)';
        periodBadgeLabel = '${monthName(target.month)} ${target.year}';
      }
    } else if (range == ChartRange.year) {
      if (offset == 0) {
        final targetEndMonth = DateTime(now.year, now.month, 1);
        final startMonth = DateTime(
          targetEndMonth.year,
          targetEndMonth.month - 11,
          1,
        );
        final endMonth = DateTime(
          targetEndMonth.year,
          targetEndMonth.month + 1,
          0,
          23,
          59,
          59,
        );

        final entries = sessionLog.where((e) {
          if (e.mode != PomodoroMode.focus) return false;
          final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
          return !d.isBefore(startMonth) && !d.isAfter(endMonth);
        });
        totalPeriodMinutes = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        minutesToDisplay = (totalPeriodMinutes / 365).round();
        subtitle = 'per day (avg)';
        periodBadgeLabel = 'Last 12 months';
      } else {
        final targetYear = now.year + offset;
        final entries = sessionLog.where((e) {
          final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
          return d.year == targetYear && e.mode == PomodoroMode.focus;
        });
        totalPeriodMinutes = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        final daysCount =
            (DateTime(
              targetYear,
              12,
              31,
            ).difference(DateTime(targetYear, 1, 1)).inDays +
            1);
        minutesToDisplay = (totalPeriodMinutes / daysCount).round();
        subtitle = 'per day (avg)';
        periodBadgeLabel = '$targetYear';
      }
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
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (totalPeriodMinutes != null && totalPeriodMinutes > 0)
              _StatChip(
                icon: Icons.timer_outlined,
                label: 'Total',
                value: formatDuration(totalPeriodMinutes),
                backgroundColor: colorScheme.secondaryContainer,
                textColor: colorScheme.onSecondaryContainer,
              ),
            if (peakDayMinutes != null && peakDayMinutes > 0)
              _StatChip(
                icon: Icons.bolt_rounded,
                label: 'Peak day',
                value: formatDuration(peakDayMinutes),
                backgroundColor: colorScheme.tertiaryContainer,
                textColor: colorScheme.onTertiaryContainer,
              ),
            if (periodBadgeLabel != null && range != ChartRange.day)
              _StatChip(
                icon: Icons.calendar_today_rounded,
                label: 'Period',
                value: periodBadgeLabel,
                backgroundColor: colorScheme.surfaceContainerHigh,
                textColor: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
