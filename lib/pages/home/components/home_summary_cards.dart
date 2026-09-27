import 'package:flutter/material.dart';

import 'active_tasks_card.dart';
import 'completed_tasks_card.dart';
import 'completion_rate_card.dart';
import 'days_left_counter_card.dart';
import 'streak_calendar_card.dart';
import 'today_milestones_card.dart';
import 'pomodoro_week_terrain_card.dart'; // Newly added widget

// Re-export standalone components so consumers can import via this module
export 'active_tasks_card.dart';
export 'completed_tasks_card.dart';
export 'completion_rate_card.dart';
export 'days_left_counter_card.dart';
export 'streak_calendar_card.dart';
export 'today_milestones_card.dart';
export 'pomodoro_week_terrain_card.dart';

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

  // Days Left Target Goal Parameters
  final DateTime? targetDate;
  final DateTime? startDate;
  final String targetTitle;

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
    this.targetDate,
    this.startDate,
    this.targetTitle = 'Sprint Target',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── 1. Streak Calendar Card ─────────────────────────────
        StreakCalendarCard(
          selectedDate: selectedDate,
          onSelectDate: onSelectDate,
          width: double.infinity,
        ),
        const SizedBox(height: 14),

        // ─── 2. Focus Terrain Widget (Past 6 + Current Day) ──────
        PomodoroWeekTerrainCard(onOpenAnalysis: onOpenPomodoroAnalysis),
        const SizedBox(height: 14),

        // ─── 3. Days Left Counter Card ───────────────────────────
        DaysLeftCounterCard(
          title: targetTitle,
          startDate:
              startDate ?? DateTime.now().subtract(const Duration(days: 7)),
          targetDate:
              targetDate ?? DateTime.now().add(const Duration(days: 14)),
        ),
        const SizedBox(height: 14),

        // ─── 4. Active Tasks (Top Green Card) ────────────────────
        ActiveTasksCard(
          activeCount: activeCount,
          todayActiveCount: todayActiveCount,
        ),
        const SizedBox(height: 14),

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
            const SizedBox(width: 14),
            Expanded(child: CompletedTasksCard(completedCount: completedCount)),
          ],
        ),
        const SizedBox(height: 14),

        // ─── 6. Today Milestones Card ────────────────────────────
        TodayMilestonesCard(todayActiveCount: todayActiveCount),
      ],
    );
  }
}

typedef SummaryWidgets = HomeSummaryCards;
