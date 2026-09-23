import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../components/task_edit_pane.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/revision_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/haptics.dart';

/// Navigation Rail widget for medium and expanded viewports.
class NavigationRailWidget extends StatelessWidget {
  final bool isExpanded;
  final NavigationProvider navProvider;

  const NavigationRailWidget({
    super.key,
    required this.isExpanded,
    required this.navProvider,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = kNavDestinations.indexWhere(
      (d) => d.id == navProvider.activePage,
    );
    final m3eTheme = M3ETheme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final railBgColor = themeProvider.navRailColor(context);

    return M3ETheme(
      data: m3eTheme.copyWith(
        colorScheme: M3EColorScheme.fromColorScheme(
          Theme.of(context).colorScheme,
        ),
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
        type: isExpanded
            ? M3ENavigationRailType.alwaysExpand
            : M3ENavigationRailType.alwaysCollapse,
        selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
        onDestinationSelected: (index) {
          ZetaHaptics.selection();
          context.read<TaskProvider>().clearSelection();
          final target = kNavDestinations[index].id;
          if (navProvider.activePage == PageId.revision &&
              target != PageId.revision) {
            context.read<RevisionProvider>().selectSubject(null);
          }
          navProvider.setActivePage(target);
        },
        fab: M3ENavigationRailFabSlot(
          icon: const Icon(Icons.add_rounded, fontWeight: FontWeight.bold),
          label: 'New Task',
          color: M3EFabColor.primary,
          onPressed: () {
            ZetaHaptics.medium();
            TaskEditPane.show(context);
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
