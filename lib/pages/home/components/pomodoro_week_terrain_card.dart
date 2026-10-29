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
      padding: const EdgeInsets.all(20),
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
                M3EIconButton(
                  onPressed: widget.onOpenAnalysis,
                  icon: const Icon(Symbols.arrow_outward_rounded, weight: 700),
                  tooltip: 'View Analysis',
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Smooth Terrain Canvas
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
                  painter: _SimpleTerrainPainter(
                    values: values,
                    selectedIndex: selectedIdx,
                    accentColor: orangeAccent,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Day Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (i) {
              final isSelected = i == selectedIdx;
              final isToday = days[i]['isHighlighted'] == true;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ZetaHaptics.selection();
                  setState(
                    () => _hoveredDayIndex = _hoveredDayIndex == i ? null : i,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
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
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Lightweight, smooth terrain area painter
class _SimpleTerrainPainter extends CustomPainter {
  final List<double> values;
  final int selectedIndex;
  final Color accentColor;

  _SimpleTerrainPainter({
    required this.values,
    required this.selectedIndex,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final n = values.length;
    final maxVal = values.reduce(math.max);
    final effectiveMax = maxVal <= 0 ? 60.0 : maxVal * 1.25;

    final points = List.generate(n, (i) {
      final x = (i / (n - 1)) * size.width;
      final normalized = (values[i] / effectiveMax).clamp(0.06, 0.92);
      final y = size.height - (normalized * size.height);
      return Offset(x, y);
    });

    // Build smooth cubic curve
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < n - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Fill gradient terrain
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.35),
          accentColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke curve line
    final strokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Highlight selected or peak point
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final p = points[selectedIndex];

      // Vertical guide line
      canvas.drawLine(
        Offset(p.dx, size.height),
        Offset(p.dx, p.dy),
        Paint()
          ..color = accentColor.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );

      // Accent dot
      canvas.drawCircle(p, 5.5, Paint()..color = accentColor);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleTerrainPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.values != values ||
        oldDelegate.accentColor != accentColor;
  }
}
