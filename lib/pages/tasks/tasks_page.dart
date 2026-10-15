import 'package:zeta/core/core.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/task_context_menu.dart';
import '../../components/task_edit_pane.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/breakpoints.dart';
import 'components/tasks_dismissible_list.dart';
import 'components/tasks_empty_view.dart';
import 'components/tasks_filter_bar.dart';
import 'components/tasks_search_banner.dart';

/// Main page coordinator for the Tasks feature.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _fabController = M3EExtendedFabController();

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

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

  TasksDismissibleList _buildCompletedList(
    BuildContext context,
    List<Task> completed,
    TaskProvider taskProvider,
    bool embedded,
  ) {
    final displayedCount = taskProvider.completedDisplayedCount;
    final visibleTasks = completed.take(displayedCount).toList();
    final hasMore = completed.length > displayedCount;

    return TasksDismissibleList(
      tasks: visibleTasks,
      provider: taskProvider,
      onContextMenu: _showContextMenu,
      embedded: embedded,
      trailingChild: hasMore
          ? () {
              bool isLoading = false;
              return StatefulBuilder(
                builder: (context, setState) {
                  return Center(
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: M3ELoadingIndicator(
                              variant: M3ELoadingIndicatorVariant.defaultStyle,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: M3EIconButton(
                              onPressed: () {
                                setState(() => isLoading = true);
                                Future.delayed(
                                  const Duration(milliseconds: 350),
                                  () {
                                    if (context.mounted) {
                                      taskProvider.loadMoreCompletedTasks();
                                    }
                                  },
                                );
                              },
                              variant: M3EIconButtonVariant.filled,
                              width: M3EIconButtonWidth.wide,
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                size: 25,
                              ),
                              tooltip:
                                  'Load ${completed.length - displayedCount} more',
                            ),
                          ),
                  );
                },
              );
            }()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final colorScheme = context.colorScheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    final pending = taskProvider.pendingTasks;
    final pendingNonRevision = taskProvider.pendingNonRevisionTasks;
    final completed = taskProvider.completedTasks;
    final filter = taskProvider.filter;
    final isSearching = taskProvider.searchQuery.isNotEmpty;
    final revisionTasksCount = taskProvider.revisionTasks.length;
    final totalCount = pendingNonRevision.length + revisionTasksCount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: M3EExtendedFabScrollVisibility(
        controller: _fabController,
        child: SingleChildScrollView(
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
                    ? 1000
                    : 860,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Page Title
                  if (!isCompact)
                    Text(
                      'Tasks',
                      style: context.textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                          ),
                    ),

                  if (!isCompact) const SizedBox(height: 18),

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
                    pendingCount: pendingNonRevision.length,
                    revisionCount: revisionTasksCount,
                    sortBy: taskProvider.sortBy,
                    onFilterChanged: (newFilter) =>
                        taskProvider.setFilter(newFilter),
                    onSortChanged: (newSort) => taskProvider.setSortBy(newSort),
                    onCycleSort: () => taskProvider.cycleSortOption(),
                    taskProvider: taskProvider,
                    isCompact: isCompact,
                  ),

                  const SizedBox(height: 20),

                  // 3. Task List Section
                  if (filter == TaskFilter.pending) ...[
                    if (pendingNonRevision.isEmpty)
                      TasksEmptyView(
                        filter: filter,
                        isSearching: isSearching,
                        searchQuery: taskProvider.searchQuery,
                        onClearSearch: () => taskProvider.clearSearchQuery(),
                      )
                    else
                      TasksDismissibleList(
                        tasks: pendingNonRevision,
                        provider: taskProvider,
                        onContextMenu: _showContextMenu,
                      ),
                    // Completed Section
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      M3EList(
                        itemCount: 1,
                        color: colorScheme.primaryContainer,
                        expandStyle: M3EExpandableStyle(
                          expandedStateFill: false,
                          gap: 5,
                          expandedIconBackground: colorScheme.primary,
                          expandIcon: Icon(
                            Icons.expand_more_rounded,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          collapseIcon: Icon(
                            Icons.expand_more_rounded,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          return M3EListItem(
                            headline: 'Completed (${completed.length})',
                            leading: const Icon(
                              Icons.task_alt_rounded,
                              size: 20,
                              color: Color(0xFF10B981),
                            ),
                            expanded: M3EExpandableExpanded.list(
                              _buildCompletedList(
                                context,
                                completed,
                                taskProvider,
                                true,
                              ).build(context) as M3EList,
                            ),
                          );
                        },
                      ),
                    ],
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
                        )
                      else
                        TasksEmptyView(
                          filter: filter,
                          isSearching: isSearching,
                          searchQuery: taskProvider.searchQuery,
                          onClearSearch: () => taskProvider.clearSearchQuery(),
                        ),

                      // Completed Section
                      if (completed.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        M3EList(
                          itemCount: 1,
                          color: colorScheme.primaryContainer,
                          expandStyle: M3EExpandableStyle(
                            expandedStateFill: false,
                            gap: 5,
                            expandedIconBackground: colorScheme.primary,
                            expandIcon: Icon(
                              Icons.expand_more_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            collapseIcon: Icon(
                              Icons.expand_more_rounded,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            return M3EListItem(
                              headline: 'Completed (${completed.length})',
                              leading: const Icon(
                                Icons.task_alt_rounded,
                                size: 20,
                                color: Color(0xFF10B981),
                              ),
                              expanded: M3EExpandableExpanded.list(
                                _buildCompletedList(
                                  context,
                                  completed,
                                  taskProvider,
                                  true,
                                ).build(context) as M3EList,
                              ),
                            );
                          },
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
      ),
      floatingActionButton: !isCompact && !taskProvider.isSelectionMode
          ? M3EExtendedFab(
              controller: _fabController,
              appear: true,
              scaleAlignment: AlignmentDirectional.bottomEnd,
              onPressed: () => TaskEditPane.show(context),
              icon: const Icon(Icons.add_rounded),
              label: 'Add Task',
              size: M3EExtendedFabSize.small,
              color: M3EFabColor.primary,
            )
          : null,
    );
  }
}
