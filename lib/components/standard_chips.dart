import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/task.dart';
import '../utils/date_time_utils.dart';

/// Reusable chip displaying a task's due date and time.
/// Used in [TaskCardItem] and across task lists.
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

    final colorScheme = context.colorScheme;
    // Show clock icon only when displaying time-only (due today with a scheduled time)
    final showTimeOnly =
        DateTimeUtils.isToday(task.dueDate) &&
        task.hasTime &&
        task.dueTime != null &&
        task.dueTime!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            showTimeOnly ? Symbols.schedule_rounded : Symbols.today_rounded,
            size: 16,
            color: colorScheme.onSecondaryContainer,
            fill: 1,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(width: 8),
          Text(
            DateTimeUtils.formatTaskListDate(
              dueDate: task.dueDate!,
              hasTime: task.hasTime,
              dueTime: task.dueTime,
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isCompleted
                  ? colorScheme.onSecondaryContainer.withValues(alpha: 0.6)
                  : colorScheme.onSecondaryContainer,
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

  static String formatDeletedDate(DateTime? timestamp) =>
      DateTimeUtils.formatDeletedDate(timestamp);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

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
            Symbols.schedule_rounded,
            size: 15,
            color: colorScheme.onSurfaceVariant,
            fill: 1,
          ),
          const SizedBox(width: 5),
          Text(
            DateTimeUtils.formatDeletedDate(timestamp),
            style: TextStyle(
              fontSize: 14,
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

    final colorScheme = context.colorScheme;
    final completedCount = subtasks.where((s) => s.completed).length;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onToggleExpand,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isExpanded
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: isExpanded
              ? BorderRadius.circular(8)
              : BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.checklist_rounded,
              size: 16,
              color: isExpanded
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fill: 1,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(width: 5),
            Text(
              '$completedCount/${subtasks.length} Subtasks',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isExpanded
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (onToggleExpand != null) ...[
              const SizedBox(width: 3),
              Icon(
                isExpanded
                    ? Symbols.expand_less_rounded
                    : Symbols.expand_more_rounded,
                size: 16,
                fontWeight: FontWeight.w600,
                fill: 1,
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

/// Reusable status pill chip indicating streak active or ready status.
class StreakStatusChip extends StatelessWidget {
  final bool hasActiveStreak;

  const StreakStatusChip({super.key, required this.hasActiveStreak});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            Symbols.bolt_rounded,
            size: 13,
            color: hasActiveStreak
                ? Colors.amber.shade700
                : colorScheme.onSurfaceVariant,
            fill: 1,
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
    );
  }
}

/// Reusable badge displaying user's best streak record.
class StreakBestBadge extends StatelessWidget {
  final int bestStreak;

  const StreakBestBadge({super.key, required this.bestStreak});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Text(
      'Best: ${bestStreak}d',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: colorScheme.outline,
      ),
    );
  }
}

/// Reusable chip displaying the active streak period range.
class StreakPeriodChip extends StatelessWidget {
  final String rangeLabel;

  const StreakPeriodChip({super.key, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.date_range_rounded,
            size: 14,
            color: colorScheme.primary,
            fill: 1,
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
    );
  }
}

/// Reusable due date chip used inside Today's Focus card.
class FocusTaskDueDateChip extends StatelessWidget {
  final String dueFormatted;
  final bool hasTime;
  final bool isOverdue;

  const FocusTaskDueDateChip({
    super.key,
    required this.dueFormatted,
    this.hasTime = false,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final fgColor = isOverdue
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;
    final borderColor = isOverdue
        ? colorScheme.error.withValues(alpha: 0.5)
        : colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasTime ? Symbols.schedule_rounded : Symbols.event_rounded,
            size: 16,
            color: fgColor,
            fill: 1,
          ),
          const SizedBox(width: 8),
          Text(
            dueFormatted,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
