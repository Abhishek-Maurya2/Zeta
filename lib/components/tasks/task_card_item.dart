import 'package:material_ui/material_ui.dart';
import '../../models/task.dart';

class TaskCardItem extends StatelessWidget {
  final Task task;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onToggleExpand;
  final void Function(String subtaskId) onToggleSubtask;
  final VoidCallback? onTap;
  final void Function(Offset globalPosition)? onContextMenu;
  final VoidCallback? onDelete;

  const TaskCardItem({
    super.key,
    required this.task,
    required this.isExpanded,
    required this.onToggle,
    required this.onToggleExpand,
    required this.onToggleSubtask,
    this.onTap,
    this.onContextMenu,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtasks = task.subtasks;
    final hasSubtasks = subtasks.isNotEmpty;
    final completedSubtasks = subtasks.where((s) => s.completed).length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          onContextMenu?.call(details.globalPosition),
      onLongPressStart: (details) =>
          onContextMenu?.call(details.globalPosition),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Leading Circular Checkbox ──────────────────────────────
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: task.completed
                          ? const Icon(
                              Icons.check_rounded,
                              size: 22,
                              color: Color(0xFF10B981),
                            )
                          : Icon(
                              Icons.radio_button_unchecked_rounded,
                              size: 22,
                              color: colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ─── Content: Title, Description, Badges ─────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: task.completed
                                ? colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7)
                                : colorScheme.onSurface,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        // Description
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Badges row: Due date & Subtasks
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Due date chip
                            if (task.dueDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        colorScheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      task.hasTime
                                          ? Icons.schedule_rounded
                                          : Icons.calendar_today_outlined,
                                      size: 14,
                                      color: const Color(0xFF006A60),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      task.hasTime && task.dueTime != null
                                          ? '${task.dueDate} • ${task.dueTime}'
                                          : task.dueDate!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: task.completed
                                            ? colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.6)
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Subtasks collapsible chip
                            if (hasSubtasks)
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: onToggleExpand,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isExpanded
                                        ? colorScheme.secondaryContainer
                                        : colorScheme.surfaceContainerHigh
                                            .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.checklist_rounded,
                                        size: 15,
                                        color: isExpanded
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '$completedSubtasks/${subtasks.length} Subtasks',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isExpanded
                                              ? colorScheme.onSecondaryContainer
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        size: 16,
                                        color: isExpanded
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ],
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

              // ─── Collapsible Subtask List ─────────────────────────────────────
              if (isExpanded && hasSubtasks) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: subtasks.map((subtask) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onToggleSubtask(subtask.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                subtask.completed
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 16,
                                color: subtask.completed
                                    ? const Color(0xFF10B981)
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  subtask.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtask.completed
                                        ? colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.6)
                                        : colorScheme.onSurface,
                                    decoration: subtask.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
