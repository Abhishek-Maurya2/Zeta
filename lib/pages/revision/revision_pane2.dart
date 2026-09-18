import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/revision_provider.dart';
import '../../providers/task_provider.dart';
import '../../components/revision/revision_topic_tile.dart';
import '../../components/revision/topic_edit_dialog.dart';
import '../../utils/haptics.dart';
import '../../widgets/segmented_column.dart';

/// Pane 2 of Revision: Topics list for the selected subject and review actions.
class RevisionPane2 extends StatelessWidget {
  final bool isSplitPane;

  const RevisionPane2({super.key, required this.isSplitPane});

  @override
  Widget build(BuildContext context) {
    final revProvider = context.watch<RevisionProvider>();
    final taskProvider = context.read<TaskProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final selectedSubject = revProvider.selectedSubject;
    final topics = revProvider.topicsForSelectedSubject;

    if (selectedSubject == null) {
      return ZetaEmptyState(
        icon: Icons.explore_rounded,
        shapeKind: M3EShapeKind.ghostish,
        title: 'Select a subject to explore',
        subtitle: isSplitPane
            ? 'Choose a subject from the left pane to view and track its topics.'
            : 'Select a subject to view and track its topics.',
        size: ZetaEmptyStateSize.standard,
      );
    }

    if (topics.isEmpty) {
      return ZetaEmptyState.revision(
        icon: Icons.library_books_rounded,
        shapeKind: M3EShapeKind.cookie9Sided,
        title: 'No topics yet',
        subtitle: 'Add chapters or topics to start tracking spaced repetition reviews.',
        size: ZetaEmptyStateSize.standard,
        actionLabel: 'Add First Topic',
        actionIcon: Icons.add_rounded,
        onAction: () =>
            AddTopicDialog.show(context, subjectId: selectedSubject.id),
      );
    }

    return M3ESegmentedColumn(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      gap: 3,
      color: colorScheme.surfaceContainerLowest,
      children: topics.map((topic) {
        return RevisionTopicTile(
          key: ValueKey(topic.id),
          topic: topic,
          onComplete: () {
            ZetaHaptics.medium();
            revProvider.completeTopic(topic.id, taskProvider);
          },
          onEdit: () {
            ZetaHaptics.light();
            TopicEditDialog.show(context, topic: topic);
          },
          onDelete: () async {
            ZetaHaptics.light();
            final confirmed = await showDeleteConfirmationDialog(
              context: context,
              title: 'Delete Topic?',
              message:
                  'Are you sure you want to delete "${topic.title}"? This cannot be undone.',
            );
            if (confirmed == true) {
              revProvider.deleteTopic(topic.id);
            }
          },
        );
      }).toList(),
    );
  }
}

/// Convenience alias for [RevisionPane2].
typedef RevisionTopicsPane = RevisionPane2;
