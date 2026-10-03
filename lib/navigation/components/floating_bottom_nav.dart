import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../components/task_edit_pane.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/revision_provider.dart';
import '../../utils/haptics.dart';

/// Floating bottom navigation toolbar for compact viewports.
class FloatingBottomNav extends StatelessWidget {
  final NavigationProvider navProvider;
  final bool isSelectionMode;
  final M3EToolbarScrollBehavior scrollBehavior;
  const FloatingBottomNav({
    super.key,
    required this.navProvider,
    required this.isSelectionMode,
    required this.scrollBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final isTasksPage = navProvider.activePage == PageId.tasks;

    return AnimatedSlide(
      offset: isSelectionMode ? const Offset(0, 2.0) : Offset.zero,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubicEmphasized,
      child: M3EToolbar(
        alignment: Alignment.bottomCenter,
        screenOffset: 5,
        elevation: 0.0,
        size: M3EToolbarSize.large,
        colorStyle: M3EToolbarColorStyle.vibrant,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        scrollBehavior: scrollBehavior,
        fabExpandIcon: isTasksPage ? const Icon(Icons.add_rounded) : null,
        fabExpandsToolbar: false,
        onFabPressed: isTasksPage
            ? () {
                ZetaHaptics.medium();
                TaskEditPane.show(context);
              }
            : null,
        actions: [
          M3EToolbarWidget(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: kNavDestinations
                  .where(
                    (dest) => dest.id != PageId.settings && dest.id != PageId.bin,
                  )
                  .map((dest) {
                    final isSelected = dest.id == navProvider.activePage;

                    return ToolbarNavItem(
                      destination: dest,
                      isSelected: isSelected,
                      onTap: () {
                        ZetaHaptics.selection();
                        context.read<TaskProvider>().clearSelection();

                        if (navProvider.activePage == PageId.revision &&
                            dest.id != PageId.revision) {
                          context.read<RevisionProvider>().selectSubject(null);
                        }

                        navProvider.setActivePage(dest.id);
                      },
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ToolbarNavItem extends StatelessWidget {
  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const ToolbarNavItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isSelected ? destination.selectedIcon : destination.icon,
          size: isSelected ? 26 : 24,
          color: isSelected
              ? colorScheme.onSurface
              : colorScheme.onPrimaryContainer,
        ),
        if (isSelected) ...[
          const SizedBox(width: 8),
          Text(
            destination.label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );

    final navItem = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(minWidth: isSelected ? 40 : 25),
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 15 : 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
      ),
      child: content,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Tooltip(
        message: destination.label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(80),
            onTap: onTap,
            child: isSelected
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(80),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: navItem,
                    ),
                  )
                : navItem,
          ),
        ),
      ),
    );
  }
}
