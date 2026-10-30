import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../providers/space_provider.dart';
import '../../../components/glass_surface.dart';

import '../../../utils/haptics.dart';
import '../../../theme/breakpoints.dart';

/// Floating canvas navigation and workflow controls as a vertical M3E toolbar
/// (Undo, Redo, Layout Switcher, Zoom In, Zoom Out, Center Root / Fit to Screen toggle).
class CanvasControlsOverlay extends StatefulWidget {
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
  State<CanvasControlsOverlay> createState() => _CanvasControlsOverlayState();
}

class _CanvasControlsOverlayState extends State<CanvasControlsOverlay> {
  // Starts false because the canvas launches already centered on the root node,
  // so the first tap triggers "Fit to Screen".
  bool _isCenterMode = false;

  void _handleToggle() {
    ZetaHaptics.selection();
    if (_isCenterMode) {
      widget.onCenterRoot();
    } else {
      widget.onFitToView();
    }
    setState(() {
      _isCenterMode = !_isCenterMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final activeMap = provider.activeMindMap;
    final isBalanced = activeMap?.layoutType == 'balanced';

    final colorScheme = context.colorScheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    return GlassSurface(
      borderRadius: BorderRadius.circular(32),
      blurSigma: 10,
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
      child: M3EToolbar(
        axis: Axis.vertical,
        screenOffset: 0,
        safeArea: false,
        elevation: 0,
        size: M3EToolbarSize.small,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onTertiaryContainer,
        maxInlineActions: isCompact ? 4 : 6,
        actions: [
          // Undo Button
          M3EToolbarAction(
            icon: Icons.undo_rounded,
            tooltip: 'Undo (Ctrl+Z)',
            enabled: provider.canUndo,
            onPressed: () {
              if (provider.canUndo) {
                ZetaHaptics.light();
                provider.undo();
              }
            },
          ),

          // Redo Button
          M3EToolbarAction(
            icon: Icons.redo_rounded,
            tooltip: 'Redo (Ctrl+Y)',
            enabled: provider.canRedo,
            onPressed: () {
              if (provider.canRedo) {
                ZetaHaptics.light();
                provider.redo();
              }
            },
          ),

          // Layout Mode Switcher: Dual-Sided (Balanced) vs Horizontal (LTR)
          M3EToolbarAction(
            icon: isBalanced
                ? Symbols.schema_rounded
                : Symbols.account_tree_rounded,
            tooltip: isBalanced
                ? 'Layout: Dual-Sided (click for Horizontal)'
                : 'Layout: Horizontal (click for Dual-Sided)',
            onPressed: () {
              ZetaHaptics.selection();
              provider.changeLayoutType(isBalanced ? 'horizontal' : 'balanced');
            },
          ),

          // Center on Root / Fit to Screen Toggle
          M3EToolbarAction(
            icon: _isCenterMode
                ? Symbols.center_focus_strong_rounded
                : Symbols.fit_screen_rounded,
            tooltip: _isCenterMode ? 'Center on Root' : 'Fit to Screen',
            onPressed: _handleToggle,
          ),

          // Zoom In
          M3EToolbarAction(
            icon: Icons.add_rounded,
            tooltip: 'Zoom In',
            onPressed: () {
              ZetaHaptics.selection();
              widget.onZoomIn();
            },
          ),

          // Zoom Out
          M3EToolbarAction(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom Out',
            onPressed: () {
              ZetaHaptics.selection();
              widget.onZoomOut();
            },
          ),
        ],
      ),
    );
  }
}