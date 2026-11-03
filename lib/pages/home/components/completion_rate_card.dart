import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../components/glass_surface.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../models/task.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/motion_tokens.dart';
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
///    - Tasks: completed today / today's regular task workload
class CompletionRateCard extends StatelessWidget {
  final VoidCallback? onMoreTap;
  final VoidCallback? onOptionsTap;
  final bool? enableHoverFlyout;

  const CompletionRateCard({
    super.key,
    this.onMoreTap,
    this.onOptionsTap,
    this.enableHoverFlyout,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isDark = context.theme.brightness == Brightness.dark;
    final colorScheme = context.colorScheme;

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
    final workloadTasks = <({Task task, bool isCompleted})>[];

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

      regularWorkload++;
      if (wasCompletedToday) regularCompletedToday++;
      workloadTasks.add((task: task, isCompleted: wasCompletedToday));
    }

    final totalAssignedToday = regularWorkload;
    final totalCompletedToday = regularCompletedToday;

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

    // Pending capsule — Purple/Lavender (Google Health "Sleep")
    final pendingColor = isDark
        ? const Color.fromRGBO(224, 212, 237, 1)
        : const Color(0xFF59318F);
    final pendingCapsule = _TasksWorkloadCapsule(
      key: const ValueKey('tasks_workload_capsule'),
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
      workloadTasks: workloadTasks,
      completedCount: regularCompletedToday,
      totalCount: regularWorkload,
      colorScheme: colorScheme,
      isDark: isDark,
      enableHoverFlyout: enableHoverFlyout,
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
                        Expanded(child: pendingCapsule),
                      ],
                    ),
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

/// Tasks metric capsule that expands inline on hover on desktop platforms.
class _TasksWorkloadCapsule extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final double progress;
  final Color capsuleBg;
  final Color progressFillBg;
  final Color iconShapeBg;
  final Color contentColor;
  final VoidCallback? onTap;
  final List<({Task task, bool isCompleted})> workloadTasks;
  final int completedCount;
  final int totalCount;
  final material_ui.ColorScheme colorScheme;
  final bool isDark;
  final bool? enableHoverFlyout;

  const _TasksWorkloadCapsule({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.progress = 0.0,
    required this.capsuleBg,
    this.progressFillBg = Colors.transparent,
    required this.iconShapeBg,
    required this.contentColor,
    this.onTap,
    required this.workloadTasks,
    required this.completedCount,
    required this.totalCount,
    required this.colorScheme,
    required this.isDark,
    this.enableHoverFlyout,
  });

  @override
  State<_TasksWorkloadCapsule> createState() => _TasksWorkloadCapsuleState();
}

class _TasksWorkloadCapsuleState extends State<_TasksWorkloadCapsule>
    with SingleTickerProviderStateMixin {
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
  final _tapRegionGroupId = Object();
  late final AnimationController _transformController;
  Timer? _closeTimer;
  bool _isExpanded = false;
  bool _popupVisible = false;
  bool _isHoveringPill = false;
  bool _isHoveringPopup = false;
  Size _closedSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _transformController = AnimationController(
      vsync: this,
      duration: M3MotionDuration.medium3,
      reverseDuration: M3MotionDuration.short4,
    );
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  bool _resolveIsDesktop(BuildContext context) {
    if (widget.enableHoverFlyout != null) {
      return widget.enableHoverFlyout!;
    }
    final platform = context.theme.platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.fuchsia ||
        kIsWeb;
  }

  void _openPopup(BuildContext triggerContext) {
    _closeTimer?.cancel();
    final renderObject = triggerContext.findRenderObject();
    if (renderObject is RenderBox) {
      _closedSize = renderObject.size;
    }
    if (!_popupVisible) {
      setState(() {
        _popupVisible = true;
        _isExpanded = false;
      });
      _overlayController.show();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _popupVisible) {
        setState(() => _isExpanded = true);
        _transformController.forward();
      }
    });
  }

  void _closePopup() {
    _closeTimer?.cancel();
    if (!_popupVisible) return;
    setState(() => _isExpanded = false);
    _transformController.reverse().then((_) {
      if (mounted && !_isExpanded) {
        setState(() => _popupVisible = false);
        _overlayController.hide();
      }
    });
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (!_isHoveringPill && !_isHoveringPopup) _closePopup();
    });
  }

  Widget _buildPopup(BuildContext context) {
    final maxWidth = math.min(340.0, MediaQuery.sizeOf(context).width - 32);
    final closedWidth = _closedSize.width > 0 ? _closedSize.width : 180.0;
    final closedHeight = _closedSize.height > 0 ? _closedSize.height : 58.0;

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topRight,
        followerAnchor: Alignment.topRight,
        child: MouseRegion(
          onEnter: (_) {
            _isHoveringPopup = true;
            _closeTimer?.cancel();
          },
          onExit: (_) {
            _isHoveringPopup = false;
            _scheduleClose();
          },
            child: AnimatedContainer(
            duration: M3MotionDuration.medium3,
              curve: M3MotionEasing.emphasizedDecelerate,
              width: _isExpanded ? maxWidth : closedWidth,
              constraints: BoxConstraints(
                minHeight: closedHeight,
                maxHeight: 380,
              ),
              child: GlassSurface(
                borderRadius: BorderRadius.circular(_isExpanded ? 24 : 20),
                blurSigma: 5,
                color: widget.capsuleBg.withValues(
                  alpha: 0.5,
                ),
                child: AnimatedSize(
                  duration: M3MotionDuration.medium3,
                  reverseDuration: M3MotionDuration.short4,
                  curve: M3MotionEasing.emphasizedDecelerate,
                  alignment: Alignment.topRight,
                  child: AnimatedSwitcher(
                    duration: M3MotionDuration.medium2,
                    switchInCurve: M3MotionEasing.emphasizedDecelerate,
                    switchOutCurve: M3MotionEasing.emphasizedAccelerate,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    ),
                    child: _isExpanded
                        ? _TasksFlyoutCard(
                            key: const ValueKey('expanded-workload'),
                            workloadTasks: widget.workloadTasks,
                            completedCount: widget.completedCount,
                            totalCount: widget.totalCount,
                            colorScheme: widget.colorScheme,
                            isDark: widget.isDark,
                            capsuleBg: widget.capsuleBg,
                            iconShapeBg: widget.iconShapeBg,
                            contentColor: widget.contentColor,
                          )
                        : KeyedSubtree(
                            key: const ValueKey('closed-workload'),
                            child: _HealthMetricCapsule(
                              title: widget.title,
                              value: widget.value,
                              icon: widget.icon,
                              progress: widget.progress,
                              capsuleBg: widget.capsuleBg,
                              progressFillBg: widget.progressFillBg,
                              iconShapeBg: widget.iconShapeBg,
                              contentColor: widget.contentColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capsule = _HealthMetricCapsule(
      title: widget.title,
      value: widget.value,
      icon: widget.icon,
      progress: widget.progress,
      capsuleBg: widget.capsuleBg,
      progressFillBg: widget.progressFillBg,
      iconShapeBg: widget.iconShapeBg,
      contentColor: widget.contentColor,
      onTap: () {
        if (_isExpanded) _closePopup();
        widget.onTap?.call();
      },
    );

    final isDesktop = _resolveIsDesktop(context);

    if (!isDesktop) {
      return capsule;
    }

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildPopup,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          onEnter: (_) {
            _isHoveringPill = true;
            _openPopup(context);
          },
          onExit: (_) {
            _isHoveringPill = false;
            _scheduleClose();
          },
          child: AnimatedOpacity(
            duration: M3MotionDuration.short4,
            opacity: _popupVisible ? 0.0 : 1.0,
            child: capsule,
          ),
        ),
      ),
    );
  }
}

/// View-only flyout card displaying the active workload tasks in an M3EList
/// styled on a GlassSurface matching weather telemetry and profile flyouts.
class _TasksFlyoutCard extends StatelessWidget {
  final List<({Task task, bool isCompleted})> workloadTasks;
  final int completedCount;
  final int totalCount;
  final material_ui.ColorScheme colorScheme;
  final bool isDark;
  final Color capsuleBg;
  final Color iconShapeBg;
  final Color contentColor;

  const _TasksFlyoutCard({
    super.key,
    required this.workloadTasks,
    required this.completedCount,
    required this.totalCount,
    required this.colorScheme,
    required this.isDark,
    required this.capsuleBg,
    required this.iconShapeBg,
    required this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Symbols.checklist_rounded,
                size: 18,
                color: contentColor,
                fill: 1.0,
                weight: 700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Workload",
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: contentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ─── Task List Display Using M3EList (View-Only) ────────────────
          if (workloadTasks.isEmpty)
            M3EList(
              color: capsuleBg.withValues(alpha: isDark ? 0.5 : 0.72),
              itemCount: 1,
              itemBuilder: (context, index) => M3EListItem(
                leading: Icon(
                  Symbols.check_circle_rounded,
                  size: 20,
                  color: contentColor,
                  fill: 1.0,
                  weight: 700,
                ),
                headline: 'No workload tasks for today',
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: M3EList(
                  color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.4),
                  itemCount: workloadTasks.length,
                  itemBuilder: (context, index) {
                    final item = workloadTasks[index];
                    final isDone = item.isCompleted;
                    final statusColor = isDone
                        ? contentColor
                        : contentColor.withValues(alpha: 0.78);
                    return M3EListItem(
                      leading: Icon(
                        isDone
                            ? Symbols.check_circle_rounded
                            : Symbols.radio_button_unchecked_rounded,
                        size: 20,
                        color: isDone
                            ? statusColor
                            : contentColor,
                        fill: 1.0,
                        weight: 700,
                      ),
                      headline: item.task.title,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
