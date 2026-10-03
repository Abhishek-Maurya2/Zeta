import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../providers/pomodoro_provider.dart';
import '../../../utils/haptics.dart';

/// Control buttons for Pomodoro timer (Play/Pause, Reset, Skip).
class PomodoroTimerControls extends StatelessWidget {
  const PomodoroTimerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final isRunning = provider.isRunning;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 96,
      child: M3EButtonGroup(
        type: M3EButtonGroupType.standard,
        style: M3EButtonStyle.tonal,
        size: M3EButtonSize.custom(
          height: 96,
          hPadding: 48,
          iconSize: 32,
          iconGap: 10,
        ),
        shape: M3EButtonShape.round,
        selectedIndex: null,
        onSelectedIndexChanged: (int? index) {
          if (index == null) return;
          ZetaHaptics.medium();
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
            width: 140,
            icon: Icon(
              fontWeight: FontWeight.bold,
              size: 35,
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            tooltip: isRunning ? 'Pause (Space)' : 'Start (Space)',
            decoration: M3EButtonDecoration.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
          M3EButtonGroupAction(
            icon: const Icon(
              Icons.restart_alt_rounded,
              fontWeight: FontWeight.bold,
              size: 35,
            ),
            width: 96,
            tooltip: 'Reset session',
            decoration: M3EButtonDecoration.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
          M3EButtonGroupAction(
            icon: const Icon(
              Icons.skip_next_rounded,
              fontWeight: FontWeight.bold,
              size: 35,
            ),
            width: 66,
            tooltip: 'Skip to next session',
            decoration: M3EButtonDecoration.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
