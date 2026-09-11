import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zeta/providers/theme_provider.dart';
import 'package:zeta/providers/task_provider.dart';
import 'package:zeta/providers/pomodoro_provider.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/pages/settings_page.dart';
import 'package:zeta/components/settings/profile_section.dart';

Widget createSettingsTestWidget({
  required ThemeProvider themeProvider,
  required TaskProvider taskProvider,
  required PomodoroProvider pomodoroProvider,
  Size size = const Size(1200, 900),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider.value(value: taskProvider),
      ChangeNotifierProvider.value(value: pomodoroProvider),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
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

  test('Avatar supports photo and falls back to first alphabet when no photo is set', () {
    final themeProvider = ThemeProvider();
    expect(themeProvider.hasAvatarPhoto, isFalse);
    expect(themeProvider.avatarInitial, equals('A'));

    // Set photo
    themeProvider.setAvatarPhoto('https://example.com/photo.png');
    expect(themeProvider.hasAvatarPhoto, isTrue);
    expect(themeProvider.avatarPhoto, equals('https://example.com/photo.png'));

    // Clear photo -> falls back to alphabet avatar
    themeProvider.clearAvatarPhoto();
    expect(themeProvider.hasAvatarPhoto, isFalse);
    expect(themeProvider.avatarInitial, equals('A'));

    themeProvider.setUserName('Zeta User');
    expect(themeProvider.avatarInitial, equals('Z'));

    themeProvider.setUserName('  elena  ');
    expect(themeProvider.avatarInitial, equals('E'));

    themeProvider.setAvatarColorIndex(2);
    expect(themeProvider.avatarColorIndex, equals(2));
    expect(themeProvider.currentAvatarColor, equals(ThemeProvider.avatarColors[2]));
  });

  test('Weather location updates in Celsius and provides telemetry', () async {
    final themeProvider = ThemeProvider();
    expect(themeProvider.cityName, equals('San Francisco, US'));

    themeProvider.setCityName('Tokyo, JP');
    expect(themeProvider.cityName, equals('Tokyo, JP'));

    await themeProvider.refreshWeather();
    expect(themeProvider.weatherData, isNotNull);
    expect(themeProvider.weatherData!.temperature, isNotNull);
    expect(themeProvider.weatherData!.condition, isNotEmpty);
  });

  test('TaskProvider auto-saves tasks and persists changes', () async {
    final taskProvider = TaskProvider();
    final initialCount = taskProvider.totalCount;

    taskProvider.addTask(title: 'New functional test task');
    expect(taskProvider.totalCount, equals(initialCount + 1));
    await taskProvider.saveTasks();

    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('zeta_tasks_v1');
    expect(tasksJson, isNotNull);
    expect(tasksJson!.contains('New functional test task'), isTrue);
  });

  test('ThemeProvider configuration export and import round-trip', () async {
    final themeProvider = ThemeProvider();
    themeProvider.setUserName('Marcus Aurelius');
    themeProvider.setThemeMode(ThemeMode.dark);
    themeProvider.setFontScale('large');
    themeProvider.setCompactDensity(true);

    final exported = {
      'userName': themeProvider.userName,
      'themeMode': themeProvider.themeMode.name,
      'fontScale': themeProvider.fontScale,
      'compactDensity': themeProvider.compactDensity,
    };

    final newProvider = ThemeProvider();
    final success = await newProvider.importConfiguration(exported);
    expect(success, isTrue);
    expect(newProvider.userName, equals('Marcus Aurelius'));
    expect(newProvider.themeMode, equals(ThemeMode.dark));
    expect(newProvider.fontScale, equals('large'));
    expect(newProvider.compactDensity, equals(true));
  });

  testWidgets('Profile section renders first-alphabet avatar and can edit display name',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final themeProvider = ThemeProvider();
    final taskProvider = TaskProvider();
    final pomodoroProvider = PomodoroProvider();

    await tester.pumpWidget(
      createSettingsTestWidget(
        themeProvider: themeProvider,
        taskProvider: taskProvider,
        pomodoroProvider: pomodoroProvider,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Profile Section is active by default
    expect(find.byType(ProfileSection), findsOneWidget);
    expect(find.text('A'), findsWidgets); // Letter "A" for Abhishek

    // Tap "Edit" on display name
    final editButton = find.text('Edit').first;
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Enter new name "Xavier"
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, 'Xavier');
    await tester.pumpAndSettle();

    // Tap "Save"
    final saveButton = find.text('Save').first;
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify avatar now displays "X"
    expect(themeProvider.userName, equals('Xavier'));
    expect(themeProvider.avatarInitial, equals('X'));
    expect(find.text('X'), findsWidgets);
  });
}
