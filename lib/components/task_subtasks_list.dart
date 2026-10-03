import 'package:material_ui/material_ui.dart';

import '../models/task.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// A reusable, modular subtasks list styled with Material 3 Expressive
/// [M3EList], shared across both the Tasks Page and Bin Page.
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

    return M3EList(
      color: effectiveBgColor,
      itemCount: subtasks.length,
      itemBuilder: (context, index) {
        final subtask = subtasks[index];
        return InkWell(
          onTap: (!isReadOnly && onToggleSubtask != null)
              ? () => onToggleSubtask!(subtask.id)
              : null,
          child: Padding(
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
                const SizedBox(width: 12),
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
          ),
        );
      },
    );
  }
}

/// Shorthand alias for [TaskSubtasksList] for cleaner usage across panes.
typedef SubtasksList = TaskSubtasksList;
