import 'dart:math' as math;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/extensions/context_extensions.dart';

import '../../../models/pomodoro.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../theme/motion_tokens.dart';
import '../../../utils/haptics.dart';
import '../../pomodoro/components/pomodoro_chart_canvas.dart';

class PomodoroWeekTerrainCard extends StatefulWidget {
  final VoidCallback? onOpenAnalysis;

  const PomodoroWeekTerrainCard({super.key, this.onOpenAnalysis});

  @override
  State<PomodoroWeekTerrainCard> createState() =>
      _PomodoroWeekTerrainCardState();
}

class _PomodoroWeekTerrainCardState extends State<PomodoroWeekTerrainCard> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    final sessionLog = context
        .select<PomodoroProvider, List<PomodoroSessionLog>>(
          (p) => p.sessionLog,
        );
    final weekDailyGoalMinutes = context.select<PomodoroProvider, int>(
      (p) => p.settings.weekDailyGoalMinutes,
    );
    final now = DateTime.now();
    final todayStr = PomodoroChartCanvas.toLocalDateStr(now);

    final days = PomodoroChartCanvas.buildWeekDays(
      sessionLog,
      now,
      0,
      todayStr,
      weekDailyGoalMinutes,
    );

    final List<double> values = days
        .map((d) => (d['focus'] as int).toDouble())
        .toList();
    final double totalMinutes = values.fold<double>(0.0, (sum, v) => sum + v);

    double maxMinutes = 0;
    int maxIndex = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i] >= maxMinutes) {
        maxMinutes = values[i];
        maxIndex = i;
      }
    }

    final hasSelection =
        _selectedDayIndex != null && _selectedDayIndex! < values.length;
    final activeIdx = hasSelection ? _selectedDayIndex! : maxIndex;
    final selectedFocus = values[activeIdx].round();

    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final goalMetOnSelected =
        weekDailyGoalMinutes > 0 && selectedFocus >= weekDailyGoalMinutes;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Expressive Hero Metric
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Past 7 Days',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: M3MotionDuration.short4,
                      switchInCurve: M3MotionEasing.emphasizedDecelerate,
                      switchOutCurve: M3MotionEasing.emphasizedAccelerate,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          ...previousChildren,
                          ?currentChild,
                        ],
                      ),
                      child: Text(
                        hasSelection
                            ? PomodoroChartCanvas.formatDuration(selectedFocus)
                            : PomodoroChartCanvas.formatDuration(totalMinutes.round()),
                        key: ValueKey(
                          hasSelection ? 'day-$activeIdx-$selectedFocus' : 'total-$totalMinutes',
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                        style: TextStyle(
                          fontFamily: 'GoogleSansFlex',
                          fontSize: 34,
                          height: 1.0,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                          fontVariations: const [
                            FontVariation('wght', 700),
                            FontVariation('ROND', 100),
                          ],
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hasSelection
                                ? '${days[activeIdx]['tooltipLabel']}'
                                : 'Peak ${PomodoroChartCanvas.formatDuration(maxMinutes.round())}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: hasSelection
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        if (hasSelection && goalMetOnSelected) ...[
                          Text(
                            '  •  Goal met',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ] else if (!hasSelection && weekDailyGoalMinutes > 0) ...[
                          Text(
                            '  •  Goal ${PomodoroChartCanvas.formatDuration(weekDailyGoalMinutes)}',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.onOpenAnalysis != null) ...[
                const SizedBox(width: 12),
                M3ETooltip(
                  message: 'Open analysis',
                  child: GestureDetector(
                    onTap: () {
                      ZetaHaptics.light();
                      widget.onOpenAnalysis!();
                    },
                    child: M3EShapeContainer(
                      kind: M3EShapeKind.cookie4Sided,
                      width: 58,
                      height: 58,
                      color: colorScheme.primaryContainer,
                      child: Center(
                        child: Icon(
                          Symbols.arrow_outward_rounded,
                          size: 24,
                          weight: 700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Material 3 Expressive Tonal Bar Chart
          LayoutBuilder(
            builder: (context, constraints) {
              void selectAtPosition(Offset localPosition) {
                if (constraints.maxWidth <= 0 || values.isEmpty) return;
                final idx =
                    ((localPosition.dx / constraints.maxWidth) * values.length)
                        .floor()
                        .clamp(0, values.length - 1);
                if (_selectedDayIndex != idx) {
                  ZetaHaptics.selection();
                  setState(() => _selectedDayIndex = idx);
                }
              }

              return MouseRegion(
                onHover: (event) => selectAtPosition(event.localPosition),
                onExit: (_) {
                  if (_selectedDayIndex != null) {
                    setState(() => _selectedDayIndex = null);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => selectAtPosition(details.localPosition),
                  onHorizontalDragStart: (details) =>
                      selectAtPosition(details.localPosition),
                  onHorizontalDragUpdate: (details) =>
                      selectAtPosition(details.localPosition),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: M3MotionDuration.medium3,
                    curve: M3MotionEasing.emphasizedDecelerate,
                    builder: (context, revealProgress, _) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, 116),
                        painter: _ExpressiveWeekBarPainter(
                          values: values,
                          selectedIndex: _selectedDayIndex,
                          goalMinutes: weekDailyGoalMinutes.toDouble(),
                          revealProgress: revealProgress,
                          selectedColor: colorScheme.primary,
                          goalMetColor: colorScheme.primary,
                          highColor: colorScheme.tertiaryContainer,
                          mediumColor: colorScheme.secondaryContainer,
                          lowColor: colorScheme.errorContainer,
                          emptyColor: colorScheme.surfaceContainerHighest,
                          goalLineColor: colorScheme.outlineVariant,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Expressive Day Pill Labels aligned under each bar
          Row(
            children: List.generate(days.length, (i) {
              final isSelected = _selectedDayIndex == i;
              final isToday = days[i]['isHighlighted'] == true;

              final Color pillBg;
              final Color labelColor;
              if (isSelected) {
                pillBg = colorScheme.primaryContainer;
                labelColor = colorScheme.onPrimaryContainer;
              } else if (isToday) {
                pillBg = colorScheme.secondaryContainer.withValues(alpha: 0.65);
                labelColor = colorScheme.onSecondaryContainer;
              } else {
                pillBg = Colors.transparent;
                labelColor = colorScheme.onSurfaceVariant;
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ZetaHaptics.selection();
                    setState(
                      () => _selectedDayIndex =
                          _selectedDayIndex == i ? null : i,
                    );
                  },
                  child: Center(
                    child: AnimatedContainer(
                      duration: M3MotionDuration.short4,
                      curve: M3MotionEasing.emphasizedDecelerate,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        days[i]['label'] as String,
                        style: textTheme.labelMedium?.copyWith(
                          fontFamily: 'GoogleSansFlex',
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Material 3 Expressive tonal bar chart painter with semantic color roles
/// and a subtle dashed daily goal reference line.
class _ExpressiveWeekBarPainter extends CustomPainter {
  final List<double> values;
  final int? selectedIndex;
  final double goalMinutes;
  final double revealProgress;
  final Color selectedColor;
  final Color goalMetColor;
  final Color highColor;
  final Color mediumColor;
  final Color lowColor;
  final Color emptyColor;
  final Color goalLineColor;

  _ExpressiveWeekBarPainter({
    required this.values,
    required this.selectedIndex,
    required this.goalMinutes,
    required this.revealProgress,
    required this.selectedColor,
    required this.goalMetColor,
    required this.highColor,
    required this.mediumColor,
    required this.lowColor,
    required this.emptyColor,
    required this.goalLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final n = values.length;
    final maxVal = values.reduce(math.max);
    final effectiveMax = math.max(
      maxVal,
      goalMinutes > 0 ? goalMinutes : 60.0,
    ).clamp(60.0, double.infinity);

    final slotWidth = size.width / n;
    final barWidth = (slotWidth * 0.56).clamp(18.0, 30.0);
    final minEmptyHeight = barWidth * 0.45;
    final minActiveHeight = barWidth;

    // Subtle dashed daily goal reference line
    if (goalMinutes > 0) {
      final goalRatio = (goalMinutes / effectiveMax).clamp(0.0, 1.0);
      final goalHeight =
          minActiveHeight + (goalRatio * (size.height - minActiveHeight));
      final goalY = size.height - goalHeight;

      final linePaint = Paint()
        ..color = goalLineColor.withValues(alpha: 0.7)
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round;

      const dashWidth = 5.0;
      const dashGap = 5.0;
      double x = 4.0;
      final maxX = size.width - 4.0;
      while (x < maxX) {
        final endX = math.min(x + dashWidth, maxX);
        canvas.drawLine(Offset(x, goalY), Offset(endX, goalY), linePaint);
        x += dashWidth + dashGap;
      }
    }

    for (int i = 0; i < n; i++) {
      final value = values[i];
      final hasData = value > 0;
      final isSelected = selectedIndex == i;
      final referenceMax = goalMinutes > 0 ? goalMinutes : effectiveMax;
      final ratio = referenceMax > 0 ? (value / referenceMax) : 0.0;

      final double barHeight;
      if (!hasData) {
        barHeight = minEmptyHeight;
      } else {
        final normalized = (value / effectiveMax).clamp(0.0, 1.0);
        final targetHeight =
            minActiveHeight + (normalized * (size.height - minActiveHeight));
        barHeight =
            minActiveHeight +
            ((targetHeight - minActiveHeight) * revealProgress);
      }

      final centerX = slotWidth * i + (slotWidth / 2);
      final left = centerX - (barWidth / 2);
      final top = size.height - barHeight;

      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(barWidth / 2),
      );

      final Color barColor;
      if (isSelected) {
        barColor = selectedColor;
      } else if (!hasData) {
        barColor = emptyColor;
      } else if (ratio >= 1.0) {
        barColor = goalMetColor;
      } else if (ratio >= 0.65) {
        barColor = highColor;
      } else if (ratio >= 0.35) {
        barColor = mediumColor;
      } else {
        barColor = lowColor;
      }

      canvas.drawRRect(rrect, Paint()..color = barColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ExpressiveWeekBarPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.goalMinutes != goalMinutes ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.selectedColor != selectedColor ||
        oldDelegate.goalMetColor != goalMetColor ||
        oldDelegate.highColor != highColor ||
        oldDelegate.mediumColor != mediumColor ||
        oldDelegate.lowColor != lowColor ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.goalLineColor != goalLineColor;
  }
}
