import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../settings/components/settings_category.dart';
import '../../../utils/task_date_formatter.dart';
import '../../../utils/date_time_utils.dart';
import '../../../utils/haptics.dart';
import '../../../components/weather_icon.dart';

/// Interactive Material 3 Expressive Weekly Calendar Strip mirroring Sharva's design:
/// - Left: Selected Date headline, Calendar DatePicker launcher, "Today" reset pill, and Weather readout.
/// - Right: Week shift chevrons, 7-day strip with single-dot priority indicators (Red: overdue, Blue: pending).
/// - Bottom legend for task indicator dots.
class WeeklyCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final int weekOffset;
  final ValueChanged<int> onShiftWeek;
  final VoidCallback onResetToToday;

  const WeeklyCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onSelectDate,
    required this.weekOffset,
    required this.onShiftWeek,
    required this.onResetToToday,
  });

  bool _isTaskOnDate(Task task, DateTime date) {
    if (task.dueDate == null) return false;
    final parsed = TaskDateFormatter.parse(task.dueDate!);
    if (parsed != null) {
      return DateTimeUtils.isSameDay(parsed, date);
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final taskProvider = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSelectedToday = DateTimeUtils.isSameDay(selectedDate, today);

    // Headline formatted: e.g. "Tuesday, 11 Sep"
    final headlineLabel = DateTimeUtils.formatHeadline(selectedDate);

    // Calculate 7 days for the active week window (Monday -> Sunday)
    final weekDays = DateTimeUtils.getWeeklyCalendarStripDays(
      today,
      weekOffset,
    );

    final allTasks = [...taskProvider.allTasks, ...taskProvider.binTasks];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Main Row: Headline & Weather on Left, Week Strip on Right ───────
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 800;

            final weather = themeProvider.weatherData;
            final tempStr = weather != null
                ? '${weather.temperature.round()}°C'
                : '24°C';
            final conditionStr =
                weather?.displayCondition ??
                (DateTime.now().hour < 6 || DateTime.now().hour >= 19
                    ? 'Clear Night'
                    : 'Partly Cloudy');

            final leftHeader = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        headlineLabel,
                        style: TextStyle(
                          fontFamily: 'GoogleSansFlex',
                          fontSize: 40,
                          color: colorScheme.onSurface.withValues(alpha: 0.9),
                          fontVariations: const [
                            FontVariation('wght', 600), // Weight
                            FontVariation('wdth', 70),
                            FontVariation('GRAD', 20), // Grade stroke density
                            FontVariation('opsz', 15), // Optical size
                            FontVariation('slnt', 0),
                            FontVariation('ROND', 100),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Calendar Datepicker Trigger (acts as "Reset to Today" in compact mode)
                      if (!isSelectedToday)
                        Tooltip(
                          message: 'Reset to Today',
                          child: M3EIconButton(
                            size: M3EIconButtonSize.xs,
                            variant: M3EIconButtonVariant.standard,
                            icon: Icon(
                              Icons.calendar_month_rounded,
                              size: 25,
                              color: colorScheme.primary,
                            ),
                            onPressed: () {
                              ZetaHaptics.light();
                              onResetToToday();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (themeProvider.weatherEnabled &&
                    themeProvider.showWeatherInHeader) ...[
                  const SizedBox(height: 4),

                  // Weather Telemetry Below Date (Clickable to open Weather Page)
                  Tooltip(
                    message:
                        '$conditionStr • ${weather?.cityName ?? themeProvider.cityName}\nClick to open weather settings',
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        ZetaHaptics.light();
                        final navProvider = context.read<NavigationProvider>();
                        navProvider.setActivePage(PageId.settings);
                        navProvider.setSettingsCategory(SettingsCategory.weather);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tempStr,
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 26,
                                color: colorScheme.onSurfaceVariant,
                                fontVariations: const [
                                  FontVariation('wght', 700), // Weight
                                  FontVariation('wdth', 180),
                                  FontVariation('GRAD', 180), // Grade stroke density
                                  FontVariation('opsz', 220), // Optical size
                                  FontVariation('slnt', -10),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            WeatherIcon(
                              name:
                                  weather?.iconName ??
                                  (DateTime.now().hour < 6 ||
                                          DateTime.now().hour >= 19
                                      ? 'partly_cloudy_night'
                                      : 'partly_cloudy_day'),
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );

            final rightWeekStrip = Row(
              mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                // Previous Week Chevron
                Tooltip(
                  message: 'Previous week',
                  child: M3EIconButton(
                    size: M3EIconButtonSize.md,
                    width: M3EIconButtonWidth.narrow,
                    decoration: M3EIconButtonDecoration(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      fontWeight: FontWeight.bold,
                      size: 40,
                    ),
                    onPressed: () {
                      ZetaHaptics.light();
                      onShiftWeek(-1);
                    },
                  ),
                ),

                // 7 Days
                Expanded(
                  flex: isCompact ? 1 : 0,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: weekDays.map((dayDate) {
                          final isSelected = DateTimeUtils.isSameDay(
                            dayDate,
                            selectedDate,
                          );
                          final isDayToday = DateTimeUtils.isSameDay(
                            dayDate,
                            today,
                          );
                          final isPast = dayDate.isBefore(today);

                          // Task indicators
                          final matchingTasks = allTasks
                              .where((t) => _isTaskOnDate(t, dayDate))
                              .toList();
                          final pendingCount = matchingTasks
                              .where((t) => !t.completed)
                              .length;
                          final overdueCount = isPast ? pendingCount : 0;

                          Color? dotColor;
                          String? dotLabel;
                          if (overdueCount > 0) {
                            dotColor = const Color(0xFFEF4444); // Red
                            dotLabel = '$overdueCount overdue';
                          } else if (pendingCount > 0) {
                            dotColor = const Color(0xFF3B82F6); // Blue
                            dotLabel = '$pendingCount pending';
                          }

                          final dayNameShort = DateTimeUtils
                              .weekdaysShortUpper[dayDate.weekday - 1];
                          final dayNumStr = dayDate.day.toString();

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 0 : 4,
                            ),
                            child: Tooltip(
                              message:
                                  '$dayNameShort $dayNumStr${dotLabel != null ? " • $dotLabel" : ""}',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(44),
                                onTap: () {
                                  ZetaHaptics.selection();
                                  onSelectDate(dayDate);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: isCompact ? 85 : 80,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primaryContainer
                                        : (isDayToday
                                              ? colorScheme
                                                    .surfaceContainerHighest
                                              : Colors.transparent),
                                    borderRadius: (isDayToday & !isSelected)
                                        ? BorderRadius.circular(10)
                                        : BorderRadius.circular(54),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayNameShort,
                                        style: TextStyle(
                                          fontSize: isSelected ? 16 : 13,
                                          fontFamily:
                                              (!isSelected && !isDayToday)
                                              ? 'GoogleSansFlex'
                                              : 'RobotoMono',
                                          fontVariations: [
                                            FontVariation('wdth', 100),
                                            FontVariation('ROND', 100),
                                          ],
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          letterSpacing: isSelected
                                              ? 0.5
                                              : null,
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : (isDayToday
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        dayNumStr,
                                        style: TextStyle(
                                          fontSize: isSelected ? 16 : 14,
                                          fontFamily:
                                              (!isSelected && !isDayToday)
                                              ? 'GoogleSansFlex'
                                              : 'RobotoMono',
                                          fontVariations: [
                                            FontVariation('wdth', 100),
                                            FontVariation('ROND', 100),
                                          ],
                                          fontWeight: isSelected || isDayToday
                                              ? FontWeight.w900
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                      // const SizedBox(height: 4),

                                      // Strict single-dot indicator
                                      SizedBox(
                                        height: 4,
                                        child: dotColor != null
                                            ? Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: dotColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : (isDayToday && !isSelected
                                                  ? Container(
                                                      width: 4,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    )
                                                  : null),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Next Week Chevron
                Tooltip(
                  message: 'Next week',
                  child: M3EIconButton(
                    size: M3EIconButtonSize.md,
                    width: M3EIconButtonWidth.narrow,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: M3EIconButtonDecoration(
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    onPressed: () {
                      ZetaHaptics.light();
                      onShiftWeek(1);
                    },
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  leftHeader,
                  const SizedBox(height: 25),
                  rightWeekStrip,
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: leftHeader),
                  const SizedBox(width: 16),
                  rightWeekStrip,
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ─── Mini Color Legend ───────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Overdue',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}
