import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/main.dart';
import 'package:zeta/navigation/app_scaffold.dart';
import 'package:zeta/pages/home_page.dart';
import 'package:zeta/components/home/weekly_calendar_strip.dart';
import 'package:zeta/components/home/todays_focus_card.dart';
import 'package:zeta/components/home/recent_tasks_section.dart';
import 'package:zeta/components/home/streak_calendar_card.dart';
import 'package:zeta/components/home/summary_widgets.dart';
import 'package:zeta/providers/navigation_provider.dart';

void main() {
  testWidgets('HomePage renders all components and verifies interactions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ZetaApp());
    await tester.pumpAndSettle();

    // 1. Verify HomePage is rendered as initial route
    expect(find.byType(HomePage), findsOneWidget);

    // 2. Verify WeeklyCalendarStrip exists
    expect(find.byType(WeeklyCalendarStrip), findsOneWidget);
    expect(find.text('24°C'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    // 3. Verify TodaysFocusCard exists
    expect(find.byType(TodaysFocusCard), findsOneWidget);
    expect(find.text("Today's Focus"), findsOneWidget);
    expect(find.text('Add new task'), findsOneWidget);
    final Text addNewTaskText = tester.widget<Text>(find.text('Add new task'));
    expect(addNewTaskText.style?.fontSize, 16.0);

    // 4. Verify RecentTasksSection exists
    expect(find.byType(RecentTasksSection), findsOneWidget);
    expect(find.text('Recent Tasks'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);

    // 5. Verify StreakCalendarCard exists
    expect(find.byType(StreakCalendarCard), findsOneWidget);
    expect(find.text('Streak Period:'), findsOneWidget);

    // 6. Verify SummaryWidgets exists with key metrics
    expect(find.byType(SummaryWidgets), findsOneWidget);
    expect(find.text('Active Tasks'), findsOneWidget);
    expect(find.text('Completion\nRate'), findsOneWidget);
    expect(find.text('Completed\nTasks'), findsOneWidget);
    expect(find.textContaining('Milestones due before end of day'), findsOneWidget);

    // 7. Verify tapping "View All" in RecentTasksSection switches page to Tasks
    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(AppScaffold));
    expect(context.read<NavigationProvider>().activePage, PageId.tasks);
  });
}
