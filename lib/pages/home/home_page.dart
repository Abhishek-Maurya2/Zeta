import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'components/weekly_calendar_strip.dart';
import 'components/todays_focus_card.dart';
import 'components/recent_tasks_section.dart';
import 'components/summary_widgets.dart';
import '../../components/task_edit_pane.dart';
import '../../models/task.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/breakpoints.dart';
import '../../utils/date_time_utils.dart';

/// Production-ready HomePage mirroring Sharva's architecture:
/// - 1. Interactive Material 3 Expressive Weekly Calendar Strip with date navigation & weather.
/// - 2. Responsive 2-column layout on wide screens (Focus & Up Next on left, Streak & Stats on right).
/// - 3. Adaptive single-column layout on mobile / tablet (<960px).
/// - 4. Live synchronization across task operations, streak tracking, and date selection.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDate;
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _handleSelectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);

      // Compute week offset relative to today's Monday
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentMonday = today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      );
      final targetMonday = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - DateTime.monday),
      );

      final diffDays = targetMonday.difference(currentMonday).inDays;
      _weekOffset = (diffDays / 7).round();
    });
  }

  void _handleShiftWeek(int delta) {
    setState(() {
      _weekOffset += delta;
    });
  }

  void _handleResetToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _weekOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;
    final isWide = sizeClass.isMultiPane;

    final taskProvider = context.watch<TaskProvider>();
    final navProvider = context.read<NavigationProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final tasks = taskProvider.allTasks;
    final binTasks = taskProvider.binTasks;
    final activeTasks = tasks.where((t) => !t.completed).toList();
    final totalCount = tasks.length + binTasks.length;
    final completedCount =
        tasks.where((t) => t.completed).length +
        binTasks.where((t) => t.completed).length;
    final activeCount = activeTasks.length;
    final completionRate = totalCount > 0
        ? ((completedCount / totalCount) * 100).round()
        : 0;

    // Filter tasks for selected date and today using cached date index
    final dateMap = taskProvider.tasksByDateKey;
    final selectedKey =
        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final selectedDateTasks = dateMap[selectedKey] ?? const <Task>[];
    final todayTasks = dateMap[todayKey] ?? const <Task>[];
    final todayActiveCount = todayTasks.where((t) => !t.completed).length;

    final isSelectedDateToday = DateTimeUtils.isSameDay(_selectedDate, today);

    // Active tasks that have a parsed due date, sorted by due date ascending
    final dueActiveTasks = activeTasks
        .where((t) => t.parsedDueDate != null)
        .toList()
      ..sort((a, b) => a.parsedDueDate!.compareTo(b.parsedDueDate!));

    // Tasks due on or before today (overdue + due today)
    final dueNowTasks = dueActiveTasks.where((t) {
      final due = t.parsedDueDate!;
      return due.isBefore(today) || DateTimeUtils.isSameDay(due, today);
    }).toList();

    // Focus Task determination:
    // When viewing today:
    //   1. Earliest overdue or due today active task
    //   2. Active task scheduled for today
    //   3. Any active task with a due date (nearest upcoming)
    //   4. First completed task for today
    // When viewing another date:
    //   1. First active task on selected date
    //   2. First completed task on selected date
    Task? focusTask;
    if (isSelectedDateToday) {
      if (dueNowTasks.isNotEmpty) {
        focusTask = dueNowTasks.first;
      } else {
        for (final t in selectedDateTasks) {
          if (!t.completed) {
            focusTask = t;
            break;
          }
        }
        focusTask ??= dueActiveTasks.firstOrNull;
        focusTask ??= selectedDateTasks.firstOrNull;
      }
    } else {
      for (final t in selectedDateTasks) {
        if (!t.completed) {
          focusTask = t;
          break;
        }
      }
      focusTask ??= selectedDateTasks.firstOrNull;
    }

    // Up Next active tasks: exclude task visible in focus component and show the rest
    final upNextTasks = activeTasks
        .where((t) => focusTask == null || t.id != focusTask.id)
        .toList();

    // Show focus card when there is a task, or when viewing today (to show empty state)
    final showFocusCard = focusTask != null || isSelectedDateToday;

    // Left Column: Focus (if scheduled/due or today) + Up Next Tasks
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFocusCard) ...[
          TodaysFocusCard(
            task: focusTask,
            selectedDate: _selectedDate,
            onOpenCreate: () => TaskEditPane.show(context),
          ),
          const SizedBox(height: 24),
        ],
        UpNextSection(
          tasks: upNextTasks,
          totalCount: upNextTasks.length,
          onViewAll: () => navProvider.setActivePage(PageId.tasks),
        ),
      ],
    );

    // Right Column: Summary Widgets (with Streak Calendar integrated)
    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSummaryCards(
          selectedDate: _selectedDate,
          onSelectDate: _handleSelectDate,
          activeCount: activeCount,
          todayActiveCount: todayActiveCount,
          completionRate: completionRate,
          completedCount: completedCount,
          onMoreTap: () => navProvider.setActivePage(PageId.tasks),
          onOpenPomodoroAnalysis: () {
            navProvider.setActivePage(PageId.pomodoro);
          },
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact
            ? ZetaBreakpoints.marginCompact
            : ZetaBreakpoints.marginExpanded,
        vertical: 24,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: sizeClass.isExtraLarge ? 1280 : 1120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. Weekly Calendar Strip ──────────────────────────────────
              WeeklyCalendarStrip(
                selectedDate: _selectedDate,
                onSelectDate: _handleSelectDate,
                weekOffset: _weekOffset,
                onShiftWeek: _handleShiftWeek,
                onResetToToday: _handleResetToToday,
              ),

              const SizedBox(height: 24),

              // ─── 2. Main Responsive Content Grid ───────────────────────────
              if (isWide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Focus & Up Next Tasks) ~ 60%
                    Expanded(flex: 6, child: leftColumn),
                    const SizedBox(width: 24),
                    // Right Column (Streak & Stats) ~ 40%
                    Expanded(flex: 4, child: rightColumn),
                  ],
                ),
              ] else ...[
                // Stacked on Mobile & Tablet
                leftColumn,
                const SizedBox(height: 24),
                rightColumn,
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
