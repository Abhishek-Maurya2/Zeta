import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../services/supabase_service.dart';

/// Standardized Splash Screen for all platforms.
///
/// Features:
/// - Consistent logo size (120x120) and background color across all platforms
/// - Only app logo centered on screen (no animations, labels, or progress bars)
/// - Concurrently warms up core services and precaches logo
@immutable
class SplashScreen extends StatefulWidget {
  /// Callback fired when initialization is complete.
  final VoidCallback? onInitializationComplete;

  /// Minimum display time before completing.
  final Duration minDuration;

  /// If true, runs in preview mode (e.g. from Settings) with a close button.
  final bool isPreview;

  const SplashScreen({
    super.key,
    this.onInitializationComplete,
    this.minDuration = const Duration(milliseconds: 1200),
    this.isPreview = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _warmupTimer;

  @override
  void initState() {
    super.initState();
    _startWarmup();
  }

  Future<void> _startWarmup() async {
    final stopwatch = Stopwatch()..start();

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
          widget.onInitializationComplete?.call();
        }
      });
    } else {
      if (!mounted) return;
      if (!widget.isPreview) {
        widget.onInitializationComplete?.call();
      }
    }
  }

  Future<void> _precacheAssets() async {
    try {
      await precacheImage(const AssetImage('assets/logo/logo.png'), context);
    } catch (_) {}
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Standardized background color across all platforms
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return Material(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Centered App Logo Only
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/logo/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 120,
                  height: 120,
                  color: Theme.of(context).colorScheme.primary,
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Preview Dismiss Button (only when previewed from Settings)
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
}
