import 'dart:convert';
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

  factory Subject.fromSupabaseRow(Map<String, dynamic> row) {
    int parsedColor = 0xFF6750A4;
    final colorStr = row['color'] as String?;
    if (colorStr != null) {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.replaceFirst('#', '');
        final val = int.tryParse(hex, radix: 16);
        if (val != null) {
          parsedColor = hex.length == 6 ? 0xFF000000 | val : val;
        }
      } else {
        parsedColor = int.tryParse(colorStr) ?? 0xFF6750A4;
      }
    }

    String icon = row['icon'] as String? ?? 'menu_book_rounded';
    if (!icon.endsWith('_rounded') && !icon.endsWith('_sharp') && !icon.endsWith('_outlined')) {
      icon = '${icon}_rounded';
    }

    DateTime created = DateTime.now();
    if (row['created_at'] != null) {
      created = DateTime.tryParse(row['created_at'].toString())?.toLocal() ?? DateTime.now();
    }

    return Subject(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      iconName: icon,
      colorValue: parsedColor,
      createdAt: created,
    );
  }

  Map<String, dynamic> toSupabaseRow({String? defaultUserId}) {
    final hex = colorValue.toRadixString(16).padLeft(8, '0').substring(2);
    return {
      'id': id,
      'user_id': defaultUserId ?? 'singleton',
      'name': name,
      'color': '#$hex',
      'icon': iconName.replaceAll('_rounded', ''),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

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

  factory ChapterTopic.fromSupabaseRow(Map<String, dynamic> row) {
    final stagesRaw = row['stages'];
    List<dynamic> stagesList = [];
    if (stagesRaw is List) {
      stagesList = stagesRaw;
    } else if (stagesRaw is String) {
      try {
        stagesList = jsonDecode(stagesRaw) as List<dynamic>;
      } catch (_) {}
    }

    int completedStages = 0;
    DateTime? lastRevised;
    DateTime? nextRevision;

    for (final s in stagesList) {
      if (s is Map<String, dynamic>) {
        final isStageDone = s['completed'] == true;
        if (isStageDone) {
          completedStages++;
          if (s['completedAt'] != null) {
            final parsed = DateTime.tryParse(s['completedAt'].toString())?.toLocal();
            if (parsed != null && (lastRevised == null || parsed.isAfter(lastRevised))) {
              lastRevised = parsed;
            }
          }
        } else if (nextRevision == null && s['dueDate'] != null) {
          nextRevision = DateTime.tryParse(s['dueDate'].toString())?.toLocal();
        }
      }
    }

    final isMastered = row['status'] == 'mastered' || completedStages >= 4;
    final isCompleted = completedStages > 0 || row['status'] == 'completed';

    return ChapterTopic(
      id: row['id'] as String? ?? '',
      subjectId: row['subject_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['notes'] as String?,
      isCompleted: isCompleted,
      revisionStage: isMastered ? 4 : completedStages,
      lastRevisedAt: lastRevised,
      nextRevisionDate: nextRevision,
    );
  }

  Map<String, dynamic> toSupabaseRow({String? defaultUserId}) {
    return {
      'id': id,
      'user_id': defaultUserId ?? 'singleton',
      'subject_id': subjectId,
      'title': title,
      'notes': description,
      'status': isMastered ? 'mastered' : 'active',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

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
