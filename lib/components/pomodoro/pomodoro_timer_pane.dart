import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../providers/pomodoro_provider.dart';

class PomodoroTimerPane extends StatelessWidget {
  final VoidCallback? onToggleAod;

  const PomodoroTimerPane({
    super.key,
    this.onToggleAod,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final modeTitle = provider.mode.label;
    final isRunning = provider.isRunning;
    final progress = provider.progress;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 840;
    final bottomPadding = isCompact ? 96.0 : 24.0;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () {
          provider.toggleTimer();
        },
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight =
                (constraints.maxHeight - bottomPadding - 16).clamp(0.0, double.infinity);

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
              // ─── Header: Mode Title & AOD Fullscreen Toggle ───────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balance right button
                  Expanded(
                    child: Text(
                      modeTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  M3EIconButton(
                    variant: M3EIconButtonVariant.tonal,
                    size: M3EIconButtonSize.sm,
                    tooltip: 'Always-on display',
                    icon: const Icon(Icons.fullscreen_rounded, size: 20),
                    onPressed: onToggleAod,
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // ─── Center: Wavy Circular Progress & Digital Countdown ───────
              Center(
                child: SizedBox(
                  width: 290,
                  height: 290,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular Wavy Progress Indicator
                      M3EProgressIndicator.circularWavy(
                        value: progress,
                        size: 290,
                        strokeWidth: 12,
                        trackStrokeWidth: 12,
                        color: colorScheme.primary,
                        trackColor: colorScheme.surfaceContainerHighest,
                      ),

                      // Inner Countdown Display
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            provider.formattedTime,
                            style: textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.0,
                              color: colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isRunning
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isRunning ? 'RUNNING' : 'PAUSED',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isRunning
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ─── Bottom Controls ──────────────────────────────────────────
              SizedBox(
                height: 96,
                child: M3EButtonGroup(
                  type: M3EButtonGroupType.standard,
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.lg,
                  shape: M3EButtonShape.round,
                  selectedIndex: null,
                  onSelectedIndexChanged: (int? index) {
                    switch (index) {
                      case 0:
                        provider.toggleTimer();
                      case 1:
                        provider.resetTimer();
                      case 2:
                        provider.skipSession();
                    }
                  },
                  actions: [
                    M3EButtonGroupAction(
                      icon: Icon(
                        isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      tooltip: isRunning ? 'Pause (Space)' : 'Start (Space)',
                    ),
                    const M3EButtonGroupAction(
                      icon: Icon(Icons.restart_alt_rounded),
                      tooltip: 'Reset session',
                    ),
                    const M3EButtonGroupAction(
                      icon: Icon(Icons.skip_next_rounded),
                      tooltip: 'Skip to next session',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
