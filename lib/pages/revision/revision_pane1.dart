import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/revision.dart';
import '../../providers/revision_provider.dart';
import '../../providers/task_provider.dart';
import 'components/revision_settings_sheet.dart';
import 'components/revision_subject_card.dart';
import 'components/topic_edit_dialog.dart';
import '../../utils/haptics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../components/zeta_empty_state.dart';

/// Pane 1 of Revision: Subjects overview, summary statistics, and subject selection.
class RevisionPane1 extends StatelessWidget {
  final bool isSplitPane;
  final ValueChanged<Subject>? onSubjectSelected;
  final ValueChanged<Subject>? onOpenNotes;

  const RevisionPane1({
    super.key,
    required this.isSplitPane,
    this.onSubjectSelected,
    this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    final revProvider = context.watch<RevisionProvider>();
    final taskProvider = context.read<TaskProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subjects = revProvider.subjects;
    final selectedSubject = revProvider.selectedSubject;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subjects',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  M3EIconButton(
                    onPressed: () {
                      ZetaHaptics.light();
                      RevisionSettingsSheet.show(context);
                    },
                    variant: M3EIconButtonVariant.tonal,
                    size: M3EIconButtonSize.sm,
                    width: M3EIconButtonWidth.wide,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    tooltip: 'Revision Settings',
                  ),
                  const SizedBox(width: 6),
                  M3EIconButton(
                    onPressed: () {
                      ZetaHaptics.light();
                      AddSubjectDialog.show(context);
                    },
                    variant: M3EIconButtonVariant.filled,
                    size: M3EIconButtonSize.sm,
                    width: M3EIconButtonWidth.wide,
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 23,
                      fontWeight: FontWeight.w600,
                    ),
                    tooltip: 'Add Subject',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSummaryStrip(context, revProvider, colorScheme, textTheme),
        const SizedBox(height: 20),

        if (subjects.isEmpty)
          ZetaEmptyState.revision(
            icon: Icons.auto_stories_rounded,
            shapeKind: M3EShapeKind.cookie4Sided,
            title: 'No subjects yet',
            subtitle: 'Tap "+ Add" to create your first subject and start your study schedule.',
            size: isSplitPane
                ? ZetaEmptyStateSize.compact
                : ZetaEmptyStateSize.standard,
            actionLabel: 'Add Subject',
            actionIcon: Icons.add_rounded,
            onAction: () => AddSubjectDialog.show(context),
          )
        else
          M3EList(
            color: colorScheme.surfaceContainerLowest,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final sub = subjects[index];
              final isSelected = selectedSubject?.id == sub.id;
              final subTopics = revProvider.topics
                  .where((t) => t.subjectId == sub.id)
                  .toList();
              final completedCount = subTopics
                  .where((t) => t.isCompleted || t.isMastered)
                  .length;
              final dueCount = subTopics
                  .where((t) => t.status == RevisionStatus.overdue)
                  .length;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.secondaryContainer : null,
                  borderRadius: BorderRadius.circular(isSelected ? 52 : 12),
                ),
                child: RevisionSubjectCard(
                  key: ValueKey(sub.id),
                  subject: sub,
                  isSelected: isSelected,
                  totalTopics: subTopics.length,
                  completedTopics: completedCount,
                  dueCount: dueCount,
                  onTap: () {
                    ZetaHaptics.selection();
                    revProvider.selectSubject(sub.id);
                    onSubjectSelected?.call(sub);
                  },
                  onNotes: () {
                    ZetaHaptics.light();
                    onOpenNotes?.call(sub);
                  },
                  onEdit: () {
                    ZetaHaptics.light();
                    SubjectEditDialog.show(context, subject: sub);
                  },
                  onDelete: () async {
                    ZetaHaptics.light();
                    final confirmed = await showDeleteConfirmationDialog(
                      context: context,
                      title: 'Delete Subject?',
                      message:
                          'Are you sure you want to delete "${sub.name}" and all of its topics? This cannot be undone.',
                    );
                    if (confirmed == true) {
                      await revProvider.deleteSubject(sub.id, taskProvider);
                    }
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSummaryStrip(
    BuildContext context,
    RevisionProvider revProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            label: 'Topics',
            value: '${revProvider.totalTopicsCount}',
            icon: Icons.topic_rounded,
            color: colorScheme.primary,
          ),
          _buildStatItem(
            context,
            label: 'Due Today',
            value: '${revProvider.dueRevisionsCount}',
            icon: Icons.notifications_active_rounded,
            color: revProvider.dueRevisionsCount > 0
                ? colorScheme.error
                : colorScheme.onPrimaryContainer,
          ),
          _buildStatItem(
            context,
            label: 'Mastered',
            value: '${revProvider.masteredTopicsCount}',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Convenience alias for [RevisionPane1].
typedef RevisionSubjectsPane = RevisionPane1;
