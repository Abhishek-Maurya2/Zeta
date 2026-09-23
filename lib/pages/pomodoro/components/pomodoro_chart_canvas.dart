import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../models/pomodoro.dart';
import '../../../theme/app_theme.dart';

enum ChartRange {
  day,
  week,
  month,
  year;

  String get fullLabel {
    switch (this) {
      case ChartRange.day:
        return 'Day';
      case ChartRange.week:
        return 'Week';
      case ChartRange.month:
        return 'Month';
      case ChartRange.year:
        return 'Year';
    }
  }

  String get shortLabel => fullLabel[0];
}

/// Universal vertical pill bar chart canvas with M3 Expressive shapes,
/// solid Goal line, dashed Average line, and right-axis labels.
class PomodoroChartCanvas extends StatelessWidget {
  final ChartRange range;
  final int offset;
  final List<Map<String, dynamic>> items;
  final int goalValue;
  final String goalLabel;
  final double chartHeight;
  final double minBarWidth;
  final double maxBarWidth;

  const PomodoroChartCanvas({
    super.key,
    required this.range,
    this.offset = 0,
    required this.items,
    required this.goalValue,
    required this.goalLabel,
    this.chartHeight = 250.0,
    this.minBarWidth = 40.0,
    this.maxBarWidth = 50.0,
  });

  static String formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static String formatAxisDuration(int minutes) {
    if (minutes <= 0) return '0';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes / 60;
    if (minutes % 60 == 0) return '${hours.toInt()}h';
    return '${hours.toStringAsFixed(1)}h';
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

  // ─── Data Generation Helpers for Chart Ranges ─────────────────────────────

  static List<Map<String, dynamic>> buildDayBlocks(
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    int offset,
    int blockGoal,
  ) {
    const blockTooltips = [
      '12:00 AM – 2:00 AM',
      '2:00 AM – 4:00 AM',
      '4:00 AM – 6:00 AM',
      '6:00 AM – 8:00 AM',
      '8:00 AM – 10:00 AM',
      '10:00 AM – 12:00 PM',
      '12:00 PM – 2:00 PM',
      '2:00 PM – 4:00 PM',
      '4:00 PM – 6:00 PM',
      '6:00 PM – 8:00 PM',
      '8:00 PM – 10:00 PM',
      '10:00 PM – 12:00 AM',
    ];
    const blockLabels = [
      '12 am',
      '2 am',
      '4 am',
      '6 am',
      '8 am',
      '10 am',
      '12 pm',
      '2 pm',
      '4 pm',
      '6 pm',
      '8 pm',
      '10 pm',
    ];

    if (offset < 0) {
      final target = now.add(Duration(days: offset));
      final ds = toLocalDateStr(target);

      final hours = List<int>.filled(24, 0);
      for (final e in sessionLog) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        if (toLocalDateStr(d) == ds && e.mode == PomodoroMode.focus) {
          hours[d.hour] += e.minutes;
        }
      }

      final rawBlocks = List.generate(12, (i) {
        return {
          'label': blockLabels[i],
          'tooltipLabel': blockTooltips[i],
          'focus': hours.sublist(i * 2, (i + 1) * 2).reduce((a, b) => a + b),
          'isHighlighted': false,
        };
      });

      return rawBlocks.map((b) {
        final focus = b['focus'] as int;
        return {...b, 'hitGoal': focus >= blockGoal};
      }).toList();
    }

    // offset == 0: continuous last 12 blocks (24 hours) ending at current block
    final currentBlockStart = DateTime(
      now.year,
      now.month,
      now.day,
      (now.hour ~/ 2) * 2,
    );

    return List.generate(12, (i) {
      final blockStart = currentBlockStart.subtract(
        Duration(hours: (11 - i) * 2),
      );
      final blockEnd = blockStart.add(const Duration(hours: 2));

      final entries = sessionLog.where((e) {
        if (e.mode != PomodoroMode.focus) return false;
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return (d.isAfter(blockStart) || d.isAtSameMomentAs(blockStart)) &&
            d.isBefore(blockEnd);
      });
      final focus = entries.fold<int>(0, (sum, e) => sum + e.minutes);

      final bIdx = blockStart.hour ~/ 2;
      final isToday = toLocalDateStr(blockStart) == toLocalDateStr(now);
      final dateTag = isToday
          ? ''
          : ' (${monthName(blockStart.month)} ${blockStart.day})';

      return {
        'label': blockLabels[bIdx],
        'tooltipLabel': '${blockTooltips[bIdx]}$dateTag',
        'focus': focus,
        'hitGoal': focus >= blockGoal,
        'isHighlighted': i == 11,
      };
    });
  }

  static List<Map<String, dynamic>> buildWeekDays(
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    int offset,
    String todayStr,
    int weekDailyGoal,
  ) {
    const dayLetters = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const fullDayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    if (offset == 0) {
      // Continuous 7 rolling days ending at today
      final targetEndDay = DateTime(now.year, now.month, now.day);
      final rawDays = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        final d = targetEndDay.subtract(Duration(days: 6 - i));
        final ds = toLocalDateStr(d);
        final entries = sessionLog.where(
          (e) =>
              toLocalDateStr(
                    DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                  ) ==
                  ds &&
              e.mode == PomodoroMode.focus,
        );
        final focus = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        final dayIdx = d.weekday % 7;
        rawDays.add({
          'label': dayLetters[dayIdx],
          'tooltipLabel':
              '${fullDayNames[dayIdx]} (${monthName(d.month)} ${d.day})',
          'dateStr': ds,
          'isHighlighted': ds == todayStr,
          'focus': focus,
          'hitGoal': focus >= weekDailyGoal,
        });
      }
      return rawDays;
    }

    // offset < 0: previous calendar week (Sun-Sat) excluding current running week
    final startOfWeek = now
        .subtract(Duration(days: now.weekday % 7))
        .add(Duration(days: offset * 7));

    final rawDays = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );
      final ds = toLocalDateStr(d);
      final entries = sessionLog.where(
        (e) =>
            toLocalDateStr(
                  DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                ) ==
                ds &&
            e.mode == PomodoroMode.focus,
      );
      final focus = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      rawDays.add({
        'label': dayLetters[i],
        'tooltipLabel': '${fullDayNames[i]} (${monthName(d.month)} ${d.day})',
        'dateStr': ds,
        'isHighlighted': false,
        'focus': focus,
        'hitGoal': focus >= weekDailyGoal,
      });
    }
    return rawDays;
  }

  static List<Map<String, dynamic>> buildMonthWeeks(
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    int offset,
    int weeklyGoal,
  ) {
    if (offset == 0) {
      // Continuous 4 rolling 7-day weeks ending at today
      final targetEndDay = DateTime(now.year, now.month, now.day);
      return List.generate(4, (i) {
        final weekStart = targetEndDay.subtract(
          Duration(days: (3 - i) * 7 + 6),
        );
        final weekEnd = targetEndDay.subtract(Duration(days: (3 - i) * 7));
        final startMs = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).millisecondsSinceEpoch;
        final endMs = DateTime(
          weekEnd.year,
          weekEnd.month,
          weekEnd.day,
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
        final focus = entries.fold<int>(0, (sum, e) => sum + e.minutes);

        return {
          'label': 'W${i + 1}',
          'tooltipLabel':
              'Week ${i + 1}: ${monthName(weekStart.month)} ${weekStart.day} – ${monthName(weekEnd.month)} ${weekEnd.day}',
          'focus': focus,
          'hitGoal': focus >= weeklyGoal,
          'isHighlighted': i == 3,
        };
      });
    }

    // offset < 0: previous calendar month (W1..W5) excluding current running month
    final target = DateTime(now.year, now.month + offset, 1);
    final daysInMonth = DateTime(target.year, target.month + 1, 0).day;
    final totalWeeks = (daysInMonth / 7).ceil();

    final weekTotals = List<int>.filled(totalWeeks, 0);
    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(target.year, target.month, day);
      final ds = toLocalDateStr(d);
      final entries = sessionLog.where(
        (e) =>
            toLocalDateStr(
                  DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                ) ==
                ds &&
            e.mode == PomodoroMode.focus,
      );
      final dayFocus = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final wIdx = math.min(totalWeeks - 1, (day - 1) ~/ 7);
      weekTotals[wIdx] += dayFocus;
    }

    return List.generate(totalWeeks, (i) {
      final focus = weekTotals[i];
      return {
        'label': 'W${i + 1}',
        'tooltipLabel':
            'Week ${i + 1} (${monthName(target.month)} ${target.year})',
        'focus': focus,
        'hitGoal': focus >= weeklyGoal,
        'isHighlighted': false,
      };
    });
  }

  static List<Map<String, dynamic>> buildYearMonths(
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    int offset,
    int monthlyGoal,
  ) {
    const monthLetters = [
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
    const fullMonthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (offset == 0) {
      // Continuous 12 rolling months ending at current month
      final targetEndMonth = DateTime(now.year, now.month, 1);
      final rawYearData = <Map<String, dynamic>>[];
      for (int i = 0; i < 12; i++) {
        final mDate = DateTime(
          targetEndMonth.year,
          targetEndMonth.month - 11 + i,
          1,
        );
        final entries = sessionLog.where((e) {
          final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
          return d.year == mDate.year &&
              d.month == mDate.month &&
              e.mode == PomodoroMode.focus;
        });
        final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
        rawYearData.add({
          'label': monthLetters[mDate.month - 1],
          'tooltipLabel': '${fullMonthNames[mDate.month - 1]} ${mDate.year}',
          'focus': total,
          'hitGoal': total >= monthlyGoal,
          'isHighlighted': i == 11,
        });
      }
      return rawYearData;
    }

    // offset < 0: previous calendar year (Jan-Dec) excluding current running year
    final targetYear = now.year + offset;
    final rawYearData = <Map<String, dynamic>>[];
    for (int m = 1; m <= 12; m++) {
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == targetYear &&
            d.month == m &&
            e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      rawYearData.add({
        'label': monthLetters[m - 1],
        'tooltipLabel': '${fullMonthNames[m - 1]} $targetYear',
        'focus': total,
        'hitGoal': total >= monthlyGoal,
        'isHighlighted': false,
      });
    }
    return rawYearData;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final maxItemFocus = items.fold<int>(
      0,
      (m, item) => math.max(m, item['focus'] as int),
    );

    final maxScale = math.max(
      (goalValue * 1.25).round(),
      (maxItemFocus * 1.15).round(),
    );
    final effectiveMax = math.max(60, maxScale);
    final goalFraction = (goalValue / effectiveMax).clamp(0.08, 0.92);

    final count = items.length;
    final totalFocusSum = items.fold<int>(
      0,
      (sum, item) => sum + (item['focus'] as int),
    );
    final averageFocus = count > 0 ? (totalFocusSum / count) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const rightAxisWidth = 52.0;
        final availableWidth = math.max(120.0, totalWidth - rightAxisWidth);

        const labelAreaHeight = 24.0;
        final barAreaHeight = chartHeight - labelAreaHeight - 16;
        final goalBottom = (goalFraction * barAreaHeight) + labelAreaHeight;

        final showAvgLine = averageFocus > 0;
        final avgFraction = effectiveMax > 0
            ? (averageFocus / effectiveMax).clamp(0.08, 0.92)
            : 0.0;
        final avgBottom = (avgFraction * barAreaHeight) + labelAreaHeight;

        // Check if mid-tick label (50%) collides with goal line or average line
        final showMidTick =
            (goalFraction - 0.5).abs() > 0.15 &&
            (!showAvgLine || (avgFraction - 0.5).abs() > 0.15);

        // Check if goal line and average line labels collide on the Y-axis
        final isGoalAvgColliding =
            showAvgLine && (goalBottom - avgBottom).abs() < 14;
        final effectiveAvgLabelBottom = isGoalAvgColliding
            ? (avgBottom < goalBottom ? avgBottom - 11 : avgBottom + 4)
            : avgBottom - 7;

        const columnGap = 10.0;
        final requiredTotalWidth =
            (count * minBarWidth) + ((count - 1) * columnGap);
        final isScrollable = requiredTotalWidth > availableWidth;

        final barWidth = isScrollable
            ? minBarWidth
            : ((availableWidth / count) - columnGap).clamp(
                minBarWidth,
                maxBarWidth,
              );

        final badgeSize = (barWidth * 0.72).clamp(12.0, 44.0);
        final iconSize = (badgeSize * 0.58).clamp(7.0, 26.0);
        final topPadding = ((barWidth - badgeSize) / 2).clamp(3.0, 8.0);

        Widget buildBarsRow() {
          return Row(
            mainAxisAlignment: isScrollable
                ? MainAxisAlignment.start
                : MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items.map((item) {
              final focus = item['focus'] as int;
              final hitGoal = item['hitGoal'] as bool? ?? false;
              final isHighlighted = item['isHighlighted'] as bool? ?? false;
              final label = item['label'] as String;
              final tooltipLabel = item['tooltipLabel'] as String? ?? label;
              final isBelowAverage =
                  focus > 0 && averageFocus > 0 && focus < averageFocus;
              final isSuccess =
                  hitGoal || (goalValue > 0 && focus >= goalValue);

              Widget barWidget;
              if (focus <= 0) {
                barWidget = Container(
                  width: barWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              } else {
                final fraction = (focus / effectiveMax).clamp(0.0, 1.0);
                final computedHeight = math.max(6.0, fraction * barAreaHeight);

                final barColor = isHighlighted
                    ? colorScheme.secondaryContainer
                    : (isSuccess
                        ? colorScheme.successContainer
                        : (isBelowAverage
                            ? colorScheme.errorContainer
                            : colorScheme.tertiaryContainer));

                Widget? badgeWidget;
                if (computedHeight >= badgeSize + 6) {
                  if (isSuccess) {
                    badgeWidget = M3EShapeContainer.softBoom(
                      width: badgeSize,
                      height: badgeSize,
                      color: colorScheme.success,
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: iconSize,
                          color: colorScheme.successContainer,
                        ),
                      ),
                    );
                  } else if (!isBelowAverage) {
                    badgeWidget = M3EShapeContainer.arrow(
                      width: badgeSize,
                      height: badgeSize,
                      color: isHighlighted
                          ? colorScheme.secondary
                          : colorScheme.tertiary,
                      child: Center(
                        child: Icon(
                          Icons.remove_rounded,
                          size: iconSize,
                          color: isHighlighted
                              ? colorScheme.secondaryContainer
                              : colorScheme.tertiaryContainer,
                        ),
                      ),
                    );
                  }
                }

                barWidget = Container(
                  width: barWidth,
                  height: computedHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(
                      math.min(barWidth / 2, computedHeight / 2),
                    ),
                  ),
                  child: badgeWidget != null
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: topPadding),
                            child: badgeWidget,
                          ),
                        )
                      : null,
                );
              }

              final columnItem = Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message:
                        '$tooltipLabel: ${formatDuration(focus)}${isBelowAverage ? ' (Below avg)' : ''}',
                    child: barWidget,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 16,
                    child: Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: isHighlighted
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isHighlighted
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontSize: count > 8 ? 10 : 11,
                      ),
                    ),
                  ),
                ],
              );

              return isScrollable
                  ? Padding(
                      padding: const EdgeInsets.only(right: columnGap),
                      child: columnItem,
                    )
                  : columnItem;
            }).toList(),
          );
        }

        return SizedBox(
          height: chartHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Background Grid Lines (Subtle) ──
              Positioned(
                left: 0,
                right: rightAxisWidth + 4,
                top: 0,
                child: Container(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),

              Positioned(
                left: 0,
                right: rightAxisWidth + 4,
                bottom: (0.5 * barAreaHeight) + labelAreaHeight,
                child: Container(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),

              // ── Goal Reference Line Across Chart ──
              Positioned(
                left: 0,
                right: rightAxisWidth + 4,
                bottom: goalBottom,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),

              // ── Average Reference Line Across Chart (Dashed) ──
              if (showAvgLine)
                Positioned(
                  left: 0,
                  right: rightAxisWidth + 4,
                  bottom: avgBottom,
                  child: DashedLine(
                    color: colorScheme.secondary.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),

              // ── Vertical Bars Row (Scrollable if needed, auto-scrolled to end/latest) ──
              Positioned(
                left: 0,
                right: rightAxisWidth + 4,
                top: 0,
                bottom: 0,
                child: isScrollable
                    ? HorizontalEndScrollView(
                        key: ValueKey('${items.length}_${range.name}_$offset'),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: buildBarsRow(),
                        ),
                      )
                    : buildBarsRow(),
              ),

              // ── Y-Axis Labels (Fixed on Right Side) ──
              Positioned(
                top: -2,
                right: 0,
                child: Text(
                  formatAxisDuration(effectiveMax),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ),

              if (showMidTick)
                Positioned(
                  bottom: (0.5 * barAreaHeight) + labelAreaHeight - 7,
                  right: 0,
                  child: Text(
                    formatAxisDuration((effectiveMax / 2).round()),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 10,
                    ),
                  ),
                ),

              Positioned(
                bottom: goalBottom - 7,
                right: 0,
                child: Text(
                  goalLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),

              if (showAvgLine)
                Positioned(
                  bottom: effectiveAvgLabelBottom,
                  right: 0,
                  child: Text(
                    formatAxisDuration(averageFocus.round()),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 9.5,
                    ),
                  ),
                ),

              Positioned(
                bottom: labelAreaHeight - 4,
                right: 0,
                child: Text(
                  '0',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper widget that renders a dashed horizontal line with customizable dash size and spacing.
class DashedLine extends StatelessWidget {
  final Color color;
  final double height;

  static const double dashWidth = 5.0;
  static const double dashSpace = 3.5;

  const DashedLine({super.key, required this.color, this.height = 1.5});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        if (boxWidth <= 0) return const SizedBox.shrink();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        if (dashCount <= 0) return const SizedBox.shrink();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Helper widget that automatically scrolls horizontal charts to the far right (end/latest data) on initial render and range updates.
class HorizontalEndScrollView extends StatefulWidget {
  final Widget child;

  const HorizontalEndScrollView({super.key, required this.child});

  @override
  State<HorizontalEndScrollView> createState() =>
      _HorizontalEndScrollViewState();
}

class _HorizontalEndScrollViewState extends State<HorizontalEndScrollView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(covariant HorizontalEndScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: widget.child,
    );
  }
}
