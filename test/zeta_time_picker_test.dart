import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/components/zeta_time_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ZetaTimePicker Widget Tests', () {
    testWidgets('renders ZetaTimePicker with connected outline AM/PM button group', (tester) async {
      M3ETime? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ZetaTimePicker.show(
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

      // Check AM/PM connected button group (outline variant)
      final buttonGroupFinder = find.byType(M3EButtonGroup);
      expect(buttonGroupFinder, findsOneWidget);

      final buttonGroup = tester.widget<M3EButtonGroup>(buttonGroupFinder);
      expect(buttonGroup.type, M3EButtonGroupType.connected);
      expect(buttonGroup.style, M3EButtonStyle.outlined);
      expect(buttonGroup.selectedIndex, 0); // AM is index 0

      // Toggle PM
      await tester.tap(find.text('PM').first);
      await tester.pumpAndSettle();

      final updatedButtonGroup = tester.widget<M3EButtonGroup>(buttonGroupFinder);
      expect(updatedButtonGroup.selectedIndex, 1); // PM is index 1

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
                onPressed: () => ZetaTimePicker.show(
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

      // Tap keyboard mode toggle
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      // Now in input mode
      expect(find.text('Enter time'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Tap back to dial mode
      await tester.tap(find.byIcon(Icons.access_time_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Select time'), findsOneWidget);
    });
  });
}
