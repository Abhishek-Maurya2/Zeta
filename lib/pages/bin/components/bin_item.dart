import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/core/core.dart';

import '../../../components/attachment_chip.dart';
import '../../../components/standard_chips.dart';
import '../../../components/task_subtasks_list.dart';
import '../../../models/task.dart';
import '../../../theme/motion_tokens.dart';
import '../../../utils/haptics.dart';

/// Material 3 Expressive list item for a deleted task in the Bin page.
class BinItem extends StatelessWidget {
  final Task task;
  final bool isExpanded;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;
  final VoidCallback? onToggleExpand;
  final void Function(Offset globalPosition)? onContextMenu;

  const BinItem({
    super.key,
    required this.task,
    required this.onRestore,
    required this.onPermanentDelete,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final subtasks = task.subtasks;
    final hasSubtasks = subtasks.isNotEmpty;
    final description = task.description;
    final hasDescription = description != null && description.isNotEmpty;

    final chips = <Widget>[
      if (task.deletedAt != null)
        TaskDeletedDateChip(timestamp: task.deletedAt),
      if (task.dueDate != null)
        TaskDueDateChip(task: task, isCompleted: true),
      if (hasSubtasks)
        TaskSubtasksBadge(
          subtasks: subtasks,
          isExpanded: isExpanded,
          onToggleExpand: onToggleExpand,
        ),
      if (task.attachments.isNotEmpty)
        TaskAttachmentsChipGroup(
          attachments: task.attachments,
          maxTitleLength: 20,
        ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          onContextMenu?.call(details.globalPosition),
      onLongPressStart: (details) =>
          onContextMenu?.call(details.globalPosition),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: hasSubtasks ? onToggleExpand : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expressive tonal leading badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Symbols.delete_outline_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),

              // Main content column: title, description, aligned chips, subtasks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: hasDescription
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (hasDescription) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _BinActionsGroup(
                          onRestore: onRestore,
                          onPermanentDelete: onPermanentDelete,
                        ),
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: chips,
                      ),
                    ],
                    if (hasSubtasks)
                      AnimatedSize(
                        duration: M3MotionDuration.medium2,
                        curve: M3MotionEasing.emphasizedDecelerate,
                        alignment: Alignment.topCenter,
                        child: isExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TaskSubtasksList(
                                  subtasks: subtasks,
                                  isReadOnly: true,
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BinActionsGroup extends StatelessWidget {
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  const _BinActionsGroup({
    required this.onRestore,
    required this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return M3EButtonGroup(
      type: M3EButtonGroupType.connected,
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.sm,
      shape: M3EButtonShape.round,
      selectedIndex: null,
      onSelectedIndexChanged: (int? index) {
        if (index == 0) {
          ZetaHaptics.light();
          onRestore();
        } else if (index == 1) {
          ZetaHaptics.medium();
          onPermanentDelete();
        }
      },
      actions: [
        M3EButtonGroupAction(
          icon: const Icon(Icons.restore_rounded, size: 20),
          tooltip: 'Restore task',
          decoration: M3EButtonDecoration.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
          ),
        ),
        M3EButtonGroupAction(
          icon: const Icon(Icons.delete_forever_rounded, size: 20),
          tooltip: 'Delete permanently',
          decoration: M3EButtonDecoration.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          ),
        ),
      ],
    );
  }
}

/// Expressive alias for [BinItem] clearly indicating it renders a deleted task card.
typedef BinTaskCard = BinItem;
