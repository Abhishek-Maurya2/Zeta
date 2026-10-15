import 'package:zeta/core/core.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import 'components/bin_header.dart';
import '../../components/task_card_item.dart';
import 'components/empty_bin_dialog.dart';
import 'components/bin_empty_state.dart';
import '../../components/task_context_menu.dart';
import '../../theme/breakpoints.dart';
import '../../utils/haptics.dart';

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
    final colorScheme = context.colorScheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    final binTasks = taskProvider.binTasks;
    final totalCount = binTasks.length;
    final hasMore = totalCount > _initialCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAutoLoad(totalCount);
    });

    final visibleTasks = (_loadedAll || !hasMore)
        ? binTasks
        : binTasks.take(_initialCount).toList();

    if (isCompact) {
      return CustomScrollView(
        key: const ValueKey<String>('bin_compact_root'),
        slivers: [
          M3EAppBar.sliver(
            backgroundColor: colorScheme.surfaceContainerLow,
            titleText: 'Bin',
            centerTitle: true,
            variant: M3EAppBarVariant.large,
            hideMode: M3EAppBarHideMode.actions,
            leading: M3EIconButton(
              variant: M3EIconButtonVariant.standard,
              width: M3EIconButtonWidth.wide,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                ZetaHaptics.light();
                navProvider.pop();
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: ZetaBreakpoints.marginCompact,
              vertical: 8,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bin Header (actions and subtitle, title is in app bar)
                  BinHeader(
                    totalCount: totalCount,
                    showTitle: false,
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

                  const SizedBox(height: 16),

                  // 2. Task List or Empty State
                  if (totalCount > 0) ...[
                    M3EList(
                      color: colorScheme.surfaceContainerLowest,
                      itemCount: visibleTasks.length,
                      itemBuilder: (context, index) {
                        final task = visibleTasks[index];
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
                          onContextMenu: (pos) => _showContextMenu(
                            context,
                            pos,
                            task,
                            taskProvider,
                          ),
                        );
                      },
                    ),

                    // Automatic Loading Indicator
                    if (hasMore && !_loadedAll) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: M3ELoadingIndicator(
                            variant: M3ELoadingIndicatorVariant.contained,
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
        ],
      );
    }

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
                M3EList(
                  color: colorScheme.surfaceContainerLowest,
                  itemCount: visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];
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
                  },
                ),

                // ─── Automatic Loading Indicator (Visible for ≥ 3 seconds) ──
                if (hasMore && !_loadedAll) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: M3ELoadingIndicator(
                        variant: M3ELoadingIndicatorVariant.contained,
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
