import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/haptics.dart';
import '../../components/zeta_empty_state.dart';
import '../../components/task_edit_pane.dart';
import '../../theme/breakpoints.dart';

class TopBarSearch extends StatelessWidget {
  final M3ESearchController searchController;

  const TopBarSearch({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCompact = ZetaWindowSizeClass.of(context).isCompact;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSearchOpen = searchController.isAttached && searchController.isOpen;
    if (!isSearchOpen && searchController.text != taskProvider.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentlyOpen =
            searchController.isAttached && searchController.isOpen;
        if (!currentlyOpen &&
            searchController.text != taskProvider.searchQuery) {
          searchController.text = taskProvider.searchQuery;
        }
      });
    }

    return Expanded(
      child: ClipRect(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: M3ESearchAnchor(
              searchController: searchController,
              builder: (BuildContext context, M3ESearchController controller) {
                return M3ESearchBar(
                  controller: controller,
                  leading: isCompact
                      ? null
                      : const Icon(
                          M3EIcons.search,
                          fontWeight: FontWeight.bold,
                        ),
                  readOnly: true,
                  hintText: isCompact
                      ? 'Search'
                      : 'Search Tasks, Notes, Subjects',
                  onTap: () {
                    if (!controller.isOpen) {
                      controller.openView();
                    }
                  },
                  onSubmitted: (query) {
                    final trimmed = query.trim();
                    if (trimmed.isNotEmpty) {
                      taskProvider.setSearchQuery(trimmed);
                      navProvider.setActivePage(PageId.tasks);
                      if (controller.isAttached && controller.isOpen) {
                        controller.closeView(trimmed);
                      }
                    }
                  },
                  trailing: [
                    if (taskProvider.searchQuery.isNotEmpty ||
                        searchController.text.isNotEmpty)
                      Tooltip(
                        message: 'Clear search',
                        child: M3EIconButton(
                          variant: M3EIconButtonVariant.standard,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            ZetaHaptics.light();
                            searchController.clear();
                            taskProvider.clearSearchQuery();
                          },
                        ),
                      ),
                    // Theme Switch Icon Button Standard inside SearchBar
                    M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      tooltip: isDark
                          ? 'Switch to light theme'
                          : 'Switch to dark theme',
                      icon: Icon(
                        fontWeight: FontWeight.bold,
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      onPressed: () {
                        ZetaHaptics.light();
                        themeProvider.toggleTheme(isDark);
                      },
                    ),
                  ],
                );
              },
              suggestionsBuilder: (context, controller) {
                return _buildSearchSuggestions(
                  context,
                  controller,
                  navProvider,
                  taskProvider,
                  textTheme,
                  colorScheme,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Iterable<Widget> _buildSearchSuggestions(
    BuildContext context,
    M3ESearchController controller,
    NavigationProvider navProvider,
    TaskProvider taskProvider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final query = controller.text.trim();

    void safeCloseView([String? result]) {
      if (controller.isAttached && controller.isOpen) {
        controller.closeView(result);
      }
    }

    if (query.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Links',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  M3EListItem(
                    leading: const Icon(Icons.add_circle_outline_rounded),
                    headline: 'New Task',
                    supportingText: 'Create a new task or note  [N]',
                    onTap: () {
                      safeCloseView(null);
                      TaskEditPane.show(context);
                    },
                  ),
                  M3EListItem(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Bin',
                    supportingText: 'Recycle bin and archived tasks',
                    onTap: () {
                      safeCloseView(null);
                      navProvider.setActivePage(PageId.bin);
                    },
                  ),
                  M3EListItem(
                    leading: Icon(
                      Icons.timer_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Pomodoro Timer',
                    supportingText: 'Focus intervals and session tracker',
                    onTap: () {
                      safeCloseView(null);
                      navProvider.setActivePage(PageId.pomodoro);
                    },
                  ),
                  M3EListItem(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Settings',
                    supportingText: 'Customize theme, typography and sync',
                    onTap: () {
                      safeCloseView(null);
                      navProvider.setActivePage(PageId.settings);
                    },
                  ),
                ],
              ),
              if (!ZetaWindowSizeClass.of(context).isCompact) ...[
                const SizedBox(height: 12),
                Text(
                  'Keyboard Shortcuts',
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _shortcutTag('Search', '/', colorScheme),
                    _shortcutTag('New Task', 'N', colorScheme),
                    _shortcutTag('Refresh', 'R', colorScheme),
                    _shortcutTag('Dismiss', 'Esc', colorScheme),
                  ],
                ),
              ],
            ],
          ),
        ),
      ];
    }

    final matchingTasks = taskProvider.searchTasks(query);
    final matchingBinTasks = taskProvider.searchBinTasks(query);
    final widgets = <Widget>[];

    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            M3EListItem(
              leading: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
              ),
              headline: 'Search all for "$query"',
              supportingText:
                  'Filter Tasks page • ${matchingTasks.length} found',
              onTap: () {
                safeCloseView(query);
                taskProvider.setSearchQuery(query);
                navProvider.setActivePage(PageId.tasks);
              },
            ),
            M3EListItem(
              leading: Icon(
                Icons.add_task_rounded,
                color: colorScheme.primary,
              ),
              headline: 'Create task "$query"',
              onTap: () {
                safeCloseView(null);
                TaskEditPane.show(context, initialTitle: query);
              },
            ),
          ],
        ),
      ),
    );

    if (matchingTasks.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Tasks (${matchingTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final qLower = query.toLowerCase();
      final taskTiles = <Widget>[];
      for (final task in matchingTasks.take(15)) {
        String? snippet;
        if (task.description != null &&
            task.description!.toLowerCase().contains(qLower)) {
          final desc = task.description!;
          final idx = desc.toLowerCase().indexOf(qLower);
          final start = (idx - 15).clamp(0, desc.length);
          final end = (idx + query.length + 25).clamp(0, desc.length);
          final prefix = start > 0 ? '…' : '';
          final suffix = end < desc.length ? '…' : '';
          snippet =
              'Note: $prefix${desc.substring(start, end).replaceAll('\n', ' ')}$suffix';
        } else {
          final matchedSubtask = task.subtasks
              .where((s) => s.title.toLowerCase().contains(qLower))
              .firstOrNull;
          if (matchedSubtask != null) {
            snippet = 'Subtask: ${matchedSubtask.title}';
          } else if (task.dueDate != null) {
            snippet =
                'Due: ${task.dueDate}${task.hasTime && task.dueTime != null ? ' at ${task.dueTime}' : ''}';
          } else if (task.subtasks.isNotEmpty) {
            final compSub = task.subtasks.where((s) => s.completed).length;
            snippet = '$compSub/${task.subtasks.length} subtasks completed';
          }
        }

        taskTiles.add(
          M3EListItem(
            leading: Icon(
              task.completed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: task.completed
                  ? const Color(0xFF10B981)
                  : colorScheme.onSurfaceVariant,
            ),
            headline: task.title,
            supportingText: snippet,
            trailing: task.dueDate != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.dueDate!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              safeCloseView(null);
              TaskEditPane.show(context, task: task);
            },
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: taskTiles,
          ),
        ),
      );
    }

    if (matchingBinTasks.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Bin (${matchingBinTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final binTiles = <Widget>[];
      for (final binTask in matchingBinTasks.take(5)) {
        binTiles.add(
          M3EListItem(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.error,
              size: 20,
            ),
            headline: binTask.title,
            supportingText: 'In Bin (Deleted)',
            onTap: () {
              safeCloseView(null);
              navProvider.setActivePage(PageId.bin);
            },
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: binTiles,
          ),
        ),
      );
    }

    if (matchingTasks.isEmpty && matchingBinTasks.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ZetaEmptyState.search(
            query: query,
            subtitle: 'Tap "Create task" above to add it to your list.',
            size: ZetaEmptyStateSize.compact,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _shortcutTag(String label, String keyChar, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              keyChar,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
