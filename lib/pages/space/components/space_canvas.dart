import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../providers/space_provider.dart';
import '../services/mindmap_layout_engine.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/haptics.dart';
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

  void _zoomBy(double factor) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.15, 3.0);
    final scaleDelta = newScale / currentScale;

    final translation = currentMatrix.getTranslation();
    final matrix = Matrix4.identity();
    matrix.storage[0] = newScale;
    matrix.storage[5] = newScale;
    matrix.storage[12] = translation.x * scaleDelta;
    matrix.storage[13] = translation.y * scaleDelta;

    _transformationController.value = matrix;
  }

  void _fitToView(Size viewportSize, Rect totalBounds) {
    if (totalBounds.isEmpty || viewportSize.isEmpty) return;

    const padding = 100.0;
    final scaleX = (viewportSize.width - padding) / totalBounds.width;
    final scaleY = (viewportSize.height - padding) / totalBounds.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.2, 1.5);

    final targetX = (viewportSize.width / 2.0) - (totalBounds.center.dx * scale);
    final targetY = (viewportSize.height / 2.0) - (totalBounds.center.dy * scale);

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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final provider = context.read<SpaceProvider>();
    final isEditing = provider.editingNodeId != null;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Global Undo / Redo
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

    // When editing text, let the TextField handle typing
    if (isEditing) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        provider.stopEditingNode();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Keyboard-First Node CRUD when a node is selected:
    final selectedId = provider.selectedNodeId;
    if (selectedId != null) {
      // Tab: Create child node
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        provider.addChildNode(parentId: selectedId);
        return KeyEventResult.handled;
      }

      // Enter: Create sibling node
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        provider.addSiblingNode(siblingOfId: selectedId);
        return KeyEventResult.handled;
      }

      // F2: Inline text edit
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        provider.startEditingNode(selectedId);
        return KeyEventResult.handled;
      }

      // Delete / Backspace: Cascade delete
      if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        provider.deleteNode(selectedId);
        return KeyEventResult.handled;
      }

      // Escape: Deselect
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

    // React to global theme changes via ThemeProvider and ZetaContextX
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isCompact = context.isCompact;

    if (provider.isLoading || activeMap == null) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    // Dynamic theme-driven canvas and dot matrix colors
    final canvasBgColor = isDark
        ? colorScheme.surfaceContainerLowest
        : colorScheme.surface;

    final dotColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.22)
        : colorScheme.outlineVariant.withValues(alpha: 0.40);

    // Step 1: Compute Layout with dynamic color scheme and text theme
    final layoutResult = MindMapLayoutEngine.computeLayout(
      mindMap: activeMap,
      defaultEdgeColor: colorScheme.primary,
      colorScheme: colorScheme,
      baseTextStyle: textTheme.bodyMedium,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Center on root on initial build
        if (!_initializedCenter && viewportSize.width > 0 && viewportSize.height > 0) {
          _initializedCenter = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerOnRoot(viewportSize);
          });
        }

        return Focus(
          focusNode: _canvasFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Stack(
            children: [
              // 1. Zoomable & Scrollable Dotmatrix Canvas
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(3000),
                  minScale: 0.15,
                  maxScale: 3.0,
                  constrained: false,
                  child: GestureDetector(
                    onTap: () {
                      // Tap on canvas background clears selection and commits active edit
                      provider.selectNode(null);
                      provider.stopEditingNode();
                      _canvasFocusNode.requestFocus();
                    },
                    child: Container(
                      width: canvasSize,
                      height: canvasSize,
                      color: canvasBgColor,
                      child: Stack(
                        children: [
                          // Layer 1: Dot-matrix Background Grid (Theme & Mode reactive)
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: DotMatrixPainter(
                                  dotColor: dotColor,
                                  spacing: 24.0,
                                  dotRadius: 1.25,
                                ),
                              ),
                            ),
                          ),

                          // Layer 2: Procedural Cubic Bézier Spline Connectors
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: MindMapEdgePainter(
                                  edges: layoutResult.edges,
                                  hoveredNodeId: provider.hoverTargetId,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),

                          // Layer 3: Interactive MindMap Node Cards
                          for (final node in activeMap.nodes)
                            if (layoutResult.nodeBounds.containsKey(node.id))
                              MindMapNodeWidget(
                                key: ValueKey(node.id),
                                node: node,
                                bounds: layoutResult.nodeBounds[node.id]!,
                                branchColor: layoutResult.nodeColors[node.id] ?? colorScheme.primary,
                                hasChildren: activeMap.childrenOf(node.id).isNotEmpty,
                                childCount: activeMap.childrenOf(node.id).length,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Refined Top Floating Toolbar (eliminating full-width topbar)
              const Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SpaceFloatingToolbar(),
                ),
              ),

              // 3. Canvas Zoom Controls (Zoom In, Zoom Out, Center, Fit)
              Positioned(
                left: 16,
                bottom: isCompact ? 88 : 24,
                child: CanvasControlsOverlay(
                  onZoomIn: () => _zoomBy(1.2),
                  onZoomOut: () => _zoomBy(0.8),
                  onCenterRoot: () => _centerOnRoot(viewportSize),
                  onFitToView: () => _fitToView(viewportSize, layoutResult.totalBounds),
                ),
              ),

              // 4. M3EFabMenu with rich actions
              Positioned(
                right: 20,
                bottom: isCompact ? 88 : 24,
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
                      icon: const Icon(Icons.subdirectory_arrow_right_rounded),
                      label: 'Add Child (Tab)',
                      onPressed: () {
                        ZetaHaptics.light();
                        provider.addChildNode();
                      },
                    ),
                    M3EFabMenuItem(
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: 'Add Sibling (Enter)',
                      onPressed: () {
                        ZetaHaptics.light();
                        provider.addSiblingNode();
                      },
                    ),
                    M3EFabMenuItem(
                      icon: const Icon(Symbols.center_focus_strong_rounded),
                      label: 'Center on Root',
                      onPressed: () {
                        ZetaHaptics.selection();
                        _centerOnRoot(viewportSize);
                      },
                    ),
                    M3EFabMenuItem(
                      icon: const Icon(Symbols.fit_screen_rounded),
                      label: 'Fit to Screen',
                      onPressed: () {
                        ZetaHaptics.selection();
                        _fitToView(viewportSize, layoutResult.totalBounds);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
