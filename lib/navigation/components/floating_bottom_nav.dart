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
  const FloatingBottomNav({super.key, required this.navProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseM3ETheme = M3ETheme.of(context);

    final isTasksPage = navProvider.activePage == PageId.tasks;

    final glassColorScheme = baseM3ETheme.colorScheme.copyWith(
      primaryContainer: colorScheme.primaryContainer.withValues(alpha: 0.50),
      secondaryContainer: colorScheme.primaryContainer.withValues(alpha: 0.50),
      tertiaryContainer: colorScheme.primaryContainer.withValues(alpha: 0.50),
      surfaceContainerHigh: colorScheme.primaryContainer.withValues(
        alpha: 0.50,
      ),
      primary: colorScheme.primaryContainer.withValues(alpha: 0.50),
      onPrimaryContainer: colorScheme.onPrimaryContainer,
      onSecondaryContainer: colorScheme.onPrimaryContainer,
      onTertiaryContainer: colorScheme.onPrimaryContainer,
      onPrimary: colorScheme.onPrimaryContainer,
    );

    final navToolbar = M3ETheme(
      data: baseM3ETheme.copyWith(
        colorScheme: glassColorScheme,
        toolbarTheme: baseM3ETheme.toolbarTheme.copyWith(containerSize: 65),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: M3EToolbar(
              alignment: Alignment.center,
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              size: M3EToolbarSize.large,
              padding: const EdgeInsets.symmetric(horizontal: 1),
              actions: [
                M3EToolbarWidget(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: kNavDestinations
                        .where(
                          (dest) =>
                              dest.id != PageId.settings && dest.id != PageId.bin,
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
                                context.read<RevisionProvider>().selectSubject(
                                  null,
                                );
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
          ),
        ),
      ),
    );

    final fabButton = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ZetaHaptics.medium();
                TaskEditPane.show(context);
              },
              child: Tooltip(
                message: 'New Task',
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 26,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IntrinsicWidth(child: navToolbar),
          if (isTasksPage) ...[const SizedBox(width: 8), fabButton],
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
      constraints: BoxConstraints(minWidth: isSelected ? 40 : 35),
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 15 : 4,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(88),
      ),
      child: content,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
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
