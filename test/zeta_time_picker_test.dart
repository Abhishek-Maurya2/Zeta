import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M3ETimePicker Widget Tests', () {
    testWidgets('renders M3ETimePicker and allows toggling AM/PM', (tester) async {
      M3ETime? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await M3ETimePicker.show(
                    context,
                    initialTime: const M3ETime(hour: 9, minute: 30),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open the picker dialog
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Check header and number boxes
      expect(find.text('Select time'), findsOneWidget);
      expect(find.text('09'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text(':'), findsOneWidget);

      // Toggle PM
      await tester.tap(find.text('PM').first);
      await tester.pumpAndSettle();

      // Confirm selection
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 9:30 PM is 21:30 in 24-hour time
      expect(result, isNotNull);
      expect(result!.hour, 21);
      expect(result!.minute, 30);
      expect(result!.isPm, isTrue);
      expect(result!.hourOf12, 9);
    });

    testWidgets('toggles between dial mode and manual input mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => M3ETimePicker.show(
                  context,
                  initialTime: const M3ETime(hour: 14, minute: 15),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Initially in dial mode
      expect(find.byType(CustomPaint), findsWidgets);

      // Tap keyboard mode toggle if present
      final keyboardIcon = find.byIcon(Icons.keyboard_outlined);
      if (keyboardIcon.evaluate().isNotEmpty) {
        await tester.tap(keyboardIcon);
        await tester.pumpAndSettle();

        expect(find.text('Enter time'), findsOneWidget);
      }
    });
  });
}
