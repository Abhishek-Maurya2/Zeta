import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../providers/theme_provider.dart'; // Adjust path as needed

import '../../../providers/pomodoro_provider.dart';
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
    final provider = context.watch<PomodoroProvider>();
    final sessionLog = provider.sessionLog;
    final now = DateTime.now();
    final todayStr = PomodoroChartCanvas.toLocalDateStr(now);

    // 1. Build rolling 7 days: past 6 days + current day (offset = 0)
    final days = PomodoroChartCanvas.buildWeekDays(
      sessionLog,
      now,
      0,
      todayStr,
      provider.settings.weekDailyGoalMinutes,
    );

    // Extract daily focus minutes (7 values)
    final List<double> values = days
        .map((d) => (d['focus'] as int).toDouble())
        .toList();
    final double totalMinutes = values.fold<double>(0.0, (sum, v) => sum + v);
    final double totalHours = totalMinutes / 60.0;

    // Determine max day index & peak value
    double maxMinutes = 0;
    int maxIndex = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i] >= maxMinutes) {
        maxMinutes = values[i];
        maxIndex = i;
      }
    }

    // Selected or active needle index (defaults to max peak, or user-selected)
    final selectedIdx =
        (_hoveredDayIndex != null && _hoveredDayIndex! < values.length)
        ? _hoveredDayIndex!
        : maxIndex;

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);

    // Palette matching the editorial off-white aesthetic
    final cardBg = isDark ? const Color(0xFF161719) : const Color(0xFFF7F6F2);
    final textColor = isDark ? Colors.white : const Color(0xFF141414);
    final textMuted = isDark
        ? const Color(0xFF8B929A)
        : const Color(0xFF757572);
    final orangeAccent = isDark
        ? const Color(0xFFFF4815)
        : const Color(0xFFE03E0A);

    final selectedFocus = values[selectedIdx].round();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 320, maxWidth: 220),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ─── Main Content ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top subtitle (e.g. Year or Date Range)
                Text(
                  ' PAST 7 DAYS',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 4),

                // Large Headline Number (Total Hours or Selected Day)
                Text(
                  _hoveredDayIndex != null
                      ? PomodoroChartCanvas.formatDuration(selectedFocus)
                            .toUpperCase()
                      : '${totalHours.toStringAsFixed(2)} hrs',
                  style: TextStyle(
                    fontFamily: 'headline',
                    fontSize: 36,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Middle Stat ("MAX 2h 15m" or selected day tag)
                Row(
                  children: [
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

                const SizedBox(
                  height: 120,
                ), // Reserve breathing room for canvas
              ],
            ),
          ),

          // ─── Hatched Ridge Terrain Canvas ───────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 280,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final localX = details.localPosition.dx;
                final idx = ((localX / box.size.width) * values.length)
                    .floor()
                    .clamp(0, values.length - 1);
                if (_hoveredDayIndex != idx) {
                  ZetaHaptics.selection();
                  setState(() => _hoveredDayIndex = idx);
                }
              },
              onHorizontalDragEnd: (_) =>
                  setState(() => _hoveredDayIndex = null),
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final localX = details.localPosition.dx;
                final idx = ((localX / box.size.width) * values.length)
                    .floor()
                    .clamp(0, values.length - 1);
                ZetaHaptics.selection();
                setState(() => _hoveredDayIndex = idx);
              },
              child: CustomPaint(
                painter: _HatchedTerrainPainter(
                  values: values,
                  selectedIndex: selectedIdx,
                  hatchColor: isDark
                      ? const Color.fromARGB(255, 128, 134, 143)
                      : const Color.fromARGB(255, 104, 107, 113),
                  accentColor: orangeAccent,
                  dotContrastColor: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white,
                  lineWidth: 1.25,
                  stripeSpacing: 4.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering the undulating contour filled with vertical pinstripes
/// and a highlighted needle pin at the chosen data point.
class _HatchedTerrainPainter extends CustomPainter {
  final List<double> values;
  final int selectedIndex;
  final Color hatchColor;
  final Color accentColor;
  final Color dotContrastColor;
  final double lineWidth;
  final double stripeSpacing;

  _HatchedTerrainPainter({
    required this.values,
    required this.selectedIndex,
    required this.hatchColor,
    required this.accentColor,
    required this.dotContrastColor,
    required this.lineWidth,
    required this.stripeSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final n = values.length;
    final maxVal = values.reduce(math.max);
    final effectiveMax = maxVal <= 0 ? 60.0 : maxVal * 1.25;

    // Generate control point coordinates along width
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = (i / (n - 1)) * size.width;
      final normalized = (values[i] / effectiveMax).clamp(0.08, 0.90);
      final y = size.height - (normalized * (size.height * 0.72)) - 24;
      points.add(Offset(x, y));
    }

    // Build smooth cubic Catmull-Rom spline path
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < n - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < n - 2 ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    path.lineTo(size.width, size.height);
    path.close();

    // ── 1. Draw Dense Hatched Vertical Lines ──
    final hatchPaint = Paint()
      ..color = hatchColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipPath(path);

    for (double x = 0; x <= size.width; x += stripeSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), hatchPaint);
    }
    canvas.restore();

    // ── 2. Draw Selected / Peak Indicator Needle & Dot ──
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final needlePoint = points[selectedIndex];

      final needlePaint = Paint()
        ..color = accentColor
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      // Vertical line from baseline to curve peak
      canvas.drawLine(
        Offset(needlePoint.dx, size.height),
        Offset(needlePoint.dx, needlePoint.dy),
        needlePaint,
      );

      // Solid circular pip on the peak
      final dotPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(needlePoint.dx, needlePoint.dy), 7.0, dotPaint);

      // Inner subtle contrast dot
      canvas.drawCircle(
        Offset(needlePoint.dx, needlePoint.dy),
        3.0,
        Paint()..color = dotContrastColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HatchedTerrainPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.values != values ||
        oldDelegate.hatchColor != hatchColor ||
        oldDelegate.accentColor != accentColor;
  }
}
