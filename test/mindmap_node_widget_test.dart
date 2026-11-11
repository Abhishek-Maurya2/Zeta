import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zeta/pages/space/components/mindmap_node_widget.dart';
import 'package:zeta/pages/space/models/mindmap_node.dart';
import 'package:zeta/pages/space/providers/space_provider.dart';
import 'package:zeta/providers/theme_provider.dart';

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  bool isDarkMode(BuildContext context) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSpaceProvider extends ChangeNotifier implements SpaceProvider {
  String? _selectedNodeId;
  String? _editingNodeId;
  bool _toggledCollapsed = false;

  @override
  String? get selectedNodeId => _selectedNodeId;
  @override
  String? get editingNodeId => _editingNodeId;
  @override
  String? get draggedNodeId => null;
  @override
  String? get hoverTargetId => null;
  @override
  bool get isHoverReparent => false;
  @override
  bool get isHoverAbove => false;
  @override
  bool get isInvalidDrop => false;

  bool get toggledCollapsed => _toggledCollapsed;

  @override
  void selectNode(String? id) {
    _selectedNodeId = id;
    notifyListeners();
  }

  @override
  void toggleNodeCollapsed(String id) {
    _toggledCollapsed = true;
    notifyListeners();
  }

  @override
  void toggleNodeChecked(String id) {
    notifyListeners();
  }

  @override
  void startEditingNode(String id) {
    _editingNodeId = id;
    notifyListeners();
  }

  @override
  void stopEditingNode() {
    _editingNodeId = null;
    notifyListeners();
  }

  @override
  void updateNodeContent(String id, String content) {
    _editingNodeId = null;
    notifyListeners();
  }

  @override
  void beginNodeResize() {}

  @override
  void updateNodeWidth(String id, double width) {}

  @override
  void startDragNode(String id) {}

  @override
  void endDragNode() {}

  @override
  void updateDragHover({
    required String? targetId,
    required bool isReparent,
    required bool isAbove,
  }) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildNodeTestWidget({
    required MindMapNode node,
    required Rect bounds,
    required FakeSpaceProvider spaceProvider,
    bool hasChildren = false,
    int childCount = 0,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SpaceProvider>.value(value: spaceProvider),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => MockThemeProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en', 'US')],
        home: Scaffold(
          body: Stack(
            children: [
              MindMapNodeWidget(
                node: node,
                bounds: bounds,
                branchColor: const Color(0xFF6366F1),
                hasChildren: hasChildren,
                childCount: childCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('MindMapNodeWidget text visibility and badge tests', () {
    testWidgets('renders node content with maxLines: 10 and ellipsis overflow', (tester) async {
      final spaceProvider = FakeSpaceProvider();
      const testContent = 'Sample Topic Text';
      final node = const MindMapNode(
        id: 'node_1',
        parentId: 'root',
        orderIndex: 0,
        content: testContent,
      );

      await tester.pumpWidget(
        buildNodeTestWidget(
          node: node,
          bounds: const Rect.fromLTWH(100, 100, 200, 52),
          spaceProvider: spaceProvider,
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text(testContent);
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.maxLines, equals(10));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('renders number badge when node has children and is collapsed', (tester) async {
      final spaceProvider = FakeSpaceProvider();
      final node = const MindMapNode(
        id: 'node_parent',
        parentId: 'root',
        orderIndex: 0,
        content: 'Parent Topic',
        isCollapsed: true,
      );

      await tester.pumpWidget(
        buildNodeTestWidget(
          node: node,
          bounds: const Rect.fromLTWH(100, 100, 240, 52),
          spaceProvider: spaceProvider,
          hasChildren: true,
          childCount: 5,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent Topic'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Tap badge directly invokes toggleNodeCollapsed
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(spaceProvider.toggledCollapsed, isTrue);
    });

    testWidgets('TextField in edit mode has maxLines: 10 and minLines: 1', (tester) async {
      final spaceProvider = FakeSpaceProvider();
      final node = const MindMapNode(
        id: 'node_edit',
        parentId: 'root',
        orderIndex: 0,
        content: 'Editable Topic',
      );

      await tester.pumpWidget(
        buildNodeTestWidget(
          node: node,
          bounds: const Rect.fromLTWH(100, 100, 250, 52),
          spaceProvider: spaceProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Trigger editing mode
      spaceProvider.startEditingNode('node_edit');
      await tester.pumpAndSettle();

      expect(spaceProvider.editingNodeId, equals('node_edit'));

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final TextField textField = tester.widget(textFieldFinder);
      expect(textField.maxLines, equals(10));
      expect(textField.minLines, equals(1));
    });
  });
}
