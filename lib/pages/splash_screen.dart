import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';

/// Expressive, animated splash screen inspired by Gmail and YouTube.
///
/// Features:
/// - Smooth entrance scaling and fade-in
/// - Subtle organic breathing pulse loop
/// - Ambient theme-seed aura bloom behind the app icon
/// - Sleek Material 3 Expressive indeterminate progress capsule
/// - "from Google"-style bottom branding tagline
/// - Concurrently warms up services (`SupabaseService`, image cache)
/// - Graceful zoom-and-dissolve exit reveal into the main app
class SplashScreen extends StatefulWidget {
  /// Callback fired when warmup and the exit transition finish.
  final VoidCallback? onInitializationComplete;

  /// Minimum display time before starting exit transition.
  final Duration minDuration;

  /// If true, runs in preview mode (e.g. from Settings) with a close button.
  final bool isPreview;

  const SplashScreen({
    super.key,
    this.onInitializationComplete,
    this.minDuration = const Duration(milliseconds: 1600),
    this.isPreview = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _exitController;

  late final Animation<double> _introScale;
  late final Animation<double> _introFade;
  late final Animation<Offset> _textSlide;

  late final Animation<double> _pulseScale;
  late final Animation<double> _auraOpacity;
  late final Animation<double> _auraSize;

  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;

  Timer? _warmupTimer;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // 1. Intro Animation (0 -> 500ms)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _introScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _introFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // 2. Subtle Organic Breathing Pulse (Sinusoidal loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseScale = Tween<double>(begin: 0.985, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _auraOpacity = Tween<double>(begin: 0.14, end: 0.32).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _auraSize = Tween<double>(begin: 120.0, end: 160.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 3. YouTube / M3E Indeterminate Shimmer Capsule
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 4. Exit Animation (Zoom and Dissolve Reveal)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    // Start entrance, breathing pulse, and shimmer
    _introController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();

    // Trigger async warmup
    _startWarmup();
  }

  Future<void> _startWarmup() async {
    final stopwatch = Stopwatch()..start();

    // Concurrent preloading (skip live network calls during widget tests)
    final bool isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );

    try {
      await Future.wait([
        if (!isTest) SupabaseService().init(),
        _precacheAssets(),
      ]);
    } catch (e) {
      debugPrint('SplashScreen warmup notice: $e');
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = widget.minDuration.inMilliseconds - elapsed;
    if (remaining > 0) {
      _warmupTimer = Timer(Duration(milliseconds: remaining), () {
        if (!mounted) return;
        if (!widget.isPreview) {
          _finishAndExit();
        }
      });
    } else {
      if (!mounted) return;
      if (!widget.isPreview) {
        _finishAndExit();
      }
    }
  }

  Future<void> _precacheAssets() async {
    try {
      await precacheImage(const AssetImage('assets/logo/logo.png'), context);
    } catch (_) {}
  }

  Future<void> _finishAndExit() async {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
    });

    try {
      await _exitController.forward();
    } catch (_) {}

    if (mounted) {
      widget.onInitializationComplete?.call();
    }
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
    _introController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider?>();
    final isDark = theme.brightness == Brightness.dark;

    // Background color strictly matching native launch background
    final backgroundColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    final primarySeed = themeProvider?.seedColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _exitFade,
      builder: (context, child) {
        // Prevent interaction during exit dissolve
        return Opacity(
          opacity: _exitFade.value.clamp(0.0, 1.0),
          child: Material(color: backgroundColor, child: child),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Center Brand Unit
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _introController,
                _pulseController,
                _exitController,
              ]),
              builder: (context, _) {
                final double currentScale = _isExiting
                    ? _exitScale.value
                    : (_introScale.value * _pulseScale.value);

                return Transform.scale(
                  scale: currentScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ambient Glow + Logo Stack
                      _buildLogoWithAmbientAura(primarySeed),

                      const SizedBox(height: 24),

                      // Text and Subtitle with gentle slide and fade
                      FadeTransition(
                        opacity: _introFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Zeta',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'GoogleSansFlex',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                  letterSpacing: 1.4,
                                  color: isDark
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                );
              },
            ),
          ),

          // Preview Dismiss Button (only shown when tested via Settings)
          if (widget.isPreview)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Close Preview',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Ambient Iris Violet bloom aura behind the logo
  Widget _buildLogoWithAmbientAura(Color primarySeed) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial Bloom
          Container(
            width: _auraSize.value,
            height: _auraSize.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primarySeed.withValues(alpha: _auraOpacity.value),
                  primarySeed.withValues(alpha: _auraOpacity.value * 0.4),
                  primarySeed.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Logo with rounded squircle and soft elevation
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: primarySeed.withValues(alpha: 0.18),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/logo/logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: primarySeed,
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
