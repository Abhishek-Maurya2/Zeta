import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/pages/settings/components/weather_section.dart';
import 'package:zeta/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'WeatherSection renders M3 Expressive components and interacts correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: const SingleChildScrollView(
              child: WeatherSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Master switch banner is rendered
    expect(find.text('Use weather'), findsOneWidget);

    // 2. Verify Sub-Category Headers are rendered
    expect(find.text('Current Forecast'), findsOneWidget);
    expect(find.text('Location & Search'), findsOneWidget);
    expect(find.text('Display & Atmosphere'), findsOneWidget);

    // 3. Verify Telemetry items & action buttons
    expect(find.text('Use device location'), findsOneWidget);
    expect(find.text('Refresh forecast'), findsOneWidget);
    expect(find.text('Selected location'), findsOneWidget);
    expect(find.text('Show weather on Home screen'), findsOneWidget);
    expect(find.text('Measurement units'), findsOneWidget);

    // 4. Tap "Search" button to expand city search & popular cities
    expect(find.text('Search'), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Popular cities'), findsOneWidget);
    expect(find.text('Tokyo, JP'), findsOneWidget);
    expect(find.text('London, UK'), findsOneWidget);

    // 5. Tap a popular city chip
    await tester.tap(find.text('Tokyo, JP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(themeProvider.cityName, equals('Tokyo, JP'));

    // 6. Tap master toggle to disable weather
    await tester.tap(find.text('Use weather'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(themeProvider.weatherEnabled, isFalse);

    // Verify status badge switches to PAUSED
    expect(find.text('PAUSED'), findsOneWidget);

    // 7. Tap master toggle to re-enable weather
    await tester.tap(find.text('Use weather'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(themeProvider.weatherEnabled, isTrue);

    themeProvider.dispose();
  });
}
