import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../components/m3e_pane_divider.dart';
import '../../theme/breakpoints.dart';
import '../../theme/motion_tokens.dart';

/// Controller for programmatic control over the supporting pane (open, close, toggle, resize).
class SupportingPaneController extends ChangeNotifier {
  bool _isOpen;
  double _paneWidth;

  SupportingPaneController({
    bool initialOpen = false,
    double initialWidth = 400.0,
  }) : _isOpen = initialOpen,
       _paneWidth = initialWidth;

  bool get isOpen => _isOpen;
  double get paneWidth => _paneWidth;

  void open() {
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  void close() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  void toggle() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void setWidth(double width) {
    if (_paneWidth != width) {
      _paneWidth = width;
      notifyListeners();
    }
  }
}

/// A canonical Material 3 Expressive Supporting Pane Layout.
///
/// Implements Material 3 Expressive adaptive layout guidelines:
/// - Compact (< 600dp): Displays only the primary pane; supporting pane opens as modal/sheet.
/// - Medium (600dp - 839dp) & Expanded (>= 840dp): Side-by-side co-planar layout
///   with draggable tactile divider, spring physics, and fluid panning transitions.
class SupportingPaneScaffold extends StatefulWidget {
  final Widget primaryPane;
  final Widget? supportingPane;
  final SupportingPaneController? controller;
  final double defaultPaneWidth;
  final double minPaneWidth;
  final double maxPaneWidth;
  final List<double> detents;

  const SupportingPaneScaffold({
    super.key,
    required this.primaryPane,
    this.supportingPane,
    this.controller,
    this.defaultPaneWidth = 400.0,
    this.minPaneWidth = 320.0,
    this.maxPaneWidth = 600.0,
    this.detents = const [360.0, 420.0, 500.0],
  });

  @override
  State<SupportingPaneScaffold> createState() => _SupportingPaneScaffoldState();
}

class _SupportingPaneScaffoldState extends State<SupportingPaneScaffold>
    with SingleTickerProviderStateMixin {
  late final SupportingPaneController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  bool _internalControllerCreated = false;
  double _currentWidth = 400.0;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = SupportingPaneController(
        initialOpen: widget.supportingPane != null,
        initialWidth: widget.defaultPaneWidth,
      );
      _internalControllerCreated = true;
    }

    _currentWidth = _controller.paneWidth;

    _animationController = AnimationController(
      vsync: this,
      duration: M3MotionDuration.medium4,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: M3MotionEasing.emphasizedDecelerate,
      reverseCurve: M3MotionEasing.emphasizedAccelerate,
    );

    if (_controller.isOpen && widget.supportingPane != null) {
      _animationController.value = 1.0;
    }

    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SupportingPaneScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.supportingPane != null && !_controller.isOpen) {
      _controller.open();
    } else if (widget.supportingPane == null && _controller.isOpen) {
      _controller.close();
    }
  }

  void _onControllerChanged() {
    if (_controller.isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    if (_currentWidth != _controller.paneWidth) {
      setState(() {
        _currentWidth = _controller.paneWidth;
      });
    }
  }

  void _snapToNearestDetent(double targetWidth) {
    if (widget.detents.isEmpty) return;
    double closest = widget.detents.first;
    double minDiff = (targetWidth - closest).abs();
    for (final d in widget.detents) {
      final diff = (targetWidth - d).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = d;
      }
    }
    _controller.setWidth(closest);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_internalControllerCreated) {
      _controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < ZetaBreakpoints.mediumMin;

    if (isCompact) {
      // On mobile / compact form factor, render primary pane full-width.
      return widget.primaryPane;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxAllowed = math
            .min(widget.maxPaneWidth, constraints.maxWidth * 0.55)
            .clamp(0.0, widget.maxPaneWidth);
        final minAllowed = math.min(widget.minPaneWidth, maxAllowed);
        final clampedWidth = _currentWidth.clamp(minAllowed, maxAllowed);

        return Stack(
          children: [
            Row(
              children: [
                // Primary Content Area
                Expanded(child: RepaintBoundary(child: widget.primaryPane)),

                // Animated Supporting Pane with spring-driven M3 Expressive physics
                if (widget.supportingPane != null)
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      final animValue = _expandAnimation.value;
                      if (animValue == 0.0) return const SizedBox.shrink();

                      final paneEffectiveWidth = clampedWidth * animValue;

                      return RepaintBoundary(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Accessible Tactile Drag Divider
                            M3EPaneDivider(
                              orientation: Axis.horizontal,
                              showLine: false,
                              onDragUpdate: (delta) {
                                final newW = (_currentWidth - delta).clamp(
                                  minAllowed,
                                  maxAllowed,
                                );
                                setState(() {
                                  _currentWidth = newW;
                                });
                                _controller.setWidth(newW);
                              },
                              onDragEnd: () {
                                _snapToNearestDetent(_currentWidth);
                              },
                              onDoubleTap: () {
                                _controller.setWidth(widget.defaultPaneWidth);
                              },
                            ),
                            // Supporting Pane Container
                            ClipRect(
                              child: SizedBox(
                                width: paneEffectiveWidth,
                                child: OverflowBox(
                                  minWidth: clampedWidth,
                                  maxWidth: clampedWidth,
                                  alignment: Alignment.topLeft,
                                  child: widget.supportingPane,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
