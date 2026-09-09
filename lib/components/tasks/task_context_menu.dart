import 'package:material_ui/material_ui.dart';
import '../../models/task.dart';

enum TaskContextAction {
  toggleComplete,
  edit,
  delete,
  restore,
  permanentDelete,
}

class TaskContextMenu {
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required Task task,
    bool isBin = false,
    VoidCallback? onToggleComplete,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onRestore,
    VoidCallback? onPermanentDelete,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;

    final RelativeRect menuPosition = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    );

    final selected = await showMenu<TaskContextAction>(
      context: context,
      position: menuPosition,
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      color: colorScheme.surfaceContainerHigh,
      items: isBin
          ? [
              PopupMenuItem(
                value: TaskContextAction.restore,
                child: Row(
                  children: [
                    Icon(
                      Icons.restore_from_trash_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Restore Task',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TaskContextAction.permanentDelete,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Delete Permanently',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : [
              PopupMenuItem(
                value: TaskContextAction.toggleComplete,
                child: Row(
                  children: [
                    Icon(
                      task.completed
                          ? Icons.radio_button_unchecked_rounded
                          : Icons.check_circle_rounded,
                      size: 20,
                      color: task.completed
                          ? colorScheme.onSurfaceVariant
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.completed
                            ? 'Mark as Incomplete'
                            : 'Mark as Complete',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TaskContextAction.edit,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Details',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TaskContextAction.delete,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Move to Bin',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
    );

    if (selected == null) return;

    switch (selected) {
      case TaskContextAction.toggleComplete:
        onToggleComplete?.call();
        break;
      case TaskContextAction.edit:
        onEdit?.call();
        break;
      case TaskContextAction.delete:
        onDelete?.call();
        break;
      case TaskContextAction.restore:
        onRestore?.call();
        break;
      case TaskContextAction.permanentDelete:
        onPermanentDelete?.call();
        break;
    }
  }
}
