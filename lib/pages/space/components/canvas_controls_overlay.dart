import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../../providers/theme_provider.dart';
import '../../../components/glass_surface.dart';
import '../../../utils/haptics.dart';

/// Floating canvas navigation controls (Zoom +/-, Center Root, Fit to View).
class CanvasControlsOverlay extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterRoot;
  final VoidCallback onFitToView;

  const CanvasControlsOverlay({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterRoot,
    required this.onFitToView,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;

    return GlassSurface(
      borderRadius: BorderRadius.circular(24),
      blurSigma: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.65)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_rounded, size: 18),
              tooltip: 'Zoom Out',
              onPressed: () {
                ZetaHaptics.selection();
                onZoomOut();
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 18),
              tooltip: 'Zoom In',
              onPressed: () {
                ZetaHaptics.selection();
                onZoomIn();
              },
            ),
            Container(
              height: 18,
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
            IconButton(
              icon: const Icon(Symbols.center_focus_strong_rounded, size: 18),
              tooltip: 'Center on Root',
              onPressed: () {
                ZetaHaptics.selection();
                onCenterRoot();
              },
            ),
            IconButton(
              icon: const Icon(Symbols.fit_screen_rounded, size: 18),
              tooltip: 'Fit to Screen',
              onPressed: () {
                ZetaHaptics.selection();
                onFitToView();
              },
            ),
          ],
        ),
      ),
    );
  }
}
