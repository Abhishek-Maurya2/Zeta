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

    return M3EList(
      key: const ValueKey('tasks_dismissible_list'),
      itemCount: tasks.length,
      embedded: embedded,
      outerRadius: 24,
      innerRadius: 4,
      gap: 3,
      color: colorScheme.surfaceContainerLowest,
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
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelectionMode = provider.isSelectionMode;
        final isSelected = provider.isTaskSelected(task.id);

        final card = TaskCardItem(
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

        if (isSelectionMode) return card;

        return Dismissible(
          key: ValueKey(task.id),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: task.completed
                ? colorScheme.secondary
                : isDark
                    ? colorScheme.successContainer
                    : colorScheme.success,
            child: Icon(
              task.completed
                  ? Icons.radio_button_unchecked_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: isDark ? colorScheme.errorContainer : colorScheme.error,
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              provider.deleteTask(task.id);
            } else {
              provider.toggleTask(task.id);
            }
            return true;
          },
          child: card,
        );
      },
    );
  }
}
