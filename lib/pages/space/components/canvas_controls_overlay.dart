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
    final canUndo = context.select<SpaceProvider, bool>((p) => p.canUndo);
    final canRedo = context.select<SpaceProvider, bool>((p) => p.canRedo);
    final layoutType = context.select<SpaceProvider, String>(
      (p) => p.activeMindMap?.layoutType ?? 'horizontal',
    );
    final provider = context.read<SpaceProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo / Redo vertically connected group
        _VerticalConnectedButtonPair(
          topAction: _VerticalGroupAction(
            icon: Icons.undo_rounded,
            tooltip: 'Undo (Ctrl+Z)',
            enabled: canUndo,
            onPressed: () {
              ZetaHaptics.light();
              provider.undo();
            },
          ),
          bottomAction: _VerticalGroupAction(
            icon: Icons.redo_rounded,
            tooltip: 'Redo (Ctrl+Y)',
            enabled: canRedo,
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

  Widget _buildSegmentButton(
    BuildContext context,
    _VerticalGroupAction action, {
    required bool isTop,
  }) {
    final colorScheme = context.colorScheme;
    final borderRadius = isTop
        ? const BorderRadius.vertical(
            top: Radius.circular(30),
            bottom: Radius.circular(4),
          )
        : const BorderRadius.vertical(
            top: Radius.circular(4),
            bottom: Radius.circular(30),
          );

    return GlassSurface(
      borderRadius: borderRadius,
      blurSigma: 8,
      color: colorScheme.tertiaryContainer.withValues(
        alpha: action.enabled ? 0.55 : 0.28,
      ),
      child: M3EButton(
        style: M3EButtonStyle.tonal,
        size: M3EButtonSize.custom(
          width: 43,
          height: 44,
          hPadding: 0,
          iconSize: 20,
          iconGap: 0,
        ),
        enabled: action.enabled,
        tooltip: action.tooltip,
        onPressed: action.enabled ? action.onPressed : null,
        decoration: M3EButtonDecoration.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: action.enabled
              ? colorScheme.onTertiaryContainer
              : colorScheme.onTertiaryContainer.withValues(alpha: 0.4),
          elevation: 0,
          borderRadius: 0,
        ),
        child: Icon(
          action.icon,
          size: 20,
          color: action.enabled
              ? colorScheme.onTertiaryContainer
              : colorScheme.onTertiaryContainer.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSegmentButton(context, topAction, isTop: true),
        const SizedBox(height: 2),
        _buildSegmentButton(context, bottomAction, isTop: false),
      ],
    );
  }
}
