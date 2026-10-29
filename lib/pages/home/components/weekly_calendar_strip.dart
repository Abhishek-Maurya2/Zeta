import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../utils/date_time_utils.dart';
import '../../../utils/haptics.dart';
import 'weather_header_telemetry.dart';

class WeeklyCalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onResetToToday;
  final int? weekOffset;
  final ValueChanged<int>? onShiftWeek;

  const WeeklyCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onResetToToday,
    required this.onSelectDate,
    this.weekOffset,
    this.onShiftWeek,
  });

  @override
  State<WeeklyCalendarStrip> createState() => _WeeklyCalendarStripState();
}

class _WeeklyCalendarStripState extends State<WeeklyCalendarStrip> {
  static const double _itemWidth = 50;
  static const double _itemSpacing = 8;
  static const double _baseItemExtent = _itemWidth + _itemSpacing;
  static const int _maxVisibleDays = 7;

  final Key _centerKey = const ValueKey('center_day_today');
  late final ScrollController _scrollController;
  late final DateTime _today;

  double _effectiveItemExtent = _baseItemExtent;
  int _effectiveVisibleDays = _maxVisibleDays;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnToday(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateTimeUtils.isSameDay(widget.selectedDate, oldWidget.selectedDate)) {
      final diff = widget.selectedDate.difference(_today);
      final dayOffset = (diff.inHours + 12) ~/ 24;
      _centerOnDayOffset(dayOffset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerOnToday({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final target = -(viewport / 2) + (_effectiveItemExtent / 2);

    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _centerOnDayOffset(int dayOffset) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final target =
        (dayOffset * _effectiveItemExtent) -
        (viewport / 2) +
        (_effectiveItemExtent / 2);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _shiftDays(int days) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.offset + (days * _effectiveItemExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDaySliver({
    Key? key,
    required bool isPast,
    required Map<String, List<Task>> tasksByDateKey,
    required double itemExtent,
    required bool isCompact,
  }) {
    return SliverFixedExtentList(
      key: key,
      itemExtent: itemExtent,
      delegate: SliverChildBuilderDelegate((context, index) {
        final offset = isPast ? -(index + 1) : index;
        final dayDate = _today.add(Duration(days: offset));
        final dateKey = '${dayDate.year}-${dayDate.month}-${dayDate.day}';

        return _StripDayPill(
          dayDate: dayDate,
          dayOffset: offset,
          today: _today,
          isSelected: DateTimeUtils.isSameDay(dayDate, widget.selectedDate),
          tasks: tasksByDateKey[dateKey] ?? const [],
          itemExtent: itemExtent,
          isCompact: isCompact,
          onTap: () {
            ZetaHaptics.selection();
            widget.onSelectDate(dayDate);
            _centerOnDayOffset(offset);
          },
        );
      }),
    );
  }

  Widget _buildScrollableStrip({
    required double itemExtent,
    required bool isCompact,
    required Map<String, List<Task>> tasksByDateKey,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      center: _centerKey,
      slivers: [
        _buildDaySliver(
          isPast: true,
          tasksByDateKey: tasksByDateKey,
          itemExtent: itemExtent,
          isCompact: isCompact,
        ),
        _buildDaySliver(
          key: _centerKey,
          isPast: false,
          tasksByDateKey: tasksByDateKey,
          itemExtent: itemExtent,
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildNavigationRow({required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StripChevronButton(
          isNext: false,

          onPressed: () {
            ZetaHaptics.light();
            _shiftDays(-_effectiveVisibleDays);
          },
        ),
        const SizedBox(width: 4),
        Expanded(child: child),
        const SizedBox(width: 4),
        _StripChevronButton(
          isNext: true,

          onPressed: () {
            ZetaHaptics.light();
            _shiftDays(_effectiveVisibleDays);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksByDateKey = context.watch<TaskProvider>().tasksByDateKey;
    final isSelectedToday = DateTimeUtils.isSameDay(
      widget.selectedDate,
      _today,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 800;

            final header = _StripHeader(
              selectedDate: widget.selectedDate,
              isSelectedToday: isSelectedToday,

              onResetToToday: () {
                ZetaHaptics.heavy();
                _centerOnToday();
                widget.onResetToToday();
              },
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 5),
                  header,
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 85,
                    child: _buildNavigationRow(
                      child: LayoutBuilder(
                        builder: (context, stripConstraints) {
                          final stripWidth = stripConstraints.maxWidth;
                          final visibleDays = (stripWidth / _baseItemExtent)
                              .floor()
                              .clamp(5, _maxVisibleDays);
                          final itemExtent = stripWidth / visibleDays;

                          _effectiveItemExtent = itemExtent;
                          _effectiveVisibleDays = visibleDays;

                          return _buildScrollableStrip(
                            itemExtent: itemExtent,
                            isCompact: true,
                            tasksByDateKey: tasksByDateKey,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            _effectiveItemExtent = _baseItemExtent;
            _effectiveVisibleDays = _maxVisibleDays;

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: header),
                  const SizedBox(width: 16),
                  SizedBox(
                    width:
                        (_baseItemExtent * _maxVisibleDays) +
                        104, // strip + buttons + spacing
                    height: 80,
                    child: _buildNavigationRow(
                      child: _buildScrollableStrip(
                        itemExtent: _baseItemExtent,
                        isCompact: false,
                        tasksByDateKey: tasksByDateKey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const _StripLegend(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Extracted Subcomponents
// ---------------------------------------------------------------------------

class _StripHeader extends StatelessWidget {
  final DateTime selectedDate;
  final bool isSelectedToday;
  final VoidCallback onResetToToday;

  const _StripHeader({
    required this.selectedDate,
    required this.isSelectedToday,
    required this.onResetToToday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateTimeUtils.formatHeadline(selectedDate),
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontSize: 40,
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                  fontVariations: const [
                    FontVariation('wght', 600),
                    FontVariation('wdth', 70),
                    FontVariation('GRAD', 20),
                    FontVariation('opsz', 15),
                    FontVariation('ROND', 100),
                  ],
                ),
              ),
              if (!isSelectedToday) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Reset to Today',
                  child: M3EIconButton(
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.tonal,
                    shape: M3EIconButtonShapeVariant.square,
                    icon: const Icon(
                      Symbols.event_upcoming_rounded,
                      weight: 700,
                      fill: 1,
                    ),
                    onPressed: onResetToToday,
                  ),
                ),
              ],
            ],
          ),
        ),
        const WeatherHeaderTelemetry(),
      ],
    );
  }
}

class _StripDayPill extends StatelessWidget {
  final DateTime dayDate;
  final int dayOffset;
  final DateTime today;
  final bool isSelected;
  final List<Task> tasks;
  final double itemExtent;
  final bool isCompact;
  final VoidCallback onTap;

  const _StripDayPill({
    required this.dayDate,
    required this.dayOffset,
    required this.today,
    required this.isSelected,
    required this.tasks,
    required this.itemExtent,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDayToday = dayOffset == 0;
    final isPast = dayDate.isBefore(today);

    final pendingCount = tasks.where((t) => !t.completed).length;
    final overdueCount = isPast ? pendingCount : 0;

    Color? dotColor;
    String? dotLabel;
    if (overdueCount > 0) {
      dotColor = const Color(0xFFEF4444);
      dotLabel = '$overdueCount overdue';
    } else if (pendingCount > 0) {
      dotColor = const Color(0xFF3B82F6);
      dotLabel = '$pendingCount pending';
    }

    final activeDotColor =
        dotColor ??
        (isDayToday && !isSelected
            ? colorScheme.primary.withValues(alpha: 0.5)
            : null);

    final dayName = DateTimeUtils.weekdaysShortUpper[dayDate.weekday - 1];
    final dayNum = dayDate.day.toString();
    final effectiveWidth = math.min(50.0, math.max(38.0, itemExtent - 6.0));

    return Center(
      child: Tooltip(
        message: '$dayName $dayNum${dotLabel != null ? " • $dotLabel" : ""}',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(44),
            onTap: onTap,
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: effectiveWidth,
            height: isCompact ? 85 : 80,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : (isDayToday
                        ? colorScheme.surfaceContainerHighest
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(
                isDayToday && !isSelected ? 10 : 54,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: isSelected ? 16 : 13,
                    fontFamily: (!isSelected && !isDayToday)
                        ? 'GoogleSansFlex'
                        : 'RobotoMono',
                    fontVariations: const [
                      FontVariation('wdth', 100),
                      FontVariation('ROND', 100),
                    ],
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: isSelected ? 0.5 : null,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : (isDayToday
                              ? colorScheme.primary
                              : colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayNum,
                  style: TextStyle(
                    fontSize: isSelected ? 16 : 14,
                    fontFamily: (!isSelected && !isDayToday)
                        ? 'GoogleSansFlex'
                        : 'RobotoMono',
                    fontVariations: const [
                      FontVariation('wdth', 100),
                      FontVariation('ROND', 100),
                    ],
                    fontWeight: isSelected || isDayToday
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
                SizedBox(
                  height: 4,
                  child: activeDotColor != null
                      ? Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: activeDotColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _StripChevronButton extends StatelessWidget {
  final bool isNext;
  final VoidCallback onPressed;

  const _StripChevronButton({required this.isNext, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Tooltip(
      message: isNext ? 'Next days' : 'Previous days',
      child: M3EIconButton(
        size: M3EIconButtonSize.md,
        width: M3EIconButtonWidth.narrow,
        haptic: M3EHapticFeedback.heavy,
        decoration: M3EIconButtonDecoration(
          backgroundColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest,
          ),
          foregroundColor: WidgetStateProperty.all(colorScheme.onSurface),
        ),
        icon: Icon(
          isNext ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
          size: 40,
          fontWeight: FontWeight.bold,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _StripLegend extends StatelessWidget {
  const _StripLegend();

  Widget _buildItem(Color color, String label, BuildContext context) {
    final colorScheme = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildItem(const Color(0xFFEF4444), 'Overdue', context),
        const SizedBox(width: 14),
        _buildItem(const Color(0xFF3B82F6), 'Pending', context),
        const SizedBox(width: 8),
      ],
    );
  }
}
