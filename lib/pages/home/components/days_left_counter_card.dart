import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/haptics.dart';
import '../../../theme/motion_tokens.dart';

enum TargetTimeFrame { days, weeks, months }

class DaysLeftCounterCard extends StatefulWidget {
  const DaysLeftCounterCard({super.key});

  @override
  State<DaysLeftCounterCard> createState() => _DaysLeftCounterCardState();
}

class _DaysLeftCounterCardState extends State<DaysLeftCounterCard> {
  String _title = 'Target Goal';
  late DateTime _targetDate;
  late DateTime _startDate;
  TargetTimeFrame _selectedUnit = TargetTimeFrame.days;


  // SharedPreferences keys
  static const _kTitle = 'days_counter_title';
  static const _kStartDate = 'days_counter_start_date';
  static const _kTargetDate = 'days_counter_target_date';

  // Discrete pill segment count across linear bar & semicircle arch
  static const int _totalSegments = 26;

  // 3-Stage gradient keyframe colors
  static const Color _greenColor = Color(0xFF62E39E); // 0%
  static const Color _amberColor = Color(0xFFF5D13B); // 50%
  static const Color _redColor = Color(0xFFEF4444); // 100%

  // Reference image spectrum tokens (Lime Green -> Cyan/Aqua -> Sky Blue)
  static const Color _glowLimeGreen = Color(0xFF72EB65);
  static const Color _glowAquaCyan = Color(0xFF42E5C5);
  static const Color _glowSkyBlue = Color(0xFF50C5F2);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now;
    _targetDate = now.add(const Duration(days: 30));
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTitle = prefs.getString(_kTitle);
    final savedStart = prefs.getString(_kStartDate);
    final savedTarget = prefs.getString(_kTargetDate);

    if (mounted) {
      setState(() {
        if (savedTitle != null) _title = savedTitle;
        if (savedStart != null) {
          _startDate = DateTime.tryParse(savedStart) ?? _startDate;
        }
        if (savedTarget != null) {
          _targetDate = DateTime.tryParse(savedTarget) ?? _targetDate;
        }
      });
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTitle, _title);
    await prefs.setString(_kStartDate, _startDate.toIso8601String());
    await prefs.setString(_kTargetDate, _targetDate.toIso8601String());
  }

  int get _rawDaysLeft {
    final now = DateTime.now();
    final difference = _targetDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return difference < 0 ? 0 : difference;
  }

  double get _progressRatio {
    final now = DateTime.now();
    final totalDays = _targetDate.difference(_startDate).inDays;
    if (totalDays <= 0) return 1.0;

    final elapsedDays = now.difference(_startDate).inDays;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }

  int get _percentage => (_progressRatio * 100).round();

  static Color getColorForProgress(double ratio) {
    final clamped = ratio.clamp(0.0, 1.0);
    if (clamped <= 0.5) {
      return Color.lerp(_greenColor, _amberColor, clamped * 2.0)!;
    } else {
      return Color.lerp(_amberColor, _redColor, (clamped - 0.5) * 2.0)!;
    }
  }

  String get _unitValue {
    switch (_selectedUnit) {
      case TargetTimeFrame.days:
        return '$_rawDaysLeft';
      case TargetTimeFrame.weeks:
        final weeks = (_rawDaysLeft / 7).toStringAsFixed(1);
        return weeks.endsWith('.0') ? '${_rawDaysLeft ~/ 7}' : weeks;
      case TargetTimeFrame.months:
        final months = (_rawDaysLeft / 30.44).toStringAsFixed(1);
        return months.endsWith('.0') ? '${_rawDaysLeft ~/ 30}' : months;
    }
  }

  String get _unitLabel {
    switch (_selectedUnit) {
      case TargetTimeFrame.days:
        return _rawDaysLeft == 1 ? 'DAY LEFT' : 'DAYS LEFT';
      case TargetTimeFrame.weeks:
        return 'WEEKS LEFT';
      case TargetTimeFrame.months:
        return 'MONTHS LEFT';
    }
  }

  Future<void> _openEditDialog() async {
    ZetaHaptics.medium();

    final titleController = TextEditingController(text: _title);
    DateTime tempStart = _startDate;
    DateTime tempTarget = _targetDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161616),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: const Text(
                'Configure Target Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'GoogleSansFlex',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'GoogleSansFlex',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Target Title',
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontFamily: 'GoogleSansFlex',
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: Colors.white.withValues(alpha: 0.06),
                      title: const Text(
                        'Start Date',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'GoogleSansFlex',
                        ),
                      ),
                      subtitle: Text(
                        '${tempStart.year}-${tempStart.month.toString().padLeft(2, '0')}-${tempStart.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Color(0xFFFF5722),
                          fontFamily: 'RobotoMono',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate: tempStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => tempStart = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: Colors.white.withValues(alpha: 0.06),
                      title: const Text(
                        'Target Date',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'GoogleSansFlex',
                        ),
                      ),
                      subtitle: Text(
                        '${tempTarget.year}-${tempTarget.month.toString().padLeft(2, '0')}-${tempTarget.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Color(0xFFFF5722),
                          fontFamily: 'RobotoMono',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.event_available_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogCtx,
                          initialDate: tempTarget.isAfter(tempStart)
                              ? tempTarget
                              : tempStart.add(const Duration(days: 1)),
                          firstDate: tempStart,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => tempTarget = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'GoogleSansFlex',
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF481F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'GoogleSansFlex',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {
        _title = titleController.text.trim().isEmpty
            ? 'Target Goal'
            : titleController.text.trim();
        _startDate = tempStart;
        _targetDate = tempTarget;
      });
      unawaited(_saveToPrefs());
    }
    titleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFF131416);
    const textMuted = Color.fromARGB(255, 175, 184, 195);

    final ratio = _progressRatio;
    final currentStatusColor = getColorForProgress(ratio);
    final activePills = (ratio * _totalSegments).round();
    final isMonthView = _selectedUnit == TargetTimeFrame.months;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: _openEditDialog,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // ─── Image-Matched Semicircular Glow ─────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 1.15),
                      radius: 1.15,
                      colors: [
                        _glowLimeGreen.withValues(alpha: 0.55),
                        _glowAquaCyan.withValues(alpha: 0.40),
                        _glowSkyBlue.withValues(alpha: 0.28),
                        _glowSkyBlue.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.30, 0.58, 0.80, 1.0],
                    ),
                  ),
                ),
              ),

              // ─── Card Foreground Content ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Header: Title + Switch Button ──────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'nothingdot',
                                  fontSize: 26,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Segmented Switch (Days / Weeks / Months)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: TargetTimeFrame.values.map((unit) {
                              final isSelected = _selectedUnit == unit;
                              final label =
                                  unit.name[0].toUpperCase() +
                                  unit.name.substring(1);

                              return GestureDetector(
                                onTap: () {
                                  ZetaHaptics.selection();
                                  setState(() => _selectedUnit = unit);
                                },
                                child: AnimatedContainer(
                                  duration: M3MotionDuration.short4,
                                  curve: M3MotionEasing.standard,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? currentStatusColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'GoogleSansFlex',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFF0D1216)
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: textMuted,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _openEditDialog,
                          tooltip: 'Edit goal dates',
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ─── Metrics Readout Row (Percentages & Units) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_percentage%',
                          style: const TextStyle(
                            fontFamily: 'headline',
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _unitValue,
                              style: const TextStyle(
                                fontFamily: 'headline',
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _unitLabel,
                              style: const TextStyle(
                                fontFamily: 'NothingDot',
                                fontSize: 13,
                                letterSpacing: 1.1,
                                color: Color.fromARGB(255, 228, 110, 51),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ─── Animated Transition: Linear Bar vs. Arch ───
                    AnimatedSwitcher(
                      duration: M3MotionDuration.long2,
                      switchInCurve: M3MotionEasing.emphasizedDecelerate,
                      switchOutCurve: M3MotionEasing.emphasizedAccelerate,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: 0.0,
                            child: child,
                          ),
                        );
                      },
                      child: isMonthView
                          ? _buildArchIndicator(ratio)
                          : _buildLinearPillBar(activePills, textMuted),
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

  /// Refined Linear Pill Bar with frosted inactive pills & balanced leads
  Widget _buildLinearPillBar(int activePills, Color textMuted) {
    return Column(
      key: const ValueKey('linear_pill_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 38,
          child: Row(
            children: List.generate(_totalSegments, (index) {
              final isFilled = index < activePills;
              final isLeadingEdge = index == activePills - 1;
              final segmentRatio = (_totalSegments > 1)
                  ? index / (_totalSegments - 1)
                  : 0.0;
              final segmentColor = getColorForProgress(segmentRatio);

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == _totalSegments - 1 ? 0 : 3.5,
                  ),
                  decoration: BoxDecoration(
                    // Filled pills use segment gradient; empty pills use frosted translucent glass
                    color: isFilled
                        ? segmentColor
                        : Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4.5),
                    // Inactive pills get a subtle border stroke to outline the track cleanly
                    border: isFilled
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                    boxShadow: isFilled
                        ? [
                            // Soft ambient floor shadow
                            BoxShadow(
                              color: segmentColor.withValues(
                                alpha: isLeadingEdge ? 0.45 : 0.20,
                              ),
                              blurRadius: isLeadingEdge ? 6 : 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  // Specular highlight on the leading edge pill tip
                  child: isLeadingEdge
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4.5),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '50',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '100',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Segmented Arched Semicircle Gauge (Used for Months)
  Widget _buildArchIndicator(double progressRatio) {
    return Center(
      key: const ValueKey('arch_semicircle_view'),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: progressRatio),
          duration: M3MotionDuration.long2,
          curve: M3MotionEasing.emphasized,
          builder: (context, animatedRatio, _) {
            final activeSegments = (animatedRatio * _totalSegments).round();
            return SizedBox(
              width: 230,
              height: 125,
              child: CustomPaint(
                painter: _SegmentedArchPainter(
                  totalSegments: _totalSegments,
                  activeSegments: activeSegments,
                  pillThickness: 7.0,
                  pillRadialLength: 22.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter rendering discrete radial pill segments across a 180° arch.
class _SegmentedArchPainter extends CustomPainter {
  final int totalSegments;
  final int activeSegments;
  final double pillThickness;
  final double pillRadialLength;

  _SegmentedArchPainter({
    required this.totalSegments,
    required this.activeSegments,
    required this.pillThickness,
    required this.pillRadialLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - pillRadialLength;

    for (int i = 0; i < totalSegments; i++) {
      final t = totalSegments > 1 ? i / (totalSegments - 1) : 0.0;
      final angle = math.pi - (math.pi * t);

      final isFilled = i < activeSegments;
      final isLeading = i == activeSegments - 1;
      final color = isFilled
          ? _DaysLeftCounterCardState.getColorForProgress(t)
          : Colors.white.withValues(alpha: 0.08); // Glassy inactive segment

      final startOffset = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy - innerRadius * math.sin(angle),
      );
      final endOffset = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy - outerRadius * math.sin(angle),
      );

      final paint = Paint()
        ..color = color
        ..strokeWidth = pillThickness
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Clean, controlled glow for active segments and lead segment
      if (isFilled) {
        final shadowPaint = Paint()
          ..color = color.withValues(alpha: isLeading ? 0.40 : 0.20)
          ..strokeWidth = pillThickness + (isLeading ? 3.0 : 1.5)
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            isLeading ? 4.5 : 2.5,
          );
        canvas.drawLine(startOffset, endOffset, shadowPaint);
      }

      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedArchPainter oldDelegate) {
    return oldDelegate.totalSegments != totalSegments ||
        oldDelegate.activeSegments != activeSegments ||
        oldDelegate.pillThickness != pillThickness ||
        oldDelegate.pillRadialLength != pillRadialLength;
  }
}
