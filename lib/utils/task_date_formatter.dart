/// Utility for formatting and parsing task dates and times consistently across Zeta.
/// 
/// Supported formats:
/// - Nearby dates: 'Today', 'Tomorrow', 'Yesterday'
/// - Calendar dates: '13, Sep'
/// - Task list item display: Time is only included when the date is for 'Today'.
class TaskDateFormatter {
  TaskDateFormatter._();

  static const List<String> months = [
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

  /// Formats a [DateTime] into 'Today', 'Tomorrow', 'Yesterday', or '13, Sep'.
  static String format(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';

    return '${date.day}, ${months[date.month - 1]}';
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
  /// - Shows time whenever hasTime is true with a valid dueTime.
  /// - Format: 'Today • 10:00 AM' or 'Tomorrow • 02:30 PM' or '13, Sep • 11:15 AM'.
  /// - Format when no time: 'Today', 'Tomorrow', '13, Sep'.
  static String formatTaskListDate({
    required String dueDate,
    required bool hasTime,
    String? dueTime,
  }) {
    final formattedDate = formatString(dueDate);

    if (hasTime && dueTime != null && dueTime.trim().isNotEmpty) {
      return '$formattedDate • $dueTime';
    }

    return formattedDate;
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
          months.indexWhere((m) => m.toLowerCase() == monthLower);
      final year = parts.length >= 3 ? int.tryParse(parts[2]) ?? now.year : now.year;
      if (day != null && monthIndex != -1) {
        return DateTime(year, monthIndex + 1, day);
      }

      // Check reverse format: "Sep 13" or "Sep 13 2026"
      final revMonthIndex =
          months.indexWhere((m) => m.toLowerCase() == parts[0].toLowerCase());
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
