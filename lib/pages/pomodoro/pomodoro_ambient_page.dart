import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../models/pomodoro.dart';
import '../../providers/pomodoro_provider.dart';
import '../../services/ambient_mode_service.dart';
import '../../utils/haptics.dart';

/// Fullscreen Ambient Display (AOD) matching Pixel Stand / StandBy charging mode:
/// - Pitch AMOLED black canvas
/// - Hero bold percentage (or countdown) on the left
/// - Segmented horizontal milestone progress bar (80% and 100% checkpoints)
/// - Wall clock and session status centered beneath the progress bar
/// - Fading ambient navigation controls
class PomodoroAmbientPage extends StatefulWidget {
  const PomodoroAmbientPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, _, _) => const PomodoroAmbientPage(),
        transitionsBuilder: (context, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  State<PomodoroAmbientPage> createState() => _PomodoroAmbientPageState();
}

class _PomodoroAmbientPageState extends State<PomodoroAmbientPage> {
  Timer? _inactivityTimer;
  Timer? _active1fpsTimer;
  DateTime _lastMouseMoveTime = DateTime(0);
  bool _controlsVisible = true;
  bool _isExiting = false;
  bool _showCountdown = false;
  int? _lastPercent;
  PomodoroProvider? _pomodoroProvider;

  @override
  void initState() {
    super.initState();
    AmbientModeService.enter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<PomodoroProvider>();
        if (!provider.isRunning) {
          provider.startTimer();
        }
      }
    });

    AmbientModeService.setPlatformFullscreenListener((isFullscreen) {
      if (!isFullscreen && mounted && !_isExiting) {
        _isExiting = true;
        AmbientModeService.setPlatformFullscreenListener(null);
        if (mounted) {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop();
          }
        }
        AmbientModeService.exit();
      }
    });

    _resetInactivityTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    if (_pomodoroProvider != provider) {
      _pomodoroProvider?.tickNotifier.removeListener(_onTickCheckPercent);
      _pomodoroProvider = provider;
      _pomodoroProvider?.tickNotifier.addListener(_onTickCheckPercent);
    }
  }

  @override
  void dispose() {
    _isExiting = true;
    _pomodoroProvider?.tickNotifier.removeListener(_onTickCheckPercent);
    _inactivityTimer?.cancel();
    _active1fpsTimer?.cancel();
    AmbientModeService.setPlatformFullscreenListener(null);
    AmbientModeService.exit();
    super.dispose();
  }

  void _onTickCheckPercent() {
    if (!mounted || _pomodoroProvider == null) return;
    final progress = _pomodoroProvider!.progress.clamp(0.0, 1.0);
    final currentPercent = (progress * 100).round();
    if (_lastPercent != null && currentPercent != _lastPercent) {
      _lastPercent = currentPercent;
      setState(() {});
    } else {
      _lastPercent = currentPercent;
    }
  }

  void _startActive1fpsTimer() {
    _active1fpsTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stopActive1fpsTimer() {
    if (!_showCountdown) {
      _active1fpsTimer?.cancel();
      _active1fpsTimer = null;
    }
  }

  void _onMouseMove() {
    final now = DateTime.now();
    // Throttle interrupt redraw to at most 1 fps
    if (now.difference(_lastMouseMoveTime) >= const Duration(seconds: 1)) {
      _lastMouseMoveTime = now;
      if (mounted) {
        setState(() {});
      }
    }
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _startActive1fpsTimer();
    _inactivityTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        final isRunning = context.read<PomodoroProvider>().isRunning;
        if (isRunning) {
          setState(() => _controlsVisible = false);
          _stopActive1fpsTimer();
        }
      }
    });
  }

  void _exitFullscreen() {
    if (_isExiting) return;
    _isExiting = true;
    AmbientModeService.setPlatformFullscreenListener(null);
    ZetaHaptics.light();
    if (mounted) {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    }
    AmbientModeService.exit();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getStatusText(PomodoroProvider provider) {
    if (!provider.isRunning) return 'Paused';
    switch (provider.mode) {
      case PomodoroMode.focus:
        final total = provider.queue.length;
        final current = provider.activeQueueIndex + 1;
        return total > 1 ? 'Focusing • $current of $total' : 'Focusing';
      case PomodoroMode.shortBreak:
        return 'Short break';
      case PomodoroMode.longBreak:
        return 'Long break';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();


    final double progress = provider.progress.clamp(0.0, 1.0);
    final int percent = (progress * 100).round();
    _lastPercent = percent;

    final totalSec = provider.totalDuration <= 0
        ? 25 * 60
        : provider.totalDuration;
    final elapsedSec = provider.elapsedSeconds;
    final leftSec = provider.timeLeft;

    // Milestone calculations
    final target80Sec = totalSec * 0.80;
    final secTo80 = math.max(0.0, target80Sec - elapsedSec);
    final minutesUntil80 = (secTo80 / 60).ceil();
    final remainingMinsTo100 = (leftSec / 60).ceil();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _exitFullscreen,
        const SingleActivator(LogicalKeyboardKey.keyF): _exitFullscreen,
        const SingleActivator(LogicalKeyboardKey.space): () {
          ZetaHaptics.medium();
          provider.toggleTimer();
          _onMouseMove();
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              _isExiting = true;
              AmbientModeService.setPlatformFullscreenListener(null);
              unawaited(AmbientModeService.exit());
            }
          },
          child: MouseRegion(
            cursor: _controlsVisible
                ? SystemMouseCursors.basic
                : SystemMouseCursors.none,
            onHover: (_) => _onMouseMove(),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onMouseMove,
              onDoubleTap: _exitFullscreen,
              child: Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: OrientationBuilder(
                        builder: (context, orientation) {
                          final isLandscape =
                              orientation == Orientation.landscape;

                          return Stack(
                            children: [
                              // ─── Main Content ───────────────────────
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLandscape ? 48.0 : 28.0,
                                    vertical: 20.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 48),

                                      // Hero Number (% or Countdown)
                                      Expanded(
                                        child: Align(
                                          alignment: isLandscape
                                              ? Alignment.bottomLeft
                                              : Alignment.centerLeft,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              ZetaHaptics.selection();
                                              setState(() {
                                                _showCountdown =
                                                    !_showCountdown;
                                                if (_showCountdown) {
                                                  _startActive1fpsTimer();
                                                } else if (!_controlsVisible) {
                                                  _stopActive1fpsTimer();
                                                }
                                              });
                                              _resetInactivityTimer();
                                            },
                                            child: _buildHeroDisplay(
                                              percent: percent,
                                              formattedTime:
                                                  provider.formattedTime,
                                              showCountdown: _showCountdown,
                                              isLandscape: isLandscape,
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isLandscape ? 20 : 36),

                                      // Milestone Progress Bar & Clock (dims when controls are hidden)
                                      AnimatedOpacity(
                                        opacity: _controlsVisible ? 1.0 : 0.45,
                                        duration: const Duration(milliseconds: 300),
                                        child: _AmbientProgressBar(
                                          progress: progress,
                                          minutesUntil80: minutesUntil80,
                                          remainingMinsTo100: remainingMinsTo100,
                                          clockTime: _formatCurrentTime(),
                                          statusText: _getStatusText(provider),
                                        ),
                                      ),

                                      SizedBox(height: isLandscape ? 20 : 28),
                                    ],
                                  ),
                                ),
                              ),

                              // ─── Top Floating Controls ──────────────
                              Positioned(
                                top: 16,
                                left: 24,
                                right: 24,
                                child: AnimatedOpacity(
                                  opacity: _controlsVisible ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton.filledTonal(
                                        icon: const Icon(
                                          Symbols.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        tooltip: 'Exit ambient mode',
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.15),
                                          hoverColor: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                        onPressed: _exitFullscreen,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton.filledTonal(
                                            icon: Icon(
                                              provider.isRunning
                                                  ? Symbols.pause_rounded
                                                  : Symbols.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            tooltip: provider.isRunning
                                                ? 'Pause'
                                                : 'Resume',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.15),
                                              hoverColor: Colors.white
                                                  .withValues(alpha: 0.25),
                                            ),
                                            onPressed: () {
                                              ZetaHaptics.medium();
                                              provider.toggleTimer();
                                              _onMouseMove();
                                            },
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton.filledTonal(
                                            icon: const Icon(
                                              Symbols.fullscreen_exit_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            tooltip: 'Exit full screen (Esc)',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white
                                              .withValues(alpha: 0.15),
                                              hoverColor: Colors.white
                                                  .withValues(alpha: 0.25),
                                            ),
                                            onPressed: _exitFullscreen,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroDisplay({
    required int percent,
    required String formattedTime,
    required bool showCountdown,
    required bool isLandscape,
  }) {
    if (showCountdown) {
      return Text(
        formattedTime,
        style: TextStyle(
          color: Colors.white,
          fontSize: isLandscape ? 104 : 72,
          height: 0.95,
          fontFamily: 'headline',
          fontWeight: FontWeight.w900,
          letterSpacing: -2.0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$percent',
          style: TextStyle(
            color: Colors.white,
            fontSize: isLandscape ? 116 : 88,
            height: 0.95,
            fontFamily: 'headline',
            fontWeight: FontWeight.w900,
            letterSpacing: -3.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '%',
          style: TextStyle(
            color: Colors.white,
            fontSize: isLandscape ? 32 : 26,
            fontFamily: 'headline',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// StandBy / Ambient horizontal progress bar with 80% & 100% milestone tick marks
class _AmbientProgressBar extends StatelessWidget {
  final double progress;
  final int minutesUntil80;
  final int remainingMinsTo100;
  final String clockTime;
  final String statusText;

  const _AmbientProgressBar({
    required this.progress,
    required this.minutesUntil80,
    required this.remainingMinsTo100,
    required this.clockTime,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const barHeight = 3.5;
        final x80 = totalWidth * 0.80;
        final isPast80 = progress >= 0.80;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top milestone times: "7m" above 80%, "35m" above 100%
            SizedBox(
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: (x80 - 24).clamp(0.0, totalWidth - 48),
                    width: 48,
                    child: Text(
                      isPast80 ? '✓' : '${minutesUntil80}m',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'headline',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isPast80
                            ? Colors.white.withValues(alpha: 0.45)
                            : Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    width: 48,
                    child: Text(
                      '${remainingMinsTo100}m',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'headline',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Segmented Progress Bar Line
            CustomPaint(
              size: Size(totalWidth, barHeight),
              painter: _BarTrackPainter(
                progress: progress,
                trackColor: Colors.white.withValues(alpha: 0.22),
                fillColor: Colors.white,
                notchX: x80,
              ),
            ),
            const SizedBox(height: 8),

            // Bottom row: Centered time & status, 80% and 100% labels
            SizedBox(
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Centered Time and Status
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clockTime,
                          style: const TextStyle(
                            fontFamily: 'headline',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 80% badge below
                  Positioned(
                    left: (x80 - 24).clamp(0.0, totalWidth - 48),
                    top: 0,
                    width: 48,
                    child: Text(
                      '80%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'headline',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isPast80
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  // 100% badge below
                  Positioned(
                    right: 0,
                    top: 0,
                    width: 48,
                    child: Text(
                      '100%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'headline',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: progress >= 1.0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Draws track with smooth rounded caps and a crisp physical notch at 80%
class _BarTrackPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double notchX;

  _BarTrackPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.notchX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(2.0);

    // 1. Inactive track background
    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      radius,
    );
    canvas.drawRRect(bgRRect, Paint()..color = trackColor);

    // 2. Active progress fill
    final fillWidth = (progress * size.width).clamp(0.0, size.width);
    if (fillWidth > 0) {
      final fillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        radius,
      );
      canvas.drawRRect(fillRRect, Paint()..color = fillColor);
    }

    // 3. Crisp vertical notch gap at 80%
    final notchPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(notchX, -1),
      Offset(notchX, size.height + 1),
      notchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BarTrackPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.notchX != notchX;
}
