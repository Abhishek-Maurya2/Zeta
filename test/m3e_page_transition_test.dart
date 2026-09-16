import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zeta/providers/theme_provider.dart';
import 'package:zeta/widgets/m3e_page_transition.dart';

void main() {
  testWidgets('M3EPageTransition sharedAxisX maintains correct opacity and transform during transition',
      (WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    Widget buildTransition(int index, String text) {
      return ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: MaterialApp(
          home: Scaffold(
            body: M3EPageTransition(
              currentIndex: index,
              previousIndex: index == 0 ? 0 : index - 1,
              transitionType: M3EPageTransitionType.sharedAxisX,
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(text),
                child: Text(text),
              ),
            ),
          ),
        ),
      );
    }

    // Initial pump: Page A
    await tester.pumpWidget(buildTransition(0, 'Page A'));
    expect(find.text('Page A'), findsOneWidget);

    // Switch to Page B
    await tester.pumpWidget(buildTransition(1, 'Page B'));

    // 1 frame in (10ms)
    await tester.pump(const Duration(milliseconds: 10));

    // Both pages are in tree during transition
    expect(find.text('Page A'), findsOneWidget);
    expect(find.text('Page B'), findsOneWidget);

    final pageAFadeFinder = find.ancestor(
      of: find.text('Page A'),
      matching: find.byType(FadeTransition),
    );
    final pageBFadeFinder = find.ancestor(
      of: find.text('Page B'),
      matching: find.byType(FadeTransition),
    );

    final pageAFade = tester.widget<FadeTransition>(pageAFadeFinder.first);
    final pageBFade = tester.widget<FadeTransition>(pageBFadeFinder.first);

    // Outgoing page A should start visible (>= 0.9) and not flash to 0 on frame 1
    expect(pageAFade.opacity.value, greaterThan(0.9));
    // Incoming page B should start invisible (<= 0.1)
    expect(pageBFade.opacity.value, lessThan(0.1));

    // Advance past the fade-out cutoff of the outgoing page (150ms of 300ms)
    await tester.pump(const Duration(milliseconds: 140));

    final pageAFadeMid = tester.widget<FadeTransition>(pageAFadeFinder.first);
    expect(pageAFadeMid.opacity.value, equals(0.0));

    // Advance to near the end (290ms of 300ms)
    await tester.pump(const Duration(milliseconds: 140));

    final pageAFadeEnd = tester.widget<FadeTransition>(pageAFadeFinder.first);
    final pageBFadeEnd = tester.widget<FadeTransition>(pageBFadeFinder.first);

    // Outgoing page A must remain completely faded out (0.0), NEVER fading back in
    expect(pageAFadeEnd.opacity.value, equals(0.0));
    // Incoming page B must be near full opacity (>= 0.9)
    expect(pageBFadeEnd.opacity.value, greaterThan(0.9));

    // Finish transition
    await tester.pumpAndSettle();
    expect(find.text('Page A'), findsNothing);
    expect(find.text('Page B'), findsOneWidget);
  });

  testWidgets('M3EPageTransition fadeThrough cleanly fades out outgoing before disappearing',
      (WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    Widget buildTransition(int index, String text) {
      return ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: MaterialApp(
          home: Scaffold(
            body: M3EPageTransition(
              currentIndex: index,
              previousIndex: 0,
              transitionType: M3EPageTransitionType.fadeThrough,
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(text),
                child: Text(text),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTransition(0, 'Page A'));
    expect(find.text('Page A'), findsOneWidget);

    await tester.pumpWidget(buildTransition(1, 'Page B'));
    await tester.pump(const Duration(milliseconds: 10));

    final pageAFadeFinder = find.ancestor(
      of: find.text('Page A'),
      matching: find.byType(FadeTransition),
    );
    final pageBFadeFinder = find.ancestor(
      of: find.text('Page B'),
      matching: find.byType(FadeTransition),
    );

    expect(tester.widget<FadeTransition>(pageAFadeFinder.first).opacity.value, greaterThan(0.9));
    expect(tester.widget<FadeTransition>(pageBFadeFinder.first).opacity.value, lessThan(0.1));

    // Advance to near end (290ms of 300ms)
    await tester.pump(const Duration(milliseconds: 280));

    // Page A must be 0.0, never fading back in
    expect(tester.widget<FadeTransition>(pageAFadeFinder.first).opacity.value, equals(0.0));
    expect(tester.widget<FadeTransition>(pageBFadeFinder.first).opacity.value, greaterThan(0.9));

    await tester.pumpAndSettle();
    expect(find.text('Page A'), findsNothing);
    expect(find.text('Page B'), findsOneWidget);
  });
}
