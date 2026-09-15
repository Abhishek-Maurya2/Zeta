import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../utils/haptics.dart';

import '../../providers/pomodoro_provider.dart';
import '../../models/pomodoro.dart';

enum ChartRange {
  day,
  week,
  month,
  threeMonths,
  year;

  String get label {
    switch (this) {
      case ChartRange.day:
        return 'D';
      case ChartRange.week:
        return 'W';
      case ChartRange.month:
        return 'M';
      case ChartRange.threeMonths:
        return '3M';
      case ChartRange.year:
        return 'Y';
    }
  }
}

class PomodoroAnalysisPane extends StatefulWidget {
  final bool isSplitPane;

  const PomodoroAnalysisPane({super.key, this.isSplitPane = false});

  @override
  State<PomodoroAnalysisPane> createState() => _PomodoroAnalysisPaneState();
}

class _PomodoroAnalysisPaneState extends State<PomodoroAnalysisPane> {
  static const int dailyGoalMins = 100;

  ChartRange _range = ChartRange.week;
  int _offset = 0; // 0 = current, -1 = previous, etc.



  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _toLocalDateStr(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _confirmClearLogs(BuildContext context, PomodoroProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Session History?'),
        content: const Text(
          'This will permanently delete all logged focus sessions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.clearSessionLog();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final sessionLog = provider.sessionLog;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final now = DateTime.now();
    final todayStr = _toLocalDateStr(now);
    final yesterdayStr = _toLocalDateStr(now.subtract(const Duration(days: 1)));

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: widget.isSplitPane ? 20 : 16,
        right: widget.isSplitPane ? 20 : 16,
        top: 16,
        bottom: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Range Selector: Centered Above Period Title [D W M 3M Y] ────
          Center(
            child: M3EButtonGroup(
              type: M3EButtonGroupType.connected,
              size: M3EButtonSize.custom(height: 40),
              style: M3EButtonStyle.tonal,
              selectedIndex: _range.index,
              onSelectedIndexChanged: (idx) {
                if (idx != null) {
                  ZetaHaptics.selection();
                  setState(() {
                    _range = ChartRange.values[idx];
                    _offset = 0;
                  });
                }
              },
              actions: ChartRange.values.map((r) {
                return M3EButtonGroupAction(label: Text(r.label), width: 70);
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ─── Period Title & Standard Navigation Buttons (Right Aligned) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildPeriodTitle(
                  textTheme,
                  colorScheme,
                  now,
                  todayStr,
                  yesterdayStr,
                ),
              ),
              const SizedBox(width: 8),
              M3EButtonGroup(
                type: M3EButtonGroupType.standard,
                size: M3EButtonSize.md,
                // style: M3EButtonStyle.tonal,
                selectedIndex: null,
                onSelectedIndexChanged: (idx) {
                  ZetaHaptics.light();
                  if (idx == 0) {
                    setState(() => _offset--);
                  } else if (idx == 1) {
                    if (_offset < 0) {
                      setState(() => _offset = math.min(0, _offset + 1));
                    }
                  } else if (idx == 2) {
                    if (_offset != 0) {
                      setState(() => _offset = 0);
                    }
                  }
                },
                actions: [
                  const M3EButtonGroupAction(
                    icon: Icon(Icons.chevron_left_rounded, size: 18),
                    tooltip: 'Previous period',
                  ),
                  M3EButtonGroupAction(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _offset < 0
                          ? null
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    tooltip: 'Next period',
                  ),
                  M3EButtonGroupAction(
                    icon: Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: _offset != 0
                          ? null
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    width: 55,
                    tooltip: 'Jump to current',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ─── Hero Stat Section ────────────────────────────────────
          _buildHeroStat(textTheme, colorScheme, sessionLog, now, todayStr),

          const SizedBox(height: 20),

          // ─── Visual Chart Card ────────────────────────────────────
          _buildChartCard(
            context,
            colorScheme,
            textTheme,
            sessionLog,
            now,
            todayStr,
          ),

          const SizedBox(height: 20),

          // ─── Summary Stat Cards Grid ──────────────────────────────
          _buildSummaryCards(context, colorScheme, textTheme, sessionLog, now),

          const SizedBox(height: 24),

          // ─── Completed Session Log List ───────────────────────────
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Recent Sessions',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
             if (sessionLog.isNotEmpty) ...[
              const SizedBox(width: 4),
              TextButton.icon(
              onPressed: () => _confirmClearLogs(context, provider),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],

            ],
          ),

          const SizedBox(height: 10),

          if (sessionLog.isEmpty)
            ZetaEmptyState.pomodoro(
              title: 'No sessions recorded yet',
              subtitle:
                  'Complete focus sessions to start tracking your daily progress.',
              size: ZetaEmptyStateSize.standard,
            )
          else
            M3ESegmentedColumn(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: colorScheme.surfaceContainerLowest,
              children: sessionLog.reversed.take(20).map((entry) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  entry.completedAt,
                );
                final timeStr =
                    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                final dateStr = '${date.day} ${_monthName(date.month)}';
                final isFocus = entry.mode == PomodoroMode.focus;

                return Row(
                  children: [
                    // Leading Icon Badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFocus
                            ? colorScheme.surfaceContainerHigh
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFocus
                            ? Icons.psychology_rounded
                            : (entry.mode == PomodoroMode.shortBreak
                                  ? Icons.coffee_rounded
                                  : Icons.hotel_rounded),
                        size: 18,
                        color: isFocus
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Main Title & Duration/Timestamp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.mode.label,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateStr at $timeStr',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Trailing Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.minutes}m',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─── Sub-widgets ─────────────────────────────────────────────────────────

  Widget _buildPeriodTitle(
    TextTheme textTheme,
    ColorScheme colorScheme,
    DateTime now,
    String todayStr,
    String yesterdayStr,
  ) {
    String title = '';
    if (_range == ChartRange.day) {
      final target = now.add(Duration(days: _offset));
      final ds = _toLocalDateStr(target);
      if (ds == todayStr) {
        title = 'Today';
      } else if (ds == yesterdayStr) {
        title = 'Yesterday';
      } else {
        title = '${target.day} ${_monthName(target.month)}';
      }
    } else if (_range == ChartRange.week) {
      if (_offset == 0) {
        title = 'This week';
      } else if (_offset == -1) {
        title = 'Last week';
      } else {
        final startOfWeek = now
            .subtract(Duration(days: now.weekday % 7))
            .add(Duration(days: _offset * 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        title =
            '${startOfWeek.day} ${_monthName(startOfWeek.month)} - ${endOfWeek.day} ${_monthName(endOfWeek.month)}';
      }
    } else if (_range == ChartRange.month) {
      final target = DateTime(now.year, now.month + _offset, 1);
      if (_offset == 0) {
        title = 'This month';
      } else {
        title = '${_monthName(target.month)} ${target.year}';
      }
    } else if (_range == ChartRange.threeMonths) {
      final endMonth = DateTime(now.year, now.month + (_offset * 3), 1);
      final startMonth = DateTime(endMonth.year, endMonth.month - 2, 1);
      if (_offset == 0) {
        title = 'Past 3 months';
      } else {
        title =
            '${_monthName(startMonth.month)} - ${_monthName(endMonth.month)} ${endMonth.year}';
      }
    } else if (_range == ChartRange.year) {
      final targetYear = now.year + _offset;
      if (_offset == 0) {
        title = 'This year';
      } else {
        title = '$targetYear';
      }
    }

    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildHeroStat(
    TextTheme textTheme,
    ColorScheme colorScheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    String todayStr,
  ) {
    int minutesToDisplay = 0;
    String subtitle = 'focus today';
    String? detailText;

    if (_range == ChartRange.day) {
      final target = now.add(Duration(days: _offset));
      final ds = _toLocalDateStr(target);
      final entries = sessionLog.where(
        (e) =>
            _toLocalDateStr(
                  DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                ) ==
                ds &&
            e.mode == PomodoroMode.focus,
      );
      minutesToDisplay = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      subtitle = ds == todayStr ? 'focus today' : 'focus recorded';
      if (minutesToDisplay >= dailyGoalMins) {
        detailText =
            'You hit your daily goal of ${dailyGoalMins}m! Great work.';
      } else {
        detailText =
            'Daily goal: ${dailyGoalMins}m (${dailyGoalMins - minutesToDisplay}m remaining)';
      }
    } else if (_range == ChartRange.week) {
      final startOfWeek = now
          .subtract(Duration(days: now.weekday % 7))
          .add(Duration(days: _offset * 7));
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
      final daysCount = _offset == 0 ? ((now.weekday % 7) + 1) : 7;
      minutesToDisplay = (total / math.max(1, daysCount)).round();
      subtitle = 'per day (avg)';

      int daysHitGoal = 0;
      for (int i = 0; i < 7; i++) {
        final d = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day + i,
        );
        final ds = _toLocalDateStr(d);
        final dayMins = sessionLog
            .where(
              (e) =>
                  _toLocalDateStr(
                        DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                      ) ==
                      ds &&
                  e.mode == PomodoroMode.focus,
            )
            .fold<int>(0, (s, e) => s + e.minutes);
        if (dayMins >= dailyGoalMins) daysHitGoal++;
      }
      detailText =
          'You hit your goal on $daysHitGoal days so far, and focused a total of ${_formatDuration(total)}';
    } else if (_range == ChartRange.month) {
      final target = DateTime(now.year, now.month + _offset, 1);
      final lastDay = DateTime(target.year, target.month + 1, 0).day;
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == target.year &&
            d.month == target.month &&
            e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final divisor = _offset == 0 ? now.day : lastDay;
      minutesToDisplay = (total / math.max(1, divisor)).round();
      subtitle = 'per day (avg)';
      detailText =
          'Total ${_formatDuration(total)} focus recorded in ${_monthName(target.month)}';
    } else if (_range == ChartRange.threeMonths) {
      final endMonth = DateTime(
        now.year,
        now.month + (_offset * 3) + 1,
        0,
        23,
        59,
        59,
      );
      final startMonth = DateTime(now.year, now.month + (_offset * 3) - 2, 1);
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return !d.isBefore(startMonth) &&
            !d.isAfter(endMonth) &&
            e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final daysCount = endMonth.difference(startMonth).inDays + 1;
      minutesToDisplay = (total / math.max(1, daysCount)).round();
      subtitle = 'per day (avg)';
      detailText =
          'Total ${_formatDuration(total)} focus recorded across 3 months';
    } else if (_range == ChartRange.year) {
      final targetYear = now.year + _offset;
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == targetYear && e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final daysCount = _offset == 0
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
          'Total ${_formatDuration(total)} focus recorded in $targetYear';
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
              _formatDuration(minutesToDisplay),
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

  Widget _buildChartCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    String todayStr,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: switch (_range) {
        ChartRange.day => _buildDayBlocksChart(
          colorScheme,
          textTheme,
          sessionLog,
          now,
        ),
        ChartRange.week => _buildWeekDaysChart(
          colorScheme,
          textTheme,
          sessionLog,
          now,
          todayStr,
        ),
        ChartRange.month => _buildMonthWeeksChart(
          colorScheme,
          textTheme,
          sessionLog,
          now,
        ),
        ChartRange.threeMonths => _buildThreeMonthsChart(
          colorScheme,
          textTheme,
          sessionLog,
          now,
        ),
        ChartRange.year => _buildYearMonthsChart(
          colorScheme,
          textTheme,
          sessionLog,
          now,
        ),
      },
    );
  }

  // ─── Duration / Axis Formatter ─────────────────────────────────────────
  String _formatAxisDuration(int minutes) {
    if (minutes <= 0) return '0';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes / 60;
    if (minutes % 60 == 0) return '${hours.toInt()}h';
    return '${hours.toStringAsFixed(1)}h';
  }

  // ─── Universal Vertical Bar Chart Canvas (M3 Expressive Pill Bars) ──────
  Widget _buildVerticalBarChartCanvas({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required List<Map<String, dynamic>> items,
    required int goalValue,
    required String goalLabel,
    double chartHeight = 175.0,
    double minBarWidth = 12.0,
    double maxBarWidth = 38.0,
  }) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const rightAxisWidth = 52.0;
        final availableWidth = math.max(120.0, totalWidth - rightAxisWidth);

        final count = items.length;
        final calculatedBarWidth = ((availableWidth / count) - 8).clamp(
          minBarWidth,
          maxBarWidth,
        );
        final barWidth = calculatedBarWidth.toDouble();
        final badgeSize = (barWidth - 6).clamp(10.0, 24.0);
        final iconSize = (badgeSize * 0.58).clamp(7.0, 14.0);

        const labelAreaHeight = 24.0;
        final barAreaHeight = chartHeight - labelAreaHeight - 16;
        final goalBottom = (goalFraction * barAreaHeight) + labelAreaHeight;

        // Check if mid-tick label (50%) collides with goal line
        final showMidTick = (goalFraction - 0.5).abs() > 0.15;

        return SizedBox(
          height: chartHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Background Grid Lines (Subtle) ──
              // Top 100% grid line
              Positioned(
                left: 0,
                right: rightAxisWidth + 4,
                top: 0,
                child: Container(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),

              // Mid 50% grid line
              Positioned(
                left: 0,
                right: rightAxisWidth + 4,
                bottom: (0.5 * barAreaHeight) + labelAreaHeight,
                child: Container(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.15),
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
                    color: colorScheme.primary.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),

              // ── Y-Axis Labels (Right Side) ──
              // Top Max label
              Positioned(
                top: -2,
                right: 0,
                child: Text(
                  _formatAxisDuration(effectiveMax),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ),

              // Mid 50% label (rendered if not colliding with goal)
              if (showMidTick)
                Positioned(
                  bottom: (0.5 * barAreaHeight) + labelAreaHeight - 7,
                  right: 0,
                  child: Text(
                    _formatAxisDuration((effectiveMax / 2).round()),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),

              // Goal label
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

              // Bottom 0 label
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

              // ── Vertical Bars Row ──
              Positioned(
                left: 0,
                right: rightAxisWidth,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: items.map((item) {
                    final focus = item['focus'] as int;
                    final hitGoal = item['hitGoal'] as bool? ?? false;
                    final isHighlighted =
                        item['isHighlighted'] as bool? ?? false;
                    final label = item['label'] as String;

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
                      final computedHeight = math.max(
                        6.0,
                        fraction * barAreaHeight,
                      );

                      barWidget = Container(
                        width: barWidth,
                        height: computedHeight,
                        decoration: BoxDecoration(
                          color: hitGoal
                              ? colorScheme.primary
                              : (isHighlighted
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.65,
                                      )
                                    : colorScheme.secondaryContainer),
                          borderRadius: BorderRadius.circular(
                            math.min(barWidth / 2, computedHeight / 2),
                          ),
                        ),
                        child: hitGoal && computedHeight >= badgeSize + 6
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 3.5),
                                  child: M3EShapeContainer.softBoom(
                                    width: badgeSize,
                                    height: badgeSize,
                                    color: colorScheme.primaryContainer,
                                    child: Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: iconSize,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      );
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: '$label: ${_formatDuration(focus)}',
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
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Day 6-Block Vertical Pill Bars ──────────────────────────────────────
  Widget _buildDayBlocksChart(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
  ) {
    final target = now.add(Duration(days: _offset));
    final ds = _toLocalDateStr(target);

    final hours = List<int>.filled(24, 0);
    for (final e in sessionLog) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
      if (_toLocalDateStr(d) == ds && e.mode == PomodoroMode.focus) {
        hours[d.hour] += e.minutes;
      }
    }

    const blockGoal = 45; // 45m block goal
    final blocks =
        [
          {
            'label': '12a',
            'focus': hours.sublist(0, 4).reduce((a, b) => a + b),
          },
          {'label': '4a', 'focus': hours.sublist(4, 8).reduce((a, b) => a + b)},
          {
            'label': '8a',
            'focus': hours.sublist(8, 12).reduce((a, b) => a + b),
          },
          {
            'label': '12p',
            'focus': hours.sublist(12, 16).reduce((a, b) => a + b),
          },
          {
            'label': '4p',
            'focus': hours.sublist(16, 20).reduce((a, b) => a + b),
          },
          {
            'label': '8p',
            'focus': hours.sublist(20, 24).reduce((a, b) => a + b),
          },
        ].map((b) {
          final focus = b['focus'] as int;
          return {
            'label': b['label'] as String,
            'focus': focus,
            'hitGoal': focus >= blockGoal,
            'isHighlighted': false,
          };
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerticalBarChartCanvas(
          colorScheme: colorScheme,
          textTheme: textTheme,
          items: blocks,
          goalValue: blockGoal,
          goalLabel: _formatDuration(blockGoal),
          chartHeight: 175,
        ),
      ],
    );
  }

  // ─── Week 7-Day Vertical Pill Bars ───────────────────────────────────────
  Widget _buildWeekDaysChart(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    String todayStr,
  ) {
    final startOfWeek = now
        .subtract(Duration(days: now.weekday % 7))
        .add(Duration(days: _offset * 7));
    const dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final days = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );
      final ds = _toLocalDateStr(d);
      final entries = sessionLog.where(
        (e) =>
            _toLocalDateStr(
                  DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                ) ==
                ds &&
            e.mode == PomodoroMode.focus,
      );
      final focus = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      days.add({
        'label': dayLetters[i],
        'dateStr': ds,
        'isHighlighted': ds == todayStr,
        'focus': focus,
        'hitGoal': focus >= dailyGoalMins,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerticalBarChartCanvas(
          colorScheme: colorScheme,
          textTheme: textTheme,
          items: days,
          goalValue: dailyGoalMins,
          goalLabel: _formatDuration(dailyGoalMins),
          chartHeight: 175,
        ),
      ],
    );
  }

  // ─── Month 4-5 Week Vertical Pill Bars ───────────────────────────────────
  Widget _buildMonthWeeksChart(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
  ) {
    final target = DateTime(now.year, now.month + _offset, 1);
    final daysInMonth = DateTime(target.year, target.month + 1, 0).day;
    final totalWeeks = (daysInMonth / 7).ceil();

    final weekTotals = List<int>.filled(totalWeeks, 0);
    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(target.year, target.month, day);
      final ds = _toLocalDateStr(d);
      final entries = sessionLog.where(
        (e) =>
            _toLocalDateStr(
                  DateTime.fromMillisecondsSinceEpoch(e.completedAt),
                ) ==
                ds &&
            e.mode == PomodoroMode.focus,
      );
      final dayFocus = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final wIdx = math.min(totalWeeks - 1, (day - 1) ~/ 7);
      weekTotals[wIdx] += dayFocus;
    }

    const weeklyGoal = dailyGoalMins * 5; // 500m
    final currentWeekIdx = _offset == 0
        ? math.min(totalWeeks - 1, (now.day - 1) ~/ 7)
        : -1;

    final weekItems = List.generate(totalWeeks, (i) {
      final focus = weekTotals[i];
      return {
        'label': 'W${i + 1}',
        'focus': focus,
        'hitGoal': focus >= weeklyGoal,
        'isHighlighted': i == currentWeekIdx,
      };
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerticalBarChartCanvas(
          colorScheme: colorScheme,
          textTheme: textTheme,
          items: weekItems,
          goalValue: weeklyGoal,
          goalLabel: _formatDuration(weeklyGoal),
          chartHeight: 175,
          maxBarWidth: 44.0,
        ),
      ],
    );
  }

  // ─── 3-Month Vertical Pill Bars ──────────────────────────────────────────
  Widget _buildThreeMonthsChart(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
  ) {
    final monthsData = <Map<String, dynamic>>[];
    const monthlyGoal = dailyGoalMins * 20; // 2000m

    for (int i = 2; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month + (_offset * 3) - i, 1);
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == targetMonth.year &&
            d.month == targetMonth.month &&
            e.mode == PomodoroMode.focus;
      });
      final totalMinutes = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      monthsData.add({
        'label': _monthName(targetMonth.month),
        'focus': totalMinutes,
        'hitGoal': totalMinutes >= monthlyGoal,
        'isHighlighted':
            targetMonth.year == now.year && targetMonth.month == now.month,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerticalBarChartCanvas(
          colorScheme: colorScheme,
          textTheme: textTheme,
          items: monthsData,
          goalValue: monthlyGoal,
          goalLabel: _formatDuration(monthlyGoal),
          chartHeight: 175,
          maxBarWidth: 54.0,
        ),
      ],
    );
  }

  // ─── Year 12-Month Vertical Pill Bars ────────────────────────────────────
  Widget _buildYearMonthsChart(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
  ) {
    final targetYear = now.year + _offset;
    const monthLetters = [
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D',
    ];
    const monthlyGoal = dailyGoalMins * 20; // 2000m
    final yearData = <Map<String, dynamic>>[];

    for (int m = 1; m <= 12; m++) {
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == targetYear &&
            d.month == m &&
            e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      yearData.add({
        'label': monthLetters[m - 1],
        'focus': total,
        'hitGoal': total >= monthlyGoal,
        'isHighlighted': targetYear == now.year && m == now.month,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerticalBarChartCanvas(
          colorScheme: colorScheme,
          textTheme: textTheme,
          items: yearData,
          goalValue: monthlyGoal,
          goalLabel: _formatDuration(monthlyGoal),
          chartHeight: 175,
          minBarWidth: 10.0,
          maxBarWidth: 20.0,
        ),
      ],
    );
  }

  // ─── Summary Stat Cards ──────────────────────────────────────────────────
  Widget _buildSummaryCards(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
  ) {
    final focusSessions = sessionLog
        .where((e) => e.mode == PomodoroMode.focus)
        .toList();
    final totalFocusMinutes = focusSessions.fold<int>(
      0,
      (sum, e) => sum + e.minutes,
    );
    final totalSessionsCount = focusSessions.length;

    // Days goal hit count
    final daysMap = <String, int>{};
    for (final e in focusSessions) {
      final ds = _toLocalDateStr(
        DateTime.fromMillisecondsSinceEpoch(e.completedAt),
      );
      daysMap[ds] = (daysMap[ds] ?? 0) + e.minutes;
    }
    final daysGoalHit = daysMap.values
        .where((mins) => mins >= dailyGoalMins)
        .length;

    return Row(
      children: [
        // Total Focus Time Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.timer_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(totalFocusMinutes),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Total Focus',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalSessionsCount',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Sessions Done',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Goal Achieved Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 20,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  '$daysGoalHit days',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Goal Hit',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
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
}
