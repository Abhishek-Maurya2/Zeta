import 'package:flutter/material.dart';

enum RevisionStatus {
  notStarted,
  scheduled,
  overdue,
  mastered,
}

class Subject {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    this.iconName = 'menu_book_rounded',
    this.colorValue = 0xFF6750A4,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        iconName: json['iconName'] as String? ?? 'menu_book_rounded',
        colorValue: json['colorValue'] as int? ?? 0xFF6750A4,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  Subject copyWith({
    String? id,
    String? name,
    String? iconName,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ChapterTopic {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final bool isCompleted;
  /// Spaced Repetition stage:
  /// 0 = Not started
  /// 1 = Revised 1x (due +1 day)
  /// 2 = Revised 2x (due +3 days)
  /// 3 = Revised 3x (due +7 days)
  /// 4 = Mastered 🏆
  final int revisionStage;
  final DateTime? lastRevisedAt;
  final DateTime? nextRevisionDate;
  final String? associatedTaskId;

  ChapterTopic({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.revisionStage = 0,
    this.lastRevisedAt,
    this.nextRevisionDate,
    this.associatedTaskId,
  });

  bool get isMastered => revisionStage >= 4;

  RevisionStatus get status {
    if (isMastered) return RevisionStatus.mastered;
    if (!isCompleted && revisionStage == 0) return RevisionStatus.notStarted;
    if (nextRevisionDate == null) return RevisionStatus.notStarted;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      nextRevisionDate!.year,
      nextRevisionDate!.month,
      nextRevisionDate!.day,
    );

    if (due.isBefore(today)) return RevisionStatus.overdue;
    return RevisionStatus.scheduled;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'revisionStage': revisionStage,
        'lastRevisedAt': lastRevisedAt?.toIso8601String(),
        'nextRevisionDate': nextRevisionDate?.toIso8601String(),
        'associatedTaskId': associatedTaskId,
      };

  factory ChapterTopic.fromJson(Map<String, dynamic> json) => ChapterTopic(
        id: json['id'] as String? ?? '',
        subjectId: json['subjectId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        revisionStage: json['revisionStage'] as int? ?? 0,
        lastRevisedAt: json['lastRevisedAt'] != null
            ? DateTime.tryParse(json['lastRevisedAt'] as String)
            : null,
        nextRevisionDate: json['nextRevisionDate'] != null
            ? DateTime.tryParse(json['nextRevisionDate'] as String)
            : null,
        associatedTaskId: json['associatedTaskId'] as String?,
      );

  ChapterTopic copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    bool? isCompleted,
    int? revisionStage,
    DateTime? lastRevisedAt,
    DateTime? nextRevisionDate,
    String? associatedTaskId,
  }) {
    return ChapterTopic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      revisionStage: revisionStage ?? this.revisionStage,
      lastRevisedAt: lastRevisedAt ?? this.lastRevisedAt,
      nextRevisionDate: nextRevisionDate ?? this.nextRevisionDate,
      associatedTaskId: associatedTaskId ?? this.associatedTaskId,
    );
  }
}
