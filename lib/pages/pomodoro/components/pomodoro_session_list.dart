import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../widgets/segmented_column.dart';
import '../../../models/pomodoro.dart';
import '../../../providers/pomodoro_provider.dart';

/// Recent completed focus sessions list with clear history action.
class PomodoroSessionList extends StatelessWidget {
  const PomodoroSessionList({super.key});

  static String monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }

  void _confirmClearLogs(BuildContext context, PomodoroProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Session History?'),
        content: const Text(
          'This will permanently delete all logged focus sessions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.clearSessionLog();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final sessionLog = provider.sessionLog;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Completed Session Log Header ─────────────────────────
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Recent Sessions',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (sessionLog.isNotEmpty) ...[
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _confirmClearLogs(context, provider),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        M3ESegmentedColumn(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          color: colorScheme.surfaceContainerLowest,
          children: sessionLog.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ZetaEmptyState.pomodoro(
                      title: 'No sessions recorded yet',
                      subtitle:
                          'Complete focus sessions to start tracking your daily progress.',
                      size: ZetaEmptyStateSize.standard,
                    ),
                  ),
                ]
              : sessionLog.reversed.take(20).map((entry) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    entry.completedAt,
                  );
                  final timeStr =
                      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  final dateStr = '${date.day} ${monthName(date.month)}';
                  final isFocus = entry.mode == PomodoroMode.focus;

                  return Row(
                    children: [
                      // Leading Icon Badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFocus
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFocus
                              ? Icons.psychology_rounded
                              : (entry.mode == PomodoroMode.shortBreak
                                    ? Icons.coffee_rounded
                                    : Icons.hotel_rounded),
                          size: 18,
                          color: isFocus
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Main Title & Duration/Timestamp
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.mode.label,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dateStr at $timeStr',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Trailing Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.minutes}m',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
        ),
      ],
    );
  }
}
