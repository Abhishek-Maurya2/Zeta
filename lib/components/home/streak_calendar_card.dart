import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../components/tasks/task_edit_pane.dart';
import '../../utils/task_date_formatter.dart';
import '../../utils/haptics.dart';

/// Streak Calendar Card mirroring Sharva's StreakCalendarCard:
/// - Fire icon badge with warm gradient, current streak counter, and active pill.
/// - Streak period range badge.
/// - Interactive custom monthly calendar with streak range highlighting, task dots, and day selection.
/// - Calendar legend.
/// - Highlighted Tasks on Selected Day Drawer with quick completion toggles and edit triggers.
class StreakCalendarCard extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final double? width;

  const StreakCalendarCard({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    this.width = 350,
  });

  @override
  State<StreakCalendarCard> createState() => _StreakCalendarCardState();
}

class _StreakCalendarCardState extends State<StreakCalendarCard> {
  late DateTime _displayedMonth;

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
  static const List<String> _weekdaysShort = [
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
  }

  @override
  void didUpdateWidget(covariant StreakCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _displayedMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        1,
      );
    }
  }

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

  String _formatDateYMD(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  void _prevMonth() {
    ZetaHaptics.light();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    ZetaHaptics.light();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final taskProvider = context.watch<TaskProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final allTasks = [...taskProvider.allTasks, ...taskProvider.binTasks];

    // Collect dates that have completed tasks
    final completedDateStrings = <String>{};
    for (final t in allTasks) {
      if (t.completed && t.dueDate != null) {
        final parsed = TaskDateFormatter.parse(t.dueDate!);
        if (parsed != null) {
          completedDateStrings.add(_formatDateYMD(parsed));
        }
      }
    }

    final curTodayStr = _formatDateYMD(today);
    final yesterdayStr = _formatDateYMD(yesterday);

    final isCompletedToday = completedDateStrings.contains(curTodayStr);
    final isCompletedYesterday = completedDateStrings.contains(yesterdayStr);

    int currentStreak = 0;
    DateTime? rangeStart;
    DateTime? rangeEnd;

    if (isCompletedToday || isCompletedYesterday) {
      final startCheck = isCompletedToday ? today : yesterday;
      rangeEnd = isCompletedToday ? today : yesterday;

      var cursor = startCheck;
      while (completedDateStrings.contains(_formatDateYMD(cursor))) {
        currentStreak++;
        rangeStart = cursor;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    int bestStreak = currentStreak;
    final sortedDates = completedDateStrings.toList()..sort();
    int tempStreak = 0;
    DateTime? prevDate;
    for (final dStr in sortedDates) {
      final parts = dStr.split('-').map(int.parse).toList();
      final curr = DateTime(parts[0], parts[1], parts[2]);
      if (prevDate == null) {
        tempStreak = 1;
      } else {
        final diff = curr.difference(prevDate).inDays;
        if (diff == 1) {
          tempStreak++;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      prevDate = curr;
      if (tempStreak > bestStreak) {
        bestStreak = tempStreak;
      }
    }

    final hasActiveStreak = currentStreak > 0;

    // Range label
    String rangeLabel;
    if (!hasActiveStreak || rangeStart == null || rangeEnd == null) {
      rangeLabel = 'Start today';
    } else {
      final startM = _monthsShort[rangeStart.month - 1];
      final startD = rangeStart.day;
      final endM = _monthsShort[rangeEnd.month - 1];
      final endD = rangeEnd.day;
      if (startM == endM) {
        rangeLabel = '$startM $startD – $endD';
      } else {
        rangeLabel = '$startM $startD – $endM $endD';
      }
    }

    // Tasks on selected date
    final selectedDayTasks = taskProvider.allTasks
        .where((t) => _isTaskOnDate(t, widget.selectedDate))
        .toList();

    // Formatted selected date
    final monthName = _monthsShort[widget.selectedDate.month - 1];
    final selectedDayStr = _isSameDay(widget.selectedDate, today)
        ? 'Today, $monthName ${widget.selectedDate.day}'
        : '$monthName ${widget.selectedDate.day}';

    final cardContent = Container(
      width: widget.width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. Header: Fire Icon, Streak Count, Status Pill ────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasActiveStreak
                              ? const [
                                  Color(0xFFF59E0B),
                                  Color(0xFFF97316),
                                  Color(0xFFE11D48),
                                ]
                              : const [Color(0xFFFBBF24), Color(0xFFEA580C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF97316)
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$currentStreak',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  currentStreak == 1
                                      ? 'Day Streak'
                                      : 'Days Streak',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill & Record
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: hasActiveStreak
                          ? Colors.amber.withValues(alpha: 0.18)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: hasActiveStreak
                              ? Colors.amber.shade700
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hasActiveStreak ? 'Active' : 'Ready',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: hasActiveStreak
                                ? Colors.amber.shade800
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bestStreak > 1) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Best: ${bestStreak}d',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── Streak Period Badge ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Streak Period:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rangeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── 2. Interactive Monthly Calendar ─────────────────────────────
          // Month header with previous/next
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthsShort[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  M3EIconButton(
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.standard,
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    onPressed: _prevMonth,
                  ),
                  M3EIconButton(
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.standard,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Weekday headers
          Row(
            children: _weekdaysShort.map((dayLabel) {
              return Expanded(
                child: Center(
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 4),

          // Calendar Grid
          _buildMonthGrid(
            context,
            colorScheme,
            rangeStart,
            rangeEnd,
            hasActiveStreak,
            today,
            allTasks,
          ),

          const SizedBox(height: 8),

          // ─── 3. Calendar Legend ──────────────────────────────────────────
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 4,
                    color: colorScheme.primaryContainer,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Streak Range',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
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
                  const SizedBox(width: 4),
                  Text(
                    'Tasks on Day',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── 4. Tasks on Selected Day Drawer ─────────────────────────────
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_note_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tasks on $selectedDayStr',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selectedDayTasks.isNotEmpty
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${selectedDayTasks.length} ${selectedDayTasks.length == 1 ? "Task" : "Tasks"}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selectedDayTasks.isNotEmpty
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (selectedDayTasks.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: selectedDayTasks.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, idx) {
                        final task = selectedDayTasks[idx];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => TaskEditPane.show(context, task: task),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => taskProvider.toggleTask(task.id),
                                  child: Icon(
                                    task.completed
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 18,
                                    color: task.completed
                                        ? const Color(0xFF10B981)
                                        : colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          decoration: task.completed
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: task.completed
                                              ? colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.6)
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                      if (task.hasTime && task.dueTime != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 10,
                                              color: colorScheme.outline,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              task.dueTime!,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colorScheme.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: colorScheme.outline,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'No tasks scheduled',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        InkWell(
                          onTap: () => TaskEditPane.show(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Add Task',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.width != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: widget.width, child: cardContent),
      );
    }

    return cardContent;
  }

  Widget _buildMonthGrid(
    BuildContext context,
    ColorScheme colorScheme,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool hasActiveStreak,
    DateTime today,
    List<Task> allTasks,
  ) {
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    // Sunday is index 0
    final startWeekday = firstDayOfMonth.weekday % 7;

    final totalCells = startWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (rowIdx) {
        return Row(
          children: List.generate(7, (colIdx) {
            final cellIdx = rowIdx * 7 + colIdx;
            final dayNum = cellIdx - startWeekday + 1;

            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 34));
            }

            final cellDate = DateTime(
              _displayedMonth.year,
              _displayedMonth.month,
              dayNum,
            );
            final isSelected = _isSameDay(cellDate, widget.selectedDate);
            final isToday = _isSameDay(cellDate, today);

            // Streak range calculation
            final inStreakRange =
                hasActiveStreak &&
                rangeStart != null &&
                rangeEnd != null &&
                !cellDate.isBefore(rangeStart) &&
                !cellDate.isAfter(rangeEnd);

            final isStreakStart = inStreakRange &&
                (_isSameDay(cellDate, rangeStart) ||
                    colIdx == 0 ||
                    dayNum == 1);
            final isStreakEnd = inStreakRange &&
                (_isSameDay(cellDate, rangeEnd) ||
                    colIdx == 6 ||
                    dayNum == daysInMonth);

            BorderRadius streakBorderRadius;
            if (isStreakStart && isStreakEnd) {
              streakBorderRadius = BorderRadius.circular(18);
            } else if (isStreakStart) {
              streakBorderRadius = const BorderRadius.horizontal(
                left: Radius.circular(18),
              );
            } else if (isStreakEnd) {
              streakBorderRadius = const BorderRadius.horizontal(
                right: Radius.circular(18),
              );
            } else {
              streakBorderRadius = BorderRadius.zero;
            }

            // Tasks on this day
            final dayTasks = allTasks
                .where((t) => _isTaskOnDate(t, cellDate))
                .toList();
            final hasPending = dayTasks.any((t) => !t.completed);
            final hasCompleted = dayTasks.any((t) => t.completed);
            final isPast = cellDate.isBefore(today);
            final hasOverdue = isPast && hasPending;

            Color? dotColor;
            if (hasOverdue) {
              dotColor = const Color(0xFFEF4444); // Red
            } else if (hasPending) {
              dotColor = const Color(0xFF3B82F6); // Blue
            } else if (hasCompleted) {
              dotColor = const Color(0xFF10B981); // Green
            }

            return Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(isToday || isSelected ? 18 : 8),
                    onTap: () {
                      ZetaHaptics.selection();
                      widget.onSelectDate(cellDate);
                    },
                    child: SizedBox(
                      height: 35,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Continuous seamless streak track
                          if (inStreakRange)
                            Positioned(
                              left: isStreakStart ? 2 : -1.0,
                              right: isStreakEnd ? 2 : -1.0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: streakBorderRadius,
                                ),
                              ),
                            ),

                          // 2. Day Indicator (Current Day or Selected Day)
                          Center(
                            child: Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : (isToday && !inStreakRange
                                        ? colorScheme.surfaceContainerHigh
                                        : Colors.transparent),
                                border: isToday && !isSelected && !inStreakRange
                                    ? Border.all(
                                        color: colorScheme.primary,
                                        width: 1.8,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected || isToday || inStreakRange
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : (isToday
                                              ? colorScheme.primary
                                              : (inStreakRange
                                                  ? colorScheme.onPrimaryContainer
                                                  : colorScheme.onSurface)),
                                    ),
                                  ),
                                  if (dotColor != null)
                                    Positioned(
                                      bottom: 3,
                                      child: Container(
                                        width: 3.5,
                                        height: 3.5,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : dotColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        );
      }),
    );
  }
}
