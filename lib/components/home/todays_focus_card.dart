import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../components/tasks/task_edit_pane.dart';
import '../../utils/task_date_formatter.dart';
import '../../widgets/segmented_column.dart';

/// Today's Focus Card mirroring Sharva's TodaysFocusCard:
/// - Header with track changes icon, title, and Scheduled badge.
/// - Top card with 28px top / 8px bottom corners displaying the focused task,
///   checkbox toggle, expandable subtasks list, and due date chip.
/// - Bottom bar with 8px top / 28px bottom corners with filled "+ Add new task" button.
/// - Expressive empty state when no tasks are scheduled for the day.
class TodaysFocusCard extends StatelessWidget {
  final Task? task;
  final DateTime selectedDate;
  final VoidCallback? onOpenCreate;

  const TodaysFocusCard({
    super.key,
    required this.task,
    required this.selectedDate,
    this.onOpenCreate,
  });

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final taskProvider = context.read<TaskProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = _isSameDay(selectedDate, today);

    final weekdayName = _weekdaysFull[selectedDate.weekday - 1];
    final monthName = _monthsShort[selectedDate.month - 1];
    final formattedDate = '$weekdayName, $monthName ${selectedDate.day}';

    final dueFormatted = task?.dueDate != null
        ? TaskDateFormatter.formatTaskListDate(
            dueDate: task!.dueDate!,
            hasTime: task!.hasTime,
            dueTime: task!.dueTime,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Header ─────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isToday ? "Today's Focus" : "Focus • $formattedDate",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (task?.dueDate != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'SCHEDULED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ─── Card Body or Empty State ────────────────────────────────────────
        if (task != null) ...[
          // Top Focus Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
                bottom: Radius.circular(8),
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Focus Task Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => taskProvider.toggleTask(task!.id),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: Icon(
                          task!.completed
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 24,
                          color: task!.completed
                              ? const Color(0xFF10B981)
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => TaskEditPane.show(context, task: task),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task!.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: task!.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task!.completed
                                    ? colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7)
                                    : colorScheme.onSurface,
                              ),
                            ),
                            if (task!.description != null &&
                                task!.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task!.description!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  decoration: task!.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Subtasks List
                if (task!.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  M3ESegmentedColumn(
                    decoration: const M3ESegmentedListDecoration(
                      padding: EdgeInsets.all(1.0),
                      outerRadius: 16.0,
                      innerRadius: 4.0,
                    ),
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                    children: task!.subtasks.map((st) {
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 0,
                        ),
                        leading: InkWell(
                          onTap: () =>
                              taskProvider.toggleSubtask(task!.id, st.id),
                          child: Icon(
                            st.completed
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: st.completed
                                ? const Color(0xFF10B981)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          st.title,
                          style: TextStyle(
                            fontSize: 13,
                            decoration: st.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: st.completed
                                ? colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7)
                                : colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Due Date Chip
                if (dueFormatted != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task!.hasTime
                              ? Icons.schedule_rounded
                              : Icons.event_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dueFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Bottom Quick Add Container
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(28),
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: M3EButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add new task'),
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.sm,
                onPressed: () {
                  if (onOpenCreate != null) {
                    onOpenCreate!();
                  } else {
                    TaskEditPane.show(context);
                  }
                },
              ),
            ),
          ),
        ] else ...[
          // Empty State
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    size: 28,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isToday ? 'Clear Focus for Today' : 'No Tasks Scheduled',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isToday
                      ? 'All set! No pending tasks scheduled right now.'
                      : 'No tasks scheduled for $formattedDate.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                M3EButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create Task'),
                  style: M3EButtonStyle.filled,
                  size: M3EButtonSize.sm,
                  onPressed: () {
                    if (onOpenCreate != null) {
                      onOpenCreate!();
                    } else {
                      TaskEditPane.show(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
