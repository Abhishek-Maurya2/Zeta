/// Centralized date, time, month, and week utility for Zeta.
/// Provides a single source of truth for:
/// - Weekly calendar strip formatting & week calculation
/// - Streak calendar card date math, ranges, and labels
/// - Today's focus card date headlines
/// - Task due date & Bin deletion date formatting and parsing
class DateTimeUtils {
  DateTimeUtils._();

  /// Short month abbreviations ('Jan', 'Feb', ... 'Dec').
  static const List<String> monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Full month names ('January', 'February', ... 'December').
  static const List<String> monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Short uppercase weekdays ('MON', 'TUE', ... 'SUN') for Weekly Calendar Strip.
  static const List<String> weekdaysShortUpper = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  /// Single-letter weekdays ('S', 'M', 'T', 'W', 'T', 'F', 'S') starting Sunday for Streak Calendar.
  static const List<String> weekdaysSingleLetter = [
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  /// Full weekday names ('Monday', 'Tuesday', ... 'Sunday').
  static const List<String> weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Checks if two [DateTime] values fall on the exact same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Formats date to 'YYYY-MM-DD' for cache keys and comparison maps.
  static String formatDateYMD(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Returns the 7 days (Monday -> Sunday) for the given [weekOffset] relative to [today].
  static List<DateTime> getWeeklyCalendarStripDays(
    DateTime today,
    int weekOffset,
  ) {
    final base = today.add(Duration(days: weekOffset * 7));
    final distanceToMonday = base.weekday - DateTime.monday;
    final monday = base.subtract(Duration(days: distanceToMonday));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Headline formatted for calendar strip: e.g. "Tuesday, 11 Sep".
  static String formatHeadline(DateTime date) {
    final weekdayName = weekdaysFull[date.weekday - 1];
    final monthName = monthsShort[date.month - 1];
    return '$weekdayName, ${date.day} $monthName';
  }

  /// Formatted date for Today's Focus Card: e.g. "Tuesday, Sep 11".
  static String formatFocusDate(DateTime date) {
    final weekdayName = weekdaysFull[date.weekday - 1];
    final monthName = monthsShort[date.month - 1];
    return '$weekdayName, $monthName ${date.day}';
  }

  /// Formats the selected day for Streak Calendar: e.g. "Today, Sep 14" or "Sep 14".
  static String formatSelectedDay(DateTime selectedDate, DateTime today) {
    final monthName = monthsShort[selectedDate.month - 1];
    return isSameDay(selectedDate, today)
        ? 'Today, $monthName ${selectedDate.day}'
        : '$monthName ${selectedDate.day}';
  }

  /// Formats the streak range label: e.g. "Sep 10 – 16" or "Sep 28 – Oct 3" or "Start today".
  static String formatStreakRange({
    required bool hasActiveStreak,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    if (!hasActiveStreak || rangeStart == null || rangeEnd == null) {
      return 'Start today';
    }
    final startM = monthsShort[rangeStart.month - 1];
    final startD = rangeStart.day;
    final endM = monthsShort[rangeEnd.month - 1];
    final endD = rangeEnd.day;
    if (startM == endM) {
      return '$startM $startD – $endD';
    }
    return '$startM $startD – $endM $endD';
  }

  /// Formats a deleted date timestamp for the Bin chip: e.g. "Deleted 13, Sep at 14:30".
  static String formatDeletedDate(DateTime? timestamp) {
    if (timestamp == null) return 'Deleted recently';
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return 'Deleted ${timestamp.day}, ${monthsShort[timestamp.month - 1]} at $timeStr';
  }

  /// Formats a [DateTime] into 'Today', 'Tomorrow', 'Yesterday', or '13, Sep'.
  static String format(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';

    return '${date.day}, ${monthsShort[date.month - 1]}';
  }

  /// Normalizes or parses an existing date string into standard display format:
  /// 'Today', 'Tomorrow', 'Yesterday', or '13, Sep'.
  static String formatString(String dateStr) {
    final parsed = parse(dateStr);
    if (parsed != null) {
      return format(parsed);
    }
    return dateStr;
  }

  /// Checks if the given date string represents "Today".
  static bool isToday(String? dateStr) {
    if (dateStr == null) return false;
    var trimmed = dateStr.trim();
    if (trimmed.contains('•')) {
      trimmed = trimmed.split('•')[0].trim();
    }
    if (trimmed.toLowerCase() == 'today') return true;
    final parsed = parse(trimmed);
    if (parsed != null) {
      final now = DateTime.now();
      return parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day;
    }
    return false;
  }

  /// Formats the date and time for a task list item chip:
  /// - Due **today** with time  → shows time only (e.g. '10:30 AM').
  /// - Due **today** without time → 'Today'.
  /// - **Any other date** with or without time → date label only
  ///   ('Yesterday', 'Tomorrow', or '13, Sep'). Time is omitted to keep
  ///   the chip compact — the date context is more useful here.
  static String formatTaskListDate({
    required String dueDate,
    required bool hasTime,
    String? dueTime,
  }) {
    final todayForTask = isToday(dueDate);

    if (todayForTask &&
        hasTime &&
        dueTime != null &&
        dueTime.trim().isNotEmpty) {
      return dueTime.trim();
    }

    return formatString(dueDate);
  }

  /// Parses strings like 'Today', 'Tomorrow', 'Yesterday', '13, Sep', '13 Sep',
  /// composite strings like 'Today • 10:00 AM', or ISO timestamps.
  static DateTime? parse(String str) {
    var clean = str.trim();
    if (clean.contains('•')) {
      clean = clean.split('•')[0].trim();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lower = clean.toLowerCase();
    if (lower == 'today') return today;
    if (lower == 'tomorrow') return today.add(const Duration(days: 1));
    if (lower == 'yesterday') return today.subtract(const Duration(days: 1));

    // Formats like "13, Sep", "13 Sep", or "13, Sep 2026"
    final parts = clean.replaceAll(',', ' ').split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final day = int.tryParse(parts[0]);
      final monthLower = parts[1].toLowerCase();
      final monthIndex =
          monthsShort.indexWhere((m) => m.toLowerCase() == monthLower);
      final year =
          parts.length >= 3 ? int.tryParse(parts[2]) ?? now.year : now.year;
      if (day != null && monthIndex != -1) {
        return DateTime(year, monthIndex + 1, day);
      }

      // Check reverse format: "Sep 13" or "Sep 13 2026"
      final revMonthIndex = monthsShort.indexWhere(
        (m) => m.toLowerCase() == parts[0].toLowerCase(),
      );
      final revDay = int.tryParse(parts[1]);
      if (revMonthIndex != -1 && revDay != null) {
        return DateTime(year, revMonthIndex + 1, revDay);
      }
    }

    // Try ISO or standard DateTime parse (ensure local representation)
    try {
      final dt = DateTime.parse(clean);
      return dt.isUtc ? dt.toLocal() : dt;
    } catch (_) {
      return null;
    }
  }
}
