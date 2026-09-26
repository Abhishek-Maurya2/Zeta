import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../providers/task_provider.dart';
import 'package:material_ui/material_ui.dart';

import '../../../components/zeta_empty_state.dart';

/// Renders contextual empty states for different task filter and search states.
class TasksEmptyView extends StatelessWidget {
  final TaskFilter filter;
  final bool isSearching;
  final String searchQuery;
  final VoidCallback onClearSearch;

  const TasksEmptyView({
    super.key,
    required this.filter,
    required this.isSearching,
    required this.searchQuery,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (filter == TaskFilter.completed) {
      if (isSearching) {
        return ZetaEmptyState.search(
          query: searchQuery,
          subtitle: 'No completed tasks match "$searchQuery".',
          onClearSearch: onClearSearch,
        );
      }
      return ZetaEmptyState.tasks(
        shapeKind: M3EShapeKind.cookie9Sided,
        icon: Icons.check_circle_outline_rounded,
        title: 'No completed tasks yet',
        subtitle: 'Tasks marked as completed will appear here.',
      );
    }

    if (filter == TaskFilter.pending) {
      if (isSearching) {
        return ZetaEmptyState.search(
          query: searchQuery,
          subtitle: 'No pending tasks match "$searchQuery".',
          onClearSearch: onClearSearch,
        );
      }
      return ZetaEmptyState.tasks(
        shapeKind: M3EShapeKind.clover4Leaf,
        icon: Icons.celebration_rounded,
        title: 'No pending tasks',
        subtitle: 'You have completed all pending tasks!',
      );
    }

    if (filter == TaskFilter.revision) {
      return ZetaEmptyState.tasks(
        shapeKind: M3EShapeKind.cookie9Sided,
        icon: Icons.sync_rounded,
        title: 'No subject tasks',
        subtitle: 'Tasks scheduled from the Subjects page will appear here.',
      );
    }

    // Default: All tasks
    if (isSearching) {
      return ZetaEmptyState.search(
        query: searchQuery,
        subtitle: 'No tasks match "$searchQuery". Try a different keyword.',
        onClearSearch: onClearSearch,
      );
    }

    return ZetaEmptyState.tasks(
      shapeKind: M3EShapeKind.cookie4Sided,
      icon: Icons.assignment_outlined,
      title: 'No tasks yet',
      subtitle: 'Get started by creating your first task or note.',
    );
  }
}
