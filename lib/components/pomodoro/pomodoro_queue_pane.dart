import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';

import '../../providers/pomodoro_provider.dart';
import '../../models/pomodoro.dart';
import 'pomodoro_settings_sheet.dart';

class PomodoroQueuePane extends StatelessWidget {
  final bool isSplitPane;

  const PomodoroQueuePane({super.key, this.isSplitPane = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final queue = provider.queue;
    final activeIndex = provider.activeQueueIndex;
    final settings = provider.settings;
    final isRunning = provider.isRunning;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isSplitPane ? 20 : 16,
        right: isSplitPane ? 20 : 16,
        top: 16,
        bottom: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: "Up next" & Configure Cycle Button ───────────
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Up next',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: colorScheme.onSurface,
                ),
              ),
              M3EButton.icon(
                label: const Text('Configure'),
                icon: const Icon(Icons.tune_rounded, size: 16),
                style: M3EButtonStyle.tonal,
                size: M3EButtonSize.sm,
                onPressed: () => PomodoroSettingsSheet.show(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── Sub-header: Session Count & Skip Breaks Switch ───────
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Session ${activeIndex + 1} of ${queue.length}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skip breaks',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  M3ESwitch(
                    value: settings.skipBreaks,
                    onChanged: (val) {
                      provider.updateSettings(
                        settings.copyWith(skipBreaks: val),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── Queue List using M3ESegmentedColumn ─────────────────
          if (queue.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No sessions in cycle',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            M3ESegmentedColumn(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              color: colorScheme.surfaceContainerLowest,
              selectedIndex: activeIndex,
              onTap: (idx) => provider.jumpToSession(idx),
              children: List.generate(queue.length, (idx) {
                final item = queue[idx];
                final isActive = idx == activeIndex;
                final isPast = idx < activeIndex;

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
                            ? (isRunning
                                  ? Icons.timelapse_rounded
                                  : Icons.play_arrow_rounded)
                            : (isPast
                                  ? Icons.check_rounded
                                  : (item.mode == PomodoroMode.focus
                                        ? Icons.psychology_rounded
                                        : (item.mode ==
                                                  PomodoroMode.shortBreak
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
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? colorScheme.onSecondaryContainer
                                      : (isPast
                                            ? colorScheme.onSurface
                                                  .withValues(alpha: 0.6)
                                            : colorScheme.onSurface),
                                ),
                              ),
                              if (item.sessionNumber != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '#${item.sessionNumber}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isActive
                                        ? colorScheme.onSecondaryContainer
                                              .withValues(alpha: 0.7)
                                        : colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.7),
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
                                  ? colorScheme.onSecondaryContainer
                                        .withValues(alpha: 0.8)
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
                            ? colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              )
                            : colorScheme.outline,
                      ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}
