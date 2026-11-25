import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../providers/pomodoro_provider.dart';
import '../../../theme/motion_tokens.dart';

/// Circular wavy progress indicator and digital countdown display.
///
/// Smoothly animates progress arc changes per second without continuous 60fps
/// busy-looping, and isolates repaints of progress vs odometer digits.
class PomodoroTimerDisplay extends StatefulWidget {
  final double size;

  const PomodoroTimerDisplay({super.key, this.size = 320.0});

  @override
  State<PomodoroTimerDisplay> createState() => _PomodoroTimerDisplayState();
}

class _PomodoroTimerDisplayState extends State<PomodoroTimerDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  Animation<double>? _progressAnimation;
  PomodoroProvider? _provider;
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<PomodoroProvider>();
    if (_provider != provider) {
      _provider?.tickNotifier.removeListener(_onTick);
      _provider = provider;
      _provider!.tickNotifier.addListener(_onTick);
      _currentProgress = _provider!.progress;
      _targetProgress = _currentProgress;
    }
  }

  void _onTick() {
    if (!mounted) return;
    final provider = _provider;
    if (provider == null) return;

    final target = provider.progress;
    final isRunning = provider.isRunning;

    if (!isRunning) {
      if (_progressController.isAnimating) {
        _progressController.stop();
      }
      _currentProgress = target;
      _targetProgress = target;
      _progressAnimation = null;
      setState(() {});
      return;
    }

    final start = _progressAnimation?.value ?? _currentProgress;
    _currentProgress = start;
    _targetProgress = target;

    final diff = (_targetProgress - _currentProgress).abs();
    if (diff > 0.05) {
      // Large jump (session switch, reset): fast catch-up
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: _targetProgress,
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.duration = const Duration(milliseconds: 250);
      _progressController.forward(from: 0.0);
    } else if (diff > 0.00001) {
      // Smooth continuous linear transition: uniform angular velocity across 1s
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: _targetProgress,
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.linear),
      );
      _progressController.duration = const Duration(seconds: 1);
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _provider?.tickNotifier.removeListener(_onTick);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = context.select<PomodoroProvider, bool>((p) => p.isRunning);
    final isCountUp = context.select<PomodoroProvider, bool>((p) => p.isCountUp);
    final provider = context.read<PomodoroProvider>();
    final colorScheme = context.colorScheme;

    if (!isRunning) {
      if (_progressController.isAnimating) {
        _progressController.stop();
      }
      _currentProgress = provider.progress;
      _targetProgress = _currentProgress;
      _progressAnimation = null;
    }

    final currentM3ETheme = M3ETheme.of(context);
    final wavyTheme = currentM3ETheme.copyWith(
      progressIndicatorTheme: currentM3ETheme.progressIndicatorTheme.copyWith(
        circular: currentM3ETheme.progressIndicatorTheme.circular.copyWith(
          waveAmplitude: 5,
        ),
      ),
    );

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Wavy Progress Indicator (isolated repaint & hoisted theme)
            M3ETheme(
              data: wavyTheme,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    final displayProgress =
                        _progressAnimation?.value ?? _currentProgress;
                    return M3EProgressIndicator.circularWavy(
                      value: displayProgress.clamp(0.0, 1.0),
                      size: widget.size,
                      strokeWidth: 15,
                      wavelength: 50,
                      trackStrokeWidth: 12,
                      color: colorScheme.primary,
                      trackColor: colorScheme.tertiaryContainer,
                    );
                  },
                ),
              ),
            ),

            // Inner Countdown Display (isolated repaint, play/pause transition hoisted above tick loop)
            RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: isRunning ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, t, _) {
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
                    fontSize: 75,
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

                  return AnimatedBuilder(
                    animation: provider.tickNotifier,
                    builder: (context, _) {
                      final formattedTime = provider.formattedTime;
                      final parts = formattedTime.split(':');
                      final minutes = parts.isNotEmpty ? parts[0] : '00';
                      final seconds = parts.length > 1 ? parts[1] : '00';

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
                              RollingDigitsText(
                                text: minutes,
                                style: textStyle,
                                countUp: isCountUp,
                              ),
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
                              RollingDigitsText(
                                text: seconds,
                                style: textStyle,
                                countUp: isCountUp,
                              ),
                              const SizedBox(height: 25),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays digits that animate individually with a rolling / odometer effect
/// when their numerical value changes.
class RollingDigitsText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool countUp;

  const RollingDigitsText({
    super.key,
    required this.text,
    required this.style,
    this.countUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < text.length; i++)
          _RollingDigitChar(
            key: ValueKey<int>(text.length - 1 - i),
            char: text[i],
            style: style,
            countUp: countUp,
          ),
      ],
    );
  }
}

class _RollingDigitChar extends StatelessWidget {
  final String char;
  final TextStyle style;
  final bool countUp;

  const _RollingDigitChar({
    super.key,
    required this.char,
    required this.style,
    required this.countUp,
  });

  @override
  Widget build(BuildContext context) {
    // When counting down, outgoing digits roll downward and incoming enter from top.
    // When counting up, outgoing digits roll upward and incoming enter from bottom.
    final enterY = countUp ? 0.7 : -0.7;
    final exitY = countUp ? -0.7 : 0.7;

    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: M3MotionEasing.emphasizedDecelerate,
        switchOutCurve: M3MotionEasing.emphasizedAccelerate,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final childKey = child.key;
          final isIncoming = childKey is ValueKey<String> && childKey.value == char;

          final inOffset = Tween<Offset>(
            begin: Offset(0.0, enterY),
            end: Offset.zero,
          ).animate(animation);

          final outOffset = Tween<Offset>(
            begin: Offset(0.0, exitY),
            end: Offset.zero,
          ).animate(animation);

          return SlideTransition(
            position: isIncoming ? inOffset : outOffset,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInQuad,
              ),
              child: child,
            ),
          );
        },
        child: Text(
          char,
          key: ValueKey<String>(char),
          style: style,
        ),
      ),
    );
  }
}
