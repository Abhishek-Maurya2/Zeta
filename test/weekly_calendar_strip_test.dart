import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/database/database_provider.dart';
import 'package:zeta/pages/home/components/weekly_calendar_strip.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/providers/weather_provider.dart';
import 'package:zeta/services/cross_device_service.dart';
import 'package:zeta/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TaskProvider taskProvider;
  late WeatherProvider weatherProvider;
  late NavigationProvider navigationProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyCrossDeviceEnabled: false,
      PreferencesService.keyShowWeatherInHeader: false,
      PreferencesService.keyWeatherEnabled: false,
    });
    await PreferencesService.instance.init();
    await PreferencesService.instance.setCrossDeviceEnabled(false);
    try {
      final db = DatabaseProvider.instance.db;
      await db.delete(db.tasksTable).go();
    } catch (_) {}

    taskProvider = TaskProvider();
    weatherProvider = WeatherProvider();
    navigationProvider = NavigationProvider();

    addTearDown(() {
      CrossDeviceService.instance.dispose();
      taskProvider.dispose();
      weatherProvider.dispose();
      navigationProvider.dispose();
    });
  });

  Widget createWidgetUnderTest({
    required Size screenSize,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onSelectDate,
    required VoidCallback onResetToToday,
    int? weekOffset,
    ValueChanged<int>? onShiftWeek,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ChangeNotifierProvider<WeatherProvider>.value(value: weatherProvider),
        ChangeNotifierProvider<NavigationProvider>.value(value: navigationProvider),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Scaffold(
            body: SizedBox(
              width: screenSize.width,
              child: WeeklyCalendarStrip(
                selectedDate: selectedDate,
                onSelectDate: onSelectDate,
                onResetToToday: onResetToToday,
                weekOffset: weekOffset,
                onShiftWeek: onShiftWeek,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'Compact mode takes all horizontal space and shows at least 4 dates',
      (tester) async {
    const compactSize = Size(400, 800);
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, now.month, now.day);
    DateTime? chosenDate;

    await tester.pumpWidget(
      createWidgetUnderTest(
        screenSize: compactSize,
        selectedDate: selectedDate,
        onSelectDate: (d) => chosenDate = d,
        onResetToToday: () {},
      ),
    );
    await tester.pumpAndSettle();

    // Verify previous and next chevrons exist
    expect(find.byTooltip('Previous days'), findsOneWidget);
    expect(find.byTooltip('Next days'), findsOneWidget);

    // Verify the scrollable strip fills space via Expanded in compact mode
    expect(
      find.descendant(
        of: find.byType(WeeklyCalendarStrip),
        matching: find.byType(CustomScrollView),
      ),
      findsOneWidget,
    );

    // Verify at least 4 date items are visible in the viewport
    final inkWells = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(InkWell),
    );
    expect(inkWells.evaluate().length, greaterThanOrEqualTo(4));

    // Tap on a visible day item (such as today's date)
    final todayDayNum = selectedDate.day.toString();
    await tester.tap(find.text(todayDayNum).first);
    await tester.pumpAndSettle();
    expect(chosenDate, isNotNull);

    // Tap on 'Next days' chevron button
    final nextDaysChevron = find.byTooltip('Next days');
    await tester.tap(nextDaysChevron);
    await tester.pumpAndSettle();
  });


  testWidgets(
      'Compact mode on narrow viewport (320px) shows at least 4 dates',
      (tester) async {
    const narrowSize = Size(320, 600);
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      createWidgetUnderTest(
        screenSize: narrowSize,
        selectedDate: selectedDate,
        onSelectDate: (_) {},
        onResetToToday: () {},
      ),
    );
    await tester.pumpAndSettle();

    // Verify at least 4 date items are visible in narrow compact mode
    final inkWells = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(InkWell),
    );
    expect(inkWells.evaluate().length, greaterThanOrEqualTo(4));
  });

  testWidgets(
      'Wide mode renders chevrons and calendar strip alongside header',
      (tester) async {
    const wideSize = Size(1024, 768);
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      createWidgetUnderTest(
        screenSize: wideSize,
        selectedDate: selectedDate,
        onSelectDate: (_) {},
        onResetToToday: () {},
      ),
    );
    await tester.pumpAndSettle();

    // In wide mode, both chevrons exist
    expect(find.byTooltip('Previous days'), findsOneWidget);
    expect(find.byTooltip('Next days'), findsOneWidget);

    // Days are displayed in CustomScrollView
    final inkWells = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(InkWell),
    );
    expect(inkWells.evaluate().length, greaterThanOrEqualTo(7));
  });
}

