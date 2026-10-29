import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../models/task.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../components/m3e_custom_list_item.dart';
import '../../../components/task_card_item.dart';
import '../../../components/task_context_menu.dart';
import '../../../components/task_edit_pane.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Up Next Section:
/// - Header with checklist icon, active tasks count pill, and "View All →" link to Tasks page.
/// - Shows maximum of 3 tasks initially.
/// - Footer listitem styled like Focus card bottom bar to load 3 more tasks after showing loading indicator.
/// - Expressive empty state when no active tasks exist.
class UpNextSection extends StatefulWidget {
  final List<Task> tasks;
  final int totalCount;
  final VoidCallback? onViewAll;

  const UpNextSection({
    super.key,
    required this.tasks,
    required this.totalCount,
    this.onViewAll,
  });

  @override
  State<UpNextSection> createState() => _UpNextSectionState();
}

class _UpNextSectionState extends State<UpNextSection> {
  int _maxDisplayed = 3;
  bool _isLoading = false;

  void _loadMore() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _maxDisplayed += 3;
          _isLoading = false;
        });
      }
    });
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
      isBin: false,
      onToggleComplete: () => provider.toggleTask(task.id),
      onEdit: () => TaskEditPane.show(context, task: task),
      onDelete: () => provider.deleteTask(task.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final navProvider = context.read<NavigationProvider>();

    final visibleTasks = widget.tasks.take(_maxDisplayed).toList();
    final hasMore = widget.tasks.length > visibleTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Section Header ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Up Next',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${widget.totalCount}',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'RobotoMono',
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // "View All →" button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    widget.onViewAll ??
                    () {
                      navProvider.setActivePage(PageId.tasks);
                    },
                borderRadius: BorderRadius.circular(100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ─── List of Tasks or Empty State ────────────────────────────────────
        if (widget.tasks.isNotEmpty) ...[
          M3EList(
            color: colorScheme.surfaceContainerLowest,
            outerRadius: 28,
            innerRadius: 8,
            gap: 4,
            itemCount: visibleTasks.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (hasMore && index == visibleTasks.length) {
                return M3ECustomListItem(
                  key: const ValueKey('up_next_load_more_footer'),
                  customChild: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: M3ELoadingIndicator(
                                variant: M3ELoadingIndicatorVariant.defaultStyle,
                              ),
                            )
                          : M3EButton.icon(
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                fontWeight: FontWeight.bold,
                                size: 27,
                              ),
                              label: const Text(
                                 'More Tasks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: M3EButtonStyle.filled,
                              size: M3EButtonSize.md,
                              onPressed: _loadMore,
                            ),
                    ),
                  ),
                );
              }

              final task = visibleTasks[index];
              return Selector<TaskProvider, bool>(
                selector: (_, p) => p.isTaskExpanded(task.id),
                builder: (context, isExpanded, _) {
                  final tp = context.read<TaskProvider>();
                  return TaskCardItem(
                    key: ValueKey(task.id),
                    task: task,
                    isExpanded: isExpanded,
                    onToggle: () => tp.toggleTask(task.id),
                    onToggleExpand: () => tp.toggleTaskExpanded(task.id),
                    onToggleSubtask: (subtaskId) =>
                        tp.toggleSubtask(task.id, subtaskId, context: context),
                    onTap: () => TaskEditPane.show(context, task: task),
                    onContextMenu: (pos) =>
                        _showContextMenu(context, pos, task, tp),
                    onDelete: () => tp.deleteTask(task.id),
                  );
                },
              );
            },
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 40,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No active tasks',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your upcoming tasks will appear here for quick access.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Backwards compatibility alias for UpNextSection
typedef RecentTasksSection = UpNextSection;
