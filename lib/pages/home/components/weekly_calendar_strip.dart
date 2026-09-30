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
    required this.onSelectDate,
    required this.onResetToToday,
    this.weekOffset,
    this.onShiftWeek,
  });

  @override
  State<WeeklyCalendarStrip> createState() => _WeeklyCalendarStripState();
}

class _WeeklyCalendarStripState extends State<WeeklyCalendarStrip> {
  static const double _itemWidth = 48.0;

  late DateTime _today;
  int _internalWeekOffset = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _internalWeekOffset =
        widget.weekOffset ?? _calculateWeekOffset(widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant WeeklyCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weekOffset != null) {
      _internalWeekOffset = widget.weekOffset!;
    } else if (!DateTimeUtils.isSameDay(
      widget.selectedDate,
      oldWidget.selectedDate,
    )) {
      _internalWeekOffset = _calculateWeekOffset(widget.selectedDate);
    }
  }

  int _calculateWeekOffset(DateTime date) {
    final currentMonday = _today.subtract(
      Duration(days: _today.weekday - DateTime.monday),
    );
    final targetMonday = date.subtract(
      Duration(days: date.weekday - DateTime.monday),
    );
    final diffDays = targetMonday.difference(currentMonday).inDays;
    return (diffDays / 7).round();
  }

  void _shiftWeek(int delta) {
    ZetaHaptics.light();
    if (widget.onShiftWeek != null) {
      widget.onShiftWeek!(delta);
    }
    setState(() {
      _internalWeekOffset += delta;
    });
  }

  void _resetToToday() {
    ZetaHaptics.light();
    setState(() {
      _internalWeekOffset = 0;
    });
    widget.onResetToToday();
  }

  Widget _buildDayItem({
    required BuildContext context,
    required DateTime dayDate,
    required Map<String, List<Task>> tasksByDateKey,
    required ColorScheme colorScheme,
    required bool isCompact,
  }) {
    final isSelected = DateTimeUtils.isSameDay(dayDate, widget.selectedDate);
    final isDayToday = DateTimeUtils.isSameDay(dayDate, _today);
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

    final pillBorderRadius = (isDayToday && !isSelected)
        ? BorderRadius.circular(12)
        : BorderRadius.circular(54);

    final pillWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCompact ? double.infinity : _itemWidth,
      height: isCompact ? 78 : 80,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer
            : (isDayToday
                  ? colorScheme.surfaceContainerHighest
                  : Colors.transparent),
        borderRadius: pillBorderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayNameShort,
            style: TextStyle(
              fontSize: isSelected ? 15 : 12,
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
                  : (isDayToday ? colorScheme.primary : colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 5),
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
          const SizedBox(height: 4),
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
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null),
          ),
        ],
      ),
    );

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 1.5 : 4.0),
        child: Tooltip(
          message:
              '$dayNameShort $dayNumStr${dotLabel != null ? " • $dotLabel" : ""}',
          child: InkWell(
            borderRadius: pillBorderRadius,
            onTap: () {
              ZetaHaptics.selection();
              widget.onSelectDate(dayDate);
            },
            child: isCompact
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 56),
                    child: pillWidget,
                  )
                : pillWidget,
          ),
        ),
      ),
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

    final int effectiveWeekOffset = widget.weekOffset ?? _internalWeekOffset;
    final List<DateTime> days = DateTimeUtils.getWeeklyCalendarStripDays(
      _today,
      effectiveWeekOffset,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 800;

            final dateHeadlineRow = FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    headlineLabel,
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontSize: isCompact ? 32 : 40,
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
                          size: 24,
                          color: colorScheme.primary,
                        ),
                        onPressed: _resetToToday,
                      ),
                    ),
                ],
              ),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 5),
                  // Header Row: Headline on left, Chevrons on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            dateHeadlineRow,
                            const WeatherHeaderTelemetry(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'Previous week',
                            child: M3EIconButton(
                              size: M3EIconButtonSize.sm,
                              width: M3EIconButtonWidth.narrow,
                              decoration: M3EIconButtonDecoration(
                                backgroundColor: WidgetStateProperty.all(
                                  colorScheme.onSurface.withValues(alpha: 0.08),
                                ),
                              ),
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                size: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              onPressed: () => _shiftWeek(-1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Next week',
                            child: M3EIconButton(
                              size: M3EIconButtonSize.sm,
                              width: M3EIconButtonWidth.narrow,
                              decoration: M3EIconButtonDecoration(
                                backgroundColor: WidgetStateProperty.all(
                                  colorScheme.onSurface.withValues(alpha: 0.08),
                                ),
                              ),
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              onPressed: () => _shiftWeek(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Edge-to-edge 7 days strip evenly distributed across the full width
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -200) {
                        _shiftWeek(1); // Swipe left -> next week
                      } else if (details.primaryVelocity! > 200) {
                        _shiftWeek(-1); // Swipe right -> previous week
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: days.map((dayDate) {
                        return Expanded(
                          child: _buildDayItem(
                            context: context,
                            dayDate: dayDate,
                            tasksByDateKey: tasksByDateKey,
                            colorScheme: colorScheme,
                            isCompact: true,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }

            // Wide / Desktop layout
            final leftHeader = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [dateHeadlineRow, const WeatherHeaderTelemetry()],
            );

            final weekStripContent = Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Previous week',
                  child: M3EIconButton(
                    size: M3EIconButtonSize.md,
                    width: M3EIconButtonWidth.narrow,
                    decoration: M3EIconButtonDecoration(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      fontWeight: FontWeight.bold,
                      size: 40,
                    ),
                    onPressed: () => _shiftWeek(-1),
                  ),
                ),
                const SizedBox(width: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: days.map((dayDate) {
                    return _buildDayItem(
                      context: context,
                      dayDate: dayDate,
                      tasksByDateKey: tasksByDateKey,
                      colorScheme: colorScheme,
                      isCompact: false,
                    );
                  }).toList(),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Next week',
                  child: M3EIconButton(
                    size: M3EIconButtonSize.md,
                    width: M3EIconButtonWidth.narrow,
                    decoration: M3EIconButtonDecoration(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    onPressed: () => _shiftWeek(1),
                  ),
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
                  weekStripContent,
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
