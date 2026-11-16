import 'package:flutter/physics.dart';
import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../components/zeta_floating_toolbar.dart';
import '../../components/task_edit_pane.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/haptics.dart';

/// Floating bottom navigation toolbar for compact viewports.
class FloatingBottomNav extends StatefulWidget {
  final NavigationProvider navProvider;
  final bool isSelectionMode;
  final bool keepVisible;
  final bool showSelectionToolbar;
  final M3EToolbarScrollBehavior scrollBehavior;

  const FloatingBottomNav({
    super.key,
    required this.navProvider,
    required this.isSelectionMode,
    required this.scrollBehavior,
    this.keepVisible = false,
    this.showSelectionToolbar = false,
  });

  @override
  State<FloatingBottomNav> createState() => _FloatingBottomNavState();
}

class _FloatingBottomNavState extends State<FloatingBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;

  bool get _shouldHide =>
      widget.isSelectionMode ||
      widget.showSelectionToolbar ||
      widget.navProvider.activePage == PageId.settings ||
      widget.navProvider.activePage == PageId.bin ||
      widget.navProvider.activePage == PageId.space;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController.unbounded(
      vsync: this,
      value: _shouldHide ? 0.0 : 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant FloatingBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldHide = _shouldHide;
    final oldShouldHide = oldWidget.isSelectionMode ||
        oldWidget.showSelectionToolbar ||
        oldWidget.navProvider.activePage == PageId.settings ||
        oldWidget.navProvider.activePage == PageId.bin ||
        oldWidget.navProvider.activePage == PageId.space;

    if (shouldHide != oldShouldHide) {
      final target = shouldHide ? 0.0 : 1.0;
      final simulation = SpringSimulation(
        ZetaToolbarMotion.spatialSpring,
        _slideController.value,
        target,
        0.0,
      );
      _slideController.animateWith(simulation);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTasksPage = widget.navProvider.activePage == PageId.tasks;
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      bottom: 5.0 + bottomInset,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: widget.scrollBehavior.controller,
        builder: (context, child) {
          return Transform.translate(
            offset: widget.keepVisible
                ? Offset.zero
                : Offset(0, -widget.scrollBehavior.controller.offset),
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            final progress = _slideController.value;
            final isFullyHidden = progress <= 0.001 && _shouldHide;
            if (isFullyHidden) {
              return const SizedBox.shrink();
            }
            final slideY = (1.0 - progress) * 160.0;
            return Transform.translate(
              offset: Offset(0, slideY),
              child: Opacity(
                opacity: progress.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZetaFloatingToolbar.custom(
                motion: const ZetaToolbarMotion(enabled: false),
                style: ZetaToolbarStyle(
                  borderRadius: BorderRadius.circular(100),
                  backgroundColor: colorScheme.primaryContainer,
                  blurSigma: 7.0,
                  alpha: 0.50,
                  border: const Border.fromBorderSide(BorderSide.none),
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                ),
                child: M3EToolbar(
                  screenOffset: 0,
                  elevation: 0.0,
                  backgroundColor: Colors.transparent,
                  size: M3EToolbarSize.large,
                  colorStyle: M3EToolbarColorStyle.vibrant,
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  actions: [
                    M3EToolbarWidget(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: kNavDestinations
                            .where(
                              (dest) =>
                                  dest.id != PageId.settings &&
                                  dest.id != PageId.bin,
                            )
                            .map((dest) {
                              final isSelected =
                                  dest.id == widget.navProvider.activePage;

                              return ToolbarNavItem(
                                destination: dest,
                                isSelected: isSelected,
                                onTap: () {
                                  ZetaHaptics.heavy();
                                  context.read<TaskProvider>().clearSelection();
                                  widget.navProvider.setActivePage(dest.id);
                                },
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              if (isTasksPage) ...[
                const SizedBox(width: 8),
                ZetaFloatingToolbar.custom(
                  motion: const ZetaToolbarMotion(enabled: false),
                  style: ZetaToolbarStyle(
                    borderRadius: BorderRadius.circular(16),
                    backgroundColor: colorScheme.tertiaryContainer,
                    blurSigma: 7.0,
                    alpha: 0.50,
                    border: const Border.fromBorderSide(BorderSide.none),
                    padding: EdgeInsets.zero,
                  ),
                  child: FloatingActionButton(
                    elevation: 0.0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: colorScheme.onTertiaryContainer,
                    onPressed: () {
                      ZetaHaptics.medium();
                      TaskEditPane.show(context);
                    },
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
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
    final colorScheme = context.colorScheme;

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
          fill: isSelected ? 1 : 0,
          weight: 700,
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(80),
          onTap: onTap,
          child: isSelected
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child: navItem,
                )
              : navItem,
        ),
      ),
    );
  }
}
