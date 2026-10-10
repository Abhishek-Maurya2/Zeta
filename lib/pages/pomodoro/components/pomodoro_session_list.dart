import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../components/glass_alert_dialog.dart';
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
    showGlassDialog<void>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: const Text('Clear Session History?'),
        content: const Text(
          'This will permanently delete all logged focus sessions. This action cannot be undone.',
        ),
        actions: [
          GlassButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _displayedCount = _batchSize);
              provider.clearSessionLog();
            },
            isDestructive: true,
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
          Builder(
            builder: (context) {
              final groupedSessions = <String, List<dynamic>>{};
              for (final session in visibleSessions) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  session.completedAt as int,
                );
                final dateStr = '${date.day} ${monthName(date.month)}';
                groupedSessions.putIfAbsent(dateStr, () => []).add(session);
              }
              final groupedKeys = groupedSessions.keys.toList();

              return M3EList(
                color: colorScheme.surfaceContainerLowest,
                itemCount: groupedKeys.length,
                expandStyle: M3EExpandableStyle(
                  expandedStateFill: false,
                  gap: 5,
                  expandedIconBackground: colorScheme.surfaceContainerHighest,
                  expandIcon: Icon(
                    Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  collapseIcon: Icon(
                    Icons.expand_less_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                itemBuilder: (context, index) {
                  final dateStr = groupedKeys[index];
                  final sessionsForDay = groupedSessions[dateStr]!;

                  int focusTime = 0;
                  for (final s in sessionsForDay) {
                    if (s.mode == PomodoroMode.focus) {
                      focusTime += s.minutes as int;
                    }
                  }

                  String? focusStr;
                  if (focusTime > 0) {
                    final int h = focusTime ~/ 60;
                    final int m = focusTime % 60;
                    if (h > 0 && m > 0) {
                      focusStr = '${h}h ${m}m focus';
                    } else if (h > 0) {
                      focusStr = '${h}h focus';
                    } else {
                      focusStr = '${m}m focus';
                    }
                  }

                  return M3EListItem(
                    headline: dateStr,
                    supportingText: focusStr,
                    leading: const Icon(Icons.calendar_today_rounded),
                    expanded: M3EExpandableExpanded.list(
                      M3EList(
                        color: colorScheme.tertiaryContainer,
                        haptic: M3EHapticFeedback.heavy,
                        itemCount: sessionsForDay.length,
                        itemBuilder: (context, sessionIndex) {
                          final entry = sessionsForDay[sessionIndex];
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            entry.completedAt as int,
                          );
                          final isPm = date.hour >= 12;
                          final hour12 = date.hour == 0
                              ? 12
                              : (date.hour > 12 ? date.hour - 12 : date.hour);
                          final timeStr =
                              '$hour12:${date.minute.toString().padLeft(2, '0')} ${isPm ? 'PM' : 'AM'}';
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
                              color: colorScheme.onTertiary,
                              child: Center(
                                child: Icon(
                                  isFocus
                                      ? Icons.psychology_rounded
                                      : (entry.mode == PomodoroMode.shortBreak
                                            ? Icons.coffee_rounded
                                            : Icons.hotel_rounded),
                                  size: 28,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                            headline: entry.mode.label,
                            supportingText: '@ $timeStr',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.minutes}m',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onTertiary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
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
