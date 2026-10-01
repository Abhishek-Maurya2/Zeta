import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../utils/task_date_formatter.dart';
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

  final Key _centerKey = const ValueKey('center_day_today');
  late final ScrollController _scrollController;
  late final DateTime _today;

  double _effectiveItemExtent = _baseItemExtent;
  int _effectiveVisibleDays = 7;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _scrollController = ScrollController();

    // Center "today" after the initial layout pass
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerOnToday(animate: false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateTimeUtils.isSameDay(
      widget.selectedDate,
      oldWidget.selectedDate,
    )) {
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
        (dayOffset * _effectiveItemExtent) - (viewport / 2) + (_effectiveItemExtent / 2);

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

  Widget _buildChevronButton({
    required BuildContext context,
    required bool isNext,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: isNext ? 'Next days' : 'Previous days',
      child: M3EIconButton(
        size: M3EIconButtonSize.md,
        width: M3EIconButtonWidth.narrow,
        decoration: M3EIconButtonDecoration(
          backgroundColor: WidgetStateProperty.all(
            colorScheme.onSurface.withValues(alpha: 0.1),
          ),
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

  Widget _buildDayItem({
    required BuildContext context,
    required DateTime dayDate,
    required int dayOffset,
    required Map<String, List<Task>> tasksByDateKey,
    required ColorScheme colorScheme,
    required bool isCompact,
    required double itemExtent,
  }) {
    final isSelected = DateTimeUtils.isSameDay(dayDate, widget.selectedDate);
    final isDayToday = dayOffset == 0;
    final isPast = dayDate.isBefore(_today);

    final dateKey = '${dayDate.year}-${dayDate.month}-${dayDate.day}';
    final matchingTasks = tasksByDateKey[dateKey] ?? const [];
    final pendingCount = matchingTasks.where((t) => !t.completed).length;
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

    final dayNameShort = DateTimeUtils.weekdaysShortUpper[dayDate.weekday - 1];
    final dayNumStr = dayDate.day.toString();
    final effectivePillWidth = math.min(_itemWidth, math.max(38.0, itemExtent - 6.0));

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Tooltip(
          message:
              '$dayNameShort $dayNumStr${dotLabel != null ? " • $dotLabel" : ""}',
          child: InkWell(
            borderRadius: BorderRadius.circular(44),
            onTap: () {
              ZetaHaptics.selection();
              widget.onSelectDate(dayDate);
              _centerOnDayOffset(dayOffset);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: effectivePillWidth,
              height: isCompact ? 85 : 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : (isDayToday
                          ? colorScheme.surfaceContainerHighest
                          : Colors.transparent),
                borderRadius: (isDayToday && !isSelected)
                    ? BorderRadius.circular(10)
                    : BorderRadius.circular(54),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNameShort,
                    style: TextStyle(
                      fontSize: isSelected ? 16 : 13,
                      fontFamily: (!isSelected && !isDayToday)
                          ? 'GoogleSansFlex'
                          : 'RobotoMono',
                      fontVariations: const [
                        FontVariation('wdth', 100),
                        FontVariation('ROND', 100),
                      ],
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
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
                    dayNumStr,
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
                    child: dotColor != null
                        ? Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        : (isDayToday && !isSelected
                              ? Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollView({
    required double itemExtent,
    required bool isCompact,
    required Map<String, List<Task>> tasksByDateKey,
    required ColorScheme colorScheme,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      center: _centerKey,
      slivers: [
        // Past days
        SliverFixedExtentList(
          itemExtent: itemExtent,
          delegate: SliverChildBuilderDelegate((context, index) {
            final pastIndex = -(index + 1);
            final dayDate = _today.add(Duration(days: pastIndex));
            return _buildDayItem(
              context: context,
              dayDate: dayDate,
              dayOffset: pastIndex,
              tasksByDateKey: tasksByDateKey,
              colorScheme: colorScheme,
              isCompact: isCompact,
              itemExtent: itemExtent,
            );
          }),
        ),

        // Today and future days
        SliverFixedExtentList(
          key: _centerKey,
          itemExtent: itemExtent,
          delegate: SliverChildBuilderDelegate((context, index) {
            final dayDate = _today.add(Duration(days: index));
            return _buildDayItem(
              context: context,
              dayDate: dayDate,
              dayOffset: index,
              tasksByDateKey: tasksByDateKey,
              colorScheme: colorScheme,
              isCompact: isCompact,
              itemExtent: itemExtent,
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final taskProvider = context.watch<TaskProvider>();

    final isSelectedToday = DateTimeUtils.isSameDay(
      widget.selectedDate,
      _today,
    );
    final headlineLabel = DateTimeUtils.formatHeadline(widget.selectedDate);

    // Pre-index task counts by date string
    final allTasks = [...taskProvider.allTasks, ...taskProvider.binTasks];
    final Map<String, List<Task>> tasksByDateKey = {};
    for (final task in allTasks) {
      if (task.dueDate == null) continue;
      final parsed = TaskDateFormatter.parse(task.dueDate!);
      if (parsed != null) {
        final key = '${parsed.year}-${parsed.month}-${parsed.day}';
        (tasksByDateKey[key] ??= []).add(task);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 800;

            final leftHeader = Column(
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
                        headlineLabel,
                        style: TextStyle(
                          fontFamily: 'GoogleSansFlex',
                          fontSize: 40,
                          color: colorScheme.onSurface.withValues(alpha: 0.9),
                          fontVariations: const [
                            FontVariation('wght', 600),
                            FontVariation('wdth', 70),
                            FontVariation('GRAD', 20),
                            FontVariation('opsz', 15),
                            FontVariation('slnt', 0),
                            FontVariation('ROND', 100),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isSelectedToday)
                        Tooltip(
                          message: 'Reset to Today',
                          child: M3EIconButton(
                            size: M3EIconButtonSize.xs,
                            variant: M3EIconButtonVariant.standard,
                            icon: Icon(
                              Icons.calendar_month_rounded,
                              size: 25,
                              color: colorScheme.primary,
                            ),
                            onPressed: () {
                              ZetaHaptics.light();
                              _centerOnToday();
                              widget.onResetToToday();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const WeatherHeaderTelemetry(),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 5),
                  leftHeader,
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 85,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildChevronButton(
                          context: context,
                          isNext: false,
                          colorScheme: colorScheme,
                          onPressed: () {
                            ZetaHaptics.light();
                            _shiftDays(-_effectiveVisibleDays);
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, stripConstraints) {
                              final double stripWidth =
                                  stripConstraints.maxWidth;
                              // Ensure calendar strip shows at least 4 dates at any point, up to 7 dates
                              final int visibleDays =
                                  (stripWidth / _baseItemExtent)
                                      .floor()
                                      .clamp(5, 7);
                              final double itemExtent =
                                  stripWidth / visibleDays;
                              _effectiveItemExtent = itemExtent;
                              _effectiveVisibleDays = visibleDays;

                              return _buildScrollView(
                                itemExtent: itemExtent,
                                isCompact: true,
                                tasksByDateKey: tasksByDateKey,
                                colorScheme: colorScheme,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildChevronButton(
                          context: context,
                          isNext: true,
                          colorScheme: colorScheme,
                          onPressed: () {
                            ZetaHaptics.light();
                            _shiftDays(_effectiveVisibleDays);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            _effectiveItemExtent = _baseItemExtent;
            _effectiveVisibleDays = 7;
            final double desktopStripWidth = _baseItemExtent * 7;

            final desktopWeekStrip = Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildChevronButton(
                  context: context,
                  isNext: false,
                  colorScheme: colorScheme,
                  onPressed: () {
                    ZetaHaptics.light();
                    _shiftDays(-_effectiveVisibleDays);
                  },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: desktopStripWidth,
                  height: 80,
                  child: _buildScrollView(
                    itemExtent: _baseItemExtent,
                    isCompact: false,
                    tasksByDateKey: tasksByDateKey,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 4),
                _buildChevronButton(
                  context: context,
                  isNext: true,
                  colorScheme: colorScheme,
                  onPressed: () {
                    ZetaHaptics.light();
                    _shiftDays(_effectiveVisibleDays);
                  },
                ),
              ],
            );

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: leftHeader),
                  const SizedBox(width: 16),
                  desktopWeekStrip,
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Mini Color Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Overdue',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}

