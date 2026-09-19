import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/segmented_column.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import 'components/bin_header.dart';
import '../../components/task_card_item.dart';
import 'components/empty_bin_dialog.dart';
import 'components/bin_empty_state.dart';
import '../../components/task_context_menu.dart';
import '../../theme/breakpoints.dart';

class BinPage extends StatelessWidget {
  const BinPage({super.key});

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Task task,
    TaskProvider provider,
  ) {
    TaskContextMenu.show(
      context: context,
      position: position,
      task: task,
      isBin: true,
      onRestore: () => provider.restoreTask(task.id),
      onPermanentDelete: () => provider.permanentlyDeleteTask(task.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final navProvider = context.read<NavigationProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    final binTasks = taskProvider.binTasks;
    final totalCount = binTasks.length;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact
            ? ZetaBreakpoints.marginCompact
            : ZetaBreakpoints.marginExpanded,
        vertical: 28,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Bin Header
              BinHeader(
                totalCount: totalCount,
                onRestoreAll: () => taskProvider.restoreAllFromBin(),
                onRequestEmptyBin: () async {
                  final confirmed = await EmptyBinDialog.show(
                    context,
                    totalCount,
                  );
                  if (confirmed == true) {
                    taskProvider.emptyBin();
                  }
                },
              ),

              const SizedBox(height: 24),

              // 2. Task List or Empty State
              if (totalCount > 0)
                M3ESegmentedColumn(
                  decoration: const M3ESegmentedListDecoration(
                    padding: EdgeInsets.all(1.0),
                  ),
                  color: colorScheme.surfaceContainerLowest,
                  children: binTasks.map((task) {
                    return TaskCardItem(
                      key: ValueKey(task.id),
                      task: task,
                      isDeleted: true,
                      isExpanded: taskProvider.isTaskExpanded(task.id),
                      onToggleExpand: () =>
                          taskProvider.toggleTaskExpanded(task.id),
                      onRestore: () => taskProvider.restoreTask(task.id),
                      onPermanentDelete: () =>
                          taskProvider.permanentlyDeleteTask(task.id),
                      onContextMenu: (pos) =>
                          _showContextMenu(context, pos, task, taskProvider),
                    );
                  }).toList(),
                )
              else
                BinEmptyState(
                  onNavigateToTasks: () =>
                      navProvider.setActivePage(PageId.tasks),
                ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
