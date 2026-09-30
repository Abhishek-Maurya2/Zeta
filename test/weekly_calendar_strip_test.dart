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
import 'package:zeta/utils/date_time_utils.dart';

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

  testWidgets('Compact mode distributes 7 days evenly edge-to-edge across full width',
      (tester) async {
    const compactSize = Size(400, 800);
    DateTime selectedDate = DateTime(2026, 9, 30);
    DateTime? chosenDate;
    int shiftDelta = 0;

    await tester.pumpWidget(
      createWidgetUnderTest(
        screenSize: compactSize,
        selectedDate: selectedDate,
        onSelectDate: (d) => chosenDate = d,
        onResetToToday: () {},
        weekOffset: 0,
        onShiftWeek: (delta) => shiftDelta += delta,
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 7 short day names (MON, TUE, WED, THU, FRI, SAT, SUN) exist
    for (final dayShort in DateTimeUtils.weekdaysShortUpper) {
      expect(find.text(dayShort), findsOneWidget);
    }

    // Find the compact Row containing the 7 Expanded day items
    final expandedDayItems = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.byType(Expanded),
    );
    expect(expandedDayItems, findsNWidgets(7));

    // Tap on 'Next week' chevron button
    final nextWeekChevron = find.byTooltip('Next week');
    expect(nextWeekChevron, findsOneWidget);
    await tester.tap(nextWeekChevron);
    await tester.pumpAndSettle();
    expect(shiftDelta, equals(1));

    // Tap on a specific day item (e.g., TUE)
    final tueItem = find.text('TUE');
    await tester.tap(tueItem);
    await tester.pumpAndSettle();
    expect(chosenDate, isNotNull);
    expect(chosenDate!.weekday, equals(DateTime.tuesday));
  });

  testWidgets('Compact mode swiping left navigates to next week',
      (tester) async {
    const compactSize = Size(400, 800);
    DateTime selectedDate = DateTime(2026, 9, 30);
    int shiftDelta = 0;

    await tester.pumpWidget(
      createWidgetUnderTest(
        screenSize: compactSize,
        selectedDate: selectedDate,
        onSelectDate: (_) {},
        onResetToToday: () {},
        weekOffset: 0,
        onShiftWeek: (delta) => shiftDelta += delta,
      ),
    );
    await tester.pumpAndSettle();

    // Swipe left (fling negative x) on the calendar strip
    await tester.fling(find.text('WED'), const Offset(-200, 0), 1000.0);
    await tester.pumpAndSettle();

    expect(shiftDelta, equals(1));
  });

  testWidgets('Wide mode renders chevrons flanking the day items horizontally',
      (tester) async {
    const wideSize = Size(1024, 768);
    DateTime selectedDate = DateTime(2026, 9, 30);

    await tester.pumpWidget(
      createWidgetUnderTest(
        screenSize: wideSize,
        selectedDate: selectedDate,
        onSelectDate: (_) {},
        onResetToToday: () {},
        weekOffset: 0,
      ),
    );
    await tester.pumpAndSettle();

    // In wide mode, both chevrons exist
    expect(find.byTooltip('Previous week'), findsOneWidget);
    expect(find.byTooltip('Next week'), findsOneWidget);

    // In wide mode, Expanded is NOT used for days; fixed width items are rendered directly
    final expandedDayItems = find.descendant(
      of: find.byType(WeeklyCalendarStrip),
      matching: find.byType(Expanded),
    );
    expect(expandedDayItems, findsNothing);
  });
}
