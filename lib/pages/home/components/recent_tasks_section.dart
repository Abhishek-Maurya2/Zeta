import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/task.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../components/task_card_item.dart';
import '../../../components/task_context_menu.dart';
import '../../../components/task_edit_pane.dart';
import '../../../components/segmented_column.dart';

/// Recent Tasks Section mirroring Sharva's RecentTasksSection:
/// - Header with checklist icon, active tasks count pill, and "View All →" link to Tasks page.
/// - Segmented column of up to 4 recent tasks with full subtask collapse, edit, and context menu support.
/// - Expressive empty state when no active tasks exist.
class RecentTasksSection extends StatelessWidget {
  final List<Task> tasks;
  final int totalCount;
  final VoidCallback? onViewAll;

  const RecentTasksSection({
    super.key,
    required this.tasks,
    required this.totalCount,
    this.onViewAll,
  });

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Task task,
    TaskProvider provider,
  ) {
    TaskContextMenu.show(
      context: context,
      position: position,
      task: task,
      isBin: false,
      onToggleComplete: () => provider.toggleTask(task.id),
      onEdit: () => TaskEditPane.show(context, task: task),
      onDelete: () => provider.deleteTask(task.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final navProvider = context.read<NavigationProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Section Header ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Recent Tasks',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // "View All →" button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onViewAll ??
                    () {
                      navProvider.setActivePage(PageId.tasks);
                    },
                borderRadius: BorderRadius.circular(100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ─── List of Tasks or Empty State ────────────────────────────────────
        if (tasks.isNotEmpty) ...[
          M3ESegmentedColumn(
            decoration: const M3ESegmentedListDecoration(
              padding: EdgeInsets.all(1.0),
              outerRadius: 24.0,
              innerRadius: 4.0,
            ),
            color: colorScheme.surfaceContainerLowest,
            children: tasks.map((task) {
              return Selector<TaskProvider, bool>(
                selector: (_, p) => p.isTaskExpanded(task.id),
                builder: (context, isExpanded, _) {
                  final tp = context.read<TaskProvider>();
                  return TaskCardItem(
                    key: ValueKey(task.id),
                    task: task,
                    isExpanded: isExpanded,
                    onToggle: () => tp.toggleTask(task.id),
                    onToggleExpand: () => tp.toggleTaskExpanded(task.id),
                    onToggleSubtask: (subtaskId) =>
                        tp.toggleSubtask(task.id, subtaskId),
                    onTap: () => TaskEditPane.show(context, task: task),
                    onContextMenu: (pos) =>
                        _showContextMenu(context, pos, task, tp),
                    onDelete: () => tp.deleteTask(task.id),
                  );
                },
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 40,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No active tasks',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recent tasks will appear here for quick access.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
