import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'pomodoro_chart_canvas.dart';
import '../../../utils/haptics.dart';

/// Top header for Pomodoro analysis pane:
/// - Connected range selector [D, W, M, Y]
/// - Period title with date range
/// - Navigation button group (Previous, Next, Jump to current)
class PomodoroAnalysisHeader extends StatelessWidget {
  final ChartRange range;
  final int offset;
  final ValueChanged<ChartRange> onRangeChanged;
  final ValueChanged<int> onOffsetChanged;

  const PomodoroAnalysisHeader({
    super.key,
    required this.range,
    required this.offset,
    required this.onRangeChanged,
    required this.onOffsetChanged,
  });

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

  static String toLocalDateStr(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatPeriodTitle(DateTime now) {
    final todayStr = toLocalDateStr(now);
    final yesterdayStr = toLocalDateStr(now.subtract(const Duration(days: 1)));

    if (range == ChartRange.day) {
      final target = now.add(Duration(days: offset));
      final ds = toLocalDateStr(target);
      if (ds == todayStr) {
        return 'Today';
      } else if (ds == yesterdayStr) {
        return 'Yesterday';
      } else {
        return '${target.day} ${monthName(target.month)}';
      }
    } else if (range == ChartRange.week) {
      if (offset == 0) {
        return 'This week';
      } else if (offset == -1) {
        return 'Last week';
      } else {
        final startOfWeek = now
            .subtract(Duration(days: now.weekday % 7))
            .add(Duration(days: offset * 7));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${startOfWeek.day} ${monthName(startOfWeek.month)} - ${endOfWeek.day} ${monthName(endOfWeek.month)}';
      }
    } else if (range == ChartRange.month) {
      final target = DateTime(now.year, now.month + offset, 1);
      if (offset == 0) {
        return 'This month';
      } else {
        return '${monthName(target.month)} ${target.year}';
      }
    } else if (range == ChartRange.year) {
      final targetYear = now.year + offset;
      if (offset == 0) {
        return 'This year';
      } else {
        return '$targetYear';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Range Selector: Centered Above Period Title [D W M Y] ────
        Center(
          child: M3EButtonGroup(
            type: M3EButtonGroupType.standard,
            shape: M3EButtonShape.square,
            size: M3EButtonSize.custom(height: 40),
            density: M3EButtonGroupDensity.compact,
            style: M3EButtonStyle.filled,
            selectedIndex: range.index,
            onSelectedIndexChanged: (idx) {
              if (idx != null) {
                ZetaHaptics.selection();
                onRangeChanged(ChartRange.values[idx]);
              }
            },
            actions: ChartRange.values.map((r) {
              final isSelected = range == r;
              return M3EButtonGroupAction(
                label: Text(isSelected ? r.fullLabel : r.shortLabel),
                decoration: M3EButtonDecoration(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.primary;
                    }
                    return colorScheme.tertiaryContainer;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.onPrimary;
                    }
                    return colorScheme.onTertiaryContainer;
                  }),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 25),

        // ─── Period Title & Navigation Buttons ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _formatPeriodTitle(now),
                style: textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  letterSpacing: -0.8
                ),
              ),
            ),
            const SizedBox(width: 4),
            M3EButtonGroup(
              type: M3EButtonGroupType.standard,
              size: M3EButtonSize.custom(
                height: 50,
                hPadding: 10,
                iconSize: 32,
                iconGap: 5,
              ),
              shape: M3EButtonShape.round,
              density: M3EButtonGroupDensity.compact,
              selectedIndex: null,
              onSelectedIndexChanged: (idx) {
                ZetaHaptics.light();
                if (idx == 0) {
                  onOffsetChanged(offset - 1);
                } else if (idx == 1) {
                  if (offset < 0) {
                    onOffsetChanged(math.min(0, offset + 1));
                  }
                } else if (idx == 2) {
                  if (offset != 0) {
                    onOffsetChanged(0);
                  }
                }
              },
              actions: [
                const M3EButtonGroupAction(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                M3EButtonGroupAction(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    fontWeight: FontWeight.w600,
                    size: 25,
                    color: offset < 0
                        ? null
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
                M3EButtonGroupAction(
                  icon: Icon(
                    Icons.history_rounded,
                    fontWeight: FontWeight.w600,
                    size: 25,
                    color: offset != 0
                        ? null
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  width: 55,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
