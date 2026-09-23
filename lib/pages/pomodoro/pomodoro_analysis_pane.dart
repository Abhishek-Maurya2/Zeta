import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/pomodoro_provider.dart';
import 'components/pomodoro_chart_canvas.dart';
import 'components/pomodoro_analysis_header.dart';
import 'components/pomodoro_hero_stat.dart';
import 'components/pomodoro_summary_cards.dart';
import 'components/pomodoro_session_list.dart';
import 'components/pomodoro_goal_sheet.dart';

class PomodoroAnalysisPane extends StatefulWidget {
  final bool isSplitPane;

  const PomodoroAnalysisPane({super.key, this.isSplitPane = false});

  @override
  State<PomodoroAnalysisPane> createState() => _PomodoroAnalysisPaneState();
}

class _PomodoroAnalysisPaneState extends State<PomodoroAnalysisPane> {
  ChartRange _range = ChartRange.week;
  int _offset = 0; // 0 = current, -1 = previous, etc.

  Widget _buildChartCard(
    BuildContext context,
    PomodoroProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final settings = provider.settings;
    final sessionLog = provider.sessionLog;
    final now = DateTime.now();
    final todayStr = PomodoroChartCanvas.toLocalDateStr(now);

    final List<Map<String, dynamic>> items;
    final int goalValue;
    final String goalLabel;

    switch (_range) {
      case ChartRange.day:
        goalValue = settings.dayBlockGoalMinutes;
        goalLabel = PomodoroChartCanvas.formatDuration(goalValue);
        items = PomodoroChartCanvas.buildDayBlocks(
          sessionLog,
          now,
          _offset,
          goalValue,
        );
      case ChartRange.week:
        goalValue = settings.weekDailyGoalMinutes;
        goalLabel = PomodoroChartCanvas.formatDuration(goalValue);
        items = PomodoroChartCanvas.buildWeekDays(
          sessionLog,
          now,
          _offset,
          todayStr,
          goalValue,
        );
      case ChartRange.month:
        goalValue = settings.monthWeeklyGoalMinutes;
        goalLabel = PomodoroChartCanvas.formatDuration(goalValue);
        items = PomodoroChartCanvas.buildMonthWeeks(
          sessionLog,
          now,
          _offset,
          goalValue,
        );
      case ChartRange.year:
        goalValue = settings.yearMonthlyGoalMinutes;
        goalLabel = PomodoroChartCanvas.formatDuration(goalValue);
        items = PomodoroChartCanvas.buildYearMonths(
          sessionLog,
          now,
          _offset,
          goalValue,
        );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Visual Legend & Set Goal Action ──
          Row(
            children: [
              // Goal indicator
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Goal',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 14),
              // Avg indicator (small dashes)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
              Text(
                'Avg',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              // Set Goal Button
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  textStyle: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.tune_rounded, size: 14),
                label: const Text('Set Goal'),
                onPressed: () => PomodoroGoalSheet.show(context, provider),
              ),
            ],
          ),

          const SizedBox(height: 16),

          PomodoroChartCanvas(
            range: _range,
            offset: _offset,
            items: items,
            goalValue: goalValue,
            goalLabel: goalLabel,
            chartHeight: 250,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PomodoroProvider>();
    final sessionLog = provider.sessionLog;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: widget.isSplitPane ? 20 : 16,
        right: widget.isSplitPane ? 20 : 16,
        top: 16,
        bottom: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Range Selector & Period Navigation ───────────
          PomodoroAnalysisHeader(
            range: _range,
            offset: _offset,
            onRangeChanged: (newRange) {
              setState(() {
                _range = newRange;
                _offset = 0;
              });
            },
            onOffsetChanged: (newOffset) {
              setState(() {
                _offset = newOffset;
              });
            },
          ),

          const SizedBox(height: 20),

          // ─── Hero Stat Section ────────────────────────────────────
          PomodoroHeroStat(
            range: _range,
            offset: _offset,
            sessionLog: sessionLog,
          ),

          const SizedBox(height: 25),

          // ─── Visual Chart Card ────────────────────────────────────
          _buildChartCard(context, provider, colorScheme, textTheme),

          const SizedBox(height: 20),

          // ─── Summary Stat Cards Grid ──────────────────────────────
          PomodoroSummaryCards(sessionLog: sessionLog),

          const SizedBox(height: 25),

          // ─── Completed Session Log List ───────────────────────────
          const PomodoroSessionList(),
        ],
      ),
    );
  }
}
