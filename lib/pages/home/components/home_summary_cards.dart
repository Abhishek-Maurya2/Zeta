import 'package:flutter/material.dart';

import 'completion_rate_card.dart';
import 'pomodoro_week_terrain_card.dart'; // Newly added widget

// Re-export standalone components so consumers can import via this module
export 'active_tasks_card.dart';
export 'completed_tasks_card.dart';
export 'completion_rate_card.dart';
export 'pomodoro_week_terrain_card.dart';

/// Aggregates and arranges the homepage dashboard summary cards.
class HomeSummaryCards extends StatelessWidget {
  final int activeCount;
  final int todayActiveCount;
  final VoidCallback? onMoreTap;
  final VoidCallback? onOptionsTap;

  // Pomodoro Actions
  final VoidCallback? onOpenPomodoroAnalysis;

  const HomeSummaryCards({
    super.key,
    required this.activeCount,
    required this.todayActiveCount,
    this.onMoreTap,
    this.onOptionsTap,
    this.onOpenPomodoroAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── 1. Task Completion & Multi-Telemetry Metrics Card ───
        CompletionRateCard(
          onMoreTap: onMoreTap,
          onOptionsTap: onOptionsTap,
        ),
        const SizedBox(height: 14),

        // ─── 2. Pomodoro Terrain Card ────────────────────────────
        PomodoroWeekTerrainCard(onOpenAnalysis: onOpenPomodoroAnalysis),
        const SizedBox(height: 14),
      ],
    );
  }
}

typedef SummaryWidgets = HomeSummaryCards;
