import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../components/zeta_empty_state.dart';
import '../../components/task_edit_pane.dart';
import '../../theme/breakpoints.dart';

class TopBarSearch {
  static Iterable<Widget> buildSuggestions(
    BuildContext context,
    M3ESearchController controller,
    NavigationProvider navProvider,
    TaskProvider taskProvider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final query = controller.text.trim();

    void safeCloseView([String? result]) {
      if (controller.isAttached && controller.isOpen) {
        controller.closeView(result);
      }
    }

    if (query.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Links',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              M3EList(
                gap: 3,
                color: colorScheme.surfaceContainerLowest,
                itemCount: 4,
                onTap: (index) {
                  safeCloseView(null);
                  switch (index) {
                    case 0:
                      TaskEditPane.show(context);
                    case 1:
                      navProvider.setActivePage(PageId.bin);
                    case 2:
                      navProvider.setActivePage(PageId.pomodoro);
                    case 3:
                      navProvider.setActivePage(PageId.settings);
                  }
                },
                itemBuilder: (context, index) => switch (index) {
                  0 => const M3EListItem(
                    leading: Icon(Icons.add_circle_outline_rounded),
                    headline: 'New Task',
                    supportingText: 'Create a new task or note  [N]',
                  ),
                  1 => M3EListItem(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Bin',
                    supportingText: 'Recycle bin and archived tasks',
                  ),
                  2 => M3EListItem(
                    leading: Icon(
                      Icons.timer_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Pomodoro Timer',
                    supportingText: 'Focus intervals and session tracker',
                  ),
                  _ => M3EListItem(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Settings',
                    supportingText: 'Customize theme, typography and sync',
                  ),
                },
              ),
              if (!ZetaWindowSizeClass.of(context).isCompact) ...[
                const SizedBox(height: 12),
                Text(
                  'Keyboard Shortcuts',
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _shortcutTag('Search', '/', colorScheme),
                    _shortcutTag('New Task', 'N', colorScheme),
                    _shortcutTag('Refresh', 'R', colorScheme),
                    _shortcutTag('Dismiss', 'Esc', colorScheme),
                  ],
                ),
              ],
            ],
          ),
        ),
      ];
    }

    final matchingTasks = taskProvider.searchTasks(query);
    final matchingBinTasks = taskProvider.searchBinTasks(query);
    final widgets = <Widget>[];

    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: M3EList(
          gap: 3,
          color: colorScheme.surfaceContainerLowest,
          itemCount: 2,
          onTap: (index) {
            if (index == 0) {
              safeCloseView(query);
              taskProvider.setSearchQuery(query);
              navProvider.setActivePage(PageId.tasks);
            } else {
              safeCloseView(null);
              TaskEditPane.show(context, initialTitle: query);
            }
          },
          itemBuilder: (context, index) => index == 0
              ? M3EListItem(
                  leading: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                  ),
                  headline: 'Search all for "$query"',
                  supportingText:
                      'Filter Tasks page • ${matchingTasks.length} found',
                )
              : M3EListItem(
                  leading: Icon(
                    Icons.add_task_rounded,
                    color: colorScheme.primary,
                  ),
                  headline: 'Create task "$query"',
                ),
        ),
      ),
    );

    if (matchingTasks.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Tasks (${matchingTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final qLower = query.toLowerCase();
      final taskList = matchingTasks.take(15).toList();
      final taskTiles = <Widget>[];
      for (final task in taskList) {
        String? snippet;
        if (task.description != null &&
            task.description!.toLowerCase().contains(qLower)) {
          final desc = task.description!;
          final idx = desc.toLowerCase().indexOf(qLower);
          final start = (idx - 15).clamp(0, desc.length);
          final end = (idx + query.length + 25).clamp(0, desc.length);
          final prefix = start > 0 ? '…' : '';
          final suffix = end < desc.length ? '…' : '';
          snippet =
              'Note: $prefix${desc.substring(start, end).replaceAll('\n', ' ')}$suffix';
        } else {
          final matchedSubtask = task.subtasks
              .where((s) => s.title.toLowerCase().contains(qLower))
              .firstOrNull;
          if (matchedSubtask != null) {
            snippet = 'Subtask: ${matchedSubtask.title}';
          } else if (task.dueDate != null) {
            snippet =
                'Due: ${task.dueDate}${task.hasTime && task.dueTime != null ? ' at ${task.dueTime}' : ''}';
          } else if (task.subtasks.isNotEmpty) {
            final compSub = task.subtasks.where((s) => s.completed).length;
            snippet = '$compSub/${task.subtasks.length} subtasks completed';
          }
        }

        taskTiles.add(
          M3EListItem(
            leading: Icon(
              task.completed
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: task.completed
                  ? const Color(0xFF10B981)
                  : colorScheme.onSurfaceVariant,
            ),
            headline: task.title,
            supportingText: snippet,
            trailing: task.dueDate != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.dueDate!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  )
                : null,
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: taskTiles.length,
            onTap: (index) {
              safeCloseView(null);
              TaskEditPane.show(context, task: taskList[index]);
            },
            itemBuilder: (context, index) => taskTiles[index],
          ),
        ),
      );
    }

    if (matchingBinTasks.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Bin (${matchingBinTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final binTiles = <Widget>[];
      for (final binTask in matchingBinTasks.take(5)) {
        binTiles.add(
          M3EListItem(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.error,
              size: 20,
            ),
            headline: binTask.title,
            supportingText: 'In Bin (Deleted)',
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: binTiles.length,
            onTap: (index) {
              safeCloseView(null);
              navProvider.setActivePage(PageId.bin);
            },
            itemBuilder: (context, index) => binTiles[index],
          ),
        ),
      );
    }

    if (matchingTasks.isEmpty && matchingBinTasks.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ZetaEmptyState.search(
            query: query,
            subtitle: 'Tap "Create task" above to add it to your list.',
            size: ZetaEmptyStateSize.compact,
          ),
        ),
      );
    }

    return widgets;
  }

  static Widget _shortcutTag(String label, String keyChar, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              keyChar,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


