import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zeta/main.dart';
import 'package:zeta/navigation/app_scaffold.dart';
import 'package:zeta/navigation/top_app_bar.dart';
import 'package:zeta/components/tasks/task_edit_pane.dart';
import 'package:zeta/providers/navigation_provider.dart';

void main() {
  testWidgets('Shortcuts: N key opens TaskEditPane when not typing, and allows typing N and R inside forms',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    // Verify TaskEditPane is NOT open initially
    expect(find.byType(TaskEditFormContent), findsNothing);

    // 1. Press 'N' when not typing -> should open TaskEditPane
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();

    expect(find.byType(TaskEditFormContent), findsOneWidget);

    // 2. Now inside TaskEditPane, find the title text field
    final titleField = find.descendant(
      of: find.byType(TaskEditFormContent),
      matching: find.byType(TextField),
    ).first;

    await tester.tap(titleField);
    await tester.pumpAndSettle();

    // Enter text containing 'n', 'r', '/'
    await tester.enterText(titleField, 'Learn / Run');
    await tester.pumpAndSettle();

    expect(find.text('Learn / Run'), findsOneWidget);

    // Send individual key events while focused in the text field
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    // Verify only ONE TaskEditPane is still open (didn't spawn a second one)
    expect(find.byType(TaskEditFormContent), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pumpAndSettle();
    expect(find.byType(TaskEditFormContent), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pumpAndSettle();
    expect(find.byType(TaskEditFormContent), findsOneWidget);

    // 3. Press Esc inside TaskEditPane -> should dismiss the dialog
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(TaskEditFormContent), findsNothing);
  });

  testWidgets('Shortcuts: Slash opens search, and typing inside search does not trigger N or R',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    final topBarState = tester.state<TopAppBarWidgetState>(find.byType(TopAppBarWidget));
    expect(topBarState.isSearchOpen, isFalse);

    // Press '/' to open search
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pumpAndSettle();

    expect(topBarState.isSearchOpen, isTrue);

    // Press 'N' while search is open -> must NOT open TaskEditPane
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.byType(TaskEditFormContent), findsNothing);

    // Press 'Esc' to close search
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(topBarState.isSearchOpen, isFalse);
  });
}
