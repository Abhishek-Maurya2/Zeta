import 'package:zeta/core/core.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../models/pomodoro.dart';
import 'pomodoro_chart_canvas.dart';

/// Row of 3 summary cards: Total Focus, Sessions Done, and Active Days.
/// Uses [M3EShapeContainer] for expressive shape iconography.
/// Filters data based on the selected [ChartRange] and [offset].
class PomodoroSummaryCards extends StatelessWidget {
  final List<PomodoroSessionLog> sessionLog;
  final ChartRange range;
  final int offset;

  const PomodoroSummaryCards({
    super.key,
    required this.sessionLog,
    required this.range,
    required this.offset,
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

  /// Returns the filtered list of focus sessions for the selected period.
  List<PomodoroSessionLog> _filteredFocusSessions() {
    final now = DateTime.now();
    final focusSessions =
        sessionLog.where((e) => e.mode == PomodoroMode.focus);

    switch (range) {
      case ChartRange.day:
        final target = now.add(Duration(days: offset));
        final ds = toLocalDateStr(target);
        return focusSessions.where((e) {
          final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
          return toLocalDateStr(d) == ds;
        }).toList();

      case ChartRange.week:
        if (offset == 0) {
          // Rolling 7 days ending today
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
          return focusSessions
              .where(
                (e) => e.completedAt >= startMs && e.completedAt <= endMs,
              )
              .toList();
        } else {
          // Previous calendar week (Sun-Sat)
          final startOfWeek = now
              .subtract(Duration(days: now.weekday % 7))
              .add(Duration(days: offset * 7));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          final startMs = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          ).millisecondsSinceEpoch;
          final endMs = DateTime(
            endOfWeek.year,
            endOfWeek.month,
            endOfWeek.day,
            23,
            59,
            59,
          ).millisecondsSinceEpoch;
          return focusSessions
              .where(
                (e) => e.completedAt >= startMs && e.completedAt <= endMs,
              )
              .toList();
        }

      case ChartRange.month:
        if (offset == 0) {
          // Rolling 4 weeks (28 days) ending today
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
          return focusSessions
              .where(
                (e) => e.completedAt >= startMs && e.completedAt <= endMs,
              )
              .toList();
        } else {
          // Previous calendar month
          final target = DateTime(now.year, now.month + offset, 1);
          return focusSessions.where((e) {
            final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
            return d.year == target.year && d.month == target.month;
          }).toList();
        }

      case ChartRange.year:
        if (offset == 0) {
          // Rolling 12 months ending at current month
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
          return focusSessions.where((e) {
            final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
            return !d.isBefore(startMonth) && !d.isAfter(endMonth);
          }).toList();
        } else {
          // Previous calendar year
          final targetYear = now.year + offset;
          return focusSessions.where((e) {
            final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
            return d.year == targetYear;
          }).toList();
        }
    }
  }

  static String _monthName(int month) {
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

  String _periodLabel() {
    final now = DateTime.now();
    final todayStr = toLocalDateStr(now);
    final yesterdayStr = toLocalDateStr(now.subtract(const Duration(days: 1)));

    switch (range) {
      case ChartRange.day:
        final target = now.add(Duration(days: offset));
        final ds = toLocalDateStr(target);
        if (ds == todayStr) return 'Today';
        if (ds == yesterdayStr) return 'Yesterday';
        return '${target.day} ${_monthName(target.month)}';

      case ChartRange.week:
        if (offset == 0) return 'This week';
        if (offset == -1) return 'Last week';
        final startOfWeek = now
            .subtract(Duration(days: now.weekday % 7))
            .add(Duration(days: offset * 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${startOfWeek.day} ${_monthName(startOfWeek.month)} - ${endOfWeek.day} ${_monthName(endOfWeek.month)}';

      case ChartRange.month:
        if (offset == 0) return 'This month';
        final target = DateTime(now.year, now.month + offset, 1);
        return '${_monthName(target.month)} ${target.year}';

      case ChartRange.year:
        if (offset == 0) return 'This year';
        return '${now.year + offset}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final filteredSessions = _filteredFocusSessions();
    final totalFocusMinutes = filteredSessions.fold<int>(
      0,
      (sum, e) => sum + e.minutes,
    );
    final totalSessionsCount = filteredSessions.length;

    // Active days count
    final daysMap = <String, int>{};
    for (final e in filteredSessions) {
      final ds = toLocalDateStr(
        DateTime.fromMillisecondsSinceEpoch(e.completedAt),
      );
      daysMap[ds] = (daysMap[ds] ?? 0) + e.minutes;
    }
    final daysActive = daysMap.length;

    // Contextual label for the third card
    final String activeDaysLabel;
    switch (range) {
      case ChartRange.day:
        activeDaysLabel = 'Hours Active';
      case ChartRange.week:
        activeDaysLabel = 'Active Days';
      case ChartRange.month:
        activeDaysLabel = 'Active Days';
      case ChartRange.year:
        activeDaysLabel = 'Active Days';
    }

    // For Day range, show active hours instead of active days
    final String activeDaysValue;
    if (range == ChartRange.day) {
      // Count unique hours with focus activity
      final hoursSet = <int>{};
      for (final e in filteredSessions) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        hoursSet.add(d.hour);
      }
      activeDaysValue = '${hoursSet.length}h';
    } else {
      activeDaysValue = '$daysActive days';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period label
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _periodLabel(),
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Focus Time Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      M3EShapeContainer(
                        kind: M3EShapeKind.cookie4Sided,
                        width: 45,
                        height: 45,
                        color: colorScheme.onPrimaryContainer,
                        child: Center(
                          child: Icon(
                            Icons.timer_rounded,
                            size: 25,
                            color: colorScheme.primaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        formatDuration(totalFocusMinutes),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Total Focus',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Completed Sessions Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      M3EShapeContainer(
                        kind: M3EShapeKind.clover8Leaf,
                        width: 45,
                        height: 45,
                        color: colorScheme.onTertiaryContainer,
                        child: Center(
                          child: Icon(
                            Icons.checklist_rounded,
                            size: 25,
                            color: colorScheme.tertiaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$totalSessionsCount',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onTertiaryContainer,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Sessions Done',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Active Days / Hours Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      M3EShapeContainer(
                        kind: M3EShapeKind.gem,
                        width: 45,
                        height: 45,
                        color: colorScheme.onSecondaryContainer,
                        child: Center(
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 25,
                            color: colorScheme.secondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        activeDaysValue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        activeDaysLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
