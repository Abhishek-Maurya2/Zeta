import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/m3e_custom_list_item.dart';
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
    this.trailingChild,
  });

  final Widget? trailingChild;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int totalCount = tasks.length + (trailingChild != null ? 1 : 0);

    return M3EList(
      key: ValueKey('tasks_list_${tasks.length}_${tasks.hashCode}'),
      itemCount: totalCount,
      embedded: embedded,
      gap: 8,
      colorBuilder: (index) => Colors.transparent,
      itemBuilder: (context, index) {
        if (trailingChild != null && index == tasks.length) {
          return M3ECustomListItem(customChild: trailingChild!);
        }

        final task = tasks[index];
        final isSelectionMode = provider.isSelectionMode;
        final isSelected = provider.isTaskSelected(task.id);

        final bool isFirst = index == 0;
        final bool isLast = index == tasks.length - 1 && trailingChild == null;
        final bool isSingle = tasks.length == 1;

        BorderRadius radius = isSingle
            ? BorderRadius.circular(16)
            : BorderRadius.vertical(
                top: Radius.circular(isFirst ? 16 : 4),
                bottom: Radius.circular(isLast ? 16 : 4),
              );

        if (isSelected) {
          radius = BorderRadius.circular(45);
        }

        final cardColor = isSelected
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerLowest;

        final card = Material(
          color: cardColor,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: TaskCardItem(
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
          ),
        );

        if (isSelectionMode) return card;

        final completeAction = M3EListSwipeAction(
          icon: Icon(
            task.completed
                ? Icons.radio_button_unchecked_rounded
                : Icons.check_circle_rounded,
            color: isDark
                ? task.completed
                      ? colorScheme.onPrimary
                      : colorScheme.onSuccessContainer
                : Colors.white,
          ),
          backgroundColor: task.completed
              ? colorScheme.primary
              : isDark
              ? colorScheme.successContainer
              : colorScheme.success,
          onPressed: () => provider.toggleTask(task.id),
          isPrimary: true,
        );

        final deleteAction = M3EListSwipeAction(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: isDark ? colorScheme.onErrorContainer : Colors.white,
          ),
          backgroundColor: isDark
              ? colorScheme.errorContainer
              : colorScheme.error,
          onPressed: () => provider.deleteTask(task.id),
          isPrimary: true,
        );

        return M3ECustomListItem(
          key: ValueKey(task.id),
          swipe: M3EListItemSwipe(
            leading: [
              provider.swapSwipeActions ? deleteAction : completeAction,
            ],
            trailing: [
              provider.swapSwipeActions ? completeAction : deleteAction,
            ],
          ),
          customChild: card,
        );
      },
    );
  }
}
