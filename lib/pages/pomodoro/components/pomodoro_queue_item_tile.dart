import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../models/pomodoro.dart';

/// Single session item row inside the Pomodoro queue list.
class PomodoroQueueItemTile extends StatelessWidget {
  final PomodoroSessionItem item;
  final bool isActive;
  final bool isPast;
  final bool isRunning;

  const PomodoroQueueItemTile({
    super.key,
    required this.item,
    required this.isActive,
    required this.isPast,
    required this.isRunning,
  });

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '$minutes:00';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Row(
      children: [
        // Leading Icon Badge
        M3EShapeContainer(
          kind: isActive ? M3EShapeKind.flower : M3EShapeKind.pentagon,
          width: 40,
          height: 40,
          color: isActive
              ? colorScheme.primaryContainer
              : (isPast
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.tertiary),
          child: Center(
            child: Icon(
              isActive
                  ? (isRunning
                        ? Icons.timelapse_rounded
                        : Icons.play_arrow_rounded)
                  : (isPast
                        ? Icons.check_rounded
                        : (item.mode == PomodoroMode.focus
                              ? Icons.psychology_rounded
                              : (item.mode == PomodoroMode.shortBreak
                                    ? Icons.coffee_rounded
                                    : Icons.hotel_rounded))),
              size: 23,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : (isPast
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onTertiary),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Main Title & Duration
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.label,
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isActive
                            ? colorScheme.onTertiary
                            : (isPast
                                  ? colorScheme.onSurface.withValues(alpha: 0.6)
                                  : colorScheme.onSurface),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.sessionNumber != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: !isActive
                            ? isPast
                                  ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                                  : colorScheme.primaryContainer
                            : colorScheme.onTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.sessionNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? colorScheme.tertiary
                              : colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontFamily: 'RobotoMono',
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _formatDuration(item.durationMinutes),
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? colorScheme.onTertiary
                      : isPast
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Icon(
          isActive ? Icons.square_rounded : Icons.play_arrow_rounded,
          size: 25,
          color: isActive ? colorScheme.onTertiary : isPast
              ? colorScheme.outlineVariant
              : colorScheme.onTertiaryContainer,
        ),
      ],
    );
  }
}
