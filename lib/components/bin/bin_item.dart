import 'package:material_ui/material_ui.dart';
import '../../models/task.dart';

class BinItem extends StatelessWidget {
  final Task task;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;
  final void Function(Offset globalPosition)? onContextMenu;

  const BinItem({
    super.key,
    required this.task,
    required this.onRestore,
    required this.onPermanentDelete,
    this.onContextMenu,
  });

  String _formatDeletedDate(DateTime? timestamp) {
    if (timestamp == null) return 'Deleted recently';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return 'Deleted ${timestamp.day}, ${months[timestamp.month - 1]} at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtasks = task.subtasks;
    final hasSubtasks = subtasks.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) =>
          onContextMenu?.call(details.globalPosition),
      onLongPressStart: (details) =>
          onContextMenu?.call(details.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading delete outline icon
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 22,
                color: colorScheme.outline,
              ),
            ),

            // Content: Title, Description, Subtasks, Chips
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
                      decoration: TextDecoration.lineThrough,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
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
                        decoration: TextDecoration.lineThrough,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],

                  // Subtasks
                  if (hasSubtasks) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: subtasks.map((st) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  st.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    st.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Chips row: Deleted timestamp & Due date
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatDeletedDate(task.deletedAt),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (task.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.hasTime
                                    ? Icons.schedule_rounded
                                    : Icons.event_rounded,
                                size: 13,
                                color: const Color(0xFF006A60),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                task.hasTime && task.dueTime != null
                                    ? '${task.dueDate} • ${task.dueTime}'
                                    : task.dueDate!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Trailing Actions: Restore and Permanent Delete
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Restore Task',
                  icon: const Icon(Icons.restore_from_trash_rounded, size: 20),
                  color: colorScheme.primary,
                  onPressed: onRestore,
                ),
                IconButton(
                  tooltip: 'Delete permanently',
                  icon: const Icon(Icons.delete_forever_rounded, size: 20),
                  color: colorScheme.error,
                  onPressed: onPermanentDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
