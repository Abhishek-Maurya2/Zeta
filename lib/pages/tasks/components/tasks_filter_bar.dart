import 'package:material_symbols_icons/symbols.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/core/core.dart';

import '../../../components/glass_m3e_menu.dart';
import '../../../providers/task_provider.dart';
import '../../../utils/haptics.dart';

/// Responsive filter button group and sort split button for the Tasks page.
class TasksFilterBar extends StatelessWidget {
  final TaskFilter filter;
  final int totalCount;
  final int pendingCount;
  final TaskSortOption sortBy;
  final ValueChanged<TaskFilter> onFilterChanged;
  final ValueChanged<TaskSortOption> onSortChanged;
  final VoidCallback onCycleSort;
  final TaskProvider taskProvider;
  final bool isCompact;

  const TasksFilterBar({
    super.key,
    required this.filter,
    required this.totalCount,
    required this.pendingCount,
    required this.sortBy,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onCycleSort,
    required this.taskProvider,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    final selectedFilterIndex = filter == TaskFilter.all
        ? 0
        : (filter == TaskFilter.pending ? 1 : null);

    final filterButtonGroup = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EButtonGroup(
        type: M3EButtonGroupType.connected,
        size: M3EButtonSize.sm,
        style: M3EButtonStyle.filled,
        decoration: M3EButtonDecoration(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.tertiaryContainer;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onTertiaryContainer;
          }),
        ),
        selectedIndex: selectedFilterIndex,
        onSelectedIndexChanged: (index) {
          if (index == null) return;
          ZetaHaptics.selection();
          if (index == 0) {
            onFilterChanged(TaskFilter.all);
          } else if (index == 1) {
            onFilterChanged(TaskFilter.pending);
          }
        },
        actions: [
          M3EButtonGroupAction(label: Text('All ($totalCount)')),
          M3EButtonGroupAction(label: Text('Pending ($pendingCount)')),
        ],
      ),
    );

    final sortButton = _TasksSortSplitButton(
      sortBy: sortBy,
      taskProvider: taskProvider,
      colorScheme: colorScheme,
      onSortChanged: onSortChanged,
      onCycleSort: onCycleSort,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: filterButtonGroup),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [sortButton]),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: filterButtonGroup),
        const SizedBox(width: 12),
        sortButton,
      ],
    );
  }
}

class _TasksSortSplitButton extends StatefulWidget {
  const _TasksSortSplitButton({
    required this.sortBy,
    required this.taskProvider,
    required this.colorScheme,
    required this.onSortChanged,
    required this.onCycleSort,
  });

  final TaskSortOption sortBy;
  final TaskProvider taskProvider;
  final ColorScheme colorScheme;
  final ValueChanged<TaskSortOption> onSortChanged;
  final VoidCallback onCycleSort;

  @override
  State<_TasksSortSplitButton> createState() => _TasksSortSplitButtonState();
}

class _TasksSortSplitButtonState extends State<_TasksSortSplitButton> {
  int _buttonGeneration = 0;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        return M3ESplitButton<TaskSortOption>(
          key: ValueKey(_buttonGeneration),
          size: M3EButtonSize.sm,
          style: M3EButtonStyle.filled,
          items: const [],
          leadingIcon: widget.taskProvider.getSortIcon(widget.sortBy),
          label: widget.taskProvider.getSortLabel(widget.sortBy),
          selectedValue: widget.sortBy,
          onPressed: () {
            ZetaHaptics.light();
            widget.onCycleSort();
          },
          decoration: M3ESplitButtonDecoration(
            popupDecoration: M3ESplitButtonPopupDecoration(
              backgroundColor: widget.colorScheme.secondaryContainer.withValues(
                alpha: 0,
              ),
              elevation: 0,
            ),
          ),
          menuBuilder: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final renderBox = buttonContext.findRenderObject() as RenderBox?;
              final anchor = renderBox != null
                  ? (renderBox.localToGlobal(Offset.zero) & renderBox.size)
                  : Rect.zero;
              final isCreationSort =
                  widget.sortBy == TaskSortOption.creationDesc ||
                  widget.sortBy == TaskSortOption.creationAsc;
              final isAlphaSort =
                  widget.sortBy == TaskSortOption.az ||
                  widget.sortBy == TaskSortOption.za;

              final selected = await showGlassM3EMenu<TaskSortOption>(
                context: buttonContext,
                anchor: anchor,
                position: M3EMenuAnchorPosition.bottomEnd,
                colorStyle: M3EMenuColorStyle.vibrant,
                selectedValue: widget.sortBy,
                preferredWidth: 210,
                blurSigma: 8.0,
                children: [
                  M3EMenuSelectable(
                    value: TaskSortOption.dueDate,
                    label: widget.taskProvider.getSortLabel(TaskSortOption.dueDate),
                    leading: const Icon(Symbols.event_rounded, size: 20, fill: 1.0),
                    selected: widget.sortBy == TaskSortOption.dueDate,
                    onPressed: () {
                      ZetaHaptics.selection();
                      widget.onSortChanged(TaskSortOption.dueDate);
                    },
                  ),
                  const M3EMenuDivider(),
                  M3EMenuSubmenu(
                    label: 'Date Created',
                    leading: const Icon(Symbols.schedule_rounded, size: 20, fill: 1.0),
                    badge: isCreationSort
                        ? Text(
                            widget.taskProvider.getSortLabel(widget.sortBy),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.colorScheme.secondary,
                            ),
                          )
                        : null,
                    children: [
                      M3EMenuSelectable(
                        value: TaskSortOption.creationDesc,
                        label: widget.taskProvider.getSortLabel(TaskSortOption.creationDesc),
                        leading: const Icon(Symbols.schedule_rounded, size: 20, fill: 1.0),
                        selected: widget.sortBy == TaskSortOption.creationDesc,
                        onPressed: () {
                          ZetaHaptics.selection();
                          widget.onSortChanged(TaskSortOption.creationDesc);
                        },
                      ),
                      M3EMenuSelectable(
                        value: TaskSortOption.creationAsc,
                        label: widget.taskProvider.getSortLabel(TaskSortOption.creationAsc),
                        leading: const Icon(Symbols.history_rounded, size: 20, fill: 1.0),
                        selected: widget.sortBy == TaskSortOption.creationAsc,
                        onPressed: () {
                          ZetaHaptics.selection();
                          widget.onSortChanged(TaskSortOption.creationAsc);
                        },
                      ),
                    ],
                  ),
                  M3EMenuSubmenu(
                    label: 'Alphabetical',
                    leading: const Icon(Symbols.sort_by_alpha_rounded, size: 20, fill: 1.0),
                    badge: isAlphaSort
                        ? Text(
                            widget.taskProvider.getSortLabel(widget.sortBy),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.colorScheme.secondary,
                            ),
                          )
                        : null,
                    children: [
                      M3EMenuSelectable(
                        value: TaskSortOption.az,
                        label: widget.taskProvider.getSortLabel(TaskSortOption.az),
                        leading: const Icon(Symbols.arrow_downward_rounded, size: 20, fill: 1.0),
                        selected: widget.sortBy == TaskSortOption.az,
                        onPressed: () {
                          ZetaHaptics.selection();
                          widget.onSortChanged(TaskSortOption.az);
                        },
                      ),
                      M3EMenuSelectable(
                        value: TaskSortOption.za,
                        label: widget.taskProvider.getSortLabel(TaskSortOption.za),
                        leading: const Icon(Symbols.arrow_upward_rounded, size: 20, fill: 1.0),
                        selected: widget.sortBy == TaskSortOption.za,
                        onPressed: () {
                          ZetaHaptics.selection();
                          widget.onSortChanged(TaskSortOption.za);
                        },
                      ),
                    ],
                  ),
                ],
              );
              if (selected != null) {
                widget.onSortChanged(selected);
              }
              if (mounted) {
                setState(() => _buttonGeneration++);
              }
            });
            return const [];
          },
        );
      },
    );
  }
}
