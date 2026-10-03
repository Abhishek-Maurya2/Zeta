import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../utils/task_date_formatter.dart';
import '../../../utils/date_time_utils.dart';
import '../../../utils/haptics.dart';
import '../../../theme/breakpoints.dart';

class StreakCalendarCard extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final double? width;

  const StreakCalendarCard({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    this.width = 100,
  });

  @override
  State<StreakCalendarCard> createState() => _StreakCalendarCardState();
}

class _StreakCalendarCardState extends State<StreakCalendarCard> {
  late DateTime _displayedMonth;

  // Custom Coral orange palette from design spec
  static const Color coralOrange = Color(0xFFF95C4B);

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

  bool _isTaskOnDate(Task task, DateTime date) {
    if (task.dueDate == null) return false;
    final parsed = TaskDateFormatter.parse(task.dueDate!);
    if (parsed != null) {
      return DateTimeUtils.isSameDay(parsed, date);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
          completedDateStrings.add(DateTimeUtils.formatDateYMD(parsed));
        }
      }
    }

    final curTodayStr = DateTimeUtils.formatDateYMD(today);
    final yesterdayStr = DateTimeUtils.formatDateYMD(yesterday);
    final isCompletedToday = completedDateStrings.contains(curTodayStr);
    final isCompletedYesterday = completedDateStrings.contains(yesterdayStr);

    DateTime? rangeStart;
    DateTime? rangeEnd;
    int currentStreak = 0;

    if (isCompletedToday || isCompletedYesterday) {
      final startCheck = isCompletedToday ? today : yesterday;
      rangeEnd = isCompletedToday ? today : yesterday;

      var cursor = startCheck;
      while (completedDateStrings.contains(
        DateTimeUtils.formatDateYMD(cursor),
      )) {
        currentStreak++;
        rangeStart = cursor;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    final hasActiveStreak = currentStreak > 0;

    // Sunday = 0, Monday = 1, ... Saturday = 6
    const weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final todayWeekdayIndex = today.weekday % 7;

    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── 1. Header: Streak Counter + Label (Left, Baseline-Aligned) & Fire Icon (Right) ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$currentStreak',
                    style: TextStyle(
                      fontSize: 70,
                      fontFamily: 'headline',

                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    hasActiveStreak
                        ? (currentStreak == 1 ? 'DAY STREAK' : 'DAYS STREAK')
                        : 'NO ACTIVE STREAK',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'GoogleSansFlex',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: hasActiveStreak
                          ? coralOrange
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.local_fire_department_rounded,
                size: 60,
                color: hasActiveStreak
                    ? coralOrange
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (!isCompact) const SizedBox(height: 16),

          // ─── 3. Weekday Letters (Sunday First: S M T W T F S) ────────────
          Row(
            children: weekLabels.asMap().entries.map((entry) {
              final idx = entry.key;
              final dayLabel = entry.value;
              final isTodayWeekday = idx == todayWeekdayIndex;

              return Expanded(
                child: Center(
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isTodayWeekday
                          ? coralOrange
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // ─── 4. Minimal Circular Grid ─────────────────────────────────
          _buildMinimalGrid(
            context: context,
            colorScheme: colorScheme,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            hasActiveStreak: hasActiveStreak,
            today: today,
            allTasks: allTasks,
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

  Widget _buildMinimalGrid({
    required BuildContext context,
    required ColorScheme colorScheme,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
    required bool hasActiveStreak,
    required DateTime today,
    required List<Task> allTasks,
  }) {
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: List.generate(7, (colIdx) {
              final cellIdx = rowIdx * 7 + colIdx;
              final dayNum = cellIdx - startWeekday + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 36));
              }

              final cellDate = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                dayNum,
              );
              final isToday = DateTimeUtils.isSameDay(cellDate, today);
              final isSelected = DateTimeUtils.isSameDay(
                cellDate,
                widget.selectedDate,
              );
              final isFuture = cellDate.isAfter(today);

              final inStreakRange =
                  hasActiveStreak &&
                  rangeStart != null &&
                  rangeEnd != null &&
                  !cellDate.isBefore(rangeStart) &&
                  !cellDate.isAfter(rangeEnd);

              Color circleColor;
              Border? cellBorder;

              if (inStreakRange) {
                circleColor = coralOrange;
              } else if (isToday) {
                circleColor = colorScheme.onSurface;
              } else if (isFuture) {
                circleColor = colorScheme.surfaceContainer;
              } else {
                circleColor = Colors.transparent;
                cellBorder = Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  width: 1.2,
                );
              }

              final dayTasks = allTasks
                  .where((t) => _isTaskOnDate(t, cellDate))
                  .toList();
              final hasPending = dayTasks.any((t) => !t.completed);
              final hasOverdue = cellDate.isBefore(today) && hasPending;

              Color? dotColor;
              if (hasOverdue) {
                dotColor = const Color(0xFFEF4444);
              } else if (hasPending) {
                dotColor = const Color(0xFF3B82F6);
              }

              final showNumber = !isToday && (isFuture || isSelected);

              final Color textColor = inStreakRange
                  ? Colors.white
                  : (isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7));

              return Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ZetaHaptics.selection();
                      widget.onSelectDate(cellDate);
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: circleColor,
                        border: isSelected && !isToday
                            ? Border.all(color: colorScheme.onSurface, width: 2)
                            : cellBorder,
                        borderRadius: BorderRadius.circular(
                          isSelected ? 8 : 50,
                        ),
                        boxShadow: null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (showNumber)
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          if (dotColor != null)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 3.5,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: (inStreakRange || isToday)
                                      ? colorScheme.surface
                                      : dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
