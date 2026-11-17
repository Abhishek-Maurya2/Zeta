import 'package:zeta/core/core.dart';
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
    final colorScheme = context.colorScheme;
    final isRunning = provider.isRunning;

    if (isRunning) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      // Snap immediately when paused
      _currentProgress = provider.progress;
    }

    return AnimatedBuilder(
      animation: provider.tickNotifier,
      builder: (context, _) {
        final providerProgress = provider.progress;
        final formattedTime = provider.formattedTime;
        _targetProgress = providerProgress;

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
                        progressIndicatorTheme: currentM3ETheme
                            .progressIndicatorTheme
                            .copyWith(
                              circular: currentM3ETheme
                                  .progressIndicatorTheme
                                  .circular
                                  .copyWith(
                                    waveAmplitude: 5, // Increase this value for higher physical amplitude
                                  ),
                            ),
                      ),
                      child: M3EProgressIndicator.circularWavy(
                        value: _currentProgress.clamp(0.0, 1.0),
                        size: widget.size,
                        strokeWidth: 15,
                        wavelength: 50,
                        trackStrokeWidth: 12,
                        color: colorScheme.primary,
                        trackColor: colorScheme.tertiaryContainer,
                      ),
                    );
                  },
                ),

                // Inner Countdown Display
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: isRunning ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, t, _) {
                    final parts = formattedTime.split(':');
                    final minutes = parts.isNotEmpty ? parts[0] : '00';
                    final seconds = parts.length > 1 ? parts[1] : '00';

                    final animatedWeight = (200.0 + (500.0 * t)).clamp(
                      80.0,
                      1000.0,
                    );
                    final animatedWidth = (140.0 + (80.0 * t)).clamp(
                      100.0,
                      180.0,
                    );
                    final animatedRoundness = (100.0 * t).clamp(0.0, 100.0);
                    final dotSize = (6.0 + (2.0 * t)).clamp(4.0, 10.0);
                    final dotRadius = (dotSize / 2) * t.clamp(0.0, 1.0);

                    final textStyle = TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontSize: 70,
                      height: 1.0,
                      color: colorScheme.tertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontVariations: [
                        FontVariation('wght', animatedWeight),
                        FontVariation('wdth', animatedWidth),
                        FontVariation('ROND', animatedRoundness),
                      ],
                    );

                    const double leadingSlotWidth = 42.0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Timer Icon + Minutes (X MM)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: leadingSlotWidth,
                              child: Center(
                                child: Icon(
                                  Icons.timer_outlined,
                                  size: 38,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(minutes, style: textStyle),
                            const SizedBox(height: 25),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Bottom Row: Custom Colon Dots + Seconds (: ss)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: leadingSlotWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: dotSize,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(
                                        dotRadius,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: dotSize,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary,
                                      borderRadius: BorderRadius.circular(
                                        dotRadius,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(seconds, style: textStyle),
                            const SizedBox(height: 25),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
