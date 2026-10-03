import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../utils/haptics.dart';

import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/revision_provider.dart';
import '../components/zeta_logo.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../components/zeta_empty_state.dart';
import '../components/task_edit_pane.dart';
import '../theme/breakpoints.dart';
import 'components/profile_avatar_menu.dart';

/// Top App Bar mirroring Sharva's header:
/// - Leading: Navigation menu toggle + Sharva logo brand + App name
/// - Center: Material 3 Expressive Search Anchor with search icon, shortcut badge [/], and standard theme switch button in trailing
/// - Trailing: Profile avatar with emerald status ring
class TopAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBarWidget({super.key});

  @override
  State<TopAppBarWidget> createState() => TopAppBarWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class TopAppBarWidgetState extends State<TopAppBarWidget> {
  late final M3ESearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = M3ESearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Opens the search bar — callable via GlobalKey from AppScaffold.
  void openSearch() {
    if (_searchController.isAttached && !_searchController.isOpen) {
      _searchController.openView();
    }
  }

  /// Closes the search bar if open.
  void closeSearch() {
    if (_searchController.isAttached && _searchController.isOpen) {
      _searchController.closeView(null);
    }
  }

  /// Whether the search view is currently open.
  bool get isSearchOpen =>
      _searchController.isAttached && _searchController.isOpen;

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final revisionProvider = context.watch<RevisionProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCompact = sizeClass.isCompact;
    final showBrandText = !isCompact;

    final isSearchOpen =
        _searchController.isAttached && _searchController.isOpen;
    if (!isSearchOpen && _searchController.text != taskProvider.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final currentlyOpen =
              _searchController.isAttached && _searchController.isOpen;
          if (!currentlyOpen &&
              _searchController.text != taskProvider.searchQuery) {
            _searchController.text = taskProvider.searchQuery;
          }
        }
      });
    }

    return Container(
      height: isCompact ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
      ),
      child: Row(
        children: [
          // ─── Leading Section: Menu Toggle & Brand ─────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompact)
                Tooltip(
                  message: navProvider.isRailExpanded
                      ? 'Collapse navigation'
                      : 'Expand navigation',
                  child: IconButton(
                    icon: Icon(
                      fontWeight: FontWeight.bold,
                      navProvider.isRailExpanded
                          ? Icons.menu_open_rounded
                          : Icons.menu_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      ZetaHaptics.light();
                      navProvider.toggleRailExpanded();
                    },
                  ),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ZetaHaptics.selection();
                  navProvider.setActivePage(PageId.home);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ZetaLogo(size: isCompact ? 37 : 45),
                      if (showBrandText) ...[
                        const SizedBox(width: 15),
                        Text(
                          'Zeta',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: isCompact ? 1 : 10),

          // ─── Center Section: M3E Search Bar with Theme Switch in Trailing ─
          Expanded(
            child: ClipRect(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: M3ESearchAnchor(
                    searchController: _searchController,
                    viewBackgroundColor: colorScheme.surfaceContainerHigh
                        .withValues(alpha: 0.65),
                    viewElevation: 0,
                    viewSurfaceTintColor: colorScheme.primaryContainer
                        .withValues(alpha: 0.5),
                    viewSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    viewShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 28 : 28),
                    ),
                    dividerColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.0,
                    ),
                    viewBuilder: (suggestions) {
                      return ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(isCompact ? 28 : 28),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 12),
                            children: suggestions.toList(),
                          ),
                        ),
                      );
                    },
                    builder:
                        (BuildContext context, M3ESearchController controller) {
                          return M3ESearchBar(
                            constraints: const BoxConstraints(minHeight: 90),
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
                            overlayColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            backgroundColor: WidgetStatePropertyAll(
                              colorScheme.surfaceContainerLowest,
                            ),
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
                                if (controller.isAttached &&
                                    controller.isOpen) {
                                  controller.closeView(trimmed);
                                }
                              }
                            },
                            trailing: [
                              if (taskProvider.searchQuery.isNotEmpty ||
                                  _searchController.text.isNotEmpty)
                                Tooltip(
                                  message: 'Clear search',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    color: colorScheme.onSurfaceVariant,
                                    onPressed: () {
                                      ZetaHaptics.light();
                                      _searchController.clear();
                                      taskProvider.clearSearchQuery();
                                    },
                                  ),
                                )
                              else if (!isCompact)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '/',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'RobotoMono',
                                      color: colorScheme.onSurfaceVariant,
                                    ),
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
                                  color: colorScheme.onSurfaceVariant,
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
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: isCompact ? 1 : 10),

          // ─── Trailing Section: Profile Avatar with Sync-Status Ring ─────
          Builder(
            builder: (context) {
              // Map sync state → ring color
              final Color syncRingColor;
              final syncError =
                  taskProvider.syncError ??
                  pomodoroProvider.syncError ??
                  revisionProvider.syncError ??
                  profileProvider.syncError;
              final isSyncing =
                  taskProvider.isSyncing ||
                  pomodoroProvider.isSyncing ||
                  revisionProvider.isSyncing ||
                  profileProvider.isSyncing;
              final allSynced =
                  taskProvider.lastSyncedAt != null &&
                  pomodoroProvider.lastSyncedAt != null &&
                  revisionProvider.lastSyncedAt != null &&
                  profileProvider.lastSyncedAt != null;
              final String tooltipMessage;
              if (syncError != null) {
                syncRingColor = Theme.of(context).colorScheme.error;
                tooltipMessage =
                    '${profileProvider.userName} • Sync Error: $syncError';
              } else if (isSyncing) {
                syncRingColor = const Color(0xFFF59E0B); // amber — syncing
                tooltipMessage = '${profileProvider.userName} • Syncing…';
              } else if (allSynced) {
                syncRingColor = const Color(0xFF10B981); // green — synced
                tooltipMessage = '${profileProvider.userName} • Synced';
              } else {
                syncRingColor = const Color(0xFFF59E0B); // amber — pending sync
                tooltipMessage =
                    '${profileProvider.userName} • Waiting to sync';
              }

              return ProfileAvatarMenu(
                syncRingColor: syncRingColor,
                tooltipMessage: tooltipMessage,
                isCompact: isCompact,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds search suggestions with Quick Links & Shortcuts (matching Sharva)
  Iterable<Widget> _buildSearchSuggestions(
    BuildContext context,
    M3ESearchController controller,
    NavigationProvider navProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = controller.text.trim();

    void safeCloseView([String? result]) {
      if (controller.isAttached && controller.isOpen) {
        controller.closeView(result);
      }
    }

    final textTheme = Theme.of(context).textTheme;

    if (query.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Quick Links Header ─────────────────────────────────────
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
                itemCount: 4,
                itemBuilder: (context, index) => switch (index) {
                  0 => M3EListItem(
                      leading: const Icon(Icons.add_circle_outline_rounded),
                      headline: 'New Task',
                      supportingText: 'Create a new task or note  [N]',
                      onTap: () {
                        safeCloseView(null);
                        TaskEditPane.show(context);
                      },
                    ),
                  1 => M3EListItem(
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
                  2 => M3EListItem(
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
                  _ => M3EListItem(
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
                },
              ),

              if (!ZetaWindowSizeClass.of(context).isCompact) ...[
                const SizedBox(height: 12),

                // ─── Keyboard Shortcuts Hint ────────────────────────────────
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

    final taskProvider = context.read<TaskProvider>();
    final matchingTasks = taskProvider.searchTasks(query);
    final matchingBinTasks = taskProvider.searchBinTasks(query);
    final widgets = <Widget>[];

    // 1. Primary Actions (Filter Tasks page, Create task)
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: M3EList(
          itemCount: 2,
          itemBuilder: (context, index) => index == 0
              ? M3EListItem(
                  leading: Icon(Icons.search_rounded, color: colorScheme.primary),
                  headline: 'Search all for "$query"',
                  supportingText:
                      'Filter Tasks page • ${matchingTasks.length} found',
                  onTap: () {
                    safeCloseView(query);
                    taskProvider.setSearchQuery(query);
                    navProvider.setActivePage(PageId.tasks);
                  },
                )
              : M3EListItem(
                  leading: Icon(Icons.add_task_rounded, color: colorScheme.primary),
                  headline: 'Create task "$query"',
                  onTap: () {
                    safeCloseView(null);
                    TaskEditPane.show(context, initialTitle: query);
                  },
                ),
        ),
      ),
    );

    // 2. Matching Tasks
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
          child: M3EList(
            itemCount: taskTiles.length,
            itemBuilder: (context, index) => taskTiles[index],
          ),
        ),
      );
    }

    // 3. Matching Bin Tasks
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
          child: M3EList(
            itemCount: binTiles.length,
            itemBuilder: (context, index) => binTiles[index],
          ),
        ),
      );
    }

    // 5. Empty State
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
