import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../widgets/segmented_column.dart';

import '../../providers/pomodoro_provider.dart';
import '../../models/pomodoro.dart';

enum ChartRange {
  day,
  week,
  month;

  String get label {
    switch (this) {
      case ChartRange.day:
        return 'Day';
      case ChartRange.week:
        return 'Week';
      case ChartRange.month:
        return 'Month';
    }
  }
}

class PomodoroAnalysisPane extends StatefulWidget {
  final bool isSplitPane;

  const PomodoroAnalysisPane({
    super.key,
    this.isSplitPane = false,
  });

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
          // ─── Header: Period Navigation & Range Toggle ─────────────
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              // Period Title & Arrow Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPeriodTitle(textTheme, colorScheme, now, todayStr, yesterdayStr),
                  const SizedBox(width: 6),
                  M3EIconButton(
                    variant: M3EIconButtonVariant.tonal,
                    size: M3EIconButtonSize.xs,
                    tooltip: 'Previous period',
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    onPressed: () => setState(() => _offset--),
                  ),
                  const SizedBox(width: 4),
                  M3EIconButton(
                    variant: M3EIconButtonVariant.tonal,
                    size: M3EIconButtonSize.xs,
                    tooltip: 'Next period',
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    onPressed: _offset < 0
                        ? () => setState(() => _offset = math.min(0, _offset + 1))
                        : null,
                  ),
                  if (_offset != 0) ...[
                    const SizedBox(width: 4),
                    M3EIconButton(
                      variant: M3EIconButtonVariant.filled,
                      size: M3EIconButtonSize.xs,
                      tooltip: 'Jump to current',
                      icon: const Icon(Icons.today_rounded, size: 16),
                      onPressed: () => setState(() => _offset = 0),
                    ),
                  ],
                ],
              ),

              // Range Segmented Toggle
              M3EButtonGroup(
                type: M3EButtonGroupType.connected,
                size: M3EButtonSize.sm,
                style: M3EButtonStyle.tonal,
                selectedIndex: _range.index,
                onSelectedIndexChanged: (idx) {
                  if (idx != null) {
                    setState(() {
                      _range = ChartRange.values[idx];
                      _offset = 0;
                    });
                  }
                },
                actions: ChartRange.values.map((r) {
                  return M3EButtonGroupAction(
                    label: Text(r.label),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ─── Hero Stat Section ────────────────────────────────────
          _buildHeroStat(textTheme, colorScheme, sessionLog, now, todayStr),

          const SizedBox(height: 20),

          // ─── Visual Chart Card ────────────────────────────────────
          _buildChartCard(context, colorScheme, textTheme, sessionLog, now, todayStr),

          const SizedBox(height: 20),

          // ─── Summary Stat Cards Grid ──────────────────────────────
          _buildSummaryCards(context, colorScheme, textTheme, sessionLog, now),

          const SizedBox(height: 24),

          // ─── Completed Session Log List ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Sessions',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (sessionLog.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _confirmClearLogs(context, provider),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (sessionLog.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No sessions recorded yet.\nStart a timer to track your focus!',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
              ),
              color: colorScheme.surfaceContainerLow,
              children: sessionLog.reversed.take(20).map((entry) {
                final date = DateTime.fromMillisecondsSinceEpoch(entry.completedAt);
                final timeStr =
                    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                final dateStr = '${date.day} ${_monthName(date.month)}';
                final isFocus = entry.mode == PomodoroMode.focus;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isFocus
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFocus
                              ? Icons.psychology_rounded
                              : (entry.mode == PomodoroMode.shortBreak
                                  ? Icons.coffee_rounded
                                  : Icons.hotel_rounded),
                          size: 16,
                          color: isFocus
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.mode.label,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '$dateStr at $timeStr',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.minutes}m',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
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
        title = 'Past 7 days';
      } else if (_offset == -1) {
        title = 'Previous 7 days';
      } else {
        final end = now.add(Duration(days: _offset * 7));
        final start = end.subtract(const Duration(days: 6));
        title = '${start.day} ${_monthName(start.month)} - ${end.day} ${_monthName(end.month)}';
      }
    } else {
      final target = DateTime(now.year, now.month + _offset, 1);
      if (_offset == 0) {
        title = 'This month';
      } else {
        title = '${_monthName(target.month)} ${target.year}';
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

    if (_range == ChartRange.day) {
      final target = now.add(Duration(days: _offset));
      final ds = _toLocalDateStr(target);
      final entries = sessionLog.where(
        (e) => _toLocalDateStr(DateTime.fromMillisecondsSinceEpoch(e.completedAt)) == ds &&
            e.mode == PomodoroMode.focus,
      );
      minutesToDisplay = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      subtitle = ds == todayStr ? 'focus today' : 'focus recorded';
    } else if (_range == ChartRange.week) {
      final end = now.add(Duration(days: _offset * 7));
      final start = end.subtract(const Duration(days: 6));
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
            !d.isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59)) &&
            e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      minutesToDisplay = (total / 7).round();
      subtitle = 'avg focus per day';
    } else {
      final target = DateTime(now.year, now.month + _offset, 1);
      final lastDay = DateTime(target.year, target.month + 1, 0).day;
      final entries = sessionLog.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.completedAt);
        return d.year == target.year && d.month == target.month && e.mode == PomodoroMode.focus;
      });
      final total = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final divisor = _offset == 0 ? now.day : lastDay;
      minutesToDisplay = (total / math.max(1, divisor)).round();
      subtitle = 'avg focus per day';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatDuration(minutesToDisplay),
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              subtitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
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
      child: _range == ChartRange.day
          ? _buildDayBlocksChart(colorScheme, textTheme, sessionLog, now)
          : (_range == ChartRange.week
              ? _buildWeekDaysChart(colorScheme, textTheme, sessionLog, now, todayStr)
              : _buildMonthWeeksChart(colorScheme, textTheme, sessionLog, now)),
    );
  }

  // ─── Day 6-Block Pill Bars ───────────────────────────────────────────────
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

    final blocks = [
      {'label': '12a', 'name': 'Late Night', 'focus': hours.sublist(0, 4).reduce((a, b) => a + b)},
      {'label': '4a', 'name': 'Early Morning', 'focus': hours.sublist(4, 8).reduce((a, b) => a + b)},
      {'label': '8a', 'name': 'Morning', 'focus': hours.sublist(8, 12).reduce((a, b) => a + b)},
      {'label': '12p', 'name': 'Midday', 'focus': hours.sublist(12, 16).reduce((a, b) => a + b)},
      {'label': '4p', 'name': 'Afternoon', 'focus': hours.sublist(16, 20).reduce((a, b) => a + b)},
      {'label': '8p', 'name': 'Evening', 'focus': hours.sublist(20, 24).reduce((a, b) => a + b)},
    ];

    final maxFocus = blocks.fold<int>(0, (m, b) => math.max(m, b['focus'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Activity Blocks',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        ...blocks.map((block) {
          final focus = block['focus'] as int;
          final fraction = maxFocus > 0 ? (focus / maxFocus) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    block['label'] as String,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction > 0 ? math.max(0.06, fraction) : 0.0,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    focus > 0 ? '${focus}m' : '-',
                    textAlign: TextAlign.right,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: focus > 0 ? colorScheme.onSurface : colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Week 7-Day Vertical Bars ────────────────────────────────────────────
  Widget _buildWeekDaysChart(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
    String todayStr,
  ) {
    final targetEnd = now.add(Duration(days: _offset * 7));
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final days = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final d = targetEnd.subtract(Duration(days: 6 - i));
      final ds = _toLocalDateStr(d);
      final entries = sessionLog.where(
        (e) => _toLocalDateStr(DateTime.fromMillisecondsSinceEpoch(e.completedAt)) == ds &&
            e.mode == PomodoroMode.focus,
      );
      final focus = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      days.add({
        'dayLetter': dayLetters[(d.weekday - 1) % 7],
        'dateStr': ds,
        'isToday': ds == todayStr,
        'focus': focus,
        'hitGoal': focus >= dailyGoalMins,
      });
    }

    final maxFocus = math.max(
      dailyGoalMins,
      days.fold<int>(0, (m, d) => math.max(m, d['focus'] as int)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Focus Time (7 Days)',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                Icon(Icons.stars_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Goal: ${dailyGoalMins}m',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((day) {
              final focus = day['focus'] as int;
              final isToday = day['isToday'] as bool;
              final hitGoal = day['hitGoal'] as bool;
              final fraction = (focus / maxFocus).clamp(0.0, 1.0);
              final barHeight = math.max(6.0, fraction * 95);

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Goal Rosette / Star Icon
                  if (hitGoal)
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Colors.green.shade600,
                    )
                  else
                    const SizedBox(height: 16),

                  const SizedBox(height: 4),

                  // Pill Bar
                  Container(
                    width: 22,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: isToday
                          ? colorScheme.primary
                          : (focus > 0
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Day Letter
                  Text(
                    day['dayLetter'] as String,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Month 4-Week Progress Bars ──────────────────────────────────────────
  Widget _buildMonthWeeksChart(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<PomodoroSessionLog> sessionLog,
    DateTime now,
  ) {
    final target = DateTime(now.year, now.month + _offset, 1);
    final daysInMonth = DateTime(target.year, target.month + 1, 0).day;

    final weekTotals = [0, 0, 0, 0];
    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(target.year, target.month, day);
      final ds = _toLocalDateStr(d);
      final entries = sessionLog.where(
        (e) => _toLocalDateStr(DateTime.fromMillisecondsSinceEpoch(e.completedAt)) == ds &&
            e.mode == PomodoroMode.focus,
      );
      final dayFocus = entries.fold<int>(0, (sum, e) => sum + e.minutes);
      final wIdx = math.min(3, (day - 1) ~/ 7);
      weekTotals[wIdx] += dayFocus;
    }

    final maxWeek = weekTotals.fold<int>(0, (m, val) => math.max(m, val));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Focus Breakdown',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(4, (i) {
          final focus = weekTotals[i];
          final fraction = maxWeek > 0 ? (focus / maxWeek) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'W${i + 1}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction > 0 ? math.max(0.06, fraction) : 0.0,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  child: Text(
                    focus > 0 ? _formatDuration(focus) : '-',
                    textAlign: TextAlign.right,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: focus > 0 ? colorScheme.onSurface : colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
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
    final focusSessions = sessionLog.where((e) => e.mode == PomodoroMode.focus).toList();
    final totalFocusMinutes = focusSessions.fold<int>(0, (sum, e) => sum + e.minutes);
    final totalSessionsCount = focusSessions.length;

    // Days goal hit count
    final daysMap = <String, int>{};
    for (final e in focusSessions) {
      final ds = _toLocalDateStr(DateTime.fromMillisecondsSinceEpoch(e.completedAt));
      daysMap[ds] = (daysMap[ds] ?? 0) + e.minutes;
    }
    final daysGoalHit = daysMap.values.where((mins) => mins >= dailyGoalMins).length;

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
                Icon(Icons.check_circle_rounded, size: 20, color: colorScheme.tertiary),
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
                Icon(Icons.stars_rounded, size: 20, color: Colors.amber.shade700),
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
      'Dec'
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}
