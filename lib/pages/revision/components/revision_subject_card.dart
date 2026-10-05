import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../components/glass_m3e_menu.dart';
import '../../../models/revision.dart';

class RevisionSubjectCard extends StatelessWidget {
  final Subject subject;
  final bool isSelected;
  final int totalTopics;
  final int completedTopics;
  final int dueCount;
  final VoidCallback? onNotes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RevisionSubjectCard({
    super.key,
    required this.subject,
    required this.isSelected,
    required this.totalTopics,
    required this.completedTopics,
    required this.dueCount,
    this.onNotes,
    this.onEdit,
    this.onDelete,
  });

  IconData _getSubjectIcon(String name) {
    return switch (name) {
      'account_balance_rounded' => Icons.account_balance_rounded,
      'history_edu_rounded' => Icons.history_edu_rounded,
      'trending_up_rounded' => Icons.trending_up_rounded,
      'terminal_rounded' => Icons.terminal_rounded,
      'calculate_rounded' => Icons.calculate_rounded,
      'biotech_rounded' => Icons.biotech_rounded,
      'science_rounded' => Icons.science_rounded,
      'palette_rounded' => Icons.palette_rounded,
      'language_rounded' => Icons.language_rounded,
      'psychology_rounded' => Icons.psychology_rounded,
      _ => Icons.menu_book_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = totalTopics > 0
        ? (completedTopics / totalTopics).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();

    final supportingText = StringBuffer(
      '$totalTopics ${totalTopics == 1 ? 'topic' : 'topics'}'
    );
    if (dueCount > 0) supportingText.write(' · $dueCount due');


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        M3EListItem(
          selected: isSelected,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: subject.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getSubjectIcon(subject.iconName),
              color: subject.color,
              size: 21,
            ),
          ),
          headline: subject.name,
          supportingText: supportingText.toString(),
          trailing: (onNotes != null || onEdit != null || onDelete != null)
              ? GlassM3EMenu(
                  position: M3EMenuAnchorPosition.bottomEnd,
                  colorStyle: M3EMenuColorStyle.vibrant,
                  anchorBuilder: (BuildContext context, VoidCallback open) {
                    return M3EIconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onPressed: open,
                      variant: M3EIconButtonVariant.standard,
                      size: M3EIconButtonSize.sm,
                    );
                  },
                  children: [
                    if (onNotes != null)
                      M3EMenuSelectable(
                        value: 'notes',
                        label: 'Notes & Attachments',
                        leading: const Icon(Icons.description_outlined),
                        onPressed: onNotes,
                      ),
                    if (onEdit != null)
                      M3EMenuSelectable(
                        value: 'edit',
                        label: 'Edit Subject',
                        leading: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      M3EMenuSelectable(
                        value: 'delete',
                        label: 'Delete Subject',
                        leading: const Icon(Icons.delete_outline_rounded),
                        onPressed: onDelete,
                      ),
                  ],
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Row(
            children: [
              Text(
                '$percent%',
                style: textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: M3EProgressIndicator.linear(
                    value: progress,
                    color: isSelected ? colorScheme.primary : subject.color,
                    trackColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
