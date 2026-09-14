import 'date_time_utils.dart';

/// Legacy alias & utility for formatting and parsing task dates and times consistently across Zeta.
/// Delegates directly to [DateTimeUtils] as the single source of truth.
class TaskDateFormatter {
  TaskDateFormatter._();

  static const List<String> months = DateTimeUtils.monthsShort;

  /// Formats a [DateTime] into 'Today', 'Tomorrow', 'Yesterday', or '13, Sep'.
  static String format(DateTime date) => DateTimeUtils.format(date);

  /// Normalizes or parses an existing date string into standard display format:
  /// 'Today', 'Tomorrow', 'Yesterday', or '13, Sep'.
  static String formatString(String dateStr) =>
      DateTimeUtils.formatString(dateStr);

  /// Checks if the given date string represents "Today".
  static bool isToday(String? dateStr) => DateTimeUtils.isToday(dateStr);

  /// Formats the date and time for a task list item chip.
  static String formatTaskListDate({
    required String dueDate,
    required bool hasTime,
    String? dueTime,
  }) => DateTimeUtils.formatTaskListDate(
    dueDate: dueDate,
    hasTime: hasTime,
    dueTime: dueTime,
  );

  /// Parses strings like 'Today', 'Tomorrow', 'Yesterday', '13, Sep', '13 Sep',
  /// composite strings like 'Today • 10:00 AM', or ISO timestamps.
  static DateTime? parse(String str) => DateTimeUtils.parse(str);
}
