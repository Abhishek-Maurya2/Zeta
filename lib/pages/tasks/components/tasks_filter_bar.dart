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
    final colorScheme = Theme.of(context).colorScheme;

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
        decoration: M3EToggleButtonDecoration(
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

    final sortButton = M3ESplitButton<TaskSortOption>(
      size: M3EButtonSize.sm,
      style: M3EButtonStyle.filled,
      leadingIcon: taskProvider.getSortIcon(sortBy),
      label: taskProvider.getSortLabel(sortBy),
      selectedValue: sortBy,
      onPressed: () {
        ZetaHaptics.light();
        onCycleSort();
      },
      onSelected: (val) {
        ZetaHaptics.selection();
        onSortChanged(val);
      },
      decoration: M3ESplitButtonDecoration(
        menuBackgroundColor: colorScheme.tertiaryContainer,
        menuForegroundColor: colorScheme.onTertiaryContainer,
        popupDecoration: M3ESplitButtonPopupDecoration(
          backgroundColor: colorScheme.tertiaryContainer,
          selectedColor: colorScheme.tertiary,
          elevation: 0,
        ),
      ),
      items: TaskSortOption.values.map((opt) {
        return M3ESplitButtonItem<TaskSortOption>(
          value: opt,
          child: taskProvider.getSortLabel(opt),
        );
      }).toList(),
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
