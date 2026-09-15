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

