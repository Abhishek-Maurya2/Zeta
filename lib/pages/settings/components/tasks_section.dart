import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../providers/task_provider.dart';
import 'settings_section_heading.dart';

class TasksSection extends StatelessWidget {
  final void Function(String message)? onToast;

  const TasksSection({super.key, this.onToast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Swipe Behavior ──────────────────────────────────────────────────
            const SettingsSectionHeading('Swipe Behavior'),
            const SizedBox(height: 12),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) {
                return M3EList(
                  color: colorScheme.surfaceContainerLowest,
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return M3EListItem(
                      leading: Icon(
                        Icons.swipe_rounded,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      headline: 'Reverse Swipe Actions',
                      supportingText:
                          'Swap the left and right swipe directions for tasks',
                      trailing: M3ESwitch(
                        value: taskProvider.swapSwipeActions,
                        selectedIcon: const Icon(Icons.check_rounded),
                        unselectedIcon: const Icon(Icons.close_rounded),
                        onChanged: (val) {
                          taskProvider.setSwapSwipeActions(val);
                          onToast?.call(
                            val
                                ? 'Swipe actions reversed'
                                : 'Swipe actions restored to default',
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // ─── Sorting Preferences ───────────────────────────────────────────
            const SettingsSectionHeading('Sorting Preferences'),
            const SizedBox(height: 12),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) {
                return M3EList(
                  color: colorScheme.surfaceContainerLowest,
                  itemCount: 2,
                  gap: 3,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected =
                          taskProvider.completedSortBy ==
                          CompletedTaskSortOption.newestFirst;
                      return M3EListItem(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        headline: 'Newest First',
                        supportingText:
                            'Recently completed tasks appear at the top',
                        onTap: () {
                          taskProvider.setCompletedSortBy(
                            CompletedTaskSortOption.newestFirst,
                          );
                          onToast?.call('Completed tasks sorted newest first');
                        },
                      );
                    } else {
                      final isSelected =
                          taskProvider.completedSortBy ==
                          CompletedTaskSortOption.oldestFirst;
                      return M3EListItem(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        headline: 'Oldest First',
                        supportingText:
                            'Previously completed tasks appear at the top',
                        onTap: () {
                          taskProvider.setCompletedSortBy(
                            CompletedTaskSortOption.oldestFirst,
                          );
                          onToast?.call('Completed tasks sorted oldest first');
                        },
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
