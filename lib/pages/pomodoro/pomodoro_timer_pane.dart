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
    final bottomPadding = isCompact ? 95.0 : 25.0;
    const topPadding = 8.0;

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
            tooltip: 'AOD',
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
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: topPadding,
                bottom: bottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - topPadding - bottomPadding)
                          .clamp(0.0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildHeader(),
                    const SizedBox(height: 24), // Min gap 1
                    const PomodoroTimerDisplay(),
                    const SizedBox(height: 24), // Min gap 2
                    const PomodoroTimerControls(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
