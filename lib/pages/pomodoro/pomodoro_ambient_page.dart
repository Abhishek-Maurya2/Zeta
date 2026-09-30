import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/pomodoro_provider.dart';
import '../../services/ambient_mode_service.dart';
import '../../theme/breakpoints.dart';
import '../../utils/haptics.dart';

/// Fullscreen Ambient Display (AOD) page with a matrix/grid progress indicator.
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
  bool _controlsVisible = true;
  bool _isExiting = false;

  // Grid configuration: 5x5 layout (25 total units)
  static const int _gridCrossAxisCount = 5;
  static const int _totalDots = 25;

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
  void dispose() {
    _isExiting = true;
    _inactivityTimer?.cancel();
    AmbientModeService.setPlatformFullscreenListener(null);
    AmbientModeService.exit();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _inactivityTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final isRunning = context.read<PomodoroProvider>().isRunning;
        if (isRunning) {
          setState(() => _controlsVisible = false);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();

    // Derive progress (0.0 to 1.0) directly or compute via provider values
    final double progress = provider.progress.clamp(0.0, 1.0);
    final int percentage = (progress * 100).round();
    final int completedDots = (progress * _totalDots).floor();

    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    return CallbackShortcuts(
      // Only keep exit shortcuts; Space/S keys are completely removed
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _exitFullscreen,
        const SingleActivator(LogicalKeyboardKey.keyF): _exitFullscreen,
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
            onHover: (_) => _resetInactivityTimer(),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    // ─── Center: Dot Matrix Progress Indicator ───────
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: AnimatedOpacity(
                          opacity: _controlsVisible ? 1.0 : 0.25,
                          duration: const Duration(milliseconds: 300),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 320,
                              maxHeight: 320,
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _totalDots,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _gridCrossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                              itemBuilder: (context, index) {
                                final bool isFilled = index < completedDots;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFilled
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isFilled
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ─── Top-Right: Exit Fullscreen Button ───────────
                    Positioned(
                      top: 16,
                      right: 24,
                      child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.25,
                        duration: const Duration(milliseconds: 300),
                        child: IconButton.filledTonal(
                          icon: const Icon(
                            Icons.fullscreen_exit_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          tooltip: 'Exit full screen (Esc)',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            hoverColor: Colors.white.withValues(alpha: 0.25),
                          ),
                          onPressed: _exitFullscreen,
                        ),
                      ),
                    ),

                    // ─── Bottom-Left: Percentage Display ─────────────
                    Positioned(
                      bottom: 24,
                      left: 24,
                      child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.25,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          child: Text(
                            "$percentage%",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: !isCompact ? 100 : 28,
                              height: 1.0,
                              fontFamily: 'headline',
                              fontWeight: FontWeight.w600,
                              letterSpacing: !isCompact ? -4.0 : -0.9,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
