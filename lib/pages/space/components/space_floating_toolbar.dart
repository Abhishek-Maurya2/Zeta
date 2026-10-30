import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../providers/space_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../components/glass_surface.dart';
import '../../../utils/haptics.dart';

/// Refined top floating toolbar for the Space mindmap canvas (Back Navigation & Mindmap Selector).
class SpaceFloatingToolbar extends StatelessWidget {
  const SpaceFloatingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final navProvider = context.watch<NavigationProvider>();
    final activeMap = provider.activeMindMap;

    // React to global theme changes via ThemeProvider and ZetaContextX
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    final isCompact = context.isCompact;

    final dropdownItems = provider.mindMaps.map((map) {
      return M3EDropdownItem<String>(
        label: map.title,
        value: map.id,
        selected: map.id == activeMap?.id,
      );
    }).toList();

    if (dropdownItems.isEmpty && !navProvider.canPop) {
      return const SizedBox.shrink();
    }

    return GlassSurface(
      borderRadius: BorderRadius.circular(32),
      blurSigma: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color:  colorScheme.tertiaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (navProvider.canPop) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Back',
                onPressed: () {
                  ZetaHaptics.light();
                  navProvider.pop();
                },
              ),
            ],
            if (dropdownItems.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? 250 : 280,
                  minWidth: 250,
                ),
                child: M3EDropdownMenu<String>(
                  key: ValueKey('${activeMap?.id}_$isDark'),
                  items: dropdownItems,
                  singleSelect: true,
                  searchEnabled: true,
                  dropdownStyle: M3EDropdownPanelStyle(
                    backgroundColor: colorScheme.tertiaryContainer,
                  ),
                  fieldStyle: M3EDropdownFieldStyle(
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                  ),
                  chipStyle: M3EDropdownChipStyle(
                    backgroundColor: colorScheme.tertiary,
                    labelStyle: TextStyle(color: colorScheme.onTertiary),
                    deleteIcon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colorScheme.onTertiary,
                    ),
                  ),
                  itemStyle: M3EDropdownItemStyle(
                    backgroundColor: colorScheme.surfaceContainerLowest,
                    selectedBackgroundColor: colorScheme.onTertiaryContainer,
                    selectedTextColor: colorScheme.tertiaryContainer,
                  ),
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      ZetaHaptics.selection();
                      provider.selectMindMap(selected.first.value);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
