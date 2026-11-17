import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/extensions/context_extensions.dart';

import '../../../models/pomodoro.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../providers/theme_provider.dart';
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
  int? _hoveredDayIndex;

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
    final double totalHours = totalMinutes / 60.0;

    double maxMinutes = 0;
    int maxIndex = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i] >= maxMinutes) {
        maxMinutes = values[i];
        maxIndex = i;
      }
    }

    final selectedIdx =
        (_hoveredDayIndex != null && _hoveredDayIndex! < values.length)
        ? _hoveredDayIndex!
        : maxIndex;

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);

    final textColor = isDark ? Colors.white : const Color(0xFF141414);
    final textMuted = isDark
        ? const Color(0xFF8B929A)
        : const Color(0xFF757572);
    final orangeAccent = isDark
        ? const Color(0xFFFF4815)
        : const Color(0xFFE03E0A);

    final selectedFocus = values[selectedIdx].round();
    final colorScheme = context.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAST 7 DAYS',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hoveredDayIndex != null
                          ? PomodoroChartCanvas.formatDuration(selectedFocus)
                                .toUpperCase()
                          : '${totalHours.toStringAsFixed(2)} hrs',
                      style: TextStyle(
                        fontFamily: 'headline',
                        fontSize: 32,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hoveredDayIndex != null
                          ? '${days[selectedIdx]['tooltipLabel']}'
                          : 'MAX ${PomodoroChartCanvas.formatDuration(maxMinutes.round())}',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _hoveredDayIndex != null
                            ? orangeAccent
                            : textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onOpenAnalysis != null)
                GestureDetector(
                  onTap: () {
                    ZetaHaptics.light();
                    widget.onOpenAnalysis!();
                  },
                  child: M3EShapeContainer(
                    kind: M3EShapeKind.cookie4Sided,
                    width: 70,
                    height: 70,
                    color: colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        Symbols.arrow_outward_rounded,
                        size: 26,
                        weight: 700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Capsule Bar Chart Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              void updateIndex(Offset localPosition) {
                final idx =
                    ((localPosition.dx / constraints.maxWidth) * values.length)
                        .floor()
                        .clamp(0, values.length - 1);
                if (_hoveredDayIndex != idx) {
                  ZetaHaptics.selection();
                  setState(() => _hoveredDayIndex = idx);
                }
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => updateIndex(details.localPosition),
                onHorizontalDragStart: (details) =>
                    updateIndex(details.localPosition),
                onHorizontalDragUpdate: (details) =>
                    updateIndex(details.localPosition),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 110),
                  painter: _CapsuleBarPainter(
                    values: values,
                    accentColor: orangeAccent,
                    inactiveColor: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.10),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Day Labels aligned directly under each bar slot
          Row(
            children: List.generate(days.length, (i) {
              final isSelected = i == selectedIdx;
              final isToday = days[i]['isHighlighted'] == true;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ZetaHaptics.selection();
                    setState(
                      () => _hoveredDayIndex = _hoveredDayIndex == i ? null : i,
                    );
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        days[i]['label'] as String,
                        style: TextStyle(
                          fontFamily: 'GoogleSansFlex',
                          fontSize: 12,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? orangeAccent
                              : (isToday ? textColor : textMuted),
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

/// Capsule bar chart painter with stronger warm yellow-orange inner glow
class _CapsuleBarPainter extends CustomPainter {
  final List<double> values;
  final Color accentColor;
  final Color inactiveColor;

  _CapsuleBarPainter({
    required this.values,
    required this.accentColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final n = values.length;
    final maxVal = values.reduce(math.max);
    final effectiveMax = maxVal <= 0 ? 60.0 : maxVal;

    final slotWidth = size.width / n;
    final barWidth = (slotWidth * 0.56).clamp(16.0, 28.0);
    final radius = Radius.circular(barWidth / 2);

    // Stronger warm yellow-gold core blended with the orange accent
    final coreColor = Color.lerp(accentColor, const Color(0xFFFFD54F), 0.65)!;

    for (int i = 0; i < n; i++) {
      final hasData = values[i] > 0;

      // Minimum height equals barWidth so zero/low values render as clean circles at the bottom
      final minBarHeight = barWidth;
      final normalized = hasData
          ? (values[i] / effectiveMax).clamp(0.0, 1.0)
          : 0.0;
      final barHeight =
          minBarHeight + (normalized * (size.height - minBarHeight));

      final centerX = slotWidth * i + (slotWidth / 2);
      final left = centerX - (barWidth / 2);
      final top = size.height - barHeight;

      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(rect, radius);

      final paint = Paint();
      if (hasData) {
        paint.shader = RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          stops: const [0.0, 0.45, 1.0],
          colors: [
            coreColor,
            Color.lerp(coreColor, accentColor, 0.45)!,
            accentColor,
          ],
        ).createShader(rect);
      } else {
        paint.color = inactiveColor;
      }

      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CapsuleBarPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
