import 'package:material_ui/material_ui.dart';

import '../../../models/pomodoro.dart';

/// Row of 3 summary cards: Total Focus, Sessions Done, and Active Days.
class PomodoroSummaryCards extends StatelessWidget {
  final List<PomodoroSessionLog> sessionLog;

  const PomodoroSummaryCards({
    super.key,
    required this.sessionLog,
  });

  static String formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static String toLocalDateStr(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final focusSessions = sessionLog
        .where((e) => e.mode == PomodoroMode.focus)
        .toList();
    final totalFocusMinutes = focusSessions.fold<int>(
      0,
      (sum, e) => sum + e.minutes,
    );
    final totalSessionsCount = focusSessions.length;

    // Active days count
    final daysMap = <String, int>{};
    for (final e in focusSessions) {
      final ds = toLocalDateStr(
        DateTime.fromMillisecondsSinceEpoch(e.completedAt),
      );
      daysMap[ds] = (daysMap[ds] ?? 0) + e.minutes;
    }
    final daysActive = daysMap.length;

    return Row(
      children: [
        // Total Focus Time Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.timer_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  formatDuration(totalFocusMinutes),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Total Focus',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Completed Sessions Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalSessionsCount',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Sessions Done',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Active Days Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 20,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  '$daysActive days',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Active Days',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
