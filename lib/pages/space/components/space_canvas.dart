import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../models/mindmap_edge.dart';
import '../providers/space_provider.dart';
import '../services/mindmap_layout_engine.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/haptics.dart';
import '../../../theme/motion_tokens.dart'; // <-- Adjust path to your M3Motion file
import 'dot_matrix_painter.dart';
import 'mindmap_edge_painter.dart';
import 'mindmap_node_widget.dart';
import 'canvas_controls_overlay.dart';
import 'space_floating_toolbar.dart';
import 'create_mindmap_dialog.dart';

/// The infinite, scrollable, zoomable dotmatrix canvas that hosts the mindmap,
/// top floating toolbar, canvas controls, and the M3E FAB menu.
class SpaceCanvas extends StatefulWidget {
  const SpaceCanvas({super.key});

  @override
  State<SpaceCanvas> createState() => _SpaceCanvasState();
}

class _SpaceCanvasState extends State<SpaceCanvas> {
  static const double canvasSize = 8000.0;
  late final TransformationController _transformationController;
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'SpaceCanvasFocus');
  bool _initializedCenter = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _canvasFocusNode.dispose();
    super.dispose();
  }

  void _centerOnRoot(Size viewportSize) {
    const originX = MindMapLayoutEngine.canvasOriginX;
    const originY = MindMapLayoutEngine.canvasOriginY;

    final targetX = (viewportSize.width / 2.0) - originX;
    final targetY = (viewportSize.height / 2.0) - originY;

    final matrix = Matrix4.identity();
    matrix.storage[0] = 1.0;
    matrix.storage[5] = 1.0;
    matrix.storage[12] = targetX;
    matrix.storage[13] = targetY;

    _transformationController.value = matrix;
  }

  void _zoomBy(double factor, Size viewportSize) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.15, 3.0);
    final scaleDelta = newScale / currentScale;

    final translation = currentMatrix.getTranslation();
    final cx = viewportSize.width / 2.0;
    final cy = viewportSize.height / 2.0;

    final matrix = Matrix4.identity();
    matrix.storage[0] = newScale;
    matrix.storage[5] = newScale;
    matrix.storage[12] = cx - (cx - translation.x) * scaleDelta;
    matrix.storage[13] = cy - (cy - translation.y) * scaleDelta;

    _transformationController.value = matrix;
  }

  void _fitToView(Size viewportSize, Rect totalBounds) {
    if (totalBounds.isEmpty || viewportSize.isEmpty) return;

    const padding = 100.0;
    final scaleX = (viewportSize.width - padding) / totalBounds.width;
    final scaleY = (viewportSize.height - padding) / totalBounds.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.2, 1.5);

    final targetX =
        (viewportSize.width / 2.0) - (totalBounds.center.dx * scale);
    final targetY =
        (viewportSize.height / 2.0) - (totalBounds.center.dy * scale);

    final matrix = Matrix4.identity();
    matrix.storage[0] = scale;
    matrix.storage[5] = scale;
    matrix.storage[12] = targetX;
    matrix.storage[13] = targetY;

    _transformationController.value = matrix;
  }

  Future<void> _handleCreateMindmap() async {
    ZetaHaptics.medium();
    final title = await CreateMindMapDialog.show(context);
    if (title != null && mounted) {
      await context.read<SpaceProvider>().createMindMap(title);
    }
  }

  Future<void> _handleRenameMindmap() async {
    final provider = context.read<SpaceProvider>();
    final activeMap = provider.activeMindMap;
    if (activeMap == null) return;
    ZetaHaptics.light();
    final newTitle = await CreateMindMapDialog.show(
      context,
      initialTitle: activeMap.title,
      isRename: true,
    );
    if (newTitle != null && mounted) {
      await provider.renameActiveMindMap(newTitle);
    }
  }

  Future<void> _handleDeleteMindmap() async {
    final provider = context.read<SpaceProvider>();
    final activeMap = provider.activeMindMap;
    if (activeMap == null) return;
    ZetaHaptics.light();
    if (provider.mindMaps.length > 1) {
      await provider.deleteActiveMindMap();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete the only remaining mindmap.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final provider = context.read<SpaceProvider>();
    final isEditing = provider.editingNodeId != null;

    final isCtrlOrCmd =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (isShift) {
        provider.redo();
      } else {
        provider.undo();
      }
      return KeyEventResult.handled;
    }
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyY) {
      provider.redo();
      return KeyEventResult.handled;
    }

    if (isEditing) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        provider.stopEditingNode();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final selectedId = provider.selectedNodeId;
    if (selectedId != null) {
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        provider.addChildNode(parentId: selectedId);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        provider.addSiblingNode(siblingOfId: selectedId);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.f2) {
        provider.startEditingNode(selectedId);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        provider.deleteNode(selectedId);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        provider.selectNode(null);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final activeMap = provider.activeMindMap;

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    if (provider.isLoading || activeMap == null) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    final canvasBgColor = isDark
        ? colorScheme.surfaceContainerLowest
        : colorScheme.surface;

    final dotColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.22)
        : colorScheme.outlineVariant.withValues(alpha: 0.40);

    final layoutResult = MindMapLayoutEngine.computeLayout(
      mindMap: activeMap,
      defaultEdgeColor: colorScheme.primary,
      colorScheme: colorScheme,
      baseTextStyle: textTheme.bodyMedium,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (!_initializedCenter &&
            viewportSize.width > 0 &&
            viewportSize.height > 0) {
          _initializedCenter = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerOnRoot(viewportSize);
          });
        }

        return Focus(
          focusNode: _canvasFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: ColoredBox(
            color: canvasBgColor,
            child: Stack(
              children: [
                // Layer 0: Viewport-Culled Dot-Matrix Grid
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: DotMatrixPainter(
                        dotColor: dotColor,
                        transformationController: _transformationController,
                        spacing: 24.0,
                        dotRadius: 1.25,
                      ),
                    ),
                  ),
                ),

                // Layer 1: Zoomable & Scrollable Interactive Canvas
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: const EdgeInsets.all(3000),
                    minScale: 0.15,
                    maxScale: 3.0,
                    constrained: false,
                    child: SizedBox(
                      width: canvasSize,
                      height: canvasSize,
                      child: Stack(
                        children: [
                          // Sub-Layer 0: Background Tap Target
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                provider.selectNode(null);
                                provider.stopEditingNode();
                                _canvasFocusNode.requestFocus();
                              },
                            ),
                          ),

                          // Sub-Layer 1: Smooth M3-Animated Cubic Bézier Spline Connectors
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _AnimatedMindMapEdges(
                                edges: layoutResult.edges,
                                hoveredNodeId: provider.hoverTargetId,
                                isDark: isDark,
                              ),
                            ),
                          ),

                          // Sub-Layer 2: Interactive MindMap Node Cards
                          for (final node in activeMap.nodes)
                            if (layoutResult.nodeBounds.containsKey(node.id))
                              MindMapNodeWidget(
                                key: ValueKey(node.id),
                                node: node,
                                bounds: layoutResult.nodeBounds[node.id]!,
                                branchColor:
                                    layoutResult.nodeColors[node.id] ??
                                    colorScheme.primary,
                                hasChildren: activeMap
                                    .childrenOf(node.id)
                                    .isNotEmpty,
                                childCount: activeMap
                                    .childrenOf(node.id)
                                    .length,
                                isLeft:
                                    layoutResult.nodeIsLeft[node.id] ?? false,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Refined Top Floating Toolbar
                const Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SpaceFloatingToolbar(),
                  ),
                ),

                // 3. Canvas Zoom Controls
                Positioned(
                  left: 15,
                  bottom: 15,
                  child: CanvasControlsOverlay(
                    onZoomIn: () => _zoomBy(1.2, viewportSize),
                    onZoomOut: () => _zoomBy(0.8, viewportSize),
                    onCenterRoot: () => _centerOnRoot(viewportSize),
                    onFitToView: () =>
                        _fitToView(viewportSize, layoutResult.totalBounds),
                  ),
                ),

                // 4. M3EFabMenu
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: M3EFabMenu(
                    color: M3EFabColor.primary,
                    position: M3EFabMenuPosition.right,
                    icon: const Icon(Icons.add_rounded),
                    items: [
                      M3EFabMenuItem(
                        icon: const Icon(Icons.add_chart_rounded),
                        label: 'New Mindmap',
                        onPressed: _handleCreateMindmap,
                      ),
                      M3EFabMenuItem(
                        icon: const Icon(Symbols.edit_rounded),
                        label: 'Rename Mindmap',
                        onPressed: _handleRenameMindmap,
                      ),
                      M3EFabMenuItem(
                        icon: const Icon(Symbols.delete_rounded),
                        label: 'Delete Mindmap',
                        onPressed: _handleDeleteMindmap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Smoothly interpolates procedural Bézier edges using M3MotionDuration.medium3
/// and M3MotionEasing.emphasized so connector splines stay glued to nodes as they
/// expand, collapse, or reorder.
class _AnimatedMindMapEdges extends StatefulWidget {
  final List<MindMapEdge> edges;
  final String? hoveredNodeId;
  final bool isDark;

  const _AnimatedMindMapEdges({
    required this.edges,
    required this.hoveredNodeId,
    required this.isDark,
  });

  @override
  State<_AnimatedMindMapEdges> createState() => _AnimatedMindMapEdgesState();
}

class _AnimatedMindMapEdgesState extends State<_AnimatedMindMapEdges>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;

  Map<String, MindMapEdge> _fromEdges = {};
  List<MindMapEdge> _currentEdges = [];

  @override
  void initState() {
    super.initState();
    _currentEdges = widget.edges;
    _fromEdges = {for (final e in widget.edges) e.targetId: e};

    _controller = AnimationController(
      vsync: this,
      duration: M3MotionDuration.medium3,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: M3MotionEasing.emphasized,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedMindMapEdges oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.edges, widget.edges)) {
      // Snapshot current interpolated positions as the new starting point
      final interpolated = _evaluateEdges(_curvedAnimation.value);
      _fromEdges = {for (final e in interpolated) e.targetId: e};
      _currentEdges = widget.edges;
      _controller.forward(from: 0.0);
    }
  }

  List<MindMapEdge> _evaluateEdges(double t) {
    if (t >= 1.0 || _fromEdges.isEmpty) return _currentEdges;

    return _currentEdges.map((targetEdge) {
      final prev = _fromEdges[targetEdge.targetId];
      if (prev == null) {
        // Newly expanded edge: unfurl outward from its parent's current startPoint
        final start = targetEdge.startPoint;
        final end =
            Offset.lerp(targetEdge.startPoint, targetEdge.endPoint, t) ??
            targetEdge.endPoint;
        return MindMapEdge(
          sourceId: targetEdge.sourceId,
          targetId: targetEdge.targetId,
          startPoint: start,
          endPoint: end,
          color: targetEdge.color,
          strokeWidth: targetEdge.strokeWidth * t,
          isLeft: targetEdge.isLeft,
        );
      }

      return MindMapEdge(
        sourceId: targetEdge.sourceId,
        targetId: targetEdge.targetId,
        startPoint:
            Offset.lerp(prev.startPoint, targetEdge.startPoint, t) ??
            targetEdge.startPoint,
        endPoint:
            Offset.lerp(prev.endPoint, targetEdge.endPoint, t) ??
            targetEdge.endPoint,
        color:
            Color.lerp(prev.color, targetEdge.color, t) ?? targetEdge.color,
        strokeWidth:
            prev.strokeWidth + (targetEdge.strokeWidth - prev.strokeWidth) * t,
        isLeft: targetEdge.isLeft,
      );
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curvedAnimation,
      builder: (context, _) {
        return CustomPaint(
          painter: MindMapEdgePainter(
            edges: _evaluateEdges(_curvedAnimation.value),
            hoveredNodeId: widget.hoveredNodeId,
            isDark: widget.isDark,
          ),
        );
      },
    );
  }
}