import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../widgets/segmented_column.dart';
import '../../../models/pomodoro.dart';
import '../../../providers/pomodoro_provider.dart';

/// Recent completed focus sessions list showing 5 sessions initially,
/// displaying [M3ELoadingIndicator] for at least 3 seconds before automatically loading the rest.
class PomodoroSessionList extends StatefulWidget {
  const PomodoroSessionList({super.key});

  @override
  State<PomodoroSessionList> createState() => _PomodoroSessionListState();
}

class _PomodoroSessionListState extends State<PomodoroSessionList> {
  static const int _initialCount = 5;
  static const Duration _minLoadingDuration = Duration(seconds: 3);

  bool _loadedAll = false;
  bool _isLoading = false;
  Timer? _timer;

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
              setState(() => _loadedAll = false);
              provider.clearSessionLog();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _checkAutoLoad(int totalSessions) {
    if (totalSessions > _initialCount && !_loadedAll && !_isLoading) {
      _isLoading = true;
      _timer?.cancel();
      _timer = Timer(_minLoadingDuration, () {
        if (!mounted) return;
        setState(() {
          _loadedAll = true;
          _isLoading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final sessionLog = provider.sessionLog;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final reversedLogs = sessionLog.reversed.toList();
    final totalSessions = reversedLogs.length;
    final hasMore = totalSessions > _initialCount;

    _checkAutoLoad(totalSessions);

    final visibleSessions = (_loadedAll || !hasMore)
        ? reversedLogs
        : reversedLogs.take(_initialCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Completed Session Log Header ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Sessions',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            if (sessionLog.isNotEmpty)
              M3EButton.icon(
                onPressed: () => _confirmClearLogs(context, provider),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('Clear'),
                size: M3EButtonSize.sm,
                tooltip: 'Clear session log',
                decoration: M3EButtonDecoration(
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.errorContainer,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // ─── Session List Container ───────────────────────────────
        M3ESegmentedColumn(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          color: colorScheme.surfaceContainerLowest,
          children: sessionLog.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ZetaEmptyState.pomodoro(
                      title: 'No sessions recorded yet',
                      subtitle: 'Complete focus sessions to start tracking your daily progress.',
                      size: ZetaEmptyStateSize.standard,
                    ),
                  ),
                ]
              : visibleSessions.map((entry) {
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

        // ─── Automatic Loading Indicator (Visible for ≥ 3 seconds) ──
        if (hasMore && !_loadedAll) ...[
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: M3ELoadingIndicator(
                variant: M3ELoadingIndicatorVariant.contained,
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
