import 'package:material_ui/material_ui.dart';

import '../../models/task.dart';
import '../../utils/task_date_formatter.dart';

/// Reusable chip displaying a task's due date and time.
class TaskDueDateChip extends StatelessWidget {
  final Task task;
  final bool isCompleted;

  const TaskDueDateChip({
    super.key,
    required this.task,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (task.dueDate == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isToday =
        TaskDateFormatter.isToday(task.dueDate) &&
        task.hasTime &&
        task.dueTime != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isToday ? Icons.schedule_rounded : Icons.calendar_today_outlined,
            size: 13,
            color: const Color(0xFF006A60),
          ),
          const SizedBox(width: 5),
          Text(
            TaskDateFormatter.formatTaskListDate(
              dueDate: task.dueDate!,
              hasTime: task.hasTime,
              dueTime: task.dueTime,
            ),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isCompleted
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable chip displaying the deletion timestamp of a task in the Bin.
class TaskDeletedDateChip extends StatelessWidget {
  final DateTime? timestamp;

  const TaskDeletedDateChip({super.key, required this.timestamp});

  static String formatDeletedDate(DateTime? timestamp) {
    if (timestamp == null) return 'Deleted recently';
    const months = [
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
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return 'Deleted ${timestamp.day}, ${months[timestamp.month - 1]} at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 13,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            formatDeletedDate(timestamp),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable badge/chip showing subtask progress and collapse/expand toggle.
class TaskSubtasksBadge extends StatelessWidget {
  final List<Subtask> subtasks;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const TaskSubtasksBadge({
    super.key,
    required this.subtasks,
    required this.isExpanded,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    if (subtasks.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final completedCount = subtasks.where((s) => s.completed).length;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onToggleExpand,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isExpanded
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 14,
              color: isExpanded
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              '$completedCount/${subtasks.length} Subtasks',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isExpanded
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (onToggleExpand != null) ...[
              const SizedBox(width: 3),
              Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 15,
                color: isExpanded
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
