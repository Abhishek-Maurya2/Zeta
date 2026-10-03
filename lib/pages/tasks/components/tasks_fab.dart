import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/task_edit_pane.dart';

/// Floating action button for creating a new task on the Tasks page.
class TasksFab extends StatelessWidget {
  final bool isSelectionMode;
  final VoidCallback? onPressed;

  const TasksFab({super.key, required this.isSelectionMode, this.onPressed});

  @override
  Widget build(BuildContext context) {
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
            child: M3EExtendedFab(
              color: M3EFabColor.primary,
              extended: true,
              icon: const Icon(Icons.add_rounded),
              label: 'Add Task',
              onPressed: onPressed ?? () => TaskEditPane.show(context),
            ),
          ),
        ),
      ),
    );
  }
}

