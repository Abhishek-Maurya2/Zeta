import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../models/task.dart';
import '../../utils/haptics.dart';
import 'task_chips.dart';
import 'task_subtasks_list.dart';

/// A modular, reusable task card item used across both the Tasks Page
/// and the Bin Page (via [isDeleted: true]).
class TaskCardItem extends StatelessWidget {
  final Task task;
  final bool isExpanded;
  final bool isDeleted;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onToggle;
  final VoidCallback? onToggleExpand;
  final void Function(String subtaskId)? onToggleSubtask;
  final VoidCallback? onTap;
  final void Function(Offset globalPosition)? onContextMenu;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? extraChips;

  const TaskCardItem({
    super.key,
    required this.task,
    this.isExpanded = false,
    this.isDeleted = false,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onToggle,
    this.onToggleExpand,
    this.onToggleSubtask,
    this.onTap,
    this.onContextMenu,
    this.onDelete,
    this.onRestore,
    this.onPermanentDelete,
    this.leading,
    this.trailing,
    this.extraChips,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtasks = task.subtasks;
    final hasSubtasks = subtasks.isNotEmpty;
    final isCompletedOrDeleted = isDeleted || task.completed;
    final revisionInfo = RevisionTagInfo.parse(task.description, taskTitle: task.title);
    final displayDescription = revisionInfo.isRevision
        ? revisionInfo.cleanedDescription
        : task.description;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          onContextMenu?.call(details.globalPosition),
      onLongPressStart: (details) =>
          onContextMenu?.call(details.globalPosition),
      child: InkWell(
        borderRadius: BorderRadius.circular(isSelected ? 50.0 : 16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: Leading, Title/Description, Trailing ────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading: Checkbox or Delete Icon
                  leading ?? _buildLeading(context),

                  const SizedBox(width: 12),

                  // Content: Title and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onSecondaryContainer
                                : (isCompletedOrDeleted
                                    ? colorScheme.onSurfaceVariant.withValues(
                                        alpha: isDeleted ? 0.75 : 0.7,
                                      )
                                    : colorScheme.onSurface),
                            decoration: isCompletedOrDeleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (displayDescription != null &&
                            displayDescription.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            displayDescription,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer
                                      .withValues(alpha: 0.8)
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: isDeleted ? 0.6 : 0.8,
                                    ),
                              decoration: isCompletedOrDeleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing: Actions (Restore/Delete in Bin, or custom)
                  if (trailing != null || isDeleted) ...[
                    const SizedBox(width: 8),
                    trailing ?? _buildBinTrailing(context),
                  ],
                ],
              ),

              // ─── Chips: Aligned with Title & Description ─────────────────
              if ((isDeleted && task.deletedAt != null) ||
                  task.dueDate != null ||
                  hasSubtasks ||
                  revisionInfo.isRevision ||
                  (extraChips != null && extraChips!.isNotEmpty)) ...[
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isDeleted && task.deletedAt != null)
                          TaskDeletedDateChip(timestamp: task.deletedAt),
                        if (task.dueDate != null)
                          TaskDueDateChip(
                            task: task,
                            isCompleted: isCompletedOrDeleted,
                          ),
                        if (revisionInfo.isRevision)
                          TaskRevisionChip(label: revisionInfo.label),
                        if (hasSubtasks)
                          TaskSubtasksBadge(
                            subtasks: subtasks,
                            isExpanded: isExpanded,
                            onToggleExpand: isDeleted ? null : onToggleExpand,
                          ),
                        ...?extraChips,
                      ],
                    ),
                  ),
                ),
              ],

              // ─── Subtasks List: Takes full horizontal space ───────────────
              if (isExpanded && hasSubtasks) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TaskSubtasksList(
                    subtasks: subtasks,
                    onToggleSubtask: isDeleted ? null : onToggleSubtask,
                    isReadOnly: isDeleted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 22,
          color: colorScheme.outline,
        ),
      );
    }

    if (isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.only(top: 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isSelected
              ? Icon(
                  Icons.check_circle_rounded,
                  key: const ValueKey('selected'),
                  size: 22,
                  color: colorScheme.primary,
                )
              : Icon(
                  Icons.radio_button_unchecked_rounded,
                  key: const ValueKey('unselected'),
                  size: 22,
                  color: colorScheme.outline,
                ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onToggle != null
          ? () {
              ZetaHaptics.light();
              onToggle!();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.all(0),
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
    );
  }

  Widget _buildBinTrailing(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final actions = <M3EButtonGroupAction>[];
    final callbacks = <VoidCallback>[];

    if (onRestore != null) {
      actions.add(
        M3EButtonGroupAction(
          icon: Icon(
            Icons.restore_from_trash_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          tooltip: 'Restore Task',
          decoration: M3EToggleButtonDecoration.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
        ),
      );
      callbacks.add(onRestore!);
    }

    if (onPermanentDelete != null) {
      actions.add(
        M3EButtonGroupAction(
          icon: Icon(
            Icons.delete_forever_rounded,
            size: 18,
            color: colorScheme.error,
          ),
          tooltip: 'Delete permanently',
          decoration: M3EToggleButtonDecoration.styleFrom(
            foregroundColor: colorScheme.error,
          ),
        ),
      );
      callbacks.add(onPermanentDelete!);
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return M3EButtonGroup(
      type: M3EButtonGroupType.connected,
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.xs,
      shape: M3EButtonShape.round,
      selectedIndex: null,
      onSelectedIndexChanged: (int? index) {
        if (index != null && index >= 0 && index < callbacks.length) {
          ZetaHaptics.light();
          callbacks[index]();
        }
      },
      actions: actions,
    );
  }
}
