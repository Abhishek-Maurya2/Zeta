import 'dart:math' as math;
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

        // Parse formattedTime (xy:za)
        // x: bigger first digit(s) of minutes
        // y: smaller last digit of minutes
        // :za: colon and seconds fitting below y
        final parts = formattedTime.split(':');
        final minsPart = parts.isNotEmpty ? parts[0] : '00';
        final secsPart = parts.length > 1 ? parts[1] : '00';

        final String xText;
        final String yText;
        if (minsPart.length <= 1) {
          xText = '0';
          yText = minsPart.isEmpty ? '0' : minsPart;
        } else {
          xText = minsPart.substring(0, minsPart.length - 1);
          yText = minsPart.substring(minsPart.length - 1);
        }
        final String colonZaText = ':$secsPart';

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

                // Inner Countdown Display (pixel-perfect mathematical alignment)
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _PomodoroDigitalTimePainter(
                      xText: xText,
                      yText: yText,
                      colonZaText: colonZaText,
                      color: colorScheme.tertiary,
                      size: widget.size,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the digital countdown display.
///
/// Ensures pixel-perfect alignment:
/// - Top cap-height of `y` aligns exactly with top cap-height of `x`.
/// - Bottom baseline of `:za` aligns exactly with bottom baseline of `x`.
class _PomodoroDigitalTimePainter extends CustomPainter {
  final String xText;
  final String yText;
  final String colonZaText;
  final Color color;
  final double size;

  const _PomodoroDigitalTimePainter({
    required this.xText,
    required this.yText,
    required this.colonZaText,
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final xSize = size * 0.75;
    final ySize = xSize * 0.62;
    final zaSize = xSize * 0.28;

    final xStyle = TextStyle(
      fontFamily: 'GoogleSansFlex',
      fontSize: xSize,
      color: color,
      fontVariations: const [
        FontVariation('wght', 400),
        FontVariation('wdth', 45),
        FontVariation('ROND', 100),
      ],
    );

    final yStyle = TextStyle(
      fontFamily: 'GoogleSansFlex',
      fontSize: ySize,
      color: color,
      fontVariations: const [
        FontVariation('wght', 400),
        FontVariation('wdth', 45),
        FontVariation('ROND', 100),
      ],
    );

    final zaStyle = TextStyle(
      fontFamily: 'GoogleSansFlex',
      fontSize: zaSize,
      color: color,
      fontVariations: const [
        FontVariation('wght', 450),
        FontVariation('wdth', 45),
        FontVariation('ROND', 100),
      ],
    );

    final xPainter = TextPainter(
      text: TextSpan(text: xText, style: xStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final yPainter = TextPainter(
      text: TextSpan(text: yText, style: yStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final zaPainter = TextPainter(
      text: TextSpan(text: colonZaText, style: zaStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final horizontalGap = size * 0.022;
    final rightWidth = math.max(yPainter.width, zaPainter.width);
    final totalWidth = xPainter.width + horizontalGap + rightWidth;

    final startX = (canvasSize.width - totalWidth) / 2;
    // 0.608 * xSize is the exact visual vertical center of digit x
    final topY = (canvasSize.height / 2) - (0.608 * xSize);

    // 1. Paint X (big left digit/digits)
    xPainter.paint(canvas, Offset(startX, topY));

    // 2. Paint Y (smaller top right digit)
    // Top of Y glyph aligns exactly with top of X glyph:
    final rightStartX = startX + xPainter.width + horizontalGap;
    final yX = rightStartX + (rightWidth - yPainter.width) / 2;
    final yY = topY + 0.25 * (xSize - ySize);
    yPainter.paint(canvas, Offset(yX, yY));

    // 3. Paint :za (seconds fitted below Y)
    // Baseline of :za digits aligns exactly with baseline of X:
    final zaX = rightStartX + (rightWidth - zaPainter.width) / 2;
    final zaY = topY + 0.966 * (xSize - zaSize);
    zaPainter.paint(canvas, Offset(zaX, zaY));
  }

  @override
  bool shouldRepaint(covariant _PomodoroDigitalTimePainter oldDelegate) {
    return oldDelegate.xText != xText ||
        oldDelegate.yText != yText ||
        oldDelegate.colonZaText != colonZaText ||
        oldDelegate.color != color ||
        oldDelegate.size != size;
  }
}
