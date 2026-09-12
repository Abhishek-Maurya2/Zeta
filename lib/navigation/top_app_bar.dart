import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../utils/haptics.dart';

import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/zeta_logo.dart';
import '../widgets/user_avatar.dart';
import '../components/tasks/task_edit_pane.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    final isCompact = width < 600;
    final showBrandText = width >= 640;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.surfaceContainer
            : colorScheme.surface,
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ZetaLogo(size: 28),
                      if (showBrandText) ...[
                        const SizedBox(width: 10),
                        Text(
                          'Zeta',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // const SizedBox(width: 6),

          // ─── Center Section: M3E Search Bar with Theme Switch in Trailing ─
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: M3ESearchAnchor.bar(
                    searchController: _searchController,
                    barOverlayColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    barHintText: isCompact
                        ? 'Search'
                        : 'Search tasks, notes, subtasks',
                    barTrailing: [
                      if (!isCompact)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '/',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      // Theme Switch Icon Button Standard inside SearchBar
                      M3EIconButton(
                        variant: M3EIconButtonVariant.standard,
                        // size: M3EIconButtonSize.sm,
                        tooltip: themeProvider.themeMode == ThemeMode.dark
                            ? 'Light theme'
                            : 'Dark theme',
                        icon: Icon(
                          themeProvider.themeMode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          // size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          ZetaHaptics.light();
                          themeProvider.toggleTheme();
                        },
                      ),
                    ],
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

          // const SizedBox(width: 12),

          // ─── Trailing Section: Profile Avatar with Status Ring ───────────
          Tooltip(
            message: 'Profile: ${themeProvider.userName} • Online',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ZetaHaptics.selection();
                navProvider.setActivePage(PageId.settings);
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const UserAvatar(radius: 17, ringWidth: 2),
                    // Online status badge dot
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

    if (query.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Quick Links Header ─────────────────────────────────────
              Text(
                'QUICK LINKS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Icon(
                  Icons.add_circle_outline_rounded,
                  color: colorScheme.primary,
                ),
                title: const Text('New Task'),
                subtitle: const Text('Create a new task or note  [N]'),
                dense: true,
                onTap: () {
                  controller.closeView(null);
                  TaskEditPane.show(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('Bin (Deleted Tasks)'),
                subtitle: const Text('Recycle bin and archived tasks'),
                dense: true,
                onTap: () {
                  controller.closeView(null);
                  navProvider.setActivePage(PageId.bin);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.timer_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('Pomodoro Timer'),
                subtitle: const Text('Focus intervals and session tracker'),
                dense: true,
                onTap: () {
                  controller.closeView(null);
                  navProvider.setActivePage(PageId.pomodoro);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.settings_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('Settings & Preferences'),
                subtitle: const Text('Customize theme, typography and sync'),
                dense: true,
                onTap: () {
                  controller.closeView(null);
                  navProvider.setActivePage(PageId.settings);
                },
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // ─── Keyboard Shortcuts Hint ────────────────────────────────
              Text(
                'KEYBOARD SHORTCUTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: colorScheme.onSurfaceVariant,
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
          ),
        ),
      ];
    }

    // Query results
    return [
      ListTile(
        leading: Icon(Icons.add_rounded, color: colorScheme.primary),
        title: Text('Create task "$query"'),
        subtitle: const Text('Press Enter to create'),
        onTap: () {
          controller.closeView(null);
          TaskEditPane.show(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.search_rounded),
        title: Text('Search for "$query" in all tasks'),
        onTap: () {
          controller.closeView(query);
          navProvider.setActivePage(PageId.tasks);
        },
      ),
    ];
  }

  Widget _shortcutTag(String label, String keyChar, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              keyChar,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
