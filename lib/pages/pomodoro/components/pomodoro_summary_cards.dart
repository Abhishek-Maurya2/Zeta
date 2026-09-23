import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../models/pomodoro.dart';

/// Row of 3 summary cards: Total Focus, Sessions Done, and Active Days.
/// Uses [M3EShapeContainer] for expressive shape iconography.
class PomodoroSummaryCards extends StatelessWidget {
  final List<PomodoroSessionLog> sessionLog;

  const PomodoroSummaryCards({super.key, required this.sessionLog});

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


    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Focus Time Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  M3EShapeContainer(
                    kind: M3EShapeKind.cookie4Sided,
                    width: 45,
                    height: 45,
                    color: colorScheme.onPrimaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.timer_rounded,
                        size: 25,
                        color: colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatDuration(totalFocusMinutes),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Total Focus',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  M3EShapeContainer(
                    kind: M3EShapeKind.clover8Leaf,
                    width: 45,
                    height: 45,
                    color: colorScheme.onTertiaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.checklist_rounded,
                        size: 25,
                        color: colorScheme.tertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$totalSessionsCount',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onTertiaryContainer,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sessions Done',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onTertiaryContainer,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  M3EShapeContainer(
                    kind: M3EShapeKind.gem,
                    width: 45,
                    height: 45,
                    color: colorScheme.onSecondaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 25,
                        color: colorScheme.secondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$daysActive days',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Active Days',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
