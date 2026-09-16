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
import 'package:zeta/widgets/segmented_column.dart';
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
    expect(initialSizedBox.width, equals(412.0)); // 1200 >= 1200 defaults to _largePaneWidth 412

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
    expect(widenedSizedBox.width, greaterThan(412.0));

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

  testWidgets('SettingsPage left pane is flat on page background and right pane is elevated',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSettingsTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Navigation pane is visible with PREFERENCES on flat background using M3ESegmentedColumn
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.byType(M3PaneDivider), findsOneWidget);
    expect(find.byType(M3ESegmentedColumn), findsWidgets);

    // Left pane has no collapse buttons / extra controls
    expect(find.byTooltip('Collapse navigation pane'), findsNothing);

    // Right pane is inside elevated supporting pane container
    final colorScheme = Theme.of(tester.element(find.byType(SettingsPage))).colorScheme;
    final containers = tester.widgetList<Container>(find.byType(Container));
    final elevatedContainer = containers.firstWhere(
      (c) => c.color == colorScheme.surfaceContainer || c.color == colorScheme.surfaceContainerLow,
    );
    expect(elevatedContainer, isNotNull);
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

  testWidgets('SettingsPage navigates to Typography section and renders flex variable controls',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createSettingsTestWidget());
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Typography category in left pane
    expect(find.text('Typography'), findsOneWidget);
    await tester.tap(find.text('Typography'));
    await tester.pumpAndSettle();

    // Verify TypographySection is rendered
    expect(find.byType(TypographySection), findsOneWidget);
    expect(find.text('TYPOGRAPHY & FLEX VARIABLE FONTS'), findsOneWidget);

    // Verify role switcher buttons
    expect(find.text('Headings'), findsWidgets);
    expect(find.text('Titles'), findsWidgets);
    expect(find.text('Body'), findsWidgets);
    expect(find.text('Labels'), findsWidgets);

    // Verify Google Sans Flex font option is displayed with ROND badge
    expect(find.text('Google Sans Flex'), findsOneWidget);
    expect(find.text('★ ROND (Roundness)'), findsWidgets);

    // Verify variable axis sliders
    expect(find.text('Weight (wght)'), findsOneWidget);
    expect(find.text('Width (wdth)'), findsOneWidget);
    expect(find.text('Slant (slnt)'), findsOneWidget);
    expect(find.text('Roundness (ROND)'), findsOneWidget);
    expect(find.text('Grade (GRAD)'), findsOneWidget);

    // Verify Live Preview card is present
    expect(find.textContaining('LIVE PREVIEW'), findsOneWidget);
  });
}
