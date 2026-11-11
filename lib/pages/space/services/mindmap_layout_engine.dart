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
  final Map<String, bool> nodeIsLeft;
  final Rect totalBounds;

  const MindMapLayoutResult({
    required this.nodeBounds,
    required this.edges,
    required this.nodeColors,
    required this.nodeIsLeft,
    required this.totalBounds,
  });
}

/// Dynamic Walker / Reingold-Tilford hierarchy layout engine.
class MindMapLayoutEngine {
  static const double siblingGap = 24.0;
  static const double levelGap = 84.0;
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
        nodeIsLeft: {},
        totalBounds: Rect.fromLTWH(canvasOriginX, canvasOriginY, 100, 100),
      );
    }

    final root = mindMap.rootNode;
    if (root == null) {
      return const MindMapLayoutResult(
        nodeBounds: {},
        edges: [],
        nodeColors: {},
        nodeIsLeft: {},
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
      final children = mindMap.childrenOf(node.id);
      final hasChildren = children.isNotEmpty;
      nodeSizes[node.id] = _measureNode(
        node,
        baseTextStyle,
        hasChildren: hasChildren,
        childCount: children.length,
      );
    }

    final nodeBounds = <String, Rect>{};
    final edges = <MindMapEdge>[];
    final nodeColors = <String, Color>{};
    final nodeIsLeft = <String, bool>{};

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
    nodeIsLeft[root.id] = false;

    if (root.isCollapsed) {
      return MindMapLayoutResult(
        nodeBounds: nodeBounds,
        edges: edges,
        nodeColors: nodeColors,
        nodeIsLeft: nodeIsLeft,
        totalBounds: rootRect,
      );
    }

    final rootChildren = mindMap.childrenOf(root.id);
    if (rootChildren.isEmpty) {
      return MindMapLayoutResult(
        nodeBounds: nodeBounds,
        edges: edges,
        nodeColors: nodeColors,
        nodeIsLeft: nodeIsLeft,
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
        nodeIsLeft: nodeIsLeft,
        palette: palette,
        isLeft: false,
        depth: 1,
        colorOffset: 0,
      );
    } else {
      // Balanced: Partition children into right and left branches with distinct color indices
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
          nodeIsLeft: nodeIsLeft,
          palette: palette,
          isLeft: false,
          depth: 1,
          colorOffset: 0,
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
          nodeIsLeft: nodeIsLeft,
          palette: palette,
          isLeft: true,
          depth: 1,
          colorOffset: rightChildren.length,
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
      nodeIsLeft: nodeIsLeft,
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
    required Map<String, bool> nodeIsLeft,
    required List<Color> palette,
    required bool isLeft,
    required int depth,
    required int colorOffset,
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
      nodeIsLeft[child.id] = isLeft;

      // Color inheritance: Level-1 gets offset palette color, descendants inherit
      final branchColor = (depth == 1)
          ? palette[(colorOffset + i) % palette.length]
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
            nodeIsLeft: nodeIsLeft,
            palette: palette,
            isLeft: isLeft,
            depth: depth + 1,
            colorOffset: colorOffset,
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
    int childCount = 0,
  }) {
    final isRoot = node.isRoot;

    // Minimum dimensions ensuring comfortable room for text + icons + padding without collision
    final minNodeWidth = isRoot ? 180.0 : 160.0;
    final maxNodeWidth = (node.style.customWidth ?? (isRoot ? 360.0 : 420.0))
        .clamp(minNodeWidth, 600.0);
    final minNodeHeight = isRoot ? 64.0 : 52.0;
    const maxNodeHeight = 500.0;
    const maxLines = 10;

    // Overhead calculation matching MindMapNodeWidget layout exactly:
    // Horizontal padding: Root 18*2 = 36, Non-root 14*2 = 28
    final paddingH = isRoot ? 36.0 : 28.0;
    // Checkbox: 18 box + 8 gap = 26
    final checkboxOverhead = node.style.hasCheckbox ? 26.0 : 0.0;
    // Collapse / child count badge: 6 gap + 14 padding + pill content + buffer
    double badgeOverhead = 0.0;
    if (hasChildren) {
      final digits = childCount > 0 ? childCount.toString().length : 1;
      final pillContentWidth = math.max(16.0, digits * 10.0);
      badgeOverhead = 6.0 + 14.0 + pillContentWidth + 4.0; // ~40.0 - 54.0
    }
    // Sub-pixel rounding + border thickness safety buffer (up to 2.5 on each side + buffer)
    const safetyBuffer = 10.0;

    final horizontalOverhead =
        paddingH + checkboxOverhead + badgeOverhead + safetyBuffer;
    final maxContentWidth = math.max(60.0, maxNodeWidth - horizontalOverhead);

    final style = (baseStyle ?? const TextStyle(fontSize: 18)).copyWith(
      fontSize: isRoot ? 20 : 18,
      fontWeight: isRoot ? FontWeight.bold : FontWeight.w500,
      height: 1.35,
    );

    final text = node.content.isEmpty
        ? (isRoot ? 'Central Topic' : 'Node')
        : node.content;

    // Measure single line width
    final singleLinePainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final singleLineWidth = singleLinePainter.width.ceilToDouble();
    final fitsOnOneLine =
        singleLineWidth <= maxContentWidth && !text.contains('\n');

    final TextPainter textPainter;
    final double targetContentWidth;

    if (fitsOnOneLine) {
      textPainter = singleLinePainter;
      targetContentWidth = singleLineWidth;
    } else {
      textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
      )..layout(maxWidth: maxContentWidth);
      targetContentWidth = textPainter.width.ceilToDouble();
    }

    // Width expands dynamically as per content up to maxNodeWidth
    double measuredWidth = node.style.customWidth ??
        (targetContentWidth + horizontalOverhead);
    measuredWidth = measuredWidth.clamp(minNodeWidth, maxNodeWidth);

    // Vertical overhead: Root padding 28 + borders/buffer 12 = 40; Non-root padding 22 + borders/buffer 12 = 34
    final verticalOverhead = isRoot ? 40.0 : 34.0;
    double measuredHeight =
        textPainter.height.ceilToDouble() + verticalOverhead;
    if (node.style.tags.isNotEmpty) {
      measuredHeight += 24.0;
    }
    // Height expands dynamically up to maxNodeHeight (accommodates 10 lines)
    measuredHeight = measuredHeight.clamp(minNodeHeight, maxNodeHeight);

    return Size(measuredWidth, measuredHeight);
  }
}
