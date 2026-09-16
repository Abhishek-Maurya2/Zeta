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
class M3EPaneDivider extends StatefulWidget {
  /// Callback receiving horizontal drag delta in logical pixels.
  final ValueChanged<double> onDragUpdate;

  /// Callback when dragging starts.
  final VoidCallback? onDragStart;

  /// Callback when dragging ends.
  final VoidCallback? onDragEnd;

  /// Callback when user double taps or double clicks the divider to reset/toggle.
  final VoidCallback? onDoubleTap;

  /// Custom tooltip message.
  final String tooltip;

  const M3EPaneDivider({
    super.key,
    required this.onDragUpdate,
    this.onDragStart,
    this.onDragEnd,
    this.onDoubleTap,
    this.tooltip = 'Drag to resize · Double-tap to reset',
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

    // Handle pill styling (M3 canonical dimensions: 4dp x 44dp resting, 6dp x 52dp active)
    final handleWidth = isActive ? 6.0 : 4.0;
    final handleHeight = isActive ? 52.0 : 44.0;
    final handleColor = _isDragging
        ? colorScheme.primary
        : (isActive
            ? colorScheme.onSurfaceVariant
            : colorScheme.outlineVariant.withValues(alpha: 0.85));

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          setState(() => _isDragging = true);
          ZetaHaptics.selection();
          widget.onDragStart?.call();
        },
        onHorizontalDragUpdate: (details) {
          widget.onDragUpdate(details.delta.dx);
        },
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onHorizontalDragCancel: () {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        onDoubleTap: _handleDoubleTap,
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 600),
          child: SizedBox(
            width: 24.0, // 24dp accessible hit-test area
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Subtle vertical 1dp hairline divider
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 1.0,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                // 2. Interactive Drag Handle Pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: handleWidth,
                  height: handleHeight,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular( handleWidth / 2 ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.18),
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
