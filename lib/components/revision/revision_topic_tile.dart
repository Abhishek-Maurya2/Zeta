import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../models/revision.dart';

class RevisionTopicTile extends StatelessWidget {
  final ChapterTopic topic;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const RevisionTopicTile({
    super.key,
    required this.topic,
    required this.onComplete,
    required this.onDelete,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Title Row ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        decoration: topic.isMastered
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (topic.description != null &&
                        topic.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        topic.description!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              M3EIconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            title: const Text('Delete Topic',
                                style: TextStyle(color: Colors.red)),
                            onTap: () {
                              Navigator.pop(ctx);
                              onDelete();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── Bottom: Status chip + Stage dots + Action button ──────────
          Row(
            children: [
              // Status chip
              M3EChip(
                type: chipType,
                label: statusLabel,
                selected: status == RevisionStatus.overdue ||
                    status == RevisionStatus.mastered,
                onPressed: () {},
              ),

              const SizedBox(width: 12),

              // Revision stage dots (●●○)
              if (stage > 0 && stage < 4)
                Row(
                  children: List.generate(3, (i) {
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
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                      ),
                    );
                  }),
                ),

              const Spacer(),

              // Action button
              if (!topic.isMastered)
                M3EButton.icon(
                  onPressed: onComplete,
                  style: stage == 0
                      ? M3EButtonStyle.filled
                      : M3EButtonStyle.tonal,
                  size: M3EButtonSize.sm,
                  icon: Icon(
                    stage == 0
                        ? Icons.check_circle_outline_rounded
                        : Icons.sync_rounded,
                    size: 16,
                  ),
                  label: Text(stage == 0 ? 'Complete' : 'Revise'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
