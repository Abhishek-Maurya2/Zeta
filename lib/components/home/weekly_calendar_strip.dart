import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/task_date_formatter.dart';

/// Interactive Material 3 Expressive Weekly Calendar Strip mirroring Sharva's design:
/// - Left: Selected Date headline, Calendar DatePicker launcher, "Today" reset pill, and Weather readout.
/// - Right: Week shift chevrons, 7-day strip with single-dot priority indicators (Red: overdue, Blue: pending).
/// - Bottom legend for task indicator dots.
class WeeklyCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final int weekOffset;
  final ValueChanged<int> onShiftWeek;
  final VoidCallback onResetToToday;

  const WeeklyCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    required this.weekOffset,
    required this.onShiftWeek,
    required this.onResetToToday,
  });

  static const List<String> _weekdaysShort = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];
  static const List<String> _weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isTaskOnDate(Task task, DateTime date) {
    if (task.dueDate == null) return false;
    final parsed = TaskDateFormatter.parse(task.dueDate!);
    if (parsed != null) {
      return _isSameDay(parsed, date);
    }
    return false;
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      onSelectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final taskProvider = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSelectedToday = _isSameDay(selectedDate, today);

    // Headline formatted: e.g. "Tuesday, 11 Sep"
    final weekdayName = _weekdaysFull[selectedDate.weekday - 1];
    final monthName = _monthsShort[selectedDate.month - 1];
    final headlineLabel = '$weekdayName, ${selectedDate.day} $monthName';

    // Calculate 7 days for the active week window (Monday -> Sunday)
    final base = today.add(Duration(days: weekOffset * 7));
    final distanceToMonday = base.weekday - DateTime.monday;
    final monday = base.subtract(Duration(days: distanceToMonday));

    final weekDays = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return day;
    });

    final allTasks = [...taskProvider.allTasks, ...taskProvider.binTasks];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Main Row: Headline & Weather on Left, Week Strip on Right ───────
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 680;

            final leftHeader = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headlineLabel,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Calendar Datepicker Trigger
                    Tooltip(
                      message: 'Open Calendar Picker',
                      child: M3EIconButton(
                        size: M3EIconButtonSize.xs,
                        variant: M3EIconButtonVariant.standard,
                        icon: Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: isSelectedToday
                              ? colorScheme.primary
                              : colorScheme.outline,
                        ),
                        onPressed: () => _openDatePicker(context),
                      ),
                    ),

                    // Reset to "Today" button
                    if (!isSelectedToday) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onResetToToday,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Weather Telemetry Below Date
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '24°C',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Partly Cloudy • ${themeProvider.cityName}',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny_rounded,
                            size: 18,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Partly Cloudy',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );

            final rightWeekStrip = Row(
              mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                // Previous Week Chevron
                Tooltip(
                  message: 'Previous week',
                  child: M3EIconButton(
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.standard,
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: () => onShiftWeek(-1),
                  ),
                ),
                const SizedBox(width: 4),

                // 7 Days
                Expanded(
                  flex: isCompact ? 1 : 0,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: weekDays.map((dayDate) {
                          final isSelected = _isSameDay(dayDate, selectedDate);
                          final isDayToday = _isSameDay(dayDate, today);
                          final isPast = dayDate.isBefore(today);

                          // Task indicators
                          final matchingTasks = allTasks.where((t) => _isTaskOnDate(t, dayDate)).toList();
                          final pendingCount = matchingTasks.where((t) => !t.completed).length;
                          final overdueCount = isPast ? pendingCount : 0;

                          Color? dotColor;
                          String? dotLabel;
                          if (overdueCount > 0) {
                            dotColor = const Color(0xFFEF4444); // Red
                            dotLabel = '$overdueCount overdue';
                          } else if (pendingCount > 0) {
                            dotColor = const Color(0xFF3B82F6); // Blue
                            dotLabel = '$pendingCount pending';
                          }

                          final dayNameShort = _weekdaysShort[dayDate.weekday - 1];
                          final dayNumStr = dayDate.day.toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Tooltip(
                              message: '$dayNameShort $dayNumStr${dotLabel != null ? " • $dotLabel" : ""}',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => onSelectDate(dayDate),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: isCompact ? 38 : 46,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                        : (isDayToday
                                            ? colorScheme.surfaceContainerHigh
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayNameShort,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : (isDayToday
                                                  ? colorScheme.primary
                                                  : colorScheme.onSurfaceVariant),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dayNumStr,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected || isDayToday
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Strict single-dot indicator
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
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Next Week Chevron
                Tooltip(
                  message: 'Next week',
                  child: M3EIconButton(
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.standard,
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: () => onShiftWeek(1),
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftHeader,
                  const SizedBox(height: 14),
                  rightWeekStrip,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leftHeader,
                rightWeekStrip,
              ],
            );
          },
        ),

        const SizedBox(height: 8),

        // ─── Mini Color Legend ───────────────────────────────────────────────
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
