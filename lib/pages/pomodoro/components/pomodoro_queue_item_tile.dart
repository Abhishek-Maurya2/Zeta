import 'package:material_ui/material_ui.dart';

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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : (isPast
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerHighest),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive
                ? (isRunning ? Icons.timelapse_rounded : Icons.play_arrow_rounded)
                : (isPast
                    ? Icons.check_rounded
                    : (item.mode == PomodoroMode.focus
                        ? Icons.psychology_rounded
                        : (item.mode == PomodoroMode.shortBreak
                            ? Icons.coffee_rounded
                            : Icons.hotel_rounded))),
            size: 18,
            color: isActive
                ? colorScheme.onPrimary
                : (isPast
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant),
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
                  Text(
                    item.label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? colorScheme.onSecondaryContainer
                          : (isPast
                              ? colorScheme.onSurface.withValues(alpha: 0.6)
                              : colorScheme.onSurface),
                    ),
                  ),
                  if (item.sessionNumber != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '#${item.sessionNumber}',
                      style: textTheme.bodySmall?.copyWith(
                        color: isActive
                            ? colorScheme.onSecondaryContainer.withValues(
                                alpha: 0.7,
                              )
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${item.durationMinutes}:00',
                style: textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: isActive
                      ? colorScheme.onSecondaryContainer.withValues(alpha: 0.8)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Trailing Indicator
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
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
            Icons.play_circle_outline_rounded,
            size: 20,
            color: isPast
                ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                : colorScheme.outline,
          ),
      ],
    );
  }
}
