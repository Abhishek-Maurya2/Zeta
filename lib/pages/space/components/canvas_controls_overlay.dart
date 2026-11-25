import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../../components/glass_surface.dart';
import '../../../utils/haptics.dart';
import '../providers/space_provider.dart';

/// Floating canvas navigation and workflow controls using vertically connected
/// button groups for Undo/Redo, Layout/Fit, and Zoom In/Out.
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

  static IconData _getLayoutIcon(String layoutType) {
    switch (layoutType) {
      case 'balanced':
        return Symbols.schema_rounded;
      case 'vertical':
        return Symbols.lan_rounded;
      case 'horizontal':
      default:
        return Symbols.account_tree_rounded;
    }
  }

  static String _getLayoutTooltip(String layoutType) {
    switch (layoutType) {
      case 'horizontal':
        return 'Layout: Horizontal (click for Dual-Sided)';
      case 'balanced':
        return 'Layout: Dual-Sided (click for Vertical)';
      case 'vertical':
        return 'Layout: Vertical (click for Horizontal)';
      default:
        return 'Layout: Horizontal (click to cycle)';
    }
  }

  static String _getNextLayoutType(String current) {
    switch (current) {
      case 'horizontal':
        return 'balanced';
      case 'balanced':
        return 'vertical';
      case 'vertical':
      default:
        return 'horizontal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final activeMap = provider.activeMindMap;
    final layoutType = activeMap?.layoutType ?? 'horizontal';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo / Redo vertically connected group
        _VerticalConnectedButtonPair(
          topAction: _VerticalGroupAction(
            icon: Icons.undo_rounded,
            tooltip: 'Undo (Ctrl+Z)',
            enabled: provider.canUndo,
            onPressed: () {
              ZetaHaptics.light();
              provider.undo();
            },
          ),
          bottomAction: _VerticalGroupAction(
            icon: Icons.redo_rounded,
            tooltip: 'Redo (Ctrl+Y)',
            enabled: provider.canRedo,
            onPressed: () {
              ZetaHaptics.light();
              provider.redo();
            },
          ),
        ),
        const SizedBox(height: 10),

        // Layout & Fit/Center vertically connected group
        _VerticalConnectedButtonPair(
          topAction: _VerticalGroupAction(
            icon: _getLayoutIcon(layoutType),
            tooltip: _getLayoutTooltip(layoutType),
            onPressed: () {
              ZetaHaptics.selection();
              provider.changeLayoutType(_getNextLayoutType(layoutType));
            },
          ),
          bottomAction: _VerticalGroupAction(
            icon: _isCenterMode
                ? Symbols.center_focus_strong_rounded
                : Symbols.fit_screen_rounded,
            tooltip: _isCenterMode ? 'Center on Root' : 'Fit to Screen',
            onPressed: _handleToggle,
          ),
        ),
        const SizedBox(height: 10),

        // Zoom In / Zoom Out vertically connected group
        _VerticalConnectedButtonPair(
          topAction: _VerticalGroupAction(
            icon: Icons.add_rounded,
            tooltip: 'Zoom In',
            onPressed: () {
              ZetaHaptics.selection();
              widget.onZoomIn();
            },
          ),
          bottomAction: _VerticalGroupAction(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom Out',
            onPressed: () {
              ZetaHaptics.selection();
              widget.onZoomOut();
            },
          ),
        ),
      ],
    );
  }
}

class _VerticalGroupAction {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _VerticalGroupAction({
    required this.icon,
    required this.tooltip,
    this.enabled = true,
    required this.onPressed,
  });
}

class _VerticalConnectedButtonPair extends StatelessWidget {
  final _VerticalGroupAction topAction;
  final _VerticalGroupAction bottomAction;

  const _VerticalConnectedButtonPair({
    required this.topAction,
    required this.bottomAction,
  });

  Widget _buildSegment(
    BuildContext context,
    _VerticalGroupAction action,
  ) {
    final colorScheme = context.colorScheme;
    return GlassSurface(
      borderRadius: BorderRadius.circular(6),
      blurSigma: 8,
      color: colorScheme.tertiaryContainer.withValues(
        alpha: action.enabled ? 0.5 : 0.3,
      ),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        width: 1,
      ),
      child: M3EButton(
        style: M3EButtonStyle.tonal,
        size: M3EButtonSize.custom(
          width: 46,
          height: 46,
          hPadding: 0,
          iconSize: 20,
          iconGap: 0,
        ),
        enabled: action.enabled,
        tooltip: action.tooltip,
        onPressed: action.enabled ? action.onPressed : null,
        decoration: M3EButtonDecoration.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onTertiaryContainer,
          borderRadius: 0,
        ),
        child: Icon(action.icon, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(context, topAction),
          const SizedBox(height: 4),
          _buildSegment(context, bottomAction),
        ],
      ),
    );
  }
}
