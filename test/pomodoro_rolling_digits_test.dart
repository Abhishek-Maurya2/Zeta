import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/pages/pomodoro/components/pomodoro_timer_display.dart';

void main() {
  testWidgets('RollingDigitsText renders text digits correctly', (tester) async {
    const textStyle = TextStyle(
      fontFamily: 'GoogleSansFlex',
      fontSize: 70,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: RollingDigitsText(
              text: '25',
              style: textStyle,
              countUp: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Update text from 25 to 24 (countdown)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: RollingDigitsText(
              text: '24',
              style: textStyle,
              countUp: false,
            ),
          ),
        ),
      ),
    );

    // Mid-animation check
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('2'), findsOneWidget);
    // '5' is animating out, '4' is animating in
    expect(find.text('4'), findsOneWidget);

    // Settle animation
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });
}
