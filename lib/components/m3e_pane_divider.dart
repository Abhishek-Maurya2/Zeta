import 'package:flutter/material.dart';
import '../utils/haptics.dart';

/// A Material 3 Expressive draggable pane divider.
///
/// Features:
/// - Subtly visible 1dp hairline divider along the pane boundary
/// - 24dp accessible hit-test area for effortless pointer and touch capture
/// - Dynamic pill handle ($4\text{dp}\times 44\text{dp}$ resting $\rightarrow$ $6\text{dp}\times 52\text{dp}$ active/hovered)
/// - Hover elevation, color morphing, and cursor feedback
/// - Double-tap / double-click gesture to reset pane width to canonical defaults
/// - Integrated haptic pulse on interaction
/// - Supports both horizontal and vertical orientations
class M3EPaneDivider extends StatefulWidget {
  /// Callback receiving horizontal or vertical drag delta in logical pixels.
  final ValueChanged<double> onDragUpdate;

  /// Callback when dragging starts.
  final VoidCallback? onDragStart;

  /// Callback when dragging ends.
  final VoidCallback? onDragEnd;

  /// Callback when user double taps or double clicks the divider to reset/toggle.
  final VoidCallback? onDoubleTap;

  /// Custom tooltip message.
  final String tooltip;

  /// Whether to render a 1dp hairline along the divider center (default false).
  final bool showLine;

  /// The orientation of the divider.
  final Axis orientation;

  const M3EPaneDivider({
    super.key,
    required this.onDragUpdate,
    this.onDragStart,
    this.onDragEnd,
    this.onDoubleTap,
    this.tooltip = 'Drag to resize · Double-tap to reset',
    this.showLine = false,
    this.orientation = Axis.horizontal,
  });

  @override
  State<M3EPaneDivider> createState() => _M3EPaneDividerState();
}

class _M3EPaneDividerState extends State<M3EPaneDivider> {
  bool _isHovered = false;
  bool _isDragging = false;

  void _handleDoubleTap() {
    ZetaHaptics.medium();
    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _isHovered || _isDragging;
    final isHorizontal = widget.orientation == Axis.horizontal;

    // Handle pill styling (M3 canonical dimensions: 4dp x 48dp resting, 10dp x 52dp active/dragging)
    final pillThickness = _isDragging ? 10.0 : (isActive ? 6.0 : 4.0);
    final pillLength = _isDragging ? 52.0 : 48.0;
    final cornerRadius = _isDragging ? 5.0 : (pillThickness / 2);
    
    final handleWidth = isHorizontal ? pillThickness : pillLength;
    final handleHeight = isHorizontal ? pillLength : pillThickness;
    
    final handleColor = _isDragging
        ? colorScheme.tertiary
        : (isActive
            ? colorScheme.onSurfaceVariant
            : colorScheme.outline);

    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : (isHorizontal ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow),
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          setState(() => _isDragging = true);
          ZetaHaptics.selection();
          widget.onDragStart?.call();
        },
        onPanUpdate: (details) {
          widget.onDragUpdate(isHorizontal ? details.delta.dx : details.delta.dy);
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onPanCancel: () {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onDoubleTap: _handleDoubleTap,
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 600),
          child: SizedBox(
            width: isHorizontal ? 24.0 : double.infinity, 
            height: isHorizontal ? double.infinity : 24.0, 
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.showLine)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: isHorizontal ? 1.0 : double.infinity,
                        height: isHorizontal ? double.infinity : 1.0,
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),

                // Interactive Drag Handle Pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: handleWidth,
                  height: handleHeight,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(cornerRadius),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.22),
                              blurRadius: 6.0,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias for [M3EPaneDivider].
typedef M3PaneDivider = M3EPaneDivider;
