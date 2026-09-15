import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../widgets/segmented_column.dart';
import '../widgets/zeta_button.dart';
import '../utils/haptics.dart';

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
      onSelect: () => provider.toggleTaskSelection(task.id),
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
    final isSearching = taskProvider.searchQuery.isNotEmpty;
    final totalCount = isSearching
        ? pending.length + completed.length
        : taskProvider.totalCount;

    final selectedFilterIndex = filter == TaskFilter.all
        ? 0
        : (filter == TaskFilter.completed ? 1 : 2);

    final filterButtonGroup = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EButtonGroup(
        type: M3EButtonGroupType.connected,
        size: M3EButtonSize.sm,
        style: M3EButtonStyle.tonal,
        selectedIndex: selectedFilterIndex,
        onSelectedIndexChanged: (index) {
          if (index == null) return;
          ZetaHaptics.selection();
          if (index == 0) {
            taskProvider.setFilter(TaskFilter.all);
          } else if (index == 1) {
            taskProvider.setFilter(TaskFilter.completed);
          } else if (index == 2) {
            taskProvider.setFilter(TaskFilter.pending);
          }
        },
        actions: [
          M3EButtonGroupAction(label: Text('All ($totalCount)')),
          M3EButtonGroupAction(label: Text('Completed (${completed.length})')),
          M3EButtonGroupAction(label: Text('Pending (${pending.length})')),
        ],
      ),
    );

    final sortButton = M3ESplitButton<TaskSortOption>(
      size: M3EButtonSize.sm,
      style: M3EButtonStyle.tonal,
      leadingIcon: taskProvider.getSortIcon(taskProvider.sortBy),
      label: taskProvider.getSortLabel(taskProvider.sortBy),
      selectedValue: taskProvider.sortBy,
      onPressed: () {
        ZetaHaptics.light();
        taskProvider.cycleSortOption();
      },
      onSelected: (val) {
        ZetaHaptics.selection();
        taskProvider.setSortBy(val);
      },
      decoration: M3ESplitButtonDecoration(
        menuBackgroundColor: colorScheme.tertiaryContainer,
        menuForegroundColor: colorScheme.onTertiaryContainer,
        popupDecoration: M3ESplitButtonPopupDecoration(
          backgroundColor: colorScheme.tertiaryContainer,
          selectedColor: colorScheme.tertiary,
        ),
      ),
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
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Active Search Query Banner
                  if (isSearching) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Search results for ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                children: [
                                  TextSpan(
                                    text: '"${taskProvider.searchQuery}"',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '  •  ${pending.length + completed.length} found',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSecondaryContainer
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: colorScheme.onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                            onPressed: () {
                              ZetaHaptics.light();
                              taskProvider.clearSearchQuery();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 2. Filter & Sort Bar
                  if (isCompact) ...[
                    Center(child: filterButtonGroup),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [sortButton],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: filterButtonGroup),
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
                      isSearching
                          ? ZetaEmptyState.search(
                              query: taskProvider.searchQuery,
                              subtitle:
                                  'No completed tasks match "${taskProvider.searchQuery}".',
                              onClearSearch: () =>
                                  taskProvider.clearSearchQuery(),
                            )
                          : ZetaEmptyState.tasks(
                              shapeKind: M3EShapeKind.cookie9Sided,
                              icon: Icons.check_circle_outline_rounded,
                              title: 'No completed tasks yet',
                              subtitle:
                                  'Tasks marked as completed will appear here.',
                            )
                    else
                      _buildDismissibleTaskList(
                        context,
                        completed,
                        taskProvider,
                        colorScheme,
                      ),
                  ] else if (filter == TaskFilter.pending) ...[
                    // Pending only view
                    if (pending.isEmpty)
                      isSearching
                          ? ZetaEmptyState.search(
                              query: taskProvider.searchQuery,
                              subtitle:
                                  'No pending tasks match "${taskProvider.searchQuery}".',
                              onClearSearch: () =>
                                  taskProvider.clearSearchQuery(),
                            )
                          : ZetaEmptyState.tasks(
                              shapeKind: M3EShapeKind.clover4Leaf,
                              icon: Icons.celebration_rounded,
                              title: 'No pending tasks',
                              subtitle:
                                  'You have completed all pending tasks!',
                             
                            )
                    else
                      _buildDismissibleTaskList(
                        context,
                        pending,
                        taskProvider,
                        colorScheme,
                      ),
                  ] else ...[
                    // All tasks view
                    if (pending.isEmpty && completed.isEmpty)
                      isSearching
                          ? ZetaEmptyState.search(
                              query: taskProvider.searchQuery,
                              subtitle:
                                  'No tasks match "${taskProvider.searchQuery}". Try a different keyword.',
                              onClearSearch: () =>
                                  taskProvider.clearSearchQuery(),
                            )
                          : ZetaEmptyState.tasks(
                              shapeKind: M3EShapeKind.cookie4Sided,
                              icon: Icons.assignment_outlined,
                              title: 'No tasks yet',
                              subtitle:
                                  'Get started by creating your first task or note.',
                       
                            )
                    else ...[
                      if (pending.isNotEmpty)
                        _buildDismissibleTaskList(
                          context,
                          pending,
                          taskProvider,
                          colorScheme,
                        ),

                      // Completed Section (Divider & Completed Segmented List)
                      if (completed.isNotEmpty) ...[
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
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: 0.85,
                          child: _buildDismissibleTaskList(
                            context,
                            completed,
                            taskProvider,
                            colorScheme,
                          ),
                        ),
                      ],
                    ],
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),

        // ─── Floating Action Button: + Add Task (Desktop/Tablet only; compact uses M3EToolbar FAB) ──
        if (!isCompact)
          Positioned(
            bottom: 28,
            right: 36,
            child: AnimatedSlide(
              offset: taskProvider.isSelectionMode
                  ? const Offset(0, 2.0)
                  : Offset.zero,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: AnimatedScale(
                scale: taskProvider.isSelectionMode ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                child: IgnorePointer(
                  ignoring: taskProvider.isSelectionMode,
                  child: ZetaExtendedFab(
                    color: M3EFabColor.primary,
                    extended: true,
                    icon: const Icon(Icons.add_rounded),
                    label: 'Add Task',
                    height: 64,
                    iconSize: 28,
                    cornerRadius: 15,
                    extendedHorizontalPadding: 30,
                    iconLabelGap: 15,
                    labelFontSize: 18,
                    labelFontWeight: FontWeight.w600,
                    onPressed: () => TaskEditPane.show(context),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDismissibleTaskList(
    BuildContext context,
    List<Task> tasks,
    TaskProvider provider,
    ColorScheme colorScheme,
  ) {
    return M3EDismissibleList(
      key: ValueKey(
        'dismissible_${tasks.map((t) => t.id).join('_')}_${provider.selectedTaskIds.join(',')}',
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
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
          return BorderRadius.circular(35.0);
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
                : const Color(0xFF10B981),
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
            backgroundColor: colorScheme.error,
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
        return _buildTaskItem(context, task, provider);
      },
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Task task,
    TaskProvider provider,
  ) {
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
      onContextMenu: (pos) => _showContextMenu(context, pos, task, provider),
      onDelete: () => provider.deleteTask(task.id),
    );
  }
}
