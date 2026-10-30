import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

import '../models/mindmap.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';

/// Computed results of the mindmap auto-layout engine.
class MindMapLayoutResult {
  final Map<String, Rect> nodeBounds;
  final List<MindMapEdge> edges;
  final Map<String, Color> nodeColors;
  final Rect totalBounds;

  const MindMapLayoutResult({
    required this.nodeBounds,
    required this.edges,
    required this.nodeColors,
    required this.totalBounds,
  });
}

/// Dynamic Walker / Reingold-Tilford hierarchy layout engine.
class MindMapLayoutEngine {
  static const double siblingGap = 22.0;
  static const double levelGap = 72.0;
  static const double canvasOriginX = 4000.0;
  static const double canvasOriginY = 4000.0;

  static const List<Color> defaultBranchPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
  ];

  static List<Color> getBranchPalette({
    ColorScheme? colorScheme,
    List<Color>? customPalette,
  }) {
    if (customPalette != null && customPalette.isNotEmpty) {
      return customPalette;
    }
    if (colorScheme == null) return defaultBranchPalette;
    return [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF8B5CF6), // Purple
    ];
  }

  /// Computes node bounds and procedural edges for a mindmap.
  static MindMapLayoutResult computeLayout({
    required MindMap mindMap,
    required Color defaultEdgeColor,
    ColorScheme? colorScheme,
    List<Color>? branchPalette,
    TextStyle? baseTextStyle,
  }) {
    if (mindMap.nodes.isEmpty) {
      return const MindMapLayoutResult(
        nodeBounds: {},
        edges: [],
        nodeColors: {},
        totalBounds: Rect.fromLTWH(canvasOriginX, canvasOriginY, 100, 100),
      );
    }

    final root = mindMap.rootNode;
    if (root == null) {
      return const MindMapLayoutResult(
        nodeBounds: {},
        edges: [],
        nodeColors: {},
        totalBounds: Rect.fromLTWH(canvasOriginX, canvasOriginY, 100, 100),
      );
    }

    final palette = getBranchPalette(
      colorScheme: colorScheme,
      customPalette: branchPalette,
    );

    // Step 1: Pre-calculate node dimensions
    final nodeSizes = <String, Size>{};
    for (final node in mindMap.nodes) {
      final hasChildren = mindMap.childrenOf(node.id).isNotEmpty;
      nodeSizes[node.id] = _measureNode(
        node,
        baseTextStyle,
        hasChildren: hasChildren,
      );
    }

    final nodeBounds = <String, Rect>{};
    final edges = <MindMapEdge>[];
    final nodeColors = <String, Color>{};

    final isBalanced = mindMap.layoutType == 'balanced';

    // Step 2: Lay out root
    final rootSize = nodeSizes[root.id]!;
    final rootRect = Rect.fromLTWH(
      canvasOriginX - rootSize.width / 2,
      canvasOriginY - rootSize.height / 2,
      rootSize.width,
      rootSize.height,
    );
    nodeBounds[root.id] = rootRect;
    nodeColors[root.id] = defaultEdgeColor;

    if (root.isCollapsed) {
      return MindMapLayoutResult(
        nodeBounds: nodeBounds,
        edges: edges,
        nodeColors: nodeColors,
        totalBounds: rootRect,
      );
    }

    final rootChildren = mindMap.childrenOf(root.id);
    if (rootChildren.isEmpty) {
      return MindMapLayoutResult(
        nodeBounds: nodeBounds,
        edges: edges,
        nodeColors: nodeColors,
        totalBounds: rootRect,
      );
    }

    if (!isBalanced) {
      // Standard Horizontal (Left-to-Right)
      _layoutBranchSubtrees(
        mindMap: mindMap,
        parentRect: rootRect,
        children: rootChildren,
        nodeSizes: nodeSizes,
        nodeBounds: nodeBounds,
        edges: edges,
        nodeColors: nodeColors,
        palette: palette,
        isLeft: false,
        depth: 1,
      );
    } else {
      // Balanced: Partition children into right and left branches
      final rightChildren = <MindMapNode>[];
      final leftChildren = <MindMapNode>[];
      for (int i = 0; i < rootChildren.length; i++) {
        if (i % 2 == 0) {
          rightChildren.add(rootChildren[i]);
        } else {
          leftChildren.add(rootChildren[i]);
        }
      }

      if (rightChildren.isNotEmpty) {
        _layoutBranchSubtrees(
          mindMap: mindMap,
          parentRect: rootRect,
          children: rightChildren,
          nodeSizes: nodeSizes,
          nodeBounds: nodeBounds,
          edges: edges,
          nodeColors: nodeColors,
          palette: palette,
          isLeft: false,
          depth: 1,
        );
      }

      if (leftChildren.isNotEmpty) {
        _layoutBranchSubtrees(
          mindMap: mindMap,
          parentRect: rootRect,
          children: leftChildren,
          nodeSizes: nodeSizes,
          nodeBounds: nodeBounds,
          edges: edges,
          nodeColors: nodeColors,
          palette: palette,
          isLeft: true,
          depth: 1,
        );
      }
    }

    // Step 3: Compute bounding box of entire mindmap
    double minX = rootRect.left;
    double minY = rootRect.top;
    double maxX = rootRect.right;
    double maxY = rootRect.bottom;

    for (final rect in nodeBounds.values) {
      if (rect.left < minX) minX = rect.left;
      if (rect.top < minY) minY = rect.top;
      if (rect.right > maxX) maxX = rect.right;
      if (rect.bottom > maxY) maxY = rect.bottom;
    }

    final totalBounds = Rect.fromLTRB(
      minX - 80,
      minY - 80,
      maxX + 80,
      maxY + 80,
    );

    return MindMapLayoutResult(
      nodeBounds: nodeBounds,
      edges: edges,
      nodeColors: nodeColors,
      totalBounds: totalBounds,
    );
  }

  static void _layoutBranchSubtrees({
    required MindMap mindMap,
    required Rect parentRect,
    required List<MindMapNode> children,
    required Map<String, Size> nodeSizes,
    required Map<String, Rect> nodeBounds,
    required List<MindMapEdge> edges,
    required Map<String, Color> nodeColors,
    required List<Color> palette,
    required bool isLeft,
    required int depth,
  }) {
    if (children.isEmpty) return;

    // Calculate subtree heights recursively
    final subtreeHeights = <String, double>{};
    for (final child in children) {
      subtreeHeights[child.id] = _computeSubtreeHeight(
        mindMap: mindMap,
        node: child,
        nodeSizes: nodeSizes,
      );
    }

    double totalHeight = 0;
    for (int i = 0; i < children.length; i++) {
      totalHeight += subtreeHeights[children[i].id]!;
      if (i < children.length - 1) {
        totalHeight += siblingGap;
      }
    }

    // Children are centered vertically around parent center Y
    double currentY = parentRect.center.dy - (totalHeight / 2.0);

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final childSize = nodeSizes[child.id]!;
      final stHeight = subtreeHeights[child.id]!;

      final childY = currentY + (stHeight / 2.0) - (childSize.height / 2.0);
      final childX = isLeft
          ? parentRect.left - levelGap - childSize.width
          : parentRect.right + levelGap;

      final childRect = Rect.fromLTWH(
        childX,
        childY,
        childSize.width,
        childSize.height,
      );
      nodeBounds[child.id] = childRect;

      // Color inheritance: Level-1 gets palette color, descendants inherit
      final branchColor = (depth == 1)
          ? palette[i % palette.length]
          : (nodeColors[child.parentId] ?? palette[0]);
      nodeColors[child.id] = branchColor;

      // Create procedural edge
      final strokeWidth = depth == 1 ? 3.5 : (depth == 2 ? 2.4 : 1.6);
      final startPoint = isLeft
          ? Offset(parentRect.left, parentRect.center.dy)
          : Offset(parentRect.right, parentRect.center.dy);
      final endPoint = isLeft
          ? Offset(childRect.right, childRect.center.dy)
          : Offset(childRect.left, childRect.center.dy);

      edges.add(
        MindMapEdge(
          sourceId: child.parentId ?? '',
          targetId: child.id,
          startPoint: startPoint,
          endPoint: endPoint,
          color: branchColor,
          strokeWidth: strokeWidth,
          isLeft: isLeft,
        ),
      );

      // Recurse into children if not collapsed
      if (!child.isCollapsed) {
        final grandChildren = mindMap.childrenOf(child.id);
        if (grandChildren.isNotEmpty) {
          _layoutBranchSubtrees(
            mindMap: mindMap,
            parentRect: childRect,
            children: grandChildren,
            nodeSizes: nodeSizes,
            nodeBounds: nodeBounds,
            edges: edges,
            nodeColors: nodeColors,
            palette: palette,
            isLeft: isLeft,
            depth: depth + 1,
          );
        }
      }

      currentY += stHeight + siblingGap;
    }
  }

  static double _computeSubtreeHeight({
    required MindMap mindMap,
    required MindMapNode node,
    required Map<String, Size> nodeSizes,
  }) {
    final selfHeight = nodeSizes[node.id]?.height ?? 50.0;
    if (node.isCollapsed) return selfHeight;

    final children = mindMap.childrenOf(node.id);
    if (children.isEmpty) return selfHeight;

    double childrenHeight = 0;
    for (int i = 0; i < children.length; i++) {
      childrenHeight += _computeSubtreeHeight(
        mindMap: mindMap,
        node: children[i],
        nodeSizes: nodeSizes,
      );
      if (i < children.length - 1) {
        childrenHeight += siblingGap;
      }
    }

    return math.max(selfHeight, childrenHeight);
  }

  static Size _measureNode(
    MindMapNode node,
    TextStyle? baseStyle, {
    bool hasChildren = false,
  }) {
    final isRoot = node.isRoot;
    final maxTextWidth = isRoot ? 260.0 : 220.0;
    final minWidth = isRoot ? 140.0 : 100.0;

    final style = (baseStyle ?? const TextStyle(fontSize: 14)).copyWith(
      fontSize: isRoot ? 16 : 14,
      fontWeight: isRoot ? FontWeight.bold : FontWeight.w500,
    );

    final text = node.content.isEmpty ? (isRoot ? 'Central Topic' : 'Node') : node.content;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 8,
    )..layout(maxWidth: maxTextWidth);

    double measuredWidth = textPainter.width + (isRoot ? 36.0 : 28.0);
    if (node.style.hasCheckbox) {
      measuredWidth += 26.0;
    }
    if (hasChildren) {
      measuredWidth += 30.0;
    }
    measuredWidth = measuredWidth.clamp(minWidth, maxTextWidth + 48.0);

    double measuredHeight = textPainter.height + (isRoot ? 28.0 : 20.0);
    if (node.style.tags.isNotEmpty) {
      measuredHeight += 20.0;
    }
    measuredHeight = measuredHeight.clamp(isRoot ? 48.0 : 38.0, 300.0);

    return Size(measuredWidth, measuredHeight);
  }
}
