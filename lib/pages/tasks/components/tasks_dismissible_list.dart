import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/task_card_item.dart';
import '../../../components/task_edit_pane.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../utils/haptics.dart';
import '../../../theme/success_colors.dart';

/// Dismissible swipe-to-complete and swipe-to-delete task list.
class TasksDismissibleList extends StatelessWidget {
  final List<Task> tasks;
  final TaskProvider provider;
  final bool embedded;
  final void Function(
    BuildContext context,
    Offset position,
    Task task,
    TaskProvider provider,
  )
  onContextMenu;

  const TasksDismissibleList({
    super.key,
    required this.tasks,
    required this.provider,
    required this.onContextMenu,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return M3EDismissibleList(
      key: const ValueKey('tasks_dismissible_list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      embedded: embedded,
      style: M3EDismissibleListStyle(
        color: colorScheme.surfaceContainerLowest,
        padding: EdgeInsets.zero,
        outerRadius: 24,
        innerRadius: 4,
        gap: 3,
      ),
      colorBuilder: (index) {
        if (index < 0 || index >= tasks.length) return null;
        final task = tasks[index];
        if (provider.isTaskSelected(task.id)) {
          return colorScheme.secondaryContainer;
        }
        return null;
      },
      borderRadiusBuilder: (index, position) {
        if (index < 0 || index >= tasks.length) return null;
        final task = tasks[index];
        if (provider.isTaskSelected(task.id)) {
          return BorderRadius.circular(45.0);
        }
        return null;
      },
      leadingActionsBuilder: (index) {
        if (provider.isSelectionMode) return [];
        final task = tasks[index];
        return [
          M3EListSwipeAction(
            icon: Icon(
              task.completed
                  ? Icons.radio_button_unchecked_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            backgroundColor: task.completed
                ? colorScheme.secondary
                : isDark
                ? colorScheme.successContainer
                : colorScheme.success,
            onPressed: () => provider.toggleTask(task.id),
          ),
        ];
      },
      trailingActionsBuilder: (index) {
        if (provider.isSelectionMode) return [];
        final task = tasks[index];
        return [
          M3EListSwipeAction(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            backgroundColor: isDark
                ? colorScheme.errorContainer
                : colorScheme.error,
            isPrimary: true,
            onPressed: () => provider.deleteTask(task.id),
          ),
        ];
      },
      onDismiss: (index, direction) async {
        if (provider.isSelectionMode) return false;
        final task = tasks[index];
        if (direction == DismissDirection.endToStart) {
          provider.deleteTask(task.id);
        } else {
          provider.toggleTask(task.id);
        }
        return true;
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelectionMode = provider.isSelectionMode;
        final isSelected = provider.isTaskSelected(task.id);

        return TaskCardItem(
          key: ValueKey(task.id),
          task: task,
          isExpanded: provider.isTaskExpanded(task.id),
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onToggle: isSelectionMode
              ? () {
                  ZetaHaptics.selection();
                  provider.toggleTaskSelection(task.id);
                }
              : () => provider.toggleTask(task.id),
          onToggleExpand: () => provider.toggleTaskExpanded(task.id),
          onToggleSubtask: (subtaskId) =>
              provider.toggleSubtask(task.id, subtaskId),
          onTap: isSelectionMode
              ? () {
                  ZetaHaptics.selection();
                  provider.toggleTaskSelection(task.id);
                }
              : () => TaskEditPane.show(context, task: task),
          onContextMenu: (pos) => onContextMenu(context, pos, task, provider),
          onDelete: () => provider.deleteTask(task.id),
        );
      },
    );
  }
}
