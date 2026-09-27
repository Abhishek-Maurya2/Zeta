import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Summary Widgets mirroring Sharva's SummaryWidgets:
/// 1. Active Tasks: Top green expressive card with large counter and today's scheduled count.
/// 2. Completion Rate: Editorial cream card with rounded donut chart and stats.
/// 3. Completed Tasks: Golden amber card with completed counter.
/// 4. Today Milestones: Bottom blue card with today's milestones.
class HomeSummaryCards extends StatelessWidget {
  final int activeCount;
  final int todayActiveCount;
  final int completionRate;
  final int completedCount;
  final VoidCallback? onMoreTap;
  final VoidCallback? onOptionsTap;

  const HomeSummaryCards({
    super.key,
    required this.activeCount,
    required this.todayActiveCount,
    required this.completionRate,
    required this.completedCount,
    this.onMoreTap,
    this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Card 1: Active Tasks (Green)
    final greenBg = isDark ? const Color(0xFF1A3821) : const Color(0xFFD4F8D3);
    final greenText = isDark
        ? const Color(0xFFA6F0B0)
        : const Color(0xFF0F3D17);

    // Card 3: Completed Tasks (Amber)
    final amberBg = isDark ? const Color(0xFF393110) : const Color(0xFFFFF0C2);
    final amberText = isDark
        ? const Color(0xFFFFE082)
        : const Color(0xFF463B05);

    // Card 4: Milestones (Blue)
    final blueBg = isDark ? const Color(0xFF1B2B46) : const Color(0xFFD8E6FF);
    final blueText = isDark ? const Color(0xFFADC6FF) : const Color(0xFF0D2A58);

    // Card 2: Completion Rate Design Colors
    final clampedRate = completionRate.clamp(0, 100);
    final remainingCount = (100 - clampedRate).clamp(0, 100);
    final cardBg = isDark ? const Color(0xFF2A261F) : const Color(0xFFF3EFE0);
    final cardTextDark = isDark
        ? const Color(0xFFEDE8D0)
        : const Color(0xFF161616);
    final cardTextSubdued = isDark
        ? const Color(0xFF9E9B8F)
        : const Color(0xFF88857C);
    final cardDivider = isDark
        ? const Color(0xFF3F3B30)
        : const Color(0xFFE2DEC8);
    const primaryOrange = Color(0xFFFF5733);
    const secondaryYellow = Color(0xFFFDB44E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Widget 1: Active Tasks (Top Green Card) ─────────────────────────
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: greenBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.check_circle_rounded, size: 26, color: greenText),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: greenText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$activeCount',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: greenText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Active Tasks',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: greenText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$todayActiveCount task${todayActiveCount == 1 ? "" : "s"} scheduled for today',
                style: TextStyle(
                  fontSize: 12,
                  color: greenText.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ─── Widget 2 & 3: Completion Rate & Completed Tasks ────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REPLACED: Completion Rate (Donut Circular Design)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // heading
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion\nRate',
                          style: TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            fontSize: 20,
                            color: cardTextDark,
                            fontVariations: const [FontVariation('wght', 900)],
                          ),
                        ),
                      ],
                    ),

                    // circle
                    Center(
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: CustomPaint(
                          painter: _DonutChartPainter(
                            progressRatio: clampedRate / 100,
                            primaryColor: primaryOrange,
                            trackColor: secondaryYellow,
                            strokeWidth: 22,
                          ),
                        ),
                      ),
                    ),

                    // percent
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Spacer(),
                        Text.rich(
                          TextSpan(
                            text: '$clampedRate',
                            style: TextStyle(
                              fontFamily: 'headlilne',
                              fontSize: 45,
                              color: cardTextDark,
                              fontWeight: FontWeight.w900,
                            ),
                            children: [
                              TextSpan(
                                text: ' %',
                                style: TextStyle(
                                  fontSize: 22, // smaller percentage symbol
                                  fontWeight: FontWeight.w800,
                                  color: cardTextDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Card 3: Completed Tasks
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: amberBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.task_alt_rounded, size: 24, color: amberText),
                    const SizedBox(height: 14),
                    Text(
                      '$completedCount',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: amberText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Completed\nTasks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: amberText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ─── Widget 4: Today Milestones (Bottom Blue Card) ───────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: blueBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 22,
                  color: blueText,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$todayActiveCount Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: blueText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Milestones due before end of day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: blueText.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the rounded dual-tone donut ring
class _DonutChartPainter extends CustomPainter {
  final double progressRatio;
  final Color primaryColor;
  final Color trackColor;
  final double strokeWidth;

  _DonutChartPainter({
    required this.progressRatio,
    required this.primaryColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    // Background full track ring
    final backgroundPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Active progress arc with rounded caps
    if (progressRatio > 0) {
      final sweepAngle = 2 * math.pi * progressRatio.clamp(0.0, 1.0);
      final activePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

typedef SummaryWidgets = HomeSummaryCards;
