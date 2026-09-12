import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/utils/app_snackbar.dart';

void main() {
  testWidgets('M3ESnackbar.show presents message over root Overlay', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => M3ETheme(
          data: M3EThemeData.fromMaterial(Theme.of(context)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                M3ESnackbar.show(
                  context,
                  message: 'Task created successfully',
                );
              },
              child: const Text('Trigger Snackbar'),
            ),
          ),
        ),
      ),
    );

    // Initial state: no snackbar
    expect(find.byType(M3ESnackbar), findsNothing);

    // Tap trigger button
    await tester.tap(find.text('Trigger Snackbar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // Verify M3ESnackbar and host are visible with message
    expect(find.byType(M3ESnackbar), findsOneWidget);
    expect(find.byType(M3ESnackbarHost), findsOneWidget);
    expect(find.text('Task created successfully'), findsOneWidget);
  });

  testWidgets('M3ESnackbar supports actionLabel and executes onAction callback', (
    WidgetTester tester,
  ) async {
    bool actionTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => M3ETheme(
          data: M3EThemeData.fromMaterial(Theme.of(context)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                M3ESnackbar.show(
                  context,
                  message: 'Task moved to bin',
                  actionLabel: 'Undo',
                  onAction: () {
                    actionTriggered = true;
                  },
                );
              },
              child: const Text('Delete Task'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete Task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Task moved to bin'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(actionTriggered, isFalse);

    // Tap Undo action button
    await tester.tap(find.text('Undo'));
    await tester.pump();

    expect(actionTriggered, isTrue);
  });

  testWidgets('AppSnackbar.show delegates to M3ESnackbar seamlessly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => M3ETheme(
          data: M3EThemeData.fromMaterial(Theme.of(context)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppSnackbar.show(
                  context,
                  message: 'Global snackbar test',
                  duration: const Duration(seconds: 1),
                );
              },
              child: const Text('Trigger AppSnackbar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger AppSnackbar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(M3ESnackbar), findsOneWidget);
    expect(find.text('Global snackbar test'), findsOneWidget);

    // Advance past duration to test auto-dismiss
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(M3ESnackbar), findsNothing);
  });
}
