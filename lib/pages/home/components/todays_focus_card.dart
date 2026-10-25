import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../components/task_edit_pane.dart';
import '../../../utils/task_date_formatter.dart';
import '../../../utils/date_time_utils.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../components/standard_chips.dart';
import '../../../components/zeta_empty_state.dart';

/// Today's Focus Card mirroring Sharva's TodaysFocusCard:
/// - Header with track changes icon, title, and Scheduled badge.
/// - Top card with 28px top / 8px bottom corners displaying the focused task,
///   checkbox toggle, expandable subtasks list, and due date chip.
/// - Bottom bar with 8px top / 28px bottom corners with filled "+ Add new task" button.
/// - Expressive empty state when no tasks are scheduled for the day.
class TodaysFocusCard extends StatelessWidget {
  final Task? task;
  final List<Task> pendingTasks;
  final DateTime selectedDate;
  final VoidCallback? onOpenCreate;

  const TodaysFocusCard({
    super.key,
    required this.task,
    this.pendingTasks = const [],
    required this.selectedDate,
    this.onOpenCreate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final taskProvider = context.read<TaskProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = DateTimeUtils.isSameDay(selectedDate, today);
    final formattedDate = DateTimeUtils.formatFocusDate(selectedDate);

    final parsedDue = task?.parsedDueDate;
    final isOverdue =
        parsedDue != null &&
        parsedDue.isBefore(today) &&
        !(task?.completed ?? false);
    final isDueToday =
        parsedDue != null &&
        DateTimeUtils.isSameDay(parsedDue, today) &&
        !(task?.completed ?? false);

    final dueFormatted = task?.dueDate != null
        ? TaskDateFormatter.formatTaskListDate(
            dueDate: task!.dueDate!,
            hasTime: task!.hasTime,
            dueTime: task!.dueTime,
          )
        : null;

    final revisionInfo = task != null
        ? RevisionTagInfo.parse(task!.description, taskTitle: task!.title)
        : const RevisionTagInfo(isRevision: false, label: '');

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
                  Symbols.track_changes_rounded,
                  size: 23,
                  color: colorScheme.primary,
                  fill: 1.0,
                ),
                const SizedBox(width: 8),
                Text(
                  isToday ? "Today's Focus" : 'Focus • $formattedDate',
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
                  color: isOverdue
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverdue
                      ? 'OVERDUE'
                      : (isDueToday ? 'DUE TODAY' : 'SCHEDULED'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isOverdue
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
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
                          fontWeight: FontWeight.bold,
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
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 22,
                                decoration: task!.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task!.completed
                                    ? colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.7,
                                      )
                                    : colorScheme.onSurface,
                              ),
                            ),
                            if ((revisionInfo.isRevision
                                        ? revisionInfo.cleanedDescription
                                        : task!.description) !=
                                    null &&
                                (revisionInfo.isRevision
                                        ? revisionInfo.cleanedDescription
                                        : task!.description)!
                                    .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                (revisionInfo.isRevision
                                    ? revisionInfo.cleanedDescription
                                    : task!.description)!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.9,
                                  ),
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
                  M3EList(
                    color: colorScheme.tertiaryContainer,
                    itemCount: task!.subtasks.length,
                    itemBuilder: (context, index) {
                      final st = task!.subtasks[index];
                      return InkWell(
                        onTap: () => taskProvider.toggleSubtask(
                          task!.id,
                          st.id,
                          context: context,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                fontWeight: FontWeight.bold,
                                st.completed
                                    ? Icons.check_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: st.completed
                                    ? const Color(0xFF10B981)
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  st.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'RobotoMono',
                                    decoration: st.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: st.completed
                                        ? colorScheme.onTertiaryContainer
                                              .withValues(alpha: 0.7)
                                        : colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // Chips Row (Due Date + Revision)
                if (dueFormatted != null || revisionInfo.isRevision) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (dueFormatted != null)
                        FocusTaskDueDateChip(
                          dueFormatted: dueFormatted,
                          hasTime: task!.hasTime,
                          isOverdue: isOverdue,
                        ),
                      if (revisionInfo.isRevision)
                        TaskRevisionChip(label: revisionInfo.label),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (pendingTasks.isNotEmpty) ...[
            const SizedBox(height: 3),
            _OtherDueTasksCard(tasks: pendingTasks, today: today),
          ],

          const SizedBox(height: 3),

          // Bottom Quick Add Container
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
                bottom: Radius.circular(28),
              ),
            ),
            child: Center(
              child: M3EButton.icon(
                icon: const Icon(
                  Icons.add_rounded,
                  fontWeight: FontWeight.bold,
                  size: 27,
                ),
                label: const Text(
                  'Add Task',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.md,
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: ZetaEmptyState.focus(
              isToday: isToday,
              formattedDate: formattedDate,
              onCreateTask: () {
                if (onOpenCreate != null) {
                  onOpenCreate!();
                } else {
                  TaskEditPane.show(context);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _OtherDueTasksCard extends StatelessWidget {
  final List<Task> tasks;
  final DateTime today;

  const _OtherDueTasksCard({required this.tasks, required this.today});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final taskProvider = context.read<TaskProvider>();

    return M3EList(
      color: colorScheme.surfaceContainerLowest,
      outerRadius: 8,
      innerRadius: 8,
      gap: 3,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final due = task.parsedDueDate;
        final isOverdue = due != null && due.isBefore(today);

        return M3EListItem(
          leading: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => taskProvider.toggleTask(task.id),
            child: Icon(
              Icons.radio_button_unchecked_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          headline: task.title,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.dueDate != null)
                FocusTaskDueDateChip(
                  dueFormatted: TaskDateFormatter.formatTaskListDate(
                    dueDate: task.dueDate!,
                    hasTime: task.hasTime,
                    dueTime: task.dueTime,
                  ),
                  hasTime: task.hasTime,
                  isOverdue: isOverdue,
                ),
              if (task.dueDate != null && task.subtasks.isNotEmpty)
                const SizedBox(width: 6),
              if (task.subtasks.isNotEmpty)
                TaskSubtasksBadge(
                  subtasks: task.subtasks,
                  isExpanded: false,
                ),
            ],
          ),
          onTap: () => TaskEditPane.show(context, task: task),
        );
      },
    );
  }
}
