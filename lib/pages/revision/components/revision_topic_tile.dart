import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../components/glass_m3e_menu.dart';
import '../../../models/revision.dart';

class RevisionTopicTile extends StatelessWidget {
  final ChapterTopic topic;
  final VoidCallback onComplete;
  final VoidCallback? onNotes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int? index;
  final bool canReorder;

  const RevisionTopicTile({
    super.key,
    required this.topic,
    required this.onComplete,
    this.onNotes,
    this.onEdit,
    this.onDelete,
    this.index,
    this.canReorder = false,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${diff.abs()}d overdue';
    return 'In ${diff}d';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = topic.status;
    final stage = topic.revisionStage;

    // ─── Status chip config ───────────────────────────────────────────────────
    String statusLabel;
    M3EChipType chipType;

    switch (status) {
      case RevisionStatus.mastered:
        statusLabel = 'Mastered 🏆';
        chipType = M3EChipType.filter;
        break;
      case RevisionStatus.overdue:
        statusLabel = topic.nextRevisionDate != null
            ? 'Overdue · ${_formatDate(topic.nextRevisionDate!)}'
            : 'Overdue';
        chipType = M3EChipType.filter;
        break;
      case RevisionStatus.scheduled:
        statusLabel = topic.nextRevisionDate != null
            ? 'Revise · ${_formatDate(topic.nextRevisionDate!)}'
            : 'Scheduled';
        chipType = M3EChipType.assist;
        break;
      default:
        statusLabel = 'Not Completed';
        chipType = M3EChipType.assist;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 1, 1, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Title & Menu Row ─────────────────────────────────────────
          Row(
            children: [
              if (index != null && canReorder)
                ReorderableDragStartListener(
                  index: index!,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

              // title
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        topic.title,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (topic.note?.isNotEmpty == true ||
                        topic.attachments.isNotEmpty ||
                        (topic.description?.isNotEmpty ?? false)) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Has notes / attachments',
                        child: Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // menu
              if (onNotes != null || onEdit != null || onDelete != null)
                GlassM3EMenu(
                  position: M3EMenuAnchorPosition.bottomEnd,
                  colorStyle: M3EMenuColorStyle.vibrant,
                  anchorBuilder: (BuildContext context, VoidCallback open) {
                    return IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onPressed: open,
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
                        label: 'Edit Topic',
                        leading: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      M3EMenuSelectable(
                        value: 'delete',
                        label: 'Delete Topic',
                        leading: const Icon(Icons.delete_outline_rounded),
                        onPressed: onDelete,
                      ),
                  ],
                ),
            ],
          ),

          // ─── Description ──────────────────────────────────────────────
          if (topic.description != null && topic.description!.isNotEmpty) ...[
            Row(
              children: [
                const SizedBox(width: 25),
                Expanded(
                  child: Text(
                    topic.description!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 35),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ─── Bottom: Status chip + Stage dots + Action button ──────────
          Row(
            children: [
              const SizedBox(width: 25),
              // Status chip
              M3EChip(
                type: chipType,
                label: statusLabel,
                selected:
                    status == RevisionStatus.overdue ||
                    status == RevisionStatus.mastered,
                onPressed: () {},
              ),

              const SizedBox(width: 12),

              // Revision stage dots (●●●○)
              if (stage > 0 && stage < 5)
                Row(
                  children: List.generate(4, (i) {
                    final active = i < stage;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: active ? 10 : 8,
                        height: active ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? colorScheme.tertiary
                              : colorScheme.outlineVariant,
                        ),
                      ),
                    );
                  }),
                ),

              const Spacer(),

              // Action button
              if (!topic.isMastered)
                M3EIconButton(
                  onPressed: onComplete,
                  size: M3EIconButtonSize.sm,
                  width: M3EIconButtonWidth.wide,
                  variant: M3EIconButtonVariant.filled,
                  icon: Icon(
                    stage == 0 ? Icons.check_rounded : Icons.sync_rounded,
                    size: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  tooltip: (stage == 0)
                      ? 'Start Revision'
                      : 'Move to Next Stage',
                ),

              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}
