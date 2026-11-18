import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/pages/space/models/mindmap.dart';
import 'package:zeta/pages/space/models/mindmap_node.dart';
import 'package:zeta/pages/space/services/mindmap_layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MindMapLayoutEngine dynamic expansion and node sizing tests', () {
    test('Root node enforces minimum width (180.0) and minimum height (64.0)', () {
      const mindMap = MindMap(
        id: 'map_1',
        title: 'Test Map',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'A',
            style: MindMapNodeStyle(hasCheckbox: false),
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      final bounds = result.nodeBounds['root']!;
      expect(bounds.width, greaterThanOrEqualTo(180.0));
      expect(bounds.height, greaterThanOrEqualTo(64.0));
    });

    test('Non-root node enforces minimum width (160.0) and minimum height (52.0)', () {
      const mindMap = MindMap(
        id: 'map_1',
        title: 'Test Map',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'child_1',
            parentId: 'root',
            orderIndex: 0,
            content: 'X',
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      final childBounds = result.nodeBounds['child_1']!;
      expect(childBounds.width, greaterThanOrEqualTo(160.0));
      expect(childBounds.height, greaterThanOrEqualTo(52.0));
    });

    test('Single-line text expands width as per content up to maxNodeWidth without wrapping', () {
      const mindMap = MindMap(
        id: 'map_1',
        title: 'Test Map',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'child_short',
            parentId: 'root',
            orderIndex: 0,
            content: 'Short',
          ),
          MindMapNode(
            id: 'child_longer',
            parentId: 'root',
            orderIndex: 1,
            content: 'Note Topic',
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      final shortBounds = result.nodeBounds['child_short']!;
      final longerBounds = result.nodeBounds['child_longer']!;

      expect(longerBounds.width, greaterThan(shortBounds.width));
      // Both fit on a single line so their heights should be equal minimum single-line height
      expect(shortBounds.height, equals(longerBounds.height));
    });

    test('Multi-line content expands both height and width up to maxLines (10) and maxNodeHeight', () {
      const tenLinesText = 'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10';
      const singleLineText = 'Single line text';

      const mindMap = MindMap(
        id: 'map_1',
        title: 'Test Map',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'child_single',
            parentId: 'root',
            orderIndex: 0,
            content: singleLineText,
          ),
          MindMapNode(
            id: 'child_10lines',
            parentId: 'root',
            orderIndex: 1,
            content: tenLinesText,
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      final singleBounds = result.nodeBounds['child_single']!;
      final tenLineBounds = result.nodeBounds['child_10lines']!;

      expect(tenLineBounds.height, greaterThan(singleBounds.height * 3));
      expect(tenLineBounds.height, lessThanOrEqualTo(500.0));
    });

    test('Collapsed node with children reserves badge overhead so text has sufficient space', () {
      const longText = 'Topic Title';

      const mindMapWithoutChildren = MindMap(
        id: 'map_1',
        title: 'Test Map',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'leaf_node',
            parentId: 'root',
            orderIndex: 0,
            content: longText,
          ),
        ],
      );

      const mindMapWithChildren = MindMap(
        id: 'map_2',
        title: 'Test Map 2',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'parent_node',
            parentId: 'root',
            orderIndex: 0,
            content: longText,
            isCollapsed: true,
          ),
          MindMapNode(
            id: 'sub_1',
            parentId: 'parent_node',
            orderIndex: 0,
            content: 'Sub 1',
          ),
          MindMapNode(
            id: 'sub_2',
            parentId: 'parent_node',
            orderIndex: 1,
            content: 'Sub 2',
          ),
          MindMapNode(
            id: 'sub_3',
            parentId: 'parent_node',
            orderIndex: 2,
            content: 'Sub 3',
          ),
        ],
      );

      final resultNoChildren = MindMapLayoutEngine.computeLayout(
        mindMap: mindMapWithoutChildren,
        defaultEdgeColor: Colors.blue,
      );
      final resultWithChildren = MindMapLayoutEngine.computeLayout(
        mindMap: mindMapWithChildren,
        defaultEdgeColor: Colors.blue,
      );

      final leafBounds = resultNoChildren.nodeBounds['leaf_node']!;
      final parentBounds = resultWithChildren.nodeBounds['parent_node']!;

      // The node with children reserves badge overhead, so its measured width expands
      expect(parentBounds.width, greaterThan(leafBounds.width));
    });

    test('Custom width is clamped to [minNodeWidth, 600.0] and height calculates to fit text', () {
      const mindMap = MindMap(
        id: 'map_1',
        title: 'Test Map',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'custom_narrow',
            parentId: 'root',
            orderIndex: 0,
            content: 'Some text inside custom width node that will wrap when narrow',
            style: MindMapNodeStyle(customWidth: 100.0), // Below 160 minNodeWidth
          ),
          MindMapNode(
            id: 'custom_wide',
            parentId: 'root',
            orderIndex: 1,
            content: 'Same text inside custom width node',
            style: MindMapNodeStyle(customWidth: 500.0),
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      final narrowBounds = result.nodeBounds['custom_narrow']!;
      final wideBounds = result.nodeBounds['custom_wide']!;

      // Clamped to minNodeWidth (160.0)
      expect(narrowBounds.width, equals(160.0));
      // Allowed up to 500.0
      expect(wideBounds.width, equals(500.0));

      // In narrow card the text wraps more, so height is larger
      expect(narrowBounds.height, greaterThan(wideBounds.height));
    });
  });

  group('MindMapLayoutEngine 1-sided vertical mode tests', () {
    test('Vertical layout places children vertically below parent with verticalLevelGap', () {
      const mindMap = MindMap(
        id: 'map_vert_1',
        title: 'Vertical Test',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        layoutType: 'vertical',
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root Node',
          ),
          MindMapNode(
            id: 'c1',
            parentId: 'root',
            orderIndex: 0,
            content: 'Child 1',
          ),
          MindMapNode(
            id: 'c2',
            parentId: 'root',
            orderIndex: 1,
            content: 'Child 2',
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      final rootBounds = result.nodeBounds['root']!;
      final c1Bounds = result.nodeBounds['c1']!;
      final c2Bounds = result.nodeBounds['c2']!;

      // Both children should be strictly below root by verticalLevelGap
      expect(c1Bounds.top, closeTo(rootBounds.bottom + MindMapLayoutEngine.verticalLevelGap, 0.01));
      expect(c2Bounds.top, closeTo(rootBounds.bottom + MindMapLayoutEngine.verticalLevelGap, 0.01));

      // Sibling nodes should be horizontally separated by at least verticalSiblingGap
      expect(c2Bounds.left, greaterThanOrEqualTo(c1Bounds.right + MindMapLayoutEngine.verticalSiblingGap - 0.01));

      // Edges should be vertical with endpoints connected parent bottom to child top
      expect(result.edges.length, equals(2));
      for (final edge in result.edges) {
        expect(edge.isVertical, isTrue);
        final childRect = result.nodeBounds[edge.targetId]!;
        expect(edge.startPoint.dx, closeTo(rootBounds.center.dx, 0.01));
        expect(edge.startPoint.dy, closeTo(rootBounds.bottom, 0.01));
        expect(edge.endPoint.dx, closeTo(childRect.center.dx, 0.01));
        expect(edge.endPoint.dy, closeTo(childRect.top, 0.01));
      }
    });

    test('Vertical layout correctly nests multi-level hierarchy (root -> child -> grandchildren)', () {
      const mindMap = MindMap(
        id: 'map_vert_2',
        title: 'Vertical Multi-level',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        layoutType: 'vertical',
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'c1',
            parentId: 'root',
            orderIndex: 0,
            content: 'Child 1',
          ),
          MindMapNode(
            id: 'gc1',
            parentId: 'c1',
            orderIndex: 0,
            content: 'Grandchild 1',
          ),
          MindMapNode(
            id: 'gc2',
            parentId: 'c1',
            orderIndex: 1,
            content: 'Grandchild 2',
          ),
          MindMapNode(
            id: 'c2',
            parentId: 'root',
            orderIndex: 1,
            content: 'Child 2',
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      final rootBounds = result.nodeBounds['root']!;
      final c1Bounds = result.nodeBounds['c1']!;
      final gc1Bounds = result.nodeBounds['gc1']!;
      final gc2Bounds = result.nodeBounds['gc2']!;
      final c2Bounds = result.nodeBounds['c2']!;

      // Children are below root
      expect(c1Bounds.top, closeTo(rootBounds.bottom + MindMapLayoutEngine.verticalLevelGap, 0.01));

      // Grandchildren are below c1
      expect(gc1Bounds.top, closeTo(c1Bounds.bottom + MindMapLayoutEngine.verticalLevelGap, 0.01));
      expect(gc2Bounds.top, closeTo(c1Bounds.bottom + MindMapLayoutEngine.verticalLevelGap, 0.01));

      // gc1 and gc2 are separated horizontally
      expect(gc2Bounds.left, greaterThanOrEqualTo(gc1Bounds.right + MindMapLayoutEngine.verticalSiblingGap - 0.01));

      // c2 subtree is separated horizontally from c1 and its grandchildren
      expect(c2Bounds.left, greaterThanOrEqualTo(gc2Bounds.right + MindMapLayoutEngine.verticalSiblingGap - 0.01));

      // 4 edges total, all vertical
      expect(result.edges.length, equals(4));
      expect(result.edges.every((e) => e.isVertical), isTrue);
    });

    test('Collapsed node in vertical layout hides its descendants', () {
      const mindMap = MindMap(
        id: 'map_vert_3',
        title: 'Vertical Collapsed',
        createdAtMs: 1000,
        updatedAtMs: 1000,
        layoutType: 'vertical',
        nodes: [
          MindMapNode(
            id: 'root',
            parentId: null,
            orderIndex: 0,
            content: 'Root',
          ),
          MindMapNode(
            id: 'c1',
            parentId: 'root',
            orderIndex: 0,
            content: 'Child 1',
            isCollapsed: true,
          ),
          MindMapNode(
            id: 'gc1',
            parentId: 'c1',
            orderIndex: 0,
            content: 'Grandchild 1',
          ),
        ],
      );

      final result = MindMapLayoutEngine.computeLayout(
        mindMap: mindMap,
        defaultEdgeColor: Colors.blue,
      );

      expect(result.nodeBounds.containsKey('root'), isTrue);
      expect(result.nodeBounds.containsKey('c1'), isTrue);
      expect(result.nodeBounds.containsKey('gc1'), isFalse);
      expect(result.edges.length, equals(1));
      expect(result.edges.first.isVertical, isTrue);
    });
  });
}
