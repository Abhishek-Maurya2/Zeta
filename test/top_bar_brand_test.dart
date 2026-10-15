import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/components/zeta_logo.dart';
import 'package:zeta/navigation/components/top_bar_brand.dart';
import 'package:zeta/providers/navigation_provider.dart';

void main() {
  Widget buildTestWidget() {
    return ChangeNotifierProvider<NavigationProvider>(
      create: (_) => NavigationProvider(),
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 64,
            child: Material(
              child: TopBarBrand(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('TopBarBrand in compact mode shows only logo and hides Zeta label',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(ZetaLogo), findsOneWidget);
    expect(find.text('Zeta'), findsNothing);
  });

  testWidgets('TopBarBrand in medium mode shows only logo and hides Zeta label',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(700, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(ZetaLogo), findsOneWidget);
    expect(find.text('Zeta'), findsNothing);
  });

  testWidgets('TopBarBrand in expanded mode shows logo and Zeta label',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(ZetaLogo), findsOneWidget);
    expect(find.text('Zeta'), findsOneWidget);
  });
}
