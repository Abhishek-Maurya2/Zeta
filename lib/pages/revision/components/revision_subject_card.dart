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
  final VoidCallback? onTap;
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
    this.onTap,
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

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: subject.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _getSubjectIcon(subject.iconName),
              color: subject.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              subject.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (subject.note?.isNotEmpty == true ||
                              subject.attachments.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.description_outlined,
                              size: 15,
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer.withValues(alpha: 0.7)
                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (dueCount > 0)
                      M3EChip(
                        type: M3EChipType.assist,
                        label: '$dueCount due',
                        onPressed: () {},
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$percent%',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: M3EProgressIndicator.linear(
                          value: progress,
                          color: isSelected
                              ? colorScheme.primary
                              : subject.color,
                          trackColor: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (onNotes != null || onEdit != null || onDelete != null) ...[
            GlassM3EMenu(
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
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isSelected ? 52 : 12),
        child: body,
      );
    }

    return body;
  }
}
