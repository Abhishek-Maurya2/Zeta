import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/theme/breakpoints.dart';
import 'package:zeta/widgets/m3e_pane_divider.dart';
import 'package:zeta/widgets/m3e_supporting_pane_scaffold.dart';

void main() {
  group('ZetaWindowSizeClass Unit Tests', () {
    test('Resolves correct size class across M3 breakpoint thresholds', () {
      // Compact (< 600dp)
      expect(ZetaWindowSizeClass.fromWidth(360.0), equals(ZetaWindowSizeClass.compact));
      expect(ZetaWindowSizeClass.fromWidth(599.0), equals(ZetaWindowSizeClass.compact));
      expect(ZetaWindowSizeClass.fromWidth(599.0).isCompact, isTrue);
      expect(ZetaWindowSizeClass.fromWidth(599.0).isSinglePane, isTrue);
      expect(ZetaWindowSizeClass.fromWidth(599.0).isMultiPane, isFalse);

      // Medium (600dp – 839dp)
      expect(ZetaWindowSizeClass.fromWidth(600.0), equals(ZetaWindowSizeClass.medium));
      expect(ZetaWindowSizeClass.fromWidth(720.0), equals(ZetaWindowSizeClass.medium));
      expect(ZetaWindowSizeClass.fromWidth(839.0), equals(ZetaWindowSizeClass.medium));
      expect(ZetaWindowSizeClass.fromWidth(720.0).isMedium, isTrue);
      expect(ZetaWindowSizeClass.fromWidth(720.0).isSinglePane, isTrue);
      expect(ZetaWindowSizeClass.fromWidth(720.0).isMultiPane, isFalse);

      // Expanded (840dp – 1199dp)
      expect(ZetaWindowSizeClass.fromWidth(840.0), equals(ZetaWindowSizeClass.expanded));
      expect(ZetaWindowSizeClass.fromWidth(1024.0), equals(ZetaWindowSizeClass.expanded));
      expect(ZetaWindowSizeClass.fromWidth(1199.0), equals(ZetaWindowSizeClass.expanded));
      expect(ZetaWindowSizeClass.fromWidth(1024.0).isExpanded, isTrue);
      expect(ZetaWindowSizeClass.fromWidth(1024.0).isSinglePane, isFalse);
      expect(ZetaWindowSizeClass.fromWidth(1024.0).isMultiPane, isTrue);

      // Large (1200dp – 1599dp)
      expect(ZetaWindowSizeClass.fromWidth(1200.0), equals(ZetaWindowSizeClass.large));
      expect(ZetaWindowSizeClass.fromWidth(1440.0), equals(ZetaWindowSizeClass.large));
      expect(ZetaWindowSizeClass.fromWidth(1599.0), equals(ZetaWindowSizeClass.large));
      expect(ZetaWindowSizeClass.fromWidth(1440.0).isLarge, isTrue);
      expect(ZetaWindowSizeClass.fromWidth(1440.0).isMultiPane, isTrue);

      // Extra-Large (1600dp+)
      expect(ZetaWindowSizeClass.fromWidth(1600.0), equals(ZetaWindowSizeClass.extraLarge));
      expect(ZetaWindowSizeClass.fromWidth(2560.0), equals(ZetaWindowSizeClass.extraLarge));
      expect(ZetaWindowSizeClass.fromWidth(2560.0).isExtraLarge, isTrue);
      expect(ZetaWindowSizeClass.fromWidth(2560.0).isMultiPane, isTrue);
    });

    test('Returns standardized M3 margins and pane widths', () {
      expect(ZetaBreakpoints.marginFor(400.0), equals(16.0));
      expect(ZetaBreakpoints.marginFor(600.0), equals(24.0));
      expect(ZetaBreakpoints.marginFor(1200.0), equals(24.0));

      // Fixed pane widths scale from 360dp on Expanded to 412dp on Large
      expect(ZetaBreakpoints.fixedPaneWidthFor(900.0), equals(360.0));
      expect(ZetaBreakpoints.fixedPaneWidthFor(1200.0), equals(412.0));
      expect(ZetaBreakpoints.fixedPaneWidthFor(1920.0), equals(412.0));
    });
  });

  group('M3EPaneDivider Widget Tests', () {
    testWidgets('Renders hairline and drag handle, calls onDragUpdate and onDoubleTap',
        (WidgetTester tester) async {
      double dragDelta = 0.0;
      bool doubleTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: M3EPaneDivider(
                onDragUpdate: (delta) => dragDelta += delta,
                onDoubleTap: () => doubleTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(M3EPaneDivider), findsOneWidget);

      // Drag divider horizontally
      await tester.drag(find.byType(M3EPaneDivider), const Offset(25, 0));
      expect(dragDelta, greaterThan(0.0));

      // Double tap divider
      await tester.tap(find.byType(M3EPaneDivider));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(M3EPaneDivider));
      await tester.pumpAndSettle();

      expect(doubleTapped, isTrue);
    });
  });

  group('M3ESupportingPaneScaffold Widget Tests', () {
    testWidgets('Displays single pane on compact and dual pane on expanded',
        (WidgetTester tester) async {
      // 1. Test Compact Mode (< 840dp)
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: M3ESupportingPaneScaffold(
              mainPane: Text('MAIN_FOCUS_PANE'),
              supportingPane: Text('SUPPORTING_AUX_PANE'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only main pane is rendered in single-pane mode
      expect(find.text('MAIN_FOCUS_PANE'), findsOneWidget);
      expect(find.text('SUPPORTING_AUX_PANE'), findsNothing);
      expect(find.byType(M3EPaneDivider), findsNothing);

      // 2. Test Expanded Mode (>= 840dp)
      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: M3ESupportingPaneScaffold(
              mainPane: Text('MAIN_FOCUS_PANE'),
              supportingPane: Text('SUPPORTING_AUX_PANE'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both panes and divider are rendered in multi-pane mode
      expect(find.text('MAIN_FOCUS_PANE'), findsOneWidget);
      expect(find.text('SUPPORTING_AUX_PANE'), findsOneWidget);
      expect(find.byType(M3EPaneDivider), findsOneWidget);
    });

    testWidgets('Shows collapsed affordance button when collapsed on expanded view',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: M3ESupportingPaneScaffold(
              mainPane: const Text('MAIN_FOCUS_PANE'),
              supportingPane: const Text('SUPPORTING_AUX_PANE'),
              isCollapsed: true,
              onToggleCollapse: () => toggleCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MAIN_FOCUS_PANE'), findsOneWidget);
      expect(find.text('SUPPORTING_AUX_PANE'), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(toggleCalled, isTrue);
    });
  });
}
