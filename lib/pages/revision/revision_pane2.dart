import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/revision_provider.dart';
import '../../providers/task_provider.dart';
import 'components/revision_topic_tile.dart';
import 'components/topic_edit_dialog.dart';
import '../../utils/haptics.dart';
import '../../components/segmented_column.dart';

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

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: topics.length,
      onReorderItem: (oldIndex, newIndex) {
        ZetaHaptics.medium();
        revProvider.reorderTopic(selectedSubject.id, oldIndex, newIndex);
      },
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? animChild) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final elevation = 6.0 * animValue;
            return Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(16),
              shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
              color: colorScheme.surfaceContainerLowest,
              child: animChild,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final topic = topics[index];
        final borderRadius = _getSegmentedBorderRadius(index, topics.length);

        return Padding(
          key: ValueKey(topic.id),
          padding: EdgeInsets.only(
            bottom: index == topics.length - 1 ? 0 : 3,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: colorScheme.surfaceContainerLowest,
              child: RevisionTopicTile(
                topic: topic,
                index: index,
                canReorder: topics.length > 1,
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
                    await revProvider.deleteTopic(topic.id, taskProvider);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  BorderRadius _getSegmentedBorderRadius(int index, int total) {
    const outer = Radius.circular(24.0);
    const inner = Radius.circular(4.0);
    if (total <= 1) return const BorderRadius.all(outer);
    if (index == 0) {
      return const BorderRadius.only(
        topLeft: outer,
        topRight: outer,
        bottomLeft: inner,
        bottomRight: inner,
      );
    }
    if (index == total - 1) {
      return const BorderRadius.only(
        topLeft: inner,
        topRight: inner,
        bottomLeft: outer,
        bottomRight: outer,
      );
    }
    return const BorderRadius.all(inner);
  }
}

/// Convenience alias for [RevisionPane2].
typedef RevisionTopicsPane = RevisionPane2;
