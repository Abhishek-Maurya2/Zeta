import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zeta/components/settings/notifications_section.dart';
import 'package:zeta/providers/theme_provider.dart';
import 'package:zeta/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('NotificationsSyncSection renders and interacts without error',
      (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final notifProvider = NotificationProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
              ChangeNotifierProvider<NotificationProvider>.value(
                value: notifProvider,
              ),
            ],
            child: const SingleChildScrollView(
              child: NotificationsSyncSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Master switch banner is rendered
    expect(find.text('Use notifications'), findsOneWidget);

    // Verify Sub-options are rendered
    expect(find.text('Task due time reminders'), findsOneWidget);
    expect(find.text('Overdue task alerts'), findsOneWidget);
    expect(find.text('Focus timer alerts'), findsOneWidget);
    expect(find.text('Sound effects & chimes'), findsOneWidget);
    expect(find.text('In-app notifications'), findsOneWidget);
    expect(find.text('System permission'), findsOneWidget);
    expect(find.text('Send test notification'), findsOneWidget);

    // Tap a switch tile (e.g. Task due time reminders)
    await tester.tap(find.text('Task due time reminders'));
    await tester.pumpAndSettle();

    // Tap master toggle
    await tester.tap(find.text('Use notifications'));
    await tester.pumpAndSettle();

    themeProvider.dispose();
    notifProvider.dispose();
  });
}
