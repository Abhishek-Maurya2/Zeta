import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/components/zeta_logo.dart';

void main() {
  testWidgets('ZetaLogo builds without throwing assertion even if assets are missing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ZetaLogo(size: 45),
          ),
        ),
      ),
    );

    // Verify ZetaLogo rendered
    expect(find.byType(ZetaLogo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
