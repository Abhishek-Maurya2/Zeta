import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../models/task.dart';
import '../utils/haptics.dart';
import 'glass_m3e_menu.dart';

enum TaskContextAction {
  select,
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
    VoidCallback? onSelect,
    VoidCallback? onToggleComplete,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onRestore,
    VoidCallback? onPermanentDelete,
  }) async {
    ZetaHaptics.medium();

    final selected = await showGlassM3EMenu<TaskContextAction>(
      context: context,
      anchor: Rect.fromLTWH(position.dx, position.dy, 1, 1),
      position: M3EMenuAnchorPosition.bottomStart,
      colorStyle: M3EMenuColorStyle.vibrant,
      preferredWidth: 230,
      blurSigma: 8.0,
      children: isBin
          ? [
              const M3EMenuEntry(
                value: TaskContextAction.restore,
                label: 'Restore Task',
                leading: Icon(Symbols.restore_from_trash_rounded, size: 20, fill: 1.0),
              ),
              const M3EMenuDivider(),
              const M3EMenuEntry(
                value: TaskContextAction.permanentDelete,
                label: 'Delete Permanently',
                leading: Icon(Symbols.delete_forever_rounded, size: 20, fill: 1.0),
                isDestructive: true,
              ),
            ]
          : [
              const M3EMenuEntry(
                value: TaskContextAction.select,
                label: 'Select',
                leading: Icon(Symbols.check_circle_rounded, size: 20, fill: 1.0),
              ),
              const M3EMenuDivider(),
              M3EMenuEntry(
                value: TaskContextAction.toggleComplete,
                label: task.completed
                    ? 'Mark as Incomplete'
                    : 'Mark as Complete',
                leading: Icon(
                  task.completed
                      ? Symbols.radio_button_unchecked_rounded
                      : Symbols.check_rounded,
                  size: 20,
                  fill: 1.0,
                ),
              ),
              const M3EMenuEntry(
                value: TaskContextAction.edit,
                label: 'Edit Details',
                leading: Icon(Symbols.edit_rounded, size: 20, fill: 1.0),
              ),
              const M3EMenuDivider(),
              const M3EMenuEntry(
                value: TaskContextAction.delete,
                label: 'Move to Bin',
                leading: Icon(Symbols.delete_rounded, size: 20, fill: 1.0),
                isDestructive: true,
              ),
            ],
    );

    if (selected == null) return;
    ZetaHaptics.light();

    switch (selected) {
      case TaskContextAction.select:
        onSelect?.call();
        break;
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
