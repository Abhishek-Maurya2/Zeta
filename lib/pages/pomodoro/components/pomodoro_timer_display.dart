import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../providers/pomodoro_provider.dart';
import 'zeta_wavy_circle_progress_painter.dart';

/// Circular wavy progress indicator and digital countdown display.
///
/// Features a decoupled, zero-allocation rendering architecture:
/// - 60 Hz wavy circle animation rendered directly on Canvas without widget rebuilds.
/// - 1 Hz digital countdown text isolated via [ValueListenableBuilder].
/// - Auto-stopping lerp ticker for smooth progress transitions across second boundaries.
class PomodoroTimerDisplay extends StatefulWidget {
  final double size;

  const PomodoroTimerDisplay({super.key, this.size = 290.0});

  @override
  State<PomodoroTimerDisplay> createState() => _PomodoroTimerDisplayState();
}

class _PomodoroTimerDisplayState extends State<PomodoroTimerDisplay>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  final ValueNotifier<double> _smoothProgressNotifier =
      ValueNotifier<double>(0.0);

  double _currentProgress = 0.0;
  double _targetProgress = 0.0;
  Ticker? _progressTicker;

  // Cached TextStyle instances to prevent GC churn on 1Hz ticks
  static const _runningTextStyle = TextStyle(
    fontFamily: 'GoogleSansFlex',
    fontSize: 70,
    letterSpacing: 1,
    fontVariations: [
      FontVariation('wght', 900),
      FontVariation('wdth', 80),
      FontVariation('ROND', 100),
    ],
  );

  static const _pausedTextStyle = TextStyle(
    fontFamily: 'RobotoFlex',
    fontSize: 70,
    letterSpacing: 5,
    fontVariations: [
      FontVariation('wght', 600),
      FontVariation('wdth', 180),
      FontVariation('ROND', 100),
    ],
  );

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 1 wavelength / sec = 50px/s
    );
  }

  bool? _lastIsRunning;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<PomodoroProvider>(context);
    final isRunning = provider.isRunning;
    if (_lastIsRunning != isRunning) {
      _lastIsRunning = isRunning;
      if (!isRunning) {
        _currentProgress = provider.progress;
        _targetProgress = _currentProgress;
        _smoothProgressNotifier.value = _currentProgress;
      }
      _syncAnimationState(isRunning);
    }
  }

  void _syncAnimationState(bool isRunning) {
    if (isRunning) {
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
    } else {
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
      _progressTicker?.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressTicker?.dispose();
    _smoothProgressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PomodoroProvider>();
    final isRunning = context.select<PomodoroProvider, bool>(
      (p) => p.isRunning,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Center(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Continuous Wave Progress Layer (60 Hz / 120 Hz, ZERO Rebuilds)
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: ZetaWavyCircleProgressPainter(
                    repaintAnimation: _waveController,
                    progressListenable: _smoothProgressNotifier,
                    activeColor: colorScheme.primary,
                    trackColor: colorScheme.tertiaryContainer,
                    strokeWidth: 15.0,
                    trackStrokeWidth: 12.0,
                    wavelength: 50.0,
                    amplitude: 5.0,
                  ),
                ),
              ),

              // 2. Discrete Countdown Text Layer (1 Hz, ZERO Animation Tick Overhead)
              RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: provider.tickNotifier,
                  builder: (context, remainingSeconds, _) {
                    final isCurrentlyRunning =
                        context.read<PomodoroProvider>().isRunning;
                    _onSecondTick(
                      provider.totalDuration > 0
                          ? ((provider.totalDuration - remainingSeconds) /
                                  provider.totalDuration)
                              .clamp(0.0, 1.0)
                          : provider.progress,
                      isCurrentlyRunning,
                    );

                    final displaySeconds = provider.isCountUp
                        ? (provider.totalDuration - remainingSeconds).clamp(
                            0,
                            provider.totalDuration,
                          )
                        : remainingSeconds;
                    final mins = displaySeconds ~/ 60;
                    final secs = displaySeconds % 60;
                    final formattedTime =
                        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

                    return Text(
                      formattedTime,
                      style: (isRunning ? _runningTextStyle : _pausedTextStyle)
                          .copyWith(color: colorScheme.tertiary),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSecondTick(double newTarget, bool isRunning) {
    _targetProgress = newTarget;
    if (!isRunning) {
      _currentProgress = newTarget;
      _smoothProgressNotifier.value = newTarget;
      if (_progressTicker?.isTicking ?? false) {
        _progressTicker?.stop();
      }
      return;
    }
    // Auto-stopping lerp ticker: runs for ~300ms then completely stops
    _startProgressLerp();
  }

  void _startProgressLerp() {
    final diff = _targetProgress - _currentProgress;
    if (diff.abs() <= 0.0001) {
      _currentProgress = _targetProgress;
      _smoothProgressNotifier.value = _currentProgress;
      if (_progressTicker?.isTicking ?? false) {
        _progressTicker?.stop();
      }
      return;
    }

    _progressTicker ??= createTicker((_) {
      const lerpSpeed = 0.08;
      final currentDiff = _targetProgress - _currentProgress;
      if (currentDiff.abs() > 0.0001) {
        _currentProgress += currentDiff * lerpSpeed;
        _smoothProgressNotifier.value = _currentProgress;
      } else {
        _currentProgress = _targetProgress;
        _smoothProgressNotifier.value = _currentProgress;
        _progressTicker?.stop(); // Idle for remaining ~700ms
      }
    });

    if (!_progressTicker!.isTicking) {
      _progressTicker!.start();
    }
  }
}
