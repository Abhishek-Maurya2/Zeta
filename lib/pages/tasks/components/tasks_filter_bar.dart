import 'package:zeta/core/core.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../providers/task_provider.dart';
import '../../../utils/haptics.dart';

/// Responsive filter button group and sort split button for the Tasks page.
class TasksFilterBar extends StatelessWidget {
  final TaskFilter filter;
  final int totalCount;
  final int pendingCount;
  final int revisionCount;
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
    required this.revisionCount,
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
        : (filter == TaskFilter.pending
              ? 1
              : (filter == TaskFilter.revision ? 2 : null));

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
          } else if (index == 2) {
            onFilterChanged(TaskFilter.revision);
          }
        },
        actions: [
          M3EButtonGroupAction(label: Text('All ($totalCount)')),
          M3EButtonGroupAction(label: Text('Pending ($pendingCount)')),
          M3EButtonGroupAction(label: Text('Revisions ($revisionCount)')),
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
          decoration: const M3ESplitButtonDecoration(
            popupDecoration: M3ESplitButtonPopupDecoration(
              elevation: 3,
            ),
          ),
          menuBuilder: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final renderBox =
                  buttonContext.findRenderObject() as RenderBox?;
              final anchor = renderBox != null
                  ? (renderBox.localToGlobal(Offset.zero) & renderBox.size)
                  : Rect.zero;
              await showM3EMenu<TaskSortOption>(
                context: buttonContext,
                anchor: anchor,
                position: M3EMenuAnchorPosition.bottomEnd,
                colorStyle: M3EMenuColorStyle.vibrant,
                selectedValue: widget.sortBy,
                preferredWidth: 200,
                children: TaskSortOption.values.map((option) {
                  return M3EMenuSelectable(
                    value: option,
                    label: widget.taskProvider.getSortLabel(option),
                    leading: Icon(
                      widget.taskProvider.getSortIcon(option),
                      size: 22,
                    ),
                    selected: option == widget.sortBy,
                    onPressed: () {
                      ZetaHaptics.selection();
                      widget.onSortChanged(option);
                    },
                  );
                }).toList(),
              );
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
