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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // Leading Icon Badge
        M3EShapeContainer(
          kind: isActive ? M3EShapeKind.flower : M3EShapeKind.pentagon,
          width: 40,
          height: 40,
          color: isActive
              ? colorScheme.primary
              : (isPast
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.secondaryContainer),
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
              fontWeight: FontWeight.w700,
              color: isActive
                  ? colorScheme.onPrimary
                  : (isPast
                        ? colorScheme.onSurface
                        : colorScheme.onSecondaryContainer),
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
                        fontWeight:
                            isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive
                            ? colorScheme.onSecondaryContainer
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: !isActive
                            ? isPast
                                  ? colorScheme.secondary.withValues(alpha: 0.7)
                                  : colorScheme.secondary
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${item.sessionNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${item.durationMinutes}:00',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? colorScheme.onSecondaryContainer
                      : isPast
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Trailing Indicator
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Current',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
              ),
            ),
          )
        else
          Icon(
            Icons.play_arrow_rounded,
            size: 25,
            color: isPast
                ? colorScheme.outlineVariant
                : colorScheme.onSecondaryContainer,
          ),
      ],
    );
  }
}
