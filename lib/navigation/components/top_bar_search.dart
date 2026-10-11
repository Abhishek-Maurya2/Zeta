import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../models/task.dart';
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: M3ESearchAnchor(
            searchController: searchController,
            builder: (BuildContext context, M3ESearchController controller) {
              return M3ESearchBar(
                controller: controller,
                margin: isCompact ? 6 : null,
                focusedMargin: isCompact ? 0 : null,
                leading: isCompact
                    ? const SizedBox(width: 1)
                    : const Icon(M3EIcons.search_rounded),
                readOnly: true,
                alignment: AlignmentDirectional.center,
                wrapActions: false,
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
                    M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        ZetaHaptics.light();
                        searchController.clear();
                        taskProvider.clearSearchQuery();
                      },
                    ),
                  // Keyboard shortcut badge [/] — non-compact only, hidden when searching
                  if (!isCompact &&
                      taskProvider.searchQuery.isEmpty &&
                      searchController.text.isEmpty)
                    Tooltip(
                      message: 'Press / to search',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          '/',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'RobotoMono',
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  // Theme Switch Icon Button Standard inside SearchBar
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
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

    final isCompact = ZetaWindowSizeClass.of(context).isCompact;

    if (query.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: isCompact ? 4 : 12,
          ),
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
              M3EList(
                gap: 3,
                color: colorScheme.surfaceContainerLowest,
                itemCount: 3,
                onTap: (index) {
                  safeCloseView(null);
                  switch (index) {
                    case 0:
                      TaskEditPane.show(context);
                    case 1:
                      navProvider.setActivePage(PageId.bin);
                    case 2:
                      navProvider.setActivePage(PageId.settings);
                  }
                },
                itemBuilder: (context, index) => switch (index) {
                  0 => const M3EListItem(
                    leading: Icon(Icons.add_circle_outline_rounded),
                    headline: 'New Task',
                  ),
                  1 => M3EListItem(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Bin',
                  ),
                  _ => M3EListItem(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Settings',
                  ),
                },
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
                  spacing: 4,
                  runSpacing: 4,
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
    final activeTasks = matchingTasks.where((t) => !t.completed).toList();
    final completedTasks = matchingTasks.where((t) => t.completed).toList();

    int scoreTask(Task task) {
      final q = query.toLowerCase();
      final title = task.title.toLowerCase();
      int score = 0;
      if (title == q) {
        score += 1000;
      } else if (title.startsWith(q)) {
        score += 800;
      } else {
        final words = title.split(RegExp(r'\s+'));
        if (words.any((w) => w.startsWith(q))) {
          score += 600;
        } else if (title.contains(q)) {
          score += 400;
        }
      }
      for (final subtask in task.subtasks) {
        final subTitle = subtask.title.toLowerCase();
        if (subTitle == q) {
          score += 300;
        } else if (subTitle.startsWith(q)) {
          score += 250;
        } else if (subTitle.contains(q)) {
          score += 200;
        }
      }
      if (task.description != null) {
        final desc = task.description!.toLowerCase();
        if (desc.startsWith(q)) {
          score += 150;
        } else if (desc.contains(q)) {
          score += 100;
        }
      }
      if (task.dueDate != null && task.dueDate!.toLowerCase().contains(q)) {
        score += 50;
      }
      return score;
    }

    int compareTasks(Task a, Task b) {
      final sA = scoreTask(a);
      final sB = scoreTask(b);
      if (sA != sB) return sB.compareTo(sA);
      return b.updatedAt.compareTo(a.updatedAt);
    }

    final activeList = (activeTasks..sort(compareTasks)).take(5).toList();
    final completedList = (completedTasks..sort(compareTasks)).take(5).toList();
    final binList = (matchingBinTasks..sort(compareTasks)).take(5).toList();

    final widgets = <Widget>[];

    widgets.add(
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4 : 12,
          vertical: isCompact ? 4 : 12,
        ),
        child: M3EList(
          gap: 3,
          color: colorScheme.surfaceContainerLowest,
          itemCount: 2,
          onTap: (index) {
            if (index == 0) {
              safeCloseView(query);
              taskProvider.setSearchQuery(query);
              navProvider.setActivePage(PageId.tasks);
            } else {
              safeCloseView(null);
              TaskEditPane.show(context, initialTitle: query);
            }
          },
          itemBuilder: (context, index) => index == 0
              ? M3EListItem(
                  leading: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                  ),
                  headline: 'Search all for \'$query\'',
                  supportingText: '${matchingTasks.length} found',
                )
              : M3EListItem(
                  leading: Icon(
                    Icons.add_task_rounded,
                    color: colorScheme.primary,
                  ),
                  headline: 'Create task \'$query\'',
                ),
        ),
      ),
    );

    final qLower = query.toLowerCase();

    M3EListItem buildTaskTile(Task task) {
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
      }

      return M3EListItem(
        leading: Icon(
          task.completed
              ? Icons.check_rounded
              : Icons.radio_button_unchecked_rounded,
          color: task.completed
              ? const Color(0xFF10B981)
              : colorScheme.onSurfaceVariant,
        ),
        headline: task.title,
        supportingText: snippet,
        trailing: task.dueDate != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.dueDate!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              )
            : null,
      );
    }

    if (activeList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: Text(
            'Tasks (${activeTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final taskTiles = activeList.map(buildTaskTile).toList();
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: taskTiles.length,
            onTap: (index) {
              safeCloseView(null);
              TaskEditPane.show(context, task: activeList[index]);
            },
            itemBuilder: (context, index) => taskTiles[index],
          ),
        ),
      );
    }

    if (completedList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: Text(
            'Completed (${completedTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final completedTiles = completedList.map(buildTaskTile).toList();
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: completedTiles.length,
            onTap: (index) {
              safeCloseView(null);
              TaskEditPane.show(context, task: completedList[index]);
            },
            itemBuilder: (context, index) => completedTiles[index],
          ),
        ),
      );
    }

    if (binList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
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
      for (final binTask in binList) {
        binTiles.add(
          M3EListItem(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.error,
            ),
            headline: binTask.title,
          ),
        );
      }

      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: binTiles.length,
            onTap: (index) {
              safeCloseView(null);
              navProvider.setActivePage(PageId.bin);
            },
            itemBuilder: (context, index) => binTiles[index],
          ),
        ),
      );
    }

    if (activeTasks.isEmpty &&
        completedTasks.isEmpty &&
        matchingBinTasks.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
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
          const SizedBox(width: 6),
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
