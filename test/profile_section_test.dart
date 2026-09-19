import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/pages/settings/components/profile_section.dart';
import 'package:zeta/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'ProfileSection renders M3 Expressive layout and supports name, email, and database sync',
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
              child: ProfileSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Headers
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Database & Cloud Sync'), findsOneWidget);

    // 2. Verify Hero card actions
    expect(find.byType(M3EButtonGroup), findsOneWidget);
    expect(find.text('Upload image'), findsWidgets);
    expect(find.text('Image URL'), findsWidgets);

    // 3. Test Display Name editing
    final editNameButton = find.widgetWithText(M3EButton, 'Edit').first;
    await tester.tap(editNameButton);
    await tester.pump();

    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'Abhishek M');
    await tester.pump();

    final saveNameButton = find.widgetWithText(M3EButton, 'Save').first;
    await tester.tap(saveNameButton);
    await tester.pump();

    expect(themeProvider.userName, equals('Abhishek M'));

    // 4. Test Email Address editing
    final addEmailButton = find.widgetWithText(M3EButton, 'Add').first;
    await tester.tap(addEmailButton);
    await tester.pump();

    final emailField = find.byType(TextField).first;
    await tester.enterText(emailField, 'test.user@domain.com');
    await tester.pump();

    final saveEmailButton = find.widgetWithText(M3EButton, 'Save').first;
    await tester.tap(saveEmailButton);
    await tester.pump();

    expect(themeProvider.userEmail, equals('test.user@domain.com'));

    // 5. Verify Database sync button exists
    expect(find.widgetWithText(M3EButton, 'Sync'), findsOneWidget);

    themeProvider.dispose();
  });
}
