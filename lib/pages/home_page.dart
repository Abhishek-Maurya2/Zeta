import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../components/home/weekly_calendar_strip.dart';
import '../components/home/todays_focus_card.dart';
import '../components/home/recent_tasks_section.dart';
import '../components/home/streak_calendar_card.dart';
import '../components/home/summary_widgets.dart';
import '../components/tasks/task_edit_pane.dart';
import '../models/task.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../utils/task_date_formatter.dart';

/// Production-ready HomePage mirroring Sharva's architecture:
/// - 1. Interactive Material 3 Expressive Weekly Calendar Strip with date navigation & weather.
/// - 2. Responsive 2-column layout on wide screens (Focus & Recent Tasks on left, Streak & Stats on right).
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isTaskOnDate(Task task, DateTime target) {
    if (task.dueDate == null) return false;
    final parsed = TaskDateFormatter.parse(task.dueDate!);
    if (parsed != null) {
      return _isSameDay(parsed, target);
    }
    return false;
  }

  void _handleSelectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);

      // Compute week offset relative to today's Monday
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentMonday =
          today.subtract(Duration(days: today.weekday - DateTime.monday));
      final targetMonday =
          _selectedDate.subtract(Duration(days: _selectedDate.weekday - DateTime.monday));

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
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final isWide = width >= 960;

    final taskProvider = context.watch<TaskProvider>();
    final navProvider = context.read<NavigationProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activeTasks = taskProvider.allTasks.where((t) => !t.completed).toList();
    final allTasks = [...taskProvider.allTasks, ...taskProvider.binTasks];
    final totalCount = allTasks.length;
    final completedCount = allTasks.where((t) => t.completed).length;
    final activeCount = activeTasks.length;
    final completionRate = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;

    // Filter tasks for selected date
    final selectedDateTasks =
        taskProvider.allTasks.where((t) => _isTaskOnDate(t, _selectedDate)).toList();

    // Tasks for today
    final todayTasks =
        taskProvider.allTasks.where((t) => _isTaskOnDate(t, today)).toList();
    final todayActiveCount = todayTasks.where((t) => !t.completed).length;

    // Focus Task: pick first active task on selected date; else first completed; else null
    Task? focusTask;
    for (final t in selectedDateTasks) {
      if (!t.completed) {
        focusTask = t;
        break;
      }
    }
    focusTask ??= selectedDateTasks.isNotEmpty ? selectedDateTasks.first : null;

    // Recent active tasks (up to 4)
    final recentTasks = activeTasks.take(4).toList();

    // Left Column: Focus + Recent Tasks
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TodaysFocusCard(
          task: focusTask,
          selectedDate: _selectedDate,
          onOpenCreate: () => TaskEditPane.show(context),
        ),
        const SizedBox(height: 24),
        RecentTasksSection(
          tasks: recentTasks,
          totalCount: totalCount,
          onViewAll: () => navProvider.setActivePage(PageId.tasks),
        ),
      ],
    );

    // Right Column: Streak Calendar + Summary Widgets
    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreakCalendarCard(
          selectedDate: _selectedDate,
          onSelectDate: _handleSelectDate,
        ),
        const SizedBox(height: 24),
        SummaryWidgets(
          activeCount: activeCount,
          todayActiveCount: todayActiveCount,
          completionRate: completionRate,
          completedCount: completedCount,
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : (isWide ? 40 : 24),
        vertical: 24,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
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
                    // Left Column (Focus & Recent Tasks) ~ 60%
                    Expanded(
                      flex: 6,
                      child: leftColumn,
                    ),
                    const SizedBox(width: 24),
                    // Right Column (Streak & Stats) ~ 40%
                    Expanded(
                      flex: 4,
                      child: rightColumn,
                    ),
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
