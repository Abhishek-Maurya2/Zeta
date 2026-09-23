import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../providers/pomodoro_provider.dart';

/// Circular wavy progress indicator and digital countdown display.
class PomodoroTimerDisplay extends StatelessWidget {
  final double size;

  const PomodoroTimerDisplay({super.key, this.size = 290.0});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isRunning = provider.isRunning;
    final progress = provider.progress;
    final formattedTime = provider.formattedTime;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Wavy Progress Indicator (smooth interpolation)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: isRunning
                  ? const Duration(seconds: 1)
                  : const Duration(milliseconds: 300),
              curve: isRunning ? Curves.linear : Curves.easeOutCubic,
              builder: (context, animatedProgress, _) {
                return M3EProgressIndicator.circularWavy(
                  value: animatedProgress,
                  size: size,
                  strokeWidth: 12,
                  wavelength: 27,
                  trackStrokeWidth: 12,
                  color: colorScheme.primary,
                  trackColor: colorScheme.surfaceContainerHighest,
                );
              },
            ),

            // Inner Countdown Display
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontFamily: isRunning ? 'GoogleSansFlex' : 'RobotoFlex',
                    fontSize: 70,
                    letterSpacing: isRunning ? 1 : 5,
                    color: colorScheme.onSurface,
                    fontVariations: [
                      FontVariation('wght', isRunning ? 900 : 600),
                      FontVariation('wdth', isRunning ? 80 : 180),
                      const FontVariation('ROND', 100),
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
    );
  }
}
