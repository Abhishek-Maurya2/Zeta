import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../components/glass_alert_dialog.dart';
import '../../../models/pomodoro.dart';
import '../../../providers/pomodoro_provider.dart';
import '../../../components/zeta_empty_state.dart';
import '../../../utils/haptics.dart';

/// Recent completed focus sessions list grouped by day, displaying 5 days of
/// session data initially, with pagination to load 5 days per batch.
class PomodoroSessionList extends StatefulWidget {
  const PomodoroSessionList({super.key});

  @override
  State<PomodoroSessionList> createState() => _PomodoroSessionListState();
}

class _PomodoroSessionListState extends State<PomodoroSessionList> {
  static const int _daysBatchSize = 5;

  int _displayedDaysCount = _daysBatchSize;
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
              setState(() => _displayedDaysCount = _daysBatchSize);
              provider.clearSessionLog();
            },
            isDestructive: true,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _loadNextBatch(int totalDays) {
    if (_isLoading || _displayedDaysCount >= totalDays) return;
    setState(() {
      _isLoading = true;
    });

    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _displayedDaysCount = (_displayedDaysCount + _daysBatchSize).clamp(
          0,
          totalDays,
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

    // Group ALL sessions by calendar day first (newest to oldest)
    final reversedLogs = sessionLog.reversed.toList();
    final groupedSessions = <DateTime, List<PomodoroSessionLog>>{};
    for (final session in reversedLogs) {
      final date = DateTime.fromMillisecondsSinceEpoch(session.completedAt);
      final dayKey = DateTime(date.year, date.month, date.day);
      groupedSessions.putIfAbsent(dayKey, () => []).add(session);
    }

    final allDays = groupedSessions.keys.toList();
    final totalDays = allDays.length;
    final hasMore = totalDays > _displayedDaysCount;

    // Take the requested number of full days
    final visibleDays = allDays.take(_displayedDaysCount).toList();

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
            itemCount: visibleDays.length,
            expandStyle: M3EExpandableStyle(
              expandedStateFill: false,
              gap: 5,
              expandedIconBackground: colorScheme.surfaceContainerHighest,
           
            ),
            itemBuilder: (context, index) {
              final dayKey = visibleDays[index];
              final sessionsForDay = groupedSessions[dayKey]!;

              int focusTime = 0;
              for (final s in sessionsForDay) {
                if (s.mode == PomodoroMode.focus) {
                  focusTime += s.minutes;
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

              final now = DateTime.now();
              final isCurrentYear = dayKey.year == now.year;
              final dateStr = isCurrentYear
                  ? '${dayKey.day} ${monthName(dayKey.month)}'
                  : '${dayKey.day} ${monthName(dayKey.month)} ${dayKey.year}';

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
                        entry.completedAt,
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
                      onPressed: () => _loadNextBatch(totalDays),
                      variant: M3EIconButtonVariant.filled,
                      width: M3EIconButtonWidth.wide,
                      icon: const Icon(Icons.expand_more_rounded),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}
