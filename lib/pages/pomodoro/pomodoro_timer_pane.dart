import 'package:zeta/core/core.dart';
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
    final modeTitle = context.select<PomodoroProvider, String>(
      (p) => p.mode.label,
    );
    final provider = context.read<PomodoroProvider>();
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;
    final bottomPadding = isCompact ? 96.0 : 24.0;

    // Extracted the header row to keep the conditional layouts clean
    Widget buildHeader() {
      return Row(
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
            tooltip: 'Always-on display',
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: onToggleAod != null
                ? () {
                    ZetaHaptics.light();
                    onToggleAod!();
                  }
                : null,
          ),
        ],
      );
    }

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
            // Check if we have enough vertical space for the flex layout (~600px is a safe threshold)
            final bool needsScroll =
                !constraints.hasBoundedHeight || constraints.maxHeight < 600;

            if (needsScroll) {
              // 1. FALLBACK LAYOUT: Short screens / Unbounded constraints
              // Uses a ScrollView and safe, fixed-height gaps instead of Spacers
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: bottomPadding,
                ),
                child: Column(
                  children: [
                    buildHeader(),
                    const SizedBox(
                      height: 32,
                    ), // Fixed gap substituting Spacer(flex: 1)
                    const PomodoroTimerDisplay(),
                    const SizedBox(
                      height: 48,
                    ), // Fixed gap substituting Spacer(flex: 2)
                    const PomodoroTimerControls(),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }

            // Keep the timer content bounded to the viewport while retaining
            // an always-scrollable surface for pull-to-refresh. The scaffold's
            // ScrollConfiguration supplies AlwaysScrollableScrollPhysics.
            return SingleChildScrollView(
              child: SizedBox(
                height: constraints.maxHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: bottomPadding,
                  ),
                  child: Column(
                    children: [
                      buildHeader(),
                      const Spacer(flex: 1),
                      const PomodoroTimerDisplay(),
                      const Spacer(flex: 2),
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
