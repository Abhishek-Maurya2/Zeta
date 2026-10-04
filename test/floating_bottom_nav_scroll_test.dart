import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:zeta/navigation/components/floating_bottom_nav.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/providers/revision_provider.dart';
import 'package:zeta/providers/pomodoro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingBottomNav Scroll & Visibility Tests', () {
    late NavigationProvider navProvider;
    late TaskProvider taskProvider;
    late RevisionProvider revisionProvider;
    late M3EToolbarVisibilityController toolbarController;
    late M3EToolbarScrollBehavior toolbarBehavior;

    setUp(() {
      navProvider = NavigationProvider();
      taskProvider = TaskProvider();
      revisionProvider = RevisionProvider();
      toolbarController = M3EToolbarVisibilityController(exitExtent: 100.0);
      toolbarBehavior = M3EToolbarScrollBehavior.exitAlways(
        exitDirection: M3EToolbarExitDirection.bottom,
        controller: toolbarController,
      );
    });

    Widget buildTestWidget({
      required Widget scrollChild,
      bool isSelectionMode = false,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
          ChangeNotifierProvider<RevisionProvider>.value(value: revisionProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: M3EToolbarScrollWrapper(
              behavior: toolbarBehavior,
              child: Stack(
                children: [
                  Positioned.fill(child: scrollChild),
                  FloatingBottomNav(
                    navProvider: navProvider,
                    isSelectionMode: isSelectionMode,
                    scrollBehavior: toolbarBehavior,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('FloatingBottomNav is initially visible at offset 0', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          scrollChild: ListView.builder(
            itemCount: 50,
            itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(toolbarController.offset, equals(0.0));
      expect(toolbarController.offsetLimit, equals(-100.0));

      final Transform transform = tester.widget(
        find.descendant(
          of: find.byType(FloatingBottomNav),
          matching: find.byType(Transform),
        ).first,
      );
      expect(transform.transform.getTranslation().y, equals(0.0));
    });

    testWidgets('FloatingBottomNav hides on scroll down and shows on scroll up', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          scrollChild: ListView.builder(
            itemCount: 100,
            itemBuilder: (context, index) => SizedBox(
              height: 60,
              child: Text('Item $index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(toolbarController.offset, equals(0.0));

      // Scroll down by dragging upward
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Controller should have animated to offsetLimit (-100.0)
      expect(toolbarController.offset, equals(-100.0));

      // Transform translate should now be offset by 100.0 downwards (-(-100.0))
      final Transform hiddenTransform = tester.widget(
        find.descendant(
          of: find.byType(FloatingBottomNav),
          matching: find.byType(Transform),
        ).first,
      );
      expect(hiddenTransform.transform.getTranslation().y, equals(100.0));

      // Scroll up by dragging downward
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Controller should have animated back to 0.0
      expect(toolbarController.offset, equals(0.0));

      final Transform visibleTransform = tester.widget(
        find.descendant(
          of: find.byType(FloatingBottomNav),
          matching: find.byType(Transform),
        ).first,
      );
      expect(visibleTransform.transform.getTranslation().y, equals(0.0));
    });

    testWidgets('FloatingBottomNav slides away when isSelectionMode is true', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          isSelectionMode: true,
          scrollChild: Container(),
        ),
      );
      await tester.pumpAndSettle();

      final AnimatedSlide slideWidget = tester.widget(
        find.descendant(
          of: find.byType(FloatingBottomNav),
          matching: find.byType(AnimatedSlide),
        ),
      );
      expect(slideWidget.offset, equals(const Offset(0, 2.0)));
    });

    testWidgets('page change triggers toolbarController.show() when hidden', (tester) async {
      PageId? lastPage = navProvider.activePage;
      void onNavChanged() {
        if (lastPage != navProvider.activePage) {
          lastPage = navProvider.activePage;
          toolbarController.show();
        }
      }
      navProvider.addListener(onNavChanged);

      await tester.pumpWidget(
        buildTestWidget(
          scrollChild: ListView.builder(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(height: 50, child: Text('Row $index')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hide the toolbar by scrolling down
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(toolbarController.offset, equals(-100.0));

      // Switch active page
      navProvider.setActivePage(PageId.tasks);
      await tester.pumpAndSettle();

      // Should be revealed back to 0.0
      expect(toolbarController.offset, equals(0.0));

      navProvider.removeListener(onNavChanged);
    });

    testWidgets('pomodoro tab change triggers toolbarController.show() when hidden', (tester) async {
      final pomodoroProvider = PomodoroProvider();
      String lastTab = pomodoroProvider.activeTab;
      void onPomodoroChanged() {
        if (lastTab != pomodoroProvider.activeTab) {
          lastTab = pomodoroProvider.activeTab;
          toolbarController.show();
        }
      }
      pomodoroProvider.addListener(onPomodoroChanged);

      await tester.pumpWidget(
        buildTestWidget(
          scrollChild: ListView.builder(
            itemCount: 50,
            itemBuilder: (context, index) => SizedBox(height: 50, child: Text('Row $index')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hide the toolbar by scrolling down
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(toolbarController.offset, equals(-100.0));

      // Switch pomodoro tab
      pomodoroProvider.setActiveTab('analytics');
      await tester.pumpAndSettle();

      // Should be revealed back to 0.0
      expect(toolbarController.offset, equals(0.0));

      pomodoroProvider.removeListener(onPomodoroChanged);
      pomodoroProvider.dispose();
    });
  });
}

