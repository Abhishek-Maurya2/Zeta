import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../utils/haptics.dart';
import '../../providers/pomodoro_provider.dart';
import '../../theme/breakpoints.dart';
import 'components/pomodoro_timer_display.dart';
import 'components/pomodoro_timer_controls.dart';

class PomodoroTimerPane extends StatelessWidget {
  final VoidCallback? onToggleAod;

  const PomodoroTimerPane({super.key, this.onToggleAod});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final modeTitle = provider.mode.label;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;
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
            final availableHeight = (constraints.maxHeight - bottomPadding - 16)
                .clamp(0.0, double.infinity);

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
                            icon: const Icon(
                              Icons.fullscreen_rounded,
                              size: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            onPressed: onToggleAod != null
                                ? () {
                                    ZetaHaptics.light();
                                    onToggleAod!();
                                  }
                                : null,
                          ),
                        ],
                      ),

                      const Spacer(flex: 1),

                      // ─── Center: Wavy Circular Progress & Digital Countdown ───────
                      const PomodoroTimerDisplay(),

                      const Spacer(flex: 2),

                      // ─── Bottom Controls ──────────────────────────────────────────
                      const PomodoroTimerControls(),

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
