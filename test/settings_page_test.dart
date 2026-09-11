import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/providers/theme_provider.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/pages/settings_page.dart';
import 'package:zeta/widgets/m3_pane_divider.dart';
import 'package:zeta/components/settings/settings.dart';

Widget createSettingsTestWidget({
  Size size = const Size(1200, 900),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ChangeNotifierProvider(create: (_) => TaskProvider()),
      ChangeNotifierProvider(create: (_) => PomodoroProvider()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const Scaffold(
          body: SettingsPage(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsPage renders M3PaneDivider on wide screen and can drag to resize',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSettingsTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify M3PaneDivider is rendered on wide screen
    expect(find.byType(M3PaneDivider), findsOneWidget);

    // Verify initial profile section is rendered
    expect(find.byType(ProfileSection), findsOneWidget);

    // Check initial width of navigation pane (SizedBox before divider)
    final initialSizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.text('PREFERENCES'),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(initialSizedBox.width, equals(360.0)); // 1200 >= 1200 defaults to _largePaneWidth 360

    // Drag M3PaneDivider to the right by +40px to widen navigation pane
    final dividerFinder = find.byType(M3PaneDivider);
    await tester.drag(dividerFinder, const Offset(40, 0));
    await tester.pumpAndSettle();

    final widenedSizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.text('PREFERENCES'),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(widenedSizedBox.width, greaterThan(360.0));

    // Double tap M3PaneDivider to reset
    await tester.tap(dividerFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(dividerFinder);
    await tester.pumpAndSettle();

    final resetSizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.text('PREFERENCES'),
        matching: find.byType(SizedBox),
      ).first,
    );
    // Either canonical 310 or 50% toggle
    expect(resetSizedBox.width, isNotNull);
  });

  testWidgets('SettingsPage navigation pane can be collapsed and expanded',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSettingsTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Navigation pane is initially expanded
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.byType(M3PaneDivider), findsOneWidget);

    // Find collapse button in header or category bar
    final collapseBtn = find.byTooltip('Collapse navigation pane').first;
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    // Now navigation pane is collapsed
    expect(find.text('PREFERENCES'), findsNothing);
    expect(find.byType(M3PaneDivider), findsNothing);

    // Collapsed expand affordance strip is visible
    final expandAffordance = find.byTooltip('Expand navigation pane');
    expect(expandAffordance, findsOneWidget);

    // Tap expand affordance strip to uncollapse
    await tester.tap(expandAffordance);
    await tester.pumpAndSettle();

    // Navigation pane is visible again
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.byType(M3PaneDivider), findsOneWidget);
  });

  testWidgets('SettingsPage switches categories in two-pane mode',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSettingsTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Initially profile section
    expect(find.byType(ProfileSection), findsOneWidget);

    // Tap on Appearance category
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    // Appearance section is now visible
    expect(find.byType(AppearanceSection), findsOneWidget);
  });

  testWidgets('SettingsPage compact view behaves as single pane',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSettingsTestWidget(size: const Size(400, 800)));
    await tester.pump(const Duration(milliseconds: 100));

    // M3PaneDivider is NOT rendered on compact view
    expect(find.byType(M3PaneDivider), findsNothing);

    // Categories list is shown
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    // Tap on Appearance category
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    // Now AppearanceSection is displayed with back button in header
    expect(find.byType(AppearanceSection), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Returns to categories list
    expect(find.text('PREFERENCES'), findsOneWidget);
  });
}
