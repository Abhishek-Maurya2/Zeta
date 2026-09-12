import 'package:flutter/material.dart';

/// A Material Design 3 draggable pane divider with an expressive drag handle pill,
/// hit-testing region, hover animations, and gesture support for resizing panes.
class M3PaneDivider extends StatefulWidget {
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

  const M3PaneDivider({
    super.key,
    required this.onDragUpdate,
    this.onDragStart,
    this.onDragEnd,
    this.onDoubleTap,
    this.tooltip = 'Drag to resize · Double-tap to reset (360dp)',
  });

  @override
  State<M3PaneDivider> createState() => _M3PaneDividerState();
}

class _M3PaneDividerState extends State<M3PaneDivider> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _isHovered || _isDragging;

    // Handle pill styling (M3 canonical dimensions: 4dp x 48dp, expanding on active)
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
        onDoubleTap: widget.onDoubleTap,
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 700),
          child: SizedBox(
            width: 16.0, // Touch / grab area
            child: Stack(
              alignment: Alignment.center,
              children: [                // Drag Handle Pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  width: handleWidth,
                  height: handleHeight,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(4.0),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.15),
                              blurRadius: 4.0,
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
