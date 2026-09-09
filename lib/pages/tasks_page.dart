import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:m3e_core/m3e_core.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';
import '../components/tasks/task_card_item.dart';
import '../components/tasks/task_context_menu.dart';
import '../components/tasks/task_edit_pane.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

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
    final taskProvider = context.watch<TaskProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    final pending = taskProvider.pendingTasks;
    final completed = taskProvider.completedTasks;
    final filter = taskProvider.filter;

    final selectedFilterIndex = filter == TaskFilter.all
        ? 0
        : (filter == TaskFilter.completed ? 1 : 2);

    final filterButtonGroup = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EToggleButtonGroup(
        type: M3EButtonGroupType.connected,
        size: M3EButtonSize.sm,
        style: M3EButtonStyle.tonal,
        selectedIndex: selectedFilterIndex,
        onSelectedIndexChanged: (index) {
          if (index == null) return;
          if (index == 0) {
            taskProvider.setFilter(TaskFilter.all);
          } else if (index == 1) {
            taskProvider.setFilter(TaskFilter.completed);
          } else if (index == 2) {
            taskProvider.setFilter(TaskFilter.pending);
          }
        },
        actions: [
          M3EToggleButtonGroupAction(
            label: Text('All (${taskProvider.totalCount})'),
          ),
          M3EToggleButtonGroupAction(
            label: Text('Completed (${completed.length})'),
          ),
          M3EToggleButtonGroupAction(
            label: Text('Pending (${pending.length})'),
          ),
        ],
      ),
    );

    final sortButton = M3ESplitButton<TaskSortOption>(
      size: M3EButtonSize.sm,
      style: M3EButtonStyle.tonal,
      leadingIcon: taskProvider.getSortIcon(taskProvider.sortBy),
      label: taskProvider.getSortLabel(taskProvider.sortBy),
      onPressed: () => taskProvider.cycleSortOption(),
      onSelected: (val) {
        taskProvider.setSortBy(val);
      },
      items: TaskSortOption.values.map((opt) {
        return M3ESplitButtonItem<TaskSortOption>(
          value: opt,
          child: taskProvider.getSortLabel(opt),
        );
      }).toList(),
    );

    return Stack(
      children: [
        // ─── Main Scrollable Content ─────────────────────────────────────────
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 36,
            vertical: 28,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Page Title
                  Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.5,
                          color: colorScheme.onSurface,
                        ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Filter & Sort Bar
                  if (isCompact) ...[
                    filterButtonGroup,
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        sortButton,
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: filterButtonGroup,
                        ),
                        const SizedBox(width: 12),
                        sortButton,
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 3. Task List Section
                  if (filter == TaskFilter.completed) ...[
                    // Completed only view
                    if (completed.isEmpty)
                      _buildEmptyState(
                        context,
                        'No completed tasks yet',
                        'Tasks marked as completed will appear here.',
                      )
                    else
                      M3ESegmentedColumn(
                        decoration: const M3ESegmentedListDecoration(
                          padding: EdgeInsets.all(1.0),
                        ),
                        color: colorScheme.surfaceContainerLow,
                        children: completed
                            .map((task) =>
                                _buildTaskItem(context, task, taskProvider))
                            .toList(),
                      ),
                  ] else if (filter == TaskFilter.pending) ...[
                    // Pending only view
                    if (pending.isEmpty)
                      _buildEmptyState(
                        context,
                        'No pending tasks',
                        'You have completed all pending tasks!',
                      )
                    else
                      M3ESegmentedColumn(
                        decoration: const M3ESegmentedListDecoration(
                          padding: EdgeInsets.all(1.0),
                        ),
                        color: colorScheme.surfaceContainerLow,
                        children: pending
                            .map((task) =>
                                _buildTaskItem(context, task, taskProvider))
                            .toList(),
                      ),
                  ] else ...[
                    // All tasks view
                    if (pending.isEmpty && completed.isNotEmpty)
                      _buildEmptyState(
                        context,
                        'No pending tasks',
                        'You have completed all pending tasks!',
                      )
                    else if (pending.isEmpty && completed.isEmpty)
                      _buildEmptyState(
                        context,
                        'No tasks yet',
                        'Click "+ Add Task" to create your first task.',
                      )
                    else if (pending.isNotEmpty)
                      M3ESegmentedColumn(
                        decoration: const M3ESegmentedListDecoration(
                          padding: EdgeInsets.all(1.0),
                        ),
                        color: colorScheme.surfaceContainerLow,
                        children: pending
                            .map((task) =>
                                _buildTaskItem(context, task, taskProvider))
                            .toList(),
                      ),

                    // Completed Section (Divider & Completed Segmented Column)
                    if (filter == TaskFilter.all && completed.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'COMPLETED (${completed.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Divider(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: 0.85,
                        child: M3ESegmentedColumn(
                          decoration: const M3ESegmentedListDecoration(
                            padding: EdgeInsets.all(1.0),
                          ),
                          color: colorScheme.surfaceContainerLow,
                          children: completed
                              .map((task) =>
                                  _buildTaskItem(context, task, taskProvider))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),

        // ─── Floating Action Button: + Add Task ──────────────────────────────
        Positioned(
          bottom: isCompact ? 84 : 28,
          right: isCompact ? 16 : 36,
          child: M3EExtendedFab(
            size: isCompact ? M3EFabSize.medium : M3EFabSize.large,
            color: M3EFabColor.tertiary,
            extended: true,
            icon: const Icon(Icons.add_rounded),
            label: 'Add Task',
            decoration: const M3EFabDecoration(pressedScale: 0.95),
            onPressed: () => TaskEditPane.show(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Task task,
    TaskProvider provider,
  ) {
    return TaskCardItem(
      key: ValueKey(task.id),
      task: task,
      isExpanded: provider.isTaskExpanded(task.id),
      onToggle: () => provider.toggleTask(task.id),
      onToggleExpand: () => provider.toggleTaskExpanded(task.id),
      onToggleSubtask: (subtaskId) =>
          provider.toggleSubtask(task.id, subtaskId),
      onTap: () => TaskEditPane.show(context, task: task),
      onContextMenu: (pos) => _showContextMenu(context, pos, task, provider),
      onDelete: () => provider.deleteTask(task.id),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
