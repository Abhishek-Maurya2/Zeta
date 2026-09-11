import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../providers/navigation_provider.dart';
import '../pages/home_page.dart';
import '../pages/tasks_page.dart';
import '../pages/revision_page.dart';
import '../pages/pomodoro_page.dart';
import '../pages/bin_page.dart';
import '../pages/settings_page.dart';
import 'top_app_bar.dart';

/// Adaptive scaffold mirroring Sharva's layout:
/// - Compact (<600px): M3EToolbar from material_3_expressive at bottom + full-width body
/// - Medium / Expanded (≥600px): M3ENavigationRail from material_3_expressive + body
/// - Top App Bar: Contains rail toggle button (hidden in mobile view)
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final isExpanded = width >= 840;

    // Top app bar visibility
    final showTopAppBar =
        isExpanded ||
        (navProvider.activePage != PageId.settings &&
            navProvider.activePage != PageId.pomodoro &&
            navProvider.activePage != PageId.revision);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              // 1. Top App Bar (contains rail toggle button, hidden on mobile)
              if (showTopAppBar) const TopAppBarWidget(),

              // 2. Main body: Rail (desktop/tablet) or Stack with Floating Toolbar (mobile)
              Expanded(
                child: isCompact
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: _BodyPane(
                              activePage: navProvider.activePage,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _FloatingBottomNav(
                                  navProvider: navProvider,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // M3E Navigation Rail from material_3_expressive (no internal toggle button)
                          _NavigationRailWidget(
                            isExpanded: navProvider.isRailExpanded,
                            navProvider: navProvider,
                          ),

                          // Body content pane
                          Expanded(
                            child: _BodyPane(
                              activePage: navProvider.activePage,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Navigation Rail (from material_3_expressive) ───────────────────────────

class _NavigationRailWidget extends StatelessWidget {
  final bool isExpanded;
  final NavigationProvider navProvider;

  const _NavigationRailWidget({
    required this.isExpanded,
    required this.navProvider,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = kNavDestinations.indexWhere(
      (d) => d.id == navProvider.activePage,
    );
    final m3eTheme = M3ETheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final railBgColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surface;

    return M3ETheme(
      data: m3eTheme.copyWith(
        navigationRailTheme: m3eTheme.navigationRailTheme.copyWith(
          containerColor: railBgColor,
          itemExpandedHeight: 52.0, // Increased height from default 40.0
          indicatorLeading:
              18.0, // Decreased inner start padding from default 16.0
          indicatorTrailing:
              10.0, // Decreased inner end padding from default 16.0
          itemVerticalGap:
              2.0, // Decreased vertical padding between items from default 4.0
        ),
      ),
      child: M3ENavigationRail(
        background: railBgColor,
        // Toggle button is in the AppBar; rail does not show its own toggle button
        type: isExpanded
            ? M3ENavigationRailType.alwaysExpand
            : M3ENavigationRailType.alwaysCollapse,
        selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
        onDestinationSelected: (index) {
          navProvider.setActivePage(kNavDestinations[index].id);
        },
        fab: M3ENavigationRailFabSlot(
          icon: const Icon(Icons.add_rounded),
          label: 'New Task',
          color: M3EFabColor.primary,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Create task modal — coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        sections: [
          M3ENavigationRailSection(
            destinations: kNavDestinations
                .map(
                  (d) => M3ENavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Floating Bottom Navigation Toolbar (from material_3_expressive) ─────────

class _FloatingBottomNav extends StatelessWidget {
  final NavigationProvider navProvider;
  const _FloatingBottomNav({required this.navProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return M3EToolbar(
      alignment: Alignment.bottomCenter,
      backgroundColor: colorScheme.primaryContainer,
      actions: [
        M3EToolbarWidget(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: kNavDestinations.map((dest) {
              final isSelected = dest.id == navProvider.activePage;
              return _ToolbarNavItem(
                destination: dest,
                isSelected: isSelected,
                onTap: () => navProvider.setActivePage(dest.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ToolbarNavItem extends StatelessWidget {
  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolbarNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 9,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.surfaceBright
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: isSelected ? 24 : 23,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onPrimaryContainer,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Text(
                    destination.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Body Pane (Page Router) ────────────────────────────────────────────────

class _BodyPane extends StatelessWidget {
  final PageId activePage;
  const _BodyPane({required this.activePage});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.expand,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildPage(activePage),
    );
  }

  Widget _buildPage(PageId page) {
    switch (page) {
      case PageId.home:
        return const HomePage(key: ValueKey('home'));
      case PageId.tasks:
        return const TasksPage(key: ValueKey('tasks'));
      case PageId.revision:
        return const RevisionPage(key: ValueKey('revision'));
      case PageId.pomodoro:
        return const PomodoroPage(key: ValueKey('pomodoro'));
      case PageId.bin:
        return const BinPage(key: ValueKey('bin'));
      case PageId.settings:
        return const SettingsPage(key: ValueKey('settings'));
    }
  }
}
