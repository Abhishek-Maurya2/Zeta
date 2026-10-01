import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../providers/pomodoro_provider.dart';

/// Circular wavy progress indicator and digital countdown display.
///
/// Uses a [Ticker] to smoothly interpolate the wavy arc between the
/// 1-second provider ticks, giving a fluid 60 fps animation instead
/// of a jerky once-per-second jump.
class PomodoroTimerDisplay extends StatefulWidget {
  final double size;

  const PomodoroTimerDisplay({super.key, this.size = 290.0});

  @override
  State<PomodoroTimerDisplay> createState() => _PomodoroTimerDisplayState();
}

class _PomodoroTimerDisplayState extends State<PomodoroTimerDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Cached provider values to detect changes that need visual update
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // This controller runs indefinitely, driven by the ticker
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onAnimationTick);
  }

  void _onAnimationTick() {
    // Smoothly lerp _currentProgress toward _targetProgress every frame
    const lerpSpeed = 0.08; // ~8% of remaining gap per frame ≈ smooth ease-out
    final diff = _targetProgress - _currentProgress;
    if (diff.abs() > 0.0001) {
      _currentProgress += diff * lerpSpeed;
    } else {
      _currentProgress = _targetProgress;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isRunning = provider.isRunning;
    final providerProgress = provider.progress;
    final formattedTime = provider.formattedTime;

    // Update target; start/stop the repeating animation
    _targetProgress = providerProgress;
    if (isRunning) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      // Snap immediately when paused
      _currentProgress = providerProgress;
    }

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Wavy Progress Indicator (smooth 60fps interpolation)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final currentM3ETheme = M3ETheme.of(context);
                return M3ETheme(
                  data: currentM3ETheme.copyWith(
                    progressIndicatorTheme: currentM3ETheme.progressIndicatorTheme.copyWith(
                      circular: currentM3ETheme.progressIndicatorTheme.circular.copyWith(
                        waveAmplitude: 3.0, // Increase this value for higher physical amplitude
                      ),
                    ),
                  ),
                  child: M3EProgressIndicator.circularWavy(
                    value: _currentProgress.clamp(0.0, 1.0),
                    size: widget.size,
                    strokeWidth: 12,
                    wavelength: 40,
                    amplitude: 1.0, // This is clamped to 1.0 by the package (100% of waveAmplitude)
                    trackStrokeWidth: 12,
                    color: colorScheme.primary,
                    trackColor: colorScheme.surfaceContainerHighest,
                  ),
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

