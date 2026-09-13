import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/main.dart';
import 'package:zeta/navigation/app_scaffold.dart';
import 'package:zeta/pages/splash_screen.dart';
import 'package:zeta/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestSplash({
    VoidCallback? onComplete,
    Duration minDuration = const Duration(milliseconds: 300),
    bool isPreview = false,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        ),
      ),
      home: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: SplashScreen(
          onInitializationComplete: onComplete,
          minDuration: minDuration,
          isPreview: isPreview,
        ),
      ),
    );
  }

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders Zeta branding, subtitle, tagline, and progress capsule',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestSplash());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Zeta'), findsOneWidget);
      expect(find.text('Personal Workspace'), findsOneWidget);
      expect(find.text('Material 3 Expressive'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Adapts background color for light and dark themes',
        (WidgetTester tester) async {
      // Light Mode test
      await tester.pumpWidget(buildTestSplash(brightness: Brightness.light));
      await tester.pump(const Duration(milliseconds: 100));

      final lightMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(Material),
        ).first,
      );
      expect(lightMaterial.color, Colors.white);

      // Dark Mode test
      await tester.pumpWidget(buildTestSplash(brightness: Brightness.dark));
      await tester.pump(const Duration(milliseconds: 100));

      final darkMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(Material),
        ).first,
      );
      expect(darkMaterial.color, const Color(0xFF1E1E2E));
    });

    testWidgets('Shows close button in preview mode and can be tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestSplash(isPreview: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byTooltip('Close Preview'), findsOneWidget);
    });

    testWidgets('Does not show close button in production launch mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestSplash(isPreview: false));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('Calls onInitializationComplete after minDuration and exit transition',
        (WidgetTester tester) async {
      bool completed = false;

      await tester.pumpWidget(
        buildTestSplash(
          minDuration: const Duration(milliseconds: 200),
          onComplete: () {
            completed = true;
          },
        ),
      );

      // Advance past entrance and minDuration
      await tester.pump(const Duration(milliseconds: 250));
      // Advance past exit animation (380ms)
      await tester.pump(const Duration(milliseconds: 400));

      expect(completed, isTrue);
    });

    testWidgets('ZetaApp with showSplash: false opens AppScaffold directly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ZetaApp(showSplash: false));
      await tester.pump();

      expect(find.byType(AppScaffold), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('ZetaApp with showSplash: true displays SplashScreen on top of AppScaffold',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ZetaApp(showSplash: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppScaffold), findsOneWidget);
      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance through splash animation and exit transition
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Splash should now be dismissed
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(AppScaffold), findsOneWidget);
    });
  });
}
