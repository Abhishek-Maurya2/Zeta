import 'package:flutter/material.dart';

import 'm3e_pane_divider.dart';

/// A Material 3 Expressive dual-view layout that separates content with a movable drag handle.
class M3ESplitPane extends StatefulWidget {
  /// The content at the logical start side of the pane.
  final Widget? start;

  /// The content at the logical end side of the pane.
  final Widget? end;

  /// The orientation of the split.
  final Axis orientation;

  /// A fractional value, between 0 and 100, indicating the size of the start pane.
  final double value;

  /// A fractional value, between 0 and 100, indicating the minimum size of the start pane.
  final double min;

  /// A fractional value, between 0 and 100, indicating the maximum size of the start pane.
  final double max;

  /// A fractional value, between 0 and 100, indicating the maximum visual overshoot allowed.
  final double overshootLimit;

  /// Detents (discrete sizes) the start pane can snap to.
  final List<double> detents;

  /// Callback when the user adjusts the drag handle.
  final ValueChanged<double>? onChanged;

  /// Callback when the user finishes adjusting the drag handle (drag ends).
  final ValueChanged<double>? onChangeEnd;

  /// Callback when the user double taps the drag handle. If not provided, it will cycle through detents if any exist.
  final VoidCallback? onDoubleTap;

  /// Accessible label for the drag handle.
  final String label;

  const M3ESplitPane({
    super.key,
    this.start,
    this.end,
    this.orientation = Axis.horizontal,
    this.value = 50,
    this.min = 0,
    this.max = 100,
    this.overshootLimit = 4,
    this.detents = const [],
    this.onChanged,
    this.onChangeEnd,
    this.onDoubleTap,
    this.label = 'Resize panes',
  });

  @override
  State<M3ESplitPane> createState() => _M3ESplitPaneState();
}

class _M3ESplitPaneState extends State<M3ESplitPane> {
  double? _dragStartValue;
  double _totalDelta = 0.0;
  double _dragCacheSize = 0;
  bool _isDragging = false;
  
  // Track visual value during drag to allow overshoot, then snap back.
  double? _currentDragValue;

  double get _effectiveValue => (_isDragging && _currentDragValue != null) 
      ? _currentDragValue! 
      : widget.value;

  void _handleDragStart(BoxConstraints constraints) {
    setState(() {
      _isDragging = true;
      _dragStartValue = widget.value;
      _totalDelta = 0.0;
      _dragCacheSize = widget.orientation == Axis.horizontal 
          ? constraints.maxWidth 
          : constraints.maxHeight;
      _currentDragValue = widget.value;
    });
  }

  void _handleDragUpdate(double delta) {
    if (!_isDragging || _dragStartValue == null || _dragCacheSize == 0) return;

    _totalDelta += delta;

    // Convert total pixel displacement to percentage delta
    double percentDelta = (_totalDelta / _dragCacheSize) * 100;
    
    // Support RTL if horizontal
    if (widget.orientation == Axis.horizontal && Directionality.of(context) == TextDirection.rtl) {
      percentDelta = -percentDelta;
    }

    double nextValue = _dragStartValue! + percentDelta;

    if (nextValue < widget.min) {
      final overshoot = widget.min - nextValue;
      final compressed = (widget.overshootLimit * overshoot) / (overshoot + widget.overshootLimit);
      nextValue = widget.min - compressed;
    } else if (nextValue > widget.max) {
      final overshoot = nextValue - widget.max;
      final compressed = (widget.overshootLimit * overshoot) / (overshoot + widget.overshootLimit);
      nextValue = widget.max + compressed;
    }

    setState(() {
      _currentDragValue = nextValue;
    });
    
    // Fire onChanged with clamped value to allow parent to update state without overshoot
    widget.onChanged?.call(nextValue.clamp(widget.min, widget.max));
  }

  void _handleDragEnd() {
    if (!_isDragging) return;

    double finalValue = _currentDragValue ?? widget.value;
    
    // Snap to closest detent if any, or clamp
    final detent = _getClosestDetent(finalValue);
    if (detent != null) {
      finalValue = detent;
    } else {
      finalValue = finalValue.clamp(widget.min, widget.max);
    }

    setState(() {
      _isDragging = false;
      _dragStartValue = null;
      _currentDragValue = null;
      _totalDelta = 0.0;
    });

    widget.onChanged?.call(finalValue);
    widget.onChangeEnd?.call(finalValue);
  }

  void _handleDoubleTap() {
    if (widget.onDoubleTap != null) {
      widget.onDoubleTap!();
      return;
    }
    
    if (widget.detents.isEmpty) return;
    
    final currentDetent = _getClosestDetent(widget.value);
    if (currentDetent == null) {
      widget.onChanged?.call(widget.detents.first);
      widget.onChangeEnd?.call(widget.detents.first);
      return;
    }
    
    final int index = widget.detents.indexOf(currentDetent);
    final int nextIndex = (index + 1) % widget.detents.length;
    widget.onChanged?.call(widget.detents[nextIndex]);
    widget.onChangeEnd?.call(widget.detents[nextIndex]);
  }

  double? _getClosestDetent(double val) {
    if (widget.detents.isEmpty) return null;
    
    double closest = widget.detents.first;
    double minDiff = (val - closest).abs();
    
    for (final d in widget.detents) {
      final double diff = (val - d).abs();
      if (diff < minDiff) {
        closest = d;
        minDiff = diff;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = widget.orientation == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;

        if (!totalSize.isFinite || totalSize <= 0) {
          return const SizedBox.shrink();
        }

        final bool hasStart = widget.start != null;
        final bool hasEnd = widget.end != null;

        // If only start is provided, give it 100% of available space
        if (hasStart && !hasEnd) {
          return SizedBox.expand(
            child: widget.start!,
          );
        }

        // If only end is provided, give it 100% of available space
        if (!hasStart && hasEnd) {
          return SizedBox.expand(
            child: widget.end!,
          );
        }

        if (!hasStart && !hasEnd) {
          return const SizedBox.shrink();
        }

        final isHorizontal = widget.orientation == Axis.horizontal;
        
        final val = _effectiveValue.clamp(-100.0, 200.0);
        double startFraction = (val / 100.0).clamp(0.0, 1.0);
        
        // Subtract half of the divider's container width (24.0 / 2 = 12.0)
        double startSize = totalSize * startFraction - 12.0;
        if (startSize < 0) startSize = 0;

        // Hide panes based on values (simulating web component's inert / hidden behavior)
        final bool showStart = val > 0;
        final bool showEnd = val < 100;

        Widget divider = M3EPaneDivider(
          orientation: widget.orientation,
          onDragStart: () => _handleDragStart(constraints),
          onDragUpdate: _handleDragUpdate,
          onDragEnd: _handleDragEnd,
          onDoubleTap: _handleDoubleTap,
          tooltip: widget.label,
          showLine: false,
        );
        
        List<Widget> children = [];
        
        if (showStart && showEnd) {
          children.add(
            SizedBox(
              width: isHorizontal ? startSize : null,
              height: isHorizontal ? null : startSize,
              child: widget.start!,
            ),
          );
          children.add(divider);
          children.add(
            Expanded(
              child: widget.end!,
            ),
          );
        } else if (showStart) {
          children.add(
            Expanded(
              child: widget.start!,
            ),
          );
        } else if (showEnd) {
          children.add(
            Expanded(
              child: widget.end!,
            ),
          );
        }

        return Flex(
          direction: widget.orientation,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}
