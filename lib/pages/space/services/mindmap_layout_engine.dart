import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/mindmap.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_edge.dart';
import '../components/node/mindmap_node_metrics.dart';

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
  static const double verticalSiblingGap = 28.0;
  static const double verticalLevelGap = 80.0;
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

  /// Cache of memoized node measurements keyed by node content, style, and badge state.
  static final Map<String, Size> _nodeSizeCache = {};

  /// Clears the node size measurement cache.
  static void clearSizeCache() {
    _nodeSizeCache.clear();
  }

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

    // Step 0: Pre-index children by parentId to achieve O(N) hierarchy traversal
    final childrenByParentId = <String?, List<MindMapNode>>{};
    for (final node in mindMap.nodes) {
      (childrenByParentId[node.parentId] ??= []).add(node);
    }
    for (final list in childrenByParentId.values) {
      list.sort((a, b) {
        final cmp = a.orderIndex.compareTo(b.orderIndex);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
    }

    List<MindMapNode> getChildren(String? parentId) =>
        childrenByParentId[parentId] ?? const <MindMapNode>[];

    // Step 1: Pre-calculate node dimensions
    final nodeSizes = <String, Size>{};
    for (final node in mindMap.nodes) {
      final children = getChildren(node.id);
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
    final isVertical = mindMap.layoutType == 'vertical';

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

    final rootChildren = getChildren(root.id);
    if (rootChildren.isEmpty) {
      return MindMapLayoutResult(
        nodeBounds: nodeBounds,
        edges: edges,
        nodeColors: nodeColors,
        nodeIsLeft: nodeIsLeft,
        totalBounds: rootRect,
      );
    }

    if (isVertical) {
      // 1-Sided Vertical (Top-to-Bottom)
      _layoutVerticalSubtrees(
        childrenByParentId: childrenByParentId,
        parentRect: rootRect,
        children: rootChildren,
        nodeSizes: nodeSizes,
        nodeBounds: nodeBounds,
        edges: edges,
        nodeColors: nodeColors,
        nodeIsLeft: nodeIsLeft,
        palette: palette,
        depth: 1,
        colorOffset: 0,
      );
    } else if (!isBalanced) {
      // Standard Horizontal (Left-to-Right)
      _layoutBranchSubtrees(
        childrenByParentId: childrenByParentId,
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
          childrenByParentId: childrenByParentId,
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
          childrenByParentId: childrenByParentId,
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
    required Map<String?, List<MindMapNode>> childrenByParentId,
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
        childrenByParentId: childrenByParentId,
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
        final grandChildren = childrenByParentId[child.id] ?? const [];
        if (grandChildren.isNotEmpty) {
          _layoutBranchSubtrees(
            childrenByParentId: childrenByParentId,
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
    required Map<String?, List<MindMapNode>> childrenByParentId,
    required MindMapNode node,
    required Map<String, Size> nodeSizes,
  }) {
    final selfHeight = nodeSizes[node.id]?.height ?? 50.0;
    if (node.isCollapsed) return selfHeight;

    final children = childrenByParentId[node.id];
    if (children == null || children.isEmpty) return selfHeight;

    double childrenHeight = 0;
    for (int i = 0; i < children.length; i++) {
      childrenHeight += _computeSubtreeHeight(
        childrenByParentId: childrenByParentId,
        node: children[i],
        nodeSizes: nodeSizes,
      );
      if (i < children.length - 1) {
        childrenHeight += siblingGap;
      }
    }

    return math.max(selfHeight, childrenHeight);
  }

  static void _layoutVerticalSubtrees({
    required Map<String?, List<MindMapNode>> childrenByParentId,
    required Rect parentRect,
    required List<MindMapNode> children,
    required Map<String, Size> nodeSizes,
    required Map<String, Rect> nodeBounds,
    required List<MindMapEdge> edges,
    required Map<String, Color> nodeColors,
    required Map<String, bool> nodeIsLeft,
    required List<Color> palette,
    required int depth,
    required int colorOffset,
  }) {
    if (children.isEmpty) return;

    // Calculate subtree widths recursively
    final subtreeWidths = <String, double>{};
    for (final child in children) {
      subtreeWidths[child.id] = _computeSubtreeWidth(
        childrenByParentId: childrenByParentId,
        node: child,
        nodeSizes: nodeSizes,
      );
    }

    double totalWidth = 0;
    for (int i = 0; i < children.length; i++) {
      totalWidth += subtreeWidths[children[i].id]!;
      if (i < children.length - 1) {
        totalWidth += verticalSiblingGap;
      }
    }

    // Children are centered horizontally around parent center X
    double currentX = parentRect.center.dx - (totalWidth / 2.0);

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final childSize = nodeSizes[child.id]!;
      final stWidth = subtreeWidths[child.id]!;

      // Center the child node card within its allocated subtree horizontal slot
      final childX = currentX + (stWidth / 2.0) - (childSize.width / 2.0);
      final childY = parentRect.bottom + verticalLevelGap;

      final childRect = Rect.fromLTWH(
        childX,
        childY,
        childSize.width,
        childSize.height,
      );
      nodeBounds[child.id] = childRect;
      nodeIsLeft[child.id] = false;

      // Color inheritance: Level-1 gets offset palette color, descendants inherit
      final branchColor = (depth == 1)
          ? palette[(colorOffset + i) % palette.length]
          : (nodeColors[child.parentId] ?? palette[0]);
      nodeColors[child.id] = branchColor;

      // Create procedural vertical edge from bottom of parent to top of child
      final strokeWidth = depth == 1 ? 3.5 : (depth == 2 ? 2.4 : 1.6);
      final startPoint = Offset(parentRect.center.dx, parentRect.bottom);
      final endPoint = Offset(childRect.center.dx, childRect.top);

      edges.add(
        MindMapEdge(
          sourceId: child.parentId ?? '',
          targetId: child.id,
          startPoint: startPoint,
          endPoint: endPoint,
          color: branchColor,
          strokeWidth: strokeWidth,
          isLeft: false,
          isVertical: true,
        ),
      );

      // Recurse into children if not collapsed
      if (!child.isCollapsed) {
        final grandChildren = childrenByParentId[child.id] ?? const [];
        if (grandChildren.isNotEmpty) {
          _layoutVerticalSubtrees(
            childrenByParentId: childrenByParentId,
            parentRect: childRect,
            children: grandChildren,
            nodeSizes: nodeSizes,
            nodeBounds: nodeBounds,
            edges: edges,
            nodeColors: nodeColors,
            nodeIsLeft: nodeIsLeft,
            palette: palette,
            depth: depth + 1,
            colorOffset: colorOffset,
          );
        }
      }

      currentX += stWidth + verticalSiblingGap;
    }
  }

  static double _computeSubtreeWidth({
    required Map<String?, List<MindMapNode>> childrenByParentId,
    required MindMapNode node,
    required Map<String, Size> nodeSizes,
  }) {
    final selfWidth = nodeSizes[node.id]?.width ?? 160.0;
    if (node.isCollapsed) return selfWidth;

    final children = childrenByParentId[node.id];
    if (children == null || children.isEmpty) return selfWidth;

    double childrenWidth = 0;
    for (int i = 0; i < children.length; i++) {
      childrenWidth += _computeSubtreeWidth(
        childrenByParentId: childrenByParentId,
        node: children[i],
        nodeSizes: nodeSizes,
      );
      if (i < children.length - 1) {
        childrenWidth += verticalSiblingGap;
      }
    }

    return math.max(selfWidth, childrenWidth);
  }

  static Size _measureNode(
    MindMapNode node,
    TextStyle? baseStyle, {
    bool hasChildren = false,
    int childCount = 0,
  }) {
    final isRoot = node.isRoot;
    final cacheKey =
        '${node.id}_${node.content}_${isRoot}_${node.style.hasCheckbox}_${node.style.tags.isNotEmpty}_${node.isCollapsed}_${hasChildren}_${childCount}_${baseStyle?.fontSize}_${baseStyle?.fontWeight}';

    final cached = _nodeSizeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    // Horizontal & vertical card paddings
    final paddingH = isRoot
        ? MindMapNodeMetrics.paddingHRoot
        : MindMapNodeMetrics.paddingHNonRoot;
    final paddingV = isRoot
        ? MindMapNodeMetrics.paddingVRoot
        : MindMapNodeMetrics.paddingVNonRoot;

    // Checkbox overhead: M3ECheckbox slot (48.0) + gap (6.0) + cushion (2.0)
    final checkboxOverhead = node.style.hasCheckbox
        ? MindMapNodeMetrics.checkboxOverhead
        : 0.0;

    // Collapse / expand badge overhead (accounts for both expanded chevron and collapsed count pill)
    final badgeOverhead = MindMapNodeMetrics.calculateBadgeOverhead(
      hasChildren: hasChildren,
      isCollapsed: node.isCollapsed,
      childCount: childCount,
    );

    // Safety buffer for sub-pixel anti-aliasing, cursor headroom, and border thickness
    const safetyBuffer = MindMapNodeMetrics.safetyBuffer;
    final horizontalOverhead =
        paddingH + checkboxOverhead + badgeOverhead + safetyBuffer;
    final maxContentWidth = math.max(
      60.0,
      MindMapNodeMetrics.maxNodeWidth - horizontalOverhead,
    );

    final style = (baseStyle ?? const TextStyle(fontSize: 18)).copyWith(
      fontSize: isRoot ? 20 : 18,
      fontWeight: isRoot ? FontWeight.bold : FontWeight.w500,
      height: 1.35,
    );

    final text = node.content.isEmpty
        ? (isRoot ? 'Central Topic' : 'Node')
        : node.content;

    // Measure single line first to determine whether text fits or wraps at max width
    final singleLinePainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final singleLineWidth = singleLinePainter.width.ceilToDouble();
    final fitsOnOneLine =
        singleLineWidth <= maxContentWidth && !text.contains('\n');

    final double targetContentWidth;
    final double targetContentHeight;

    if (fitsOnOneLine) {
      targetContentWidth = singleLineWidth;
      targetContentHeight = singleLinePainter.height.ceilToDouble();
      singleLinePainter.dispose();
    } else {
      singleLinePainter.dispose();
      final multiLinePainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxContentWidth);
      targetContentWidth = multiLinePainter.width.ceilToDouble();
      targetContentHeight = multiLinePainter.height.ceilToDouble();
      multiLinePainter.dispose();
    }

    final minNodeWidth = isRoot
        ? MindMapNodeMetrics.minNodeWidthRoot
        : MindMapNodeMetrics.minNodeWidthNonRoot;
    final customWidth = node.style.customWidth;
    final double measuredWidth;
    if (customWidth != null) {
      measuredWidth = customWidth.clamp(minNodeWidth, 600.0);
    } else {
      measuredWidth = math.min(
        MindMapNodeMetrics.maxNodeWidth,
        math.max(minNodeWidth, targetContentWidth + horizontalOverhead),
      );
    }

    // Height expands dynamically without any max height limitation
    final minNodeHeight = isRoot
        ? MindMapNodeMetrics.minNodeHeightRoot
        : MindMapNodeMetrics.minNodeHeightNonRoot;
    double measuredHeight =
        targetContentHeight + paddingV + 6.0; // border & safety buffer
    if (node.style.tags.isNotEmpty) {
      measuredHeight += 24.0;
    }
    measuredHeight = math.max(minNodeHeight, measuredHeight);

    final result = Size(measuredWidth, measuredHeight);
    if (_nodeSizeCache.length > 2000) {
      _nodeSizeCache.clear();
    }
    _nodeSizeCache[cacheKey] = result;
    return result;
  }
}
