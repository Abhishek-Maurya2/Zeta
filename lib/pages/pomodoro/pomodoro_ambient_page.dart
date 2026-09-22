import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/pomodoro_provider.dart';
import '../../services/ambient_mode_service.dart';
import '../../utils/haptics.dart';

/// Fullscreen Ambient Display (AOD) page.
/// Completely takes over the screen across Web, Windows, Android, and iOS,
/// and prevents device sleep while running.
class PomodoroAmbientPage extends StatefulWidget {
  const PomodoroAmbientPage({super.key});

  /// Opens the ambient mode taking over the entire root window/screen.
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

  @override
  void initState() {
    super.initState();
    // 1. Enter platform fullscreen and acquire wake lock
    AmbientModeService.enter();

    // 2. Automatically start timer if paused
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<PomodoroProvider>();
        if (!provider.isRunning) {
          provider.startTimer();
        }
      }
    });

    // 3. Listen for browser/system-level fullscreen exit (e.g. Esc in web)
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _exitFullscreen,
        const SingleActivator(LogicalKeyboardKey.keyF): _exitFullscreen,
        const SingleActivator(LogicalKeyboardKey.space): () {
          ZetaHaptics.medium();
          provider.toggleTimer();
          _resetInactivityTimer();
        },
        const SingleActivator(LogicalKeyboardKey.keyS): () {
          ZetaHaptics.medium();
          provider.skipSession();
          _resetInactivityTimer();
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
              AmbientModeService.exit();
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
                    // ─── Background Tap Handler ─────────────────────────
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ZetaHaptics.light();
                          provider.toggleTimer();
                          _resetInactivityTimer();
                        },
                      ),
                    ),

                    // ─── Center: Enormous Clock & Progress ───────────────
                    IgnorePointer(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress Ring & Giant Countdown
                            SizedBox(
                              width: 320,
                              height: 320,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Digital Countdown
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          provider.formattedTime,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontSize: 104,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -1.0,
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── Top Bar: Mode Title & Fullscreen Exit ───────────
                    Positioned(
                      top: 16,
                      left: 24,
                      right: 24,
                      child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.15,
                        duration: const Duration(milliseconds: 300),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Exit Fullscreen Button
                            IconButton.filledTonal(
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
                                hoverColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                              onPressed: _exitFullscreen,
                            ),
                          ],
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
