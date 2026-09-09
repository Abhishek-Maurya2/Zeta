import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/main.dart';
import 'package:zeta/navigation/app_scaffold.dart';
import 'package:zeta/navigation/top_app_bar.dart';

void main() {
  testWidgets('ZetaApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    expect(find.byType(AppScaffold), findsOneWidget);
    expect(find.byType(TopAppBarWidget), findsOneWidget);
  });
}
