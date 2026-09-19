import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/task_context_menu.dart';
import '../../components/task_edit_pane.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/breakpoints.dart';
import 'components/tasks_dismissible_list.dart';
import 'components/tasks_empty_view.dart';
import 'components/tasks_fab.dart';
import 'components/tasks_filter_bar.dart';
import 'components/tasks_search_banner.dart';

/// Main page coordinator for the Tasks feature.
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
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    final pending = taskProvider.pendingTasks;
    final completed = taskProvider.completedTasks;
    final filter = taskProvider.filter;
    final isSearching = taskProvider.searchQuery.isNotEmpty;
    final totalCount = isSearching
        ? pending.length + completed.length
        : taskProvider.totalCount;

    final revisionTasksCount = taskProvider.revisionTasks.length;

    return Stack(
      children: [
        // Main Scrollable Content
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact
                ? ZetaBreakpoints.marginCompact
                : ZetaBreakpoints.marginExpanded,
            vertical: 28,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: sizeClass.isLarge || sizeClass.isExtraLarge
                    ? 960
                    : 860,
              ),
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
                  if (isSearching)
                    TasksSearchBanner(
                      query: taskProvider.searchQuery,
                      foundCount: pending.length + completed.length,
                      onClear: () => taskProvider.clearSearchQuery(),
                    ),

                  // 2. Filter & Sort Bar
                  TasksFilterBar(
                    filter: filter,
                    totalCount: totalCount,
                    pendingCount: pending.length,
                    revisionCount: revisionTasksCount,
                    sortBy: taskProvider.sortBy,
                    onFilterChanged: (newFilter) =>
                        taskProvider.setFilter(newFilter),
                    onSortChanged: (newSort) =>
                        taskProvider.setSortBy(newSort),
                    onCycleSort: () => taskProvider.cycleSortOption(),
                    taskProvider: taskProvider,
                    isCompact: isCompact,
                  ),

                  const SizedBox(height: 20),

                  // 3. Task List Section
                  if (filter == TaskFilter.completed) ...[
                    if (completed.isEmpty)
                      TasksEmptyView(
                        filter: filter,
                        isSearching: isSearching,
                        searchQuery: taskProvider.searchQuery,
                        onClearSearch: () => taskProvider.clearSearchQuery(),
                      )
                    else
                      TasksDismissibleList(
                        tasks: completed,
                        provider: taskProvider,
                        onContextMenu: _showContextMenu,
                      ),
                  ] else if (filter == TaskFilter.pending) ...[
                    if (pending.isEmpty)
                      TasksEmptyView(
                        filter: filter,
                        isSearching: isSearching,
                        searchQuery: taskProvider.searchQuery,
                        onClearSearch: () => taskProvider.clearSearchQuery(),
                      )
                    else
                      TasksDismissibleList(
                        tasks: pending,
                        provider: taskProvider,
                        onContextMenu: _showContextMenu,
                      ),
                  ] else if (filter == TaskFilter.revision) ...[
                    if (taskProvider.revisionTasks.isEmpty)
                      TasksEmptyView(
                        filter: filter,
                        isSearching: isSearching,
                        searchQuery: taskProvider.searchQuery,
                        onClearSearch: () => taskProvider.clearSearchQuery(),
                      )
                    else
                      TasksDismissibleList(
                        tasks: taskProvider.revisionTasks,
                        provider: taskProvider,
                        onContextMenu: _showContextMenu,
                      ),
                  ] else ...[
                    // All tasks view
                    if (pending.isEmpty && completed.isEmpty)
                      TasksEmptyView(
                        filter: filter,
                        isSearching: isSearching,
                        searchQuery: taskProvider.searchQuery,
                        onClearSearch: () => taskProvider.clearSearchQuery(),
                      )
                    else ...[
                      if (pending.isNotEmpty)
                        TasksDismissibleList(
                          tasks: pending,
                          provider: taskProvider,
                          onContextMenu: _showContextMenu,
                        ),

                      // Completed Section
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
                          child: TasksDismissibleList(
                            tasks: completed,
                            provider: taskProvider,
                            onContextMenu: _showContextMenu,
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

        // Floating Action Button
        if (!isCompact)
          TasksFab(
            isSelectionMode: taskProvider.isSelectionMode,
            onPressed: () => TaskEditPane.show(context),
          ),
      ],
    );
  }
}
