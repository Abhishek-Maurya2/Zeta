import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../providers/navigation_provider.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/date_time_utils.dart';
import '../../../utils/haptics.dart';

/// Bento Grid Task Completion & Multi-Domain Metrics Widget.
///
/// Designed to match Google Health Premium card style with:
/// - M3 flower-morphed icon shapes
/// - Google Health color palette (teal, coral, purple)
/// - Donut ring gauge with delta badge
///
/// Automatically adapts its layout depending on available width and space:
/// - Wide / Desktop Bento (width >= 560px): Ring hero block (left) alongside a 2-column or 3-column bento capsule grid.
/// - Medium / Tablet Bento (340px <= width < 560px): Ring hero block (left) + stacked pills (right) or 2x2 grid.
/// - Narrow / Mobile Bento (< 340px): Compact stacked bento layout.
///
/// Features:
/// 1. Donut Ring Gauge:
///    - Calculates: today's workload completed today / today's workload target
///    - Circular top-right delta badge (+N done today)
///    - Center percentage, title, and "X of Y" count
/// 2. Bento Capsule Metric Pills:
///    - Focus: Total Pomodoro focus time today
///    - Revision: completed today / today's revision workload
///    - Tasks: completed today / today's regular task workload
class CompletionRateCard extends StatelessWidget {
  final VoidCallback? onMoreTap;
  final VoidCallback? onOptionsTap;

  const CompletionRateCard({super.key, this.onMoreTap, this.onOptionsTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);

    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final navProvider = context.read<NavigationProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool completedToday(DateTime? timestamp) =>
        timestamp != null && DateTimeUtils.isSameDay(timestamp, today);

    // Today's workload includes tasks assigned today and overdue tasks that
    // remain pending or were completed today.
    final tasks = taskProvider.allTasks;
    int regularWorkload = 0;
    int regularCompletedToday = 0;
    int revisionWorkload = 0;
    int revisionCompletedToday = 0;

    for (final task in tasks) {
      final due = task.parsedDueDate;
      if (due == null) continue;

      final dueToday = DateTimeUtils.isSameDay(due, today);
      final overdue = due.isBefore(today);
      final wasCompletedToday =
          task.completed && completedToday(task.completedAt);
      final hasRecordedTaskCompletion = task.completedAt != null;
      final belongsToTodaysWorkload =
          dueToday ||
          // A subtask can auto-complete its parent without setting completedAt;
          // keep that item in the workload without counting it as completed.
          (overdue &&
              (!task.completed ||
                  !hasRecordedTaskCompletion ||
                  wasCompletedToday));
      if (!belongsToTodaysWorkload) continue;

      final isRevision = TaskProvider.isRevisionTask(task);
      if (isRevision) {
        revisionWorkload++;
        if (wasCompletedToday) revisionCompletedToday++;
      } else {
        regularWorkload++;
        if (wasCompletedToday) regularCompletedToday++;
      }
    }

    final totalAssignedToday = regularWorkload + revisionWorkload;
    final totalCompletedToday = regularCompletedToday + revisionCompletedToday;

    final calculatedRate = totalAssignedToday > 0
        ? ((totalCompletedToday / totalAssignedToday) * 100).round()
        : 0;

    final displayRate = calculatedRate;
    final displayCompleted = totalCompletedToday;
    final displayTotal = totalAssignedToday;

    // ─── 2. Calculate Telemetry for Metric Capsules ──────────────
    // A) Focus Time Today (Pomodoro) — Goal Reached
    final sessionLog = pomodoroProvider.sessionLog;
    int todayFocusMinutes = 0;
    for (final session in sessionLog) {
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(
        session.completedAt,
      );
      if (DateTimeUtils.isSameDay(sessionDate, today)) {
        todayFocusMinutes += session.minutes;
      }
    }

    final focusGoalMinutes = pomodoroProvider.settings.dailyGoalMinutes > 0
        ? pomodoroProvider.settings.dailyGoalMinutes
        : 60;
    final focusProgress = (todayFocusMinutes / focusGoalMinutes).clamp(
      0.0,
      1.0,
    );
    // in hourse and minutes
    final focusValue =
        '${todayFocusMinutes ~/ 60}h ${todayFocusMinutes % 60}min';

    // B) Revision Metric — Completed today / today's revision workload.
    final revisionProgress = revisionWorkload > 0
        ? (revisionCompletedToday / revisionWorkload).clamp(0.0, 1.0)
        : 0.0;
    final revisionValue =
        revisionWorkload > 0 && revisionCompletedToday == revisionWorkload
        ? 'All done'
        : '$revisionCompletedToday/$revisionWorkload';

    // C) Regular Task Metric — Completed today / today's regular workload.
    final tasksProgress = regularWorkload > 0
        ? (regularCompletedToday / regularWorkload).clamp(0.0, 1.0)
        : 0.0;
    final tasksValue =
        regularWorkload > 0 && regularCompletedToday == regularWorkload
        ? 'All done'
        : '$regularCompletedToday/$regularWorkload';

    // ─── Google Health Color Palette ─────────────────────────────
    // Focus capsule — Teal (Google Health "Steps" teal)
    final focusColor = isDark
        ? const Color.fromRGBO(187, 244, 238, 1)
        : const Color(0xFF00695C);
    final focusCapsule = _HealthMetricCapsule(
      title: 'Focus',
      value: focusValue,
      icon: Symbols.timer_rounded,
      progress: focusProgress,
      capsuleBg: isDark
          ? const Color.fromRGBO(0, 100, 88, 1)
          : const Color(0xFF8FF3E7),
      progressFillBg: isDark
          ? const Color.fromARGB(255, 3, 147, 125)
          : const Color.fromARGB(255, 82, 227, 220),
      iconShapeBg: isDark
          ? const Color.fromRGBO(0, 59, 53, 1)
          : const Color.fromARGB(255, 217, 255, 250),
      contentColor: focusColor,
      onTap: () {
        ZetaHaptics.light();
        navProvider.setActivePage(PageId.pomodoro);
      },
    );

    // Revision capsule — Coral/Pink (Google Health "Readiness")
    final revisionColor = isDark
        ? const Color.fromRGBO(216, 246, 224, 1)
        : const Color(0xFF08542C);
    final revisionCapsule = _HealthMetricCapsule(
      title: 'Revision',
      value: revisionValue,
      icon: Symbols.book_rounded,
      progress: revisionProgress,
      capsuleBg: isDark
          ? const Color.fromRGBO(1, 99, 26, 1)
          : const Color(0xFFBEF0BD),
      progressFillBg: isDark
          ? const Color.fromRGBO(1, 99, 26, 1)
          : const Color(0xFFDEF7DA),
      iconShapeBg: isDark
          ? const Color.fromRGBO(1, 57, 26, 1)
          : const Color.fromARGB(255, 236, 252, 234),
      contentColor: revisionColor,
      onTap: () {
        ZetaHaptics.light();
        taskProvider.setFilter(TaskFilter.revision);
        navProvider.setActivePage(PageId.tasks);
      },
    );

    // Pending capsule — Purple/Lavender (Google Health "Sleep")
    final pendingColor = isDark
        ? const Color.fromRGBO(224, 212, 237, 1)
        : const Color(0xFF59318F);
    final pendingCapsule = _HealthMetricCapsule(
      title: 'Tasks',
      value: tasksValue,
      icon: Symbols.checklist_rounded,
      progress: tasksProgress,
      capsuleBg: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFEBDDFE),
      progressFillBg: isDark
          ? const Color.fromARGB(255, 152, 84, 204)
          : const Color(0xFFD3B1FD),
      iconShapeBg: isDark
          ? const Color.fromARGB(255, 74, 5, 143)
          : const Color(0xFFF9EEFF),
      contentColor: pendingColor,
      onTap: () {
        ZetaHaptics.light();
        taskProvider.setFilter(TaskFilter.pending);
        navProvider.setActivePage(PageId.tasks);
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        final ringWidget = MetricDonutRingGauge(
          rate: displayRate,
          completedCount: displayCompleted,
          totalTargetCount: displayTotal,
          deltaBadgeCount: displayCompleted,
          isDark: isDark,
        );

        // ─── Layout Mode A: Extra Wide Bento (w >= 540) ─────────────
        // 2-row Bento grid: Ring on left (spanning full height) + 2-col capsule grid on right
        if (w >= 540) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 170, height: 170, child: ringWidget),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: focusCapsule),
                        const SizedBox(width: 8),
                        Expanded(child: revisionCapsule),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: pendingCapsule)]),
                  ],
                ),
              ),
            ],
          );
        }

        // ─── Layout Mode B: Medium Bento (320 <= w < 540) ───────────
        // Side-by-side Bento: Ring on left + vertically stacked capsules on right
        if (w >= 320) {
          final ringSize = (w * 0.42).clamp(130.0, 185.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Center(child: ringWidget),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    focusCapsule,
                    const SizedBox(height: 7),
                    revisionCapsule,
                    const SizedBox(height: 7),
                    pendingCapsule,
                  ],
                ),
              ),
            ],
          );
        }

        // ─── Layout Mode C: Compact Bento (w < 320) ─────────────────
        // Stacked Bento: Centered Ring on top + full width capsules beneath
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 160, height: 160, child: ringWidget),
            const SizedBox(height: 14),
            focusCapsule,
            const SizedBox(height: 7),
            revisionCapsule,
            const SizedBox(height: 7),
            pendingCapsule,
          ],
        );
      },
    );
  }
}

/// Modular Circular Donut Gauge with floating delta badge
/// Matches Google Health Premium ring style — thick stroke,
/// rounded caps, centered labels with a "Due + overdue" title.
class MetricDonutRingGauge extends StatelessWidget {
  final int rate;
  final int completedCount;
  final int totalTargetCount;
  final int deltaBadgeCount;
  final bool isDark;

  const MetricDonutRingGauge({
    super.key,
    required this.rate,
    required this.completedCount,
    required this.totalTargetCount,
    required this.deltaBadgeCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRate = rate.clamp(0, 100);
    // Google Health primary blue
    const primaryBlue = Color(0xFF387BFF);
    final trackColor = isDark
        ? const Color(0xFF2C2D32)
        : const Color(0xFFE2E5EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF16171B);
    final textMuted = isDark
        ? const Color(0xFF8E939C)
        : const Color(0xFF6B7280);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final strokeWidth = (size * 0.16).clamp(12.0, 26.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Donut Canvas
            CustomPaint(
              size: Size(size, size),
              painter: _RingProgressPainter(
                progressRatio: clampedRate / 100.0,
                primaryColor: primaryBlue,
                trackColor: trackColor,
                strokeWidth: strokeWidth,
              ),
            ),

            // Center Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Due + overdue',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontVariations: const [
                      FontVariation('ROND', 100),
                      FontVariation('wght', 600),
                    ],
                    fontSize: (size * 0.08).clamp(9.0, 13.0),
                    letterSpacing: -0.2,
                    color: textMuted,
                  ),
                ),
                Text(
                  '$clampedRate%',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontVariations: const [
                      FontVariation('ROND', 100),
                      FontVariation('wght', 800),
                    ],
                    fontSize: (size * 0.22).clamp(22.0, 36.0),
                    letterSpacing: -1.0,
                    height: 1.1,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '$completedCount of $totalTargetCount',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontVariations: const [
                      FontVariation('ROND', 100),
                      FontVariation('wght', 700),
                    ],
                    fontSize: (size * 0.075).clamp(9.0, 12.0),
                    letterSpacing: -0.2,
                    color: textMuted,
                  ),
                ),
              ],
            ),

            // Top-Right Floating Circular Delta Badge (+N)
            Positioned(
              top: size * 0.02,
              right: size * 0.10,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (size * 0.045).clamp(5.0, 9.0),
                  vertical: (size * 0.02).clamp(2.0, 4.0),
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF152C58)
                      : const Color(0xFFD6E4FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B4D8A) : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '+$deltaBadgeCount',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontVariations: const [
                      FontVariation('ROND', 100),
                      FontVariation('wght', 800),
                    ],
                    fontSize: (size * 0.075).clamp(9.0, 12.0),
                    color: isDark
                        ? const Color(0xFF7CA6FE)
                        : const Color(0xFF1D54C2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter for rounded progress arc
class _RingProgressPainter extends CustomPainter {
  final double progressRatio;
  final Color primaryColor;
  final Color trackColor;
  final double strokeWidth;

  const _RingProgressPainter({
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

    // Full Circular Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Active Progress Arc
    if (progressRatio > 0.0) {
      final sweepAngle = 2 * math.pi * progressRatio.clamp(0.0, 1.0);
      final progressPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Google Health–style metric capsule with M3 Expressive shaped icon
/// and two-tone progress fill.
///
/// Layout: [M3EShape Icon] [Title + Bold Value]
/// The capsule background shows a darker shade filling from the left
/// to indicate progress, exactly like Google Health metric cards.
/// Shape is rounded-lg (16px), not pill-shaped.
class _HealthMetricCapsule extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double progress; // 0.0 – 1.0 fill ratio
  final Color capsuleBg;
  final Color progressFillBg; // darker shade for filled portion
  final Color iconShapeBg;
  final Color contentColor;
  final VoidCallback? onTap;

  const _HealthMetricCapsule({
    required this.title,
    required this.value,
    required this.icon,
    this.progress = 0.0,
    required this.capsuleBg,
    this.progressFillBg = Colors.transparent,
    required this.iconShapeBg,
    required this.contentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    final isComplete = progress >= 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // ─── Base background (unfilled portion) ─────────
              Positioned.fill(child: ColoredBox(color: capsuleBg)),

              // ─── Progress fill (darker shade, from left) ────
              if (progress > 0.0)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: ColoredBox(color: progressFillBg),
                  ),
                ),

              // ─── Content row on top ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    // ─── Icon Container: Flower at 100%, else Vertical Pill ──
                    if (isComplete)
                      M3EShapeContainer(
                        kind: M3EShapeKind.cookie9Sided,
                        width: 45,
                        height: 45,
                        color: iconShapeBg,
                        child: Center(
                          child: Icon(
                            icon,
                            color: contentColor,
                            fill: 1.0,
                            weight: 700,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 35,
                        height: 50,
                        decoration: BoxDecoration(
                          color: iconShapeBg,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          color: contentColor,
                          fill: 1.0,
                          weight: 700,
                        ),
                      ),
                    const SizedBox(width: 10),

                    // ─── Metric Label & Value ─────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontVariations: const [
                                FontVariation('ROND', 100),
                                FontVariation('wght', 600),
                              ],
                              fontSize: 15,
                              letterSpacing: 0.1,
                              color: contentColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontVariations: const [
                                FontVariation('ROND', 100),
                                FontVariation('wght', 700),
                              ],
                              fontSize: 22,
                              letterSpacing: -0.3,
                              height: 1.3,
                              color: contentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
