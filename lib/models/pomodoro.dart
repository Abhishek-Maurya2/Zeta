enum PomodoroMode {
  focus,
  shortBreak,
  longBreak;

  String get label {
    switch (this) {
      case PomodoroMode.focus:
        return 'Focus';
      case PomodoroMode.shortBreak:
        return 'Short break';
      case PomodoroMode.longBreak:
        return 'Long break';
    }
  }

  static PomodoroMode fromString(String val) {
    switch (val) {
      case 'short_break':
      case 'shortBreak':
        return PomodoroMode.shortBreak;
      case 'long_break':
      case 'longBreak':
        return PomodoroMode.longBreak;
      case 'focus':
      default:
        return PomodoroMode.focus;
    }
  }

  String toJsonString() {
    switch (this) {
      case PomodoroMode.shortBreak:
        return 'short_break';
      case PomodoroMode.longBreak:
        return 'long_break';
      case PomodoroMode.focus:
        return 'focus';
    }
  }
}

class PomodoroSessionItem {
  final String id;
  final PomodoroMode mode;
  final String label;
  final int durationMinutes;
  final int? sessionNumber;

  const PomodoroSessionItem({
    required this.id,
    required this.mode,
    required this.label,
    required this.durationMinutes,
    this.sessionNumber,
  });
}

class PomodoroSettings {
  final int focusDuration; // in minutes
  final int shortBreakDuration; // in minutes
  final int longBreakDuration; // in minutes
  final int longBreakInterval; // number of focus sessions before long break
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool autoStartNext;
  final bool skipBreaks;
  final bool soundNotification;
  final bool toastNotification;

  const PomodoroSettings({
    this.focusDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.longBreakInterval = 4,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
    this.autoStartNext = false,
    this.skipBreaks = false,
    this.soundNotification = true,
    this.toastNotification = true,
  });

  PomodoroSettings copyWith({
    int? focusDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? longBreakInterval,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? autoStartNext,
    bool? skipBreaks,
    bool? soundNotification,
    bool? toastNotification,
  }) {
    return PomodoroSettings(
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      autoStartNext: autoStartNext ?? this.autoStartNext,
      skipBreaks: skipBreaks ?? this.skipBreaks,
      soundNotification: soundNotification ?? this.soundNotification,
      toastNotification: toastNotification ?? this.toastNotification,
    );
  }

  Map<String, dynamic> toJson() => {
        'focusDuration': focusDuration,
        'shortBreakDuration': shortBreakDuration,
        'longBreakDuration': longBreakDuration,
        'longBreakInterval': longBreakInterval,
        'autoStartBreaks': autoStartBreaks,
        'autoStartFocus': autoStartFocus,
        'autoStartNext': autoStartNext,
        'skipBreaks': skipBreaks,
        'soundNotification': soundNotification,
        'toastNotification': toastNotification,
      };

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    return PomodoroSettings(
      focusDuration: json['focusDuration'] as int? ?? 25,
      shortBreakDuration: json['shortBreakDuration'] as int? ?? 5,
      longBreakDuration: json['longBreakDuration'] as int? ?? 15,
      longBreakInterval: json['longBreakInterval'] as int? ?? 4,
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? false,
      autoStartFocus: json['autoStartFocus'] as bool? ?? false,
      autoStartNext: json['autoStartNext'] as bool? ?? false,
      skipBreaks: json['skipBreaks'] as bool? ?? false,
      soundNotification: json['soundNotification'] as bool? ?? true,
      toastNotification: json['toastNotification'] as bool? ?? true,
    );
  }
}

class PomodoroSessionLog {
  final String id;
  final PomodoroMode mode;
  final int minutes;
  final int completedAt; // Unix timestamp in ms

  const PomodoroSessionLog({
    required this.id,
    required this.mode,
    required this.minutes,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.toJsonString(),
        'minutes': minutes,
        'completedAt': completedAt,
      };

  factory PomodoroSessionLog.fromJson(Map<String, dynamic> json) {
    return PomodoroSessionLog(
      id: json['id'] as String? ?? '',
      mode: PomodoroMode.fromString(json['mode'] as String? ?? 'focus'),
      minutes: json['minutes'] as int? ?? 0,
      completedAt: json['completedAt'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}

List<PomodoroSessionItem> generateQueue(PomodoroSettings settings) {
  final queue = <PomodoroSessionItem>[];
  final interval =
      settings.longBreakInterval < 1 ? 1 : settings.longBreakInterval;

  for (int i = 1; i <= interval; i++) {
    queue.add(
      PomodoroSessionItem(
        id: 'focus-$i',
        mode: PomodoroMode.focus,
        label: 'Focus',
        durationMinutes: settings.focusDuration,
        sessionNumber: i,
      ),
    );

    if (!settings.skipBreaks) {
      if (i < interval) {
        queue.add(
          PomodoroSessionItem(
            id: 'short-break-$i',
            mode: PomodoroMode.shortBreak,
            label: 'Short break',
            durationMinutes: settings.shortBreakDuration,
          ),
        );
      } else {
        queue.add(
          PomodoroSessionItem(
            id: 'long-break-$i',
            mode: PomodoroMode.longBreak,
            label: 'Long break',
            durationMinutes: settings.longBreakDuration,
          ),
        );
      }
    }
  }

  return queue;
}

/// Generates realistic sample session logs distributed across today,
/// the current week, month, past 3 months, and the entire year.
List<PomodoroSessionLog> generateSampleSessionLogs([DateTime? referenceTime]) {
  final now = referenceTime ?? DateTime.now();
  final logs = <PomodoroSessionLog>[];
  int idCounter = 1;

  void addSession(DateTime dt, int minutes, [PomodoroMode mode = PomodoroMode.focus]) {
    logs.add(
      PomodoroSessionLog(
        id: 'sample-${idCounter++}',
        mode: mode,
        minutes: minutes,
        completedAt: dt.millisecondsSinceEpoch,
      ),
    );
  }

  // 1. TODAY (Active focus sessions throughout morning, afternoon, evening)
  addSession(DateTime(now.year, now.month, now.day, 9, 25), 25);
  addSession(DateTime(now.year, now.month, now.day, 9, 30), 5, PomodoroMode.shortBreak);
  addSession(DateTime(now.year, now.month, now.day, 10, 0), 25);
  addSession(DateTime(now.year, now.month, now.day, 10, 5), 5, PomodoroMode.shortBreak);
  addSession(DateTime(now.year, now.month, now.day, 11, 45), 30);
  addSession(DateTime(now.year, now.month, now.day, 14, 30), 25);
  addSession(DateTime(now.year, now.month, now.day, 16, 45), 45);

  // 2. YESTERDAY (Hit daily goal: 125m)
  final yesterday = now.subtract(const Duration(days: 1));
  addSession(DateTime(yesterday.year, yesterday.month, yesterday.day, 9, 30), 25);
  addSession(DateTime(yesterday.year, yesterday.month, yesterday.day, 10, 45), 25);
  addSession(DateTime(yesterday.year, yesterday.month, yesterday.day, 14, 0), 30);
  addSession(DateTime(yesterday.year, yesterday.month, yesterday.day, 16, 0), 25);
  addSession(DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 30), 25);

  // 3. THIS WEEK (Days -2 through -6)
  // Day -2: 125 mins (Goal hit)
  final d2 = now.subtract(const Duration(days: 2));
  addSession(DateTime(d2.year, d2.month, d2.day, 9, 30), 50);
  addSession(DateTime(d2.year, d2.month, d2.day, 14, 0), 50);
  addSession(DateTime(d2.year, d2.month, d2.day, 17, 0), 25);

  // Day -3: 150 mins (Goal hit)
  final d3 = now.subtract(const Duration(days: 3));
  addSession(DateTime(d3.year, d3.month, d3.day, 10, 0), 50);
  addSession(DateTime(d3.year, d3.month, d3.day, 13, 30), 50);
  addSession(DateTime(d3.year, d3.month, d3.day, 16, 0), 50);

  // Day -4: 100 mins (Goal hit)
  final d4 = now.subtract(const Duration(days: 4));
  addSession(DateTime(d4.year, d4.month, d4.day, 11, 0), 50);
  addSession(DateTime(d4.year, d4.month, d4.day, 15, 0), 50);

  // Day -5: 50 mins
  final d5 = now.subtract(const Duration(days: 5));
  addSession(DateTime(d5.year, d5.month, d5.day, 14, 0), 25);
  addSession(DateTime(d5.year, d5.month, d5.day, 16, 0), 25);

  // Day -6: 125 mins (Goal hit)
  final d6 = now.subtract(const Duration(days: 6));
  addSession(DateTime(d6.year, d6.month, d6.day, 9, 30), 50);
  addSession(DateTime(d6.year, d6.month, d6.day, 14, 0), 50);
  addSession(DateTime(d6.year, d6.month, d6.day, 17, 0), 25);

  // 4. EARLIER IN THIS MONTH (Days 7 through 28)
  for (int dayOffset = 7; dayOffset <= 28; dayOffset += 2) {
    final d = now.subtract(Duration(days: dayOffset));
    final mins = (dayOffset % 4 == 0) ? 125 : 75;
    addSession(DateTime(d.year, d.month, d.day, 10, 0), mins ~/ 2);
    addSession(DateTime(d.year, d.month, d.day, 15, 0), mins - (mins ~/ 2));
  }

  // 5. PAST 2-11 MONTHS (For 3-Month and Year charts)
  for (int monthOffset = 1; monthOffset <= 11; monthOffset++) {
    final targetMonth = DateTime(now.year, now.month - monthOffset, 1);
    final daysInMonth = [5, 10, 15, 20, 25];
    final minutesList = [75, 100, 125, 90, 110];
    for (int i = 0; i < daysInMonth.length; i++) {
      final sessionDate = DateTime(
        targetMonth.year,
        targetMonth.month,
        daysInMonth[i],
        11,
        0,
      );
      addSession(sessionDate, minutesList[i]);
    }
  }

  // Sort logs chronologically ascending
  logs.sort((a, b) => a.completedAt.compareTo(b.completedAt));
  return logs;
}
