import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../components/task_edit_pane.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    final railBgColor = themeProvider.navRailColor(context);
    final m3eTheme = M3ETheme.of(context);

    return M3ETheme(
      data: m3eTheme.copyWith(
        navigationRailTheme: m3eTheme.navigationRailTheme.copyWith(
          labelFontSize: m3eTheme.navigationRailTheme.labelFontSize + 1,
          activeLabelWeight: FontWeight.bold,
          inactiveLabelWeight: FontWeight.bold,
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
                    icon: Icon(d.icon, weight: 700),
                    selectedIcon: Icon(d.selectedIcon, fill: 1, weight: 700),
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
