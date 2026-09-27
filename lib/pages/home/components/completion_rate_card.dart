import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompletionRateCard extends StatelessWidget {
  final int completionRate;
  final int? completedCount;
  final int? remainingCount;
  final VoidCallback? onMoreTap;
  final VoidCallback? onOptionsTap;

  const CompletionRateCard({
    super.key,
    required this.completionRate,
    this.completedCount,
    this.remainingCount,
    this.onMoreTap,
    this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedRate = completionRate.clamp(0, 100);

    final cardBg = isDark ? const Color(0xFF2A261F) : const Color(0xFFF3EFE0);
    final cardTextDark = isDark
        ? const Color(0xFFEDE8D0)
        : const Color(0xFF161616);
    const primaryOrange = Color(0xFFFF5733);
    const secondaryYellow = Color(0xFFFDB44E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMoreTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion\nRate',
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontSize: 16,
                      height: 1.15,
                      color: cardTextDark,
                      fontVariations: const [FontVariation('wght', 900)],
                    ),
                  ),
                  if (onOptionsTap != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: cardTextDark,
                      ),
                      onPressed: onOptionsTap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      progressRatio: clampedRate / 100,
                      primaryColor: primaryOrange,
                      trackColor: secondaryYellow,
                      strokeWidth: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$clampedRate',
                      style: TextStyle(
                        fontFamily: 'headline',
                        fontSize: 38,
                        color: cardTextDark,
                        fontWeight: FontWeight.w900,
                      ),
                      children: [
                        TextSpan(
                          text: ' %',
                          style: TextStyle(
                            fontSize: 18,
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
    );
  }
}

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
