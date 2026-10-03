import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../providers/pomodoro_provider.dart';
import '../../components/zeta_empty_state.dart';
import 'components/pomodoro_settings_sheet.dart';
import 'components/pomodoro_queue_item_tile.dart';

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: "Up next" & Configure Cycle Button ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Up next',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Session ${activeIndex + 1} of ${queue.length}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
                    selectedIcon: const Icon(Icons.check_rounded),
                    unselectedIcon: const Icon(Icons.close_rounded),
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

          // ─── Queue List using M3ESegmentedColumn & PomodoroQueueItemTile ──
          if (queue.isEmpty)
            ZetaEmptyState.pomodoro(
              title: 'No sessions in cycle',
              subtitle:
                  'Start a new pomodoro session to populate the focus cycle.',
              size: ZetaEmptyStateSize.compact,
            )
          else
            M3EList(
              itemCount: queue.length,
              gap: 4,
              colorBuilder: (idx) {
                return idx == activeIndex
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerLowest;
              },
              borderRadiusBuilder: (idx, position) {
                if (idx == activeIndex) {
                  return BorderRadius.circular(100);
                }
                return calculateCardRadius(
                  position: position,
                  outerRadius: M3EListCardListTheme.defaultOuterRadius,
                  innerRadius: M3EListCardListTheme.defaultInnerRadius,
                );
              },
              onTap: (idx) => provider.jumpToSession(idx),
              itemBuilder: (context, idx) {
                final item = queue[idx];
                final isActive = idx == activeIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: PomodoroQueueItemTile(
                    item: item,
                    isActive: isActive,
                    isPast: idx < activeIndex,
                    isRunning: isRunning,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
