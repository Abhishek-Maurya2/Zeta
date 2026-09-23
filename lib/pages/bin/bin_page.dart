import 'dart:async';
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

/// Recycle bin page showing deleted tasks, initially loading 10 at a time
/// and displaying [M3ELoadingIndicator] for at least 3 seconds before loading the rest.
class BinPage extends StatefulWidget {
  const BinPage({super.key});

  @override
  State<BinPage> createState() => _BinPageState();
}

class _BinPageState extends State<BinPage> {
  static const int _initialCount = 10;
  static const Duration _minLoadingDuration = Duration(seconds: 3);

  bool _loadedAll = false;
  bool _isLoading = false;
  Timer? _timer;

  void _checkAutoLoad(int totalCount) {
    if (totalCount > _initialCount && !_loadedAll && !_isLoading) {
      _isLoading = true;
      _timer?.cancel();
      _timer = Timer(_minLoadingDuration, () {
        if (!mounted) return;
        setState(() {
          _loadedAll = true;
          _isLoading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
    final hasMore = totalCount > _initialCount;

    _checkAutoLoad(totalCount);

    final visibleTasks = (_loadedAll || !hasMore)
        ? binTasks
        : binTasks.take(_initialCount).toList();

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
                onRestoreAll: () {
                  setState(() => _loadedAll = false);
                  taskProvider.restoreAllFromBin();
                },
                onRequestEmptyBin: () async {
                  final confirmed = await EmptyBinDialog.show(
                    context,
                    totalCount,
                  );
                  if (confirmed == true) {
                    setState(() => _loadedAll = false);
                    await taskProvider.emptyBin();
                  }
                },
              ),

              const SizedBox(height: 24),

              // 2. Task List or Empty State
              if (totalCount > 0) ...[
                M3ESegmentedColumn(
                  decoration: const M3ESegmentedListDecoration(
                    padding: EdgeInsets.all(1.0),
                  ),
                  color: colorScheme.surfaceContainerLowest,
                  children: visibleTasks.map((task) {
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
                ),

                // ─── Automatic Loading Indicator (Visible for ≥ 3 seconds) ──
                if (hasMore && !_loadedAll) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: M3ELoadingIndicator(
                        variant: M3ELoadingIndicatorVariant.contained,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ] else
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
