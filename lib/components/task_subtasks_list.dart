import 'package:material_ui/material_ui.dart';

import '../models/task.dart';
import '../widgets/segmented_column.dart';

/// A reusable, modular subtasks list styled with Material 3 Expressive
/// [M3ESegmentedColumn], shared across both the Tasks Page and Bin Page.
class TaskSubtasksList extends StatelessWidget {
  final List<Subtask> subtasks;
  final void Function(String subtaskId)? onToggleSubtask;
  final bool isReadOnly;
  final Color? backgroundColor;

  const TaskSubtasksList({
    super.key,
    required this.subtasks,
    this.onToggleSubtask,
    this.isReadOnly = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (subtasks.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBgColor = backgroundColor ?? colorScheme.tertiaryContainer;

    return M3ESegmentedColumn(
      decoration: const M3ESegmentedListDecoration(
        padding: EdgeInsets.all(1),
        outerRadius: 16,
        innerRadius: 6,
      ),
      color: effectiveBgColor,
      children: subtasks.map((subtask) {
        final rowContent = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                subtask.completed
                    ? Icons.check_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                fontWeight: FontWeight.w600,
                color: subtask.completed
                    ? const Color(0xFF10B981)
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.w500,
                    color: subtask.completed
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                        : colorScheme.onSurface,
                    decoration: subtask.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );

        if (!isReadOnly && onToggleSubtask != null) {
          return InkWell(
            onTap: () => onToggleSubtask!(subtask.id),
            child: rowContent,
          );
        }

        return rowContent;
      }).toList(),
    );
  }
}

/// Shorthand alias for [TaskSubtasksList] for cleaner usage across panes.
typedef SubtasksList = TaskSubtasksList;
