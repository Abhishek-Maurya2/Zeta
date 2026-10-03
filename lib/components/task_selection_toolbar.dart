import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/task_provider.dart';
import '../utils/haptics.dart';

/// Floating selection toolbar that slides into view when one or more tasks
/// are selected on the Tasks page.
///
/// Built natively with M3E components:
/// - [M3EToolbar] floating pill container
/// - [M3EToolbarAction] for icon actions (close, complete, delete)
/// - [M3EToolbarWidget] for the animated selection count chip
class TaskSelectionToolbar extends StatelessWidget {
  final TaskProvider taskProvider;

  const TaskSelectionToolbar({super.key, required this.taskProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCount = taskProvider.selectedCount;

    final isSelectionMode = selectedCount > 0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: AnimatedSlide(
        offset: isSelectionMode ? Offset.zero : const Offset(0, 2.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubicEmphasized,
        child: AnimatedOpacity(
          opacity: isSelectionMode ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !isSelectionMode,
            child: M3EToolbar(
              alignment: Alignment.center,
      colorStyle: M3EToolbarColorStyle.vibrant,
      size: M3EToolbarSize.large,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      screenOffset: 0,
      actions: [
        // ── Close / Cancel ──────────────────────────────────────────────────
        M3EToolbarAction(
          icon: Icons.close_rounded,
          tooltip: 'Cancel Selection',
          onPressed: () {
            ZetaHaptics.light();
            taskProvider.clearSelection();
          },
        ),

        // ── Selection count chip ─────────────────────────────────────────────
        M3EToolbarWidget(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Container(
              key: ValueKey(selectedCount),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onPrimaryContainer.withValues(
                    alpha: 0.20,
                  ),
                  width: 0.8,
                ),
              ),
              child: Text(
                '$selectedCount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),

        // ── Mark Complete ────────────────────────────────────────────────────
        M3EToolbarAction(
          icon: Icons.check_circle_outline_rounded,
          tooltip: 'Mark as Complete',
          onPressed: () {
            ZetaHaptics.medium();
            taskProvider.completeSelectedTasks();
          },
        ),

        // ── Delete (Move to Bin) ─────────────────────────────────────────────
        M3EToolbarAction(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Move to Bin',
          isDestructive: true,
          onPressed: () {
            ZetaHaptics.medium();
            taskProvider.deleteSelectedTasks();
          },
        ),
      ],
    )
          ),
        ),
      ),
    );
  }
}
