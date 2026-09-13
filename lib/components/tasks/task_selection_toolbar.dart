import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/task_provider.dart';
import '../../utils/haptics.dart';

/// Floating selection toolbar that slides into view when one or more tasks
/// are selected on the Tasks page.
///
/// Built entirely with M3E components:
/// - [M3EToolbar] floating pill container
/// - [M3EToolbarAction]  for icon actions (close, select-all, complete, delete)
/// - [M3EToolbarWidget]  for the animated selection count chip
class TaskSelectionToolbar extends StatelessWidget {
  final TaskProvider taskProvider;

  const TaskSelectionToolbar({super.key, required this.taskProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCount = taskProvider.selectedCount;
    final visibleTasks = taskProvider.filteredAndSortedTasks;
    final allSelected =
        visibleTasks.isNotEmpty && selectedCount >= visibleTasks.length;

    return M3EToolbar(
      alignment: Alignment.bottomCenter,
      colorStyle: M3EToolbarColorStyle.vibrant,
      size: M3EToolbarSize.large,
      padding: EdgeInsets.fromLTRB(2, 4, 2, 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$selectedCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),

        // ── Select All / Deselect All ────────────────────────────────────────
        // M3EToolbarAction(
        //   icon: allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
        //   tooltip: allSelected ? 'Deselect All' : 'Select All',
        //   onPressed: () {
        //     ZetaHaptics.selection();
        //     if (allSelected) {
        //       taskProvider.clearSelection();
        //     } else {
        //       taskProvider.selectAllTasks();
        //     }
        //   },
        // ),

        // ── Mark Complete ────────────────────────────────────────────────────
        M3EToolbarAction(
          icon: Icons.check_circle_outline_rounded,
          // label: 'Complete',
          tooltip: 'Mark as Complete',
          // active: true,
          onPressed: () {
            ZetaHaptics.medium();
            taskProvider.completeSelectedTasks();
          },
        ),

        // ── Delete (Move to Bin) ─────────────────────────────────────────────
        M3EToolbarAction(
          icon: Icons.delete_outline_rounded,
          // label: 'Delete',
          tooltip: 'Move to Bin',
          // active: true,
          isDestructive: true,
          onPressed: () {
            ZetaHaptics.medium();
            taskProvider.deleteSelectedTasks();
          },
        ),
      ],
    );
  }
}
