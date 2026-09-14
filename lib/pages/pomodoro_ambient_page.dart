import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/pomodoro.dart';
import '../providers/pomodoro_provider.dart';
import '../services/ambient_mode_service.dart';
import '../utils/haptics.dart';

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
      ),
    );
  }

  @override
  State<PomodoroAmbientPage> createState() => _PomodoroAmbientPageState();
}

class _PomodoroAmbientPageState extends State<PomodoroAmbientPage> {
  Timer? _inactivityTimer;
  bool _controlsVisible = true;

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
      if (!isFullscreen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    _resetInactivityTimer();
  }

  @override
  void dispose() {
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
    debugPrint('--> _exitFullscreen CALLED!');
    ZetaHaptics.light();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Color _getModeColor(PomodoroMode mode, ColorScheme scheme) {
    switch (mode) {
      case PomodoroMode.focus:
        return scheme.primary;
      case PomodoroMode.shortBreak:
        return const Color(0xFF4CAF50); // Bright fresh green
      case PomodoroMode.longBreak:
        return const Color(0xFF29B6F6); // Serene blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final modeColor = _getModeColor(provider.mode, colorScheme);
    final currentSession = provider.currentSession;
    final sessionNum = currentSession?.sessionNumber;
    final totalInterval = provider.settings.longBreakInterval;

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
        const SingleActivator(LogicalKeyboardKey.keyR): () {
          ZetaHaptics.light();
          provider.resetTimer();
          _resetInactivityTimer();
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
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
                    Center(
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
                                  // Subtle ambient circular progress track
                                  SizedBox(
                                    width: 300,
                                    height: 300,
                                    child: CircularProgressIndicator(
                                      value: provider.progress,
                                      strokeWidth: 4,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        modeColor.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),

                                  // Digital Countdown
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          provider.formattedTime,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 104,
                                            fontWeight: FontWeight.w200,
                                            letterSpacing: -3.0,
                                            fontFeatures: [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Status Badge
                                      AnimatedOpacity(
                                        opacity: provider.isRunning ? 0.7 : 1.0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: provider.isRunning
                                                    ? modeColor
                                                    : Colors.white38,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              provider.isRunning
                                                  ? 'RUNNING'
                                                  : 'PAUSED',
                                              style: TextStyle(
                                                color: provider.isRunning
                                                    ? Colors.white70
                                                    : Colors.white38,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 3.5,
                                              ),
                                            ),
                                          ],
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

                      // ─── Top Bar: Mode Title & Fullscreen Exit ───────────
                      Positioned(
                        top: 16,
                        left: 24,
                        right: 24,
                        child: AnimatedOpacity(
                          opacity: _controlsVisible ? 1.0 : 0.15,
                          duration: const Duration(milliseconds: 300),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Mode Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: modeColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      provider.mode == PomodoroMode.focus
                                          ? Icons.psychology_rounded
                                          : Icons.coffee_rounded,
                                      size: 16,
                                      color: modeColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      provider.mode.label.toUpperCase(),
                                      style: TextStyle(
                                        color: modeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    if (sessionNum != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• $sessionNum / $totalInterval',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Exit Fullscreen Button
                              IconButton.filledTonal(
                                icon: const Icon(
                                  Icons.fullscreen_exit_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                tooltip: 'Exit full screen (Esc)',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.15),
                                  hoverColor:
                                      Colors.white.withValues(alpha: 0.25),
                                ),
                                onPressed: _exitFullscreen,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Bottom Ambient Controls ─────────────────────────
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 24,
                        child: AnimatedOpacity(
                          opacity: _controlsVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Play / Pause, Skip, Reset Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Reset Button
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.replay_rounded),
                                    tooltip: 'Reset timer (R)',
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.15),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      ZetaHaptics.light();
                                      provider.resetTimer();
                                      _resetInactivityTimer();
                                    },
                                  ),
                                  const SizedBox(width: 20),

                                  // Play / Pause Button
                                  IconButton.filled(
                                    icon: Icon(
                                      provider.isRunning
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 32,
                                    ),
                                    tooltip: provider.isRunning
                                        ? 'Pause (Space)'
                                        : 'Resume (Space)',
                                    style: IconButton.styleFrom(
                                      backgroundColor: modeColor,
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size(60, 60),
                                    ),
                                    onPressed: () {
                                      ZetaHaptics.medium();
                                      provider.toggleTimer();
                                      _resetInactivityTimer();
                                    },
                                  ),
                                  const SizedBox(width: 20),

                                  // Skip Button
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.skip_next_rounded),
                                    tooltip: 'Skip session (S)',
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.15),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      ZetaHaptics.medium();
                                      provider.skipSession();
                                      _resetInactivityTimer();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Subtle Keyboard Shortcut hints
                              const Text(
                                'Space: Play/Pause • Esc: Exit • S: Skip • R: Reset',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
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
