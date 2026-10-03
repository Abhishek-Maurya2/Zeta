import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../models/pomodoro.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../components/zeta_empty_state.dart';
import '../../../utils/haptics.dart';

/// Recent completed focus sessions list showing 5 sessions initially,
/// displaying a button to load the next batch of 5 sessions.
class PomodoroSessionList extends StatefulWidget {
  const PomodoroSessionList({super.key});

  @override
  State<PomodoroSessionList> createState() => _PomodoroSessionListState();
}

class _PomodoroSessionListState extends State<PomodoroSessionList> {
  static const int _batchSize = 5;

  int _displayedCount = _batchSize;
  bool _isLoading = false;
  Timer? _loadTimer;

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
              setState(() => _displayedCount = _batchSize);
              provider.clearSessionLog();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _loadNextBatch(int totalSessions) {
    if (_isLoading || _displayedCount >= totalSessions) return;
    setState(() {
      _isLoading = true;
    });

    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _displayedCount = (_displayedCount + _batchSize).clamp(
          0,
          totalSessions,
        );
        _isLoading = false;
      });
      ZetaHaptics.light();
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
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
    final hasMore = totalSessions > _displayedCount;

    final visibleSessions = reversedLogs.take(_displayedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Completed Session Log Header ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Recent Sessions',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 25,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (sessionLog.isNotEmpty)
              M3EIconButton(
                onPressed: () => _confirmClearLogs(context, provider),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                width: M3EIconButtonWidth.wide,
                tooltip: 'Clear session log',
                decoration: M3EIconButtonDecoration(
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
        if (sessionLog.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ZetaEmptyState.pomodoro(
              title: 'No sessions recorded yet',
              subtitle: 'Complete focus sessions to start tracking your daily progress.',
              size: ZetaEmptyStateSize.standard,
            ),
          )
        else
          M3EList(
            color: colorScheme.surfaceContainerLowest,
            itemCount: visibleSessions.length,
            itemBuilder: (context, index) {
              final entry = visibleSessions[index];
              final date = DateTime.fromMillisecondsSinceEpoch(
                entry.completedAt,
              );
              final timeStr =
                  '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              final dateStr = '${date.day} ${monthName(date.month)}';
              final isFocus = entry.mode == PomodoroMode.focus;

              return M3EListItem(
                leading: M3EShapeContainer(
                  kind: isFocus
                      ? M3EShapeKind.ghostish
                      : (entry.mode == PomodoroMode.shortBreak
                            ? M3EShapeKind.softBoom
                            : M3EShapeKind.pill),
                  width: 40,
                  height: 40,
                  color: isFocus
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      isFocus
                          ? Icons.psychology_rounded
                          : (entry.mode == PomodoroMode.shortBreak
                                ? Icons.coffee_rounded
                                : Icons.hotel_rounded),
                      size: 28,
                      color: isFocus
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                headline: entry.mode.label,
                supportingText: '$dateStr at $timeStr',
                trailing: Container(
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
              );
            },
          ),

        // ─── Bottom Loading Trigger / Indicator ─────────────────────
        if (hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: M3ELoadingIndicator(
                      variant: M3ELoadingIndicatorVariant.defaultStyle,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: M3EIconButton(
                      onPressed: () => _loadNextBatch(totalSessions),
                      variant: M3EIconButtonVariant.filled,
                      width: M3EIconButtonWidth.wide,
                      icon: const Icon(Icons.expand_more_rounded, size: 25),
                      tooltip: 'Load ${totalSessions - _displayedCount} more',
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}
