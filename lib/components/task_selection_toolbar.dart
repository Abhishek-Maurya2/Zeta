import 'dart:ui';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

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
    final selectedCount = context.select<TaskProvider, int>(
      (p) => p.selectedCount,
    );

    final isSelectionMode = selectedCount > 0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSlide(
            offset: isSelectionMode ? Offset.zero : const Offset(0, 2.0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubicEmphasized,
            child: AnimatedOpacity(
              opacity: isSelectionMode ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !isSelectionMode,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: M3EToolbar(
                      alignment: Alignment.center,
                      backgroundColor: colorScheme.primaryContainer.withValues(
                        alpha: 0.7,
                      ),
                      screenOffset: 0,
                      elevation: 0.0,
                      actions: [
                        // ── Close / Cancel ──────────────────────────────────────────────────
                        M3EToolbarAction(
                          icon: Icons.close_rounded,
                          isDestructive: true,
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
                                color: colorScheme.surfaceContainerLowest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
