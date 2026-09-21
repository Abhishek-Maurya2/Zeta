import 'dart:ui';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/task_edit_pane.dart';
import '../../../components/zeta_button.dart';

/// Floating action button for creating a new task on the Tasks page.
class TasksFab extends StatelessWidget {
  final bool isSelectionMode;
  final VoidCallback? onPressed;

  const TasksFab({super.key, required this.isSelectionMode, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseM3ETheme = M3ETheme.of(context);

    final glassColorScheme = baseM3ETheme.colorScheme.copyWith(
      primary: colorScheme.primaryContainer.withValues(alpha: 0.70),
      onPrimary: colorScheme.onPrimaryContainer,
      primaryContainer: colorScheme.primaryContainer.withValues(alpha: 0.70),
      onPrimaryContainer: colorScheme.onPrimaryContainer,
      secondaryContainer: colorScheme.primaryContainer.withValues(alpha: 0.70),
      onSecondaryContainer: colorScheme.onPrimaryContainer,
    );

    return Positioned(
      bottom: 28,
      right: 36,
      child: AnimatedSlide(
        offset: isSelectionMode ? const Offset(0, 2.0) : Offset.zero,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubicEmphasized,
        child: AnimatedScale(
          scale: isSelectionMode ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          child: IgnorePointer(
            ignoring: isSelectionMode,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: M3ETheme(
                      data: baseM3ETheme.copyWith(colorScheme: glassColorScheme),
                      child: ZetaExtendedFab(
                        color: M3EFabColor.primary,
                        extended: true,
                        icon: const Icon(Icons.add_rounded),
                        label: 'Add Task',
                        height: 64,
                        iconSize: 28,
                        cornerRadius: 20,
                        extendedHorizontalPadding: 30,
                        iconLabelGap: 15,
                        labelFontSize: 18,
                        labelFontWeight: FontWeight.w600,
                        elevation: 0,
                        hoverElevation: 0,
                        onPressed: onPressed ?? () => TaskEditPane.show(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

