import 'package:material_ui/material_ui.dart';

/// The in-app visual bridge from Android's launch screen to the first app view.
/// Startup work is owned by the application bootstrap, not by this widget.
@immutable
class SplashScreen extends StatelessWidget {
  /// If true, shows a close button for the Settings preview.
  final bool isPreview;

  const SplashScreen({super.key, this.isPreview = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return Material(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/logo/logo.png',
                width: 120,
                height: 120,
                cacheWidth: 240,
                cacheHeight: 240,
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
          if (isPreview)
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
