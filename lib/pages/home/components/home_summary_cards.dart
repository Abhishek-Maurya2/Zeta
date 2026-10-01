import 'package:flutter/material.dart';

import 'completion_rate_card.dart';
import 'days_left_counter_card.dart';
import 'streak_calendar_card.dart';
import 'mock_test_tracker_card.dart';
import 'pomodoro_week_terrain_card.dart'; // Newly added widget

// Re-export standalone components so consumers can import via this module
export 'active_tasks_card.dart';
export 'completed_tasks_card.dart';
export 'completion_rate_card.dart';
export 'days_left_counter_card.dart';
export 'streak_calendar_card.dart';
export 'today_milestones_card.dart';
export 'pomodoro_week_terrain_card.dart';
export 'mock_test_tracker_card.dart';

/// Aggregates and arranges the homepage dashboard summary cards.
class HomeSummaryCards extends StatelessWidget {
  final int activeCount;
  final int todayActiveCount;
  final int completionRate;
  final int completedCount;
  final VoidCallback? onMoreTap;
  final VoidCallback? onOptionsTap;

  // Pomodoro Actions
  final VoidCallback? onOpenPomodoroAnalysis;

  // Streak Calendar Parameters
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  // Mock Test Radar Callback
  final void Function(MockEntryRecord record)? onSaveMockTest;

  const HomeSummaryCards({
    super.key,
    required this.activeCount,
    required this.todayActiveCount,
    required this.completionRate,
    required this.completedCount,
    required this.selectedDate,
    required this.onSelectDate,
    this.onMoreTap,
    this.onOptionsTap,
    this.onOpenPomodoroAnalysis,
    this.onSaveMockTest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── 5. Completion Rate & Completed Tasks Row ────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CompletionRateCard(
                completionRate: completionRate,
                completedCount: completedCount,
                onMoreTap: onMoreTap,
                onOptionsTap: onOptionsTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PomodoroWeekTerrainCard(onOpenAnalysis: onOpenPomodoroAnalysis),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ─── 1. Streak Calendar + Mock Radar (responsive) ────────
        LayoutBuilder(
          builder: (context, constraints) {
            final streakCard = StreakCalendarCard(
              selectedDate: selectedDate,
              onSelectDate: onSelectDate,
              width: null, // let parent dictate width
            );
            final mockCard = MockTestRadarCard(onSaveTest: onSaveMockTest);

            return Column(
              children: [streakCard, const SizedBox(height: 14), mockCard],
            );
          },
        ),
        const SizedBox(height: 14),
        // ─── 3. Days Left Counter Card ───────────────────────────
        const DaysLeftCounterCard(),
      ],
    );
  }
}

typedef SummaryWidgets = HomeSummaryCards;

