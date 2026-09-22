import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/revision.dart';
import '../providers/task_provider.dart';
import '../utils/task_date_formatter.dart';
import '../services/revision_sync_service.dart';

/// Persisted configuration for the Revision spaced-repetition system.
class RevisionSettings {
  /// Days until next revision for stages 1-4.
  final int stage1Days;
  final int stage2Days;
  final int stage3Days;
  final int stage4Days;
  /// Whether to automatically create revision reminder tasks on the Task Page.
  final bool autoCreateTasks;
  /// Whether to provide haptic feedback when updating revisions.
  final bool hapticFeedback;

  const RevisionSettings({
    this.stage1Days = 5,
    this.stage2Days = 10,
    this.stage3Days = 20,
    this.stage4Days = 40,
    this.autoCreateTasks = true,
    this.hapticFeedback = true,
  });

  RevisionSettings copyWith({
    int? stage1Days,
    int? stage2Days,
    int? stage3Days,
    int? stage4Days,
    bool? autoCreateTasks,
    bool? hapticFeedback,
  }) =>
      RevisionSettings(
        stage1Days: stage1Days ?? this.stage1Days,
        stage2Days: stage2Days ?? this.stage2Days,
        stage3Days: stage3Days ?? this.stage3Days,
        stage4Days: stage4Days ?? this.stage4Days,
        autoCreateTasks: autoCreateTasks ?? this.autoCreateTasks,
        hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      );

  Map<String, dynamic> toJson() => {
    'stage1Days': stage1Days,
    'stage2Days': stage2Days,
    'stage3Days': stage3Days,
    'stage4Days': stage4Days,
    'autoCreateTasks': autoCreateTasks,
    'hapticFeedback': hapticFeedback,
  };

  factory RevisionSettings.fromJson(Map<String, dynamic> json) =>
      RevisionSettings(
        stage1Days: (json['stage1Days'] as int?) ?? 5,
        stage2Days: (json['stage2Days'] as int?) ?? 10,
        stage3Days: (json['stage3Days'] as int?) ?? 20,
        stage4Days: (json['stage4Days'] as int?) ?? 40,
        autoCreateTasks: (json['autoCreateTasks'] as bool?) ?? true,
        hapticFeedback: (json['hapticFeedback'] as bool?) ?? true,
      );
}

class RevisionProvider with ChangeNotifier {
  static const String _subjectsKey = 'zeta_revision_subjects_v2';
  static const String _topicsKey = 'zeta_revision_topics_v2';
  static const String _settingsKey = 'zeta_revision_settings_v1';
  final Uuid _uuid = const Uuid();
  final RevisionSyncService _syncService = RevisionSyncService();

  List<Subject> _subjects = [];
  List<ChapterTopic> _topics = [];
  String? _selectedSubjectId;
  bool _isLoading = true;
  RevisionSettings _settings = const RevisionSettings();

  RevisionProvider() {
    _loadData();
  }

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<ChapterTopic> get topics => List.unmodifiable(_topics);
  String? get selectedSubjectId => _selectedSubjectId;
  bool get isLoading => _isLoading;
  RevisionSettings get settings => _settings;

  Subject? get selectedSubject {
    if (_selectedSubjectId == null) return null;
    return _subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
  }

  List<ChapterTopic> get topicsForSelectedSubject {
    final sub = selectedSubject;
    if (sub == null || sub.id.isEmpty) return [];
    final list = _topics.where((t) => t.subjectId == sub.id).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  int get totalTopicsCount => _topics.length;
  int get completedTopicsCount => _topics.where((t) => t.isCompleted || t.isMastered).length;
  int get masteredTopicsCount => _topics.where((t) => t.isMastered).length;
  int get dueRevisionsCount => _topics.where((t) => t.status == RevisionStatus.overdue || (t.status == RevisionStatus.scheduled && _isDueToday(t.nextRevisionDate))).length;

  static bool _isDueToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void selectSubject(String? subjectId) {
    _selectedSubjectId = subjectId;
    notifyListeners();
  }

  // ─── Data Loading & Persistence ──────────────────────────────────────────────

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsRaw = prefs.getString(_subjectsKey);
      final topicsRaw = prefs.getString(_topicsKey);
      final settingsRaw = prefs.getString(_settingsKey);

      if (settingsRaw != null && settingsRaw.isNotEmpty) {
        _settings = RevisionSettings.fromJson(
          jsonDecode(settingsRaw) as Map<String, dynamic>,
        );
      }

      if (subjectsRaw != null && subjectsRaw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(subjectsRaw);
        _subjects = list.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (topicsRaw != null && topicsRaw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(topicsRaw);
        _topics = list.map((e) => ChapterTopic.fromJson(e as Map<String, dynamic>)).toList();
      }

      // If cached data was loaded, render immediately
      if (_subjects.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
      }

      // Fetch dynamic data from Supabase
      final remoteSubjects = await _syncService.pullSubjects();
      final remoteTopics = await _syncService.pullTopics();

      if (remoteSubjects.isNotEmpty) {
        _subjects = remoteSubjects;
        _topics = remoteTopics;
        await _saveData();
      }
    } catch (e) {
      debugPrint('Error loading Revision data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pulls the latest revision subjects and topics from Supabase.
  Future<void> refreshData() async {
    try {
      final remoteSubjects = await _syncService.pullSubjects();
      final remoteTopics = await _syncService.pullTopics();

      if (_syncService.lastError == null) {
        if (remoteSubjects.isNotEmpty) {
          _subjects = remoteSubjects;
        }
        if (remoteTopics.isNotEmpty) {
          _topics = remoteTopics;
        }
        if (remoteSubjects.isNotEmpty || remoteTopics.isNotEmpty) {
          await _saveData();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('RevisionProvider: refreshData error - $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectsJson = jsonEncode(_subjects.map((s) => s.toJson()).toList());
      final topicsJson = jsonEncode(_topics.map((t) => t.toJson()).toList());

      await prefs.setString(_subjectsKey, subjectsJson);
      await prefs.setString(_topicsKey, topicsJson);
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('Error saving Revision data: $e');
    }
  }

  // ─── Settings ────────────────────────────────────────────────────────────────

  Future<void> updateSettings(RevisionSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _saveData();
  }

  void resetToDefaultSettings() {
    _settings = const RevisionSettings();
    notifyListeners();
    _saveData();
  }

  // ─── CRUD Operations ────────────────────────────────────────────────────────

  Future<void> addSubject(String name, {String iconName = 'menu_book_rounded', int colorValue = 0xFF6750A4}) async {
    final newSubject = Subject(
      id: _uuid.v4(),
      name: name,
      iconName: iconName,
      colorValue: colorValue,
    );
    _subjects.add(newSubject);
    _selectedSubjectId = newSubject.id;
    await _saveData();
    notifyListeners();
    _syncService.pushSubject(newSubject);
  }

  Future<void> updateSubject(Subject subject) async {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      await _saveData();
      notifyListeners();
      _syncService.pushSubject(subject);
    }
  }

  Future<void> deleteSubject(String subjectId, TaskProvider taskProvider) async {
    // Cascade: delete all revision tasks linked to topics of this subject
    final subjectTopics = _topics.where((t) => t.subjectId == subjectId).toList();
    for (final topic in subjectTopics) {
      final taskId = topic.associatedTaskId;
      if (taskId != null) {
        taskProvider.deleteTask(taskId);
      }
    }
    _subjects.removeWhere((s) => s.id == subjectId);
    _topics.removeWhere((t) => t.subjectId == subjectId);
    if (_selectedSubjectId == subjectId) {
      _selectedSubjectId = null;
    }
    await _saveData();
    notifyListeners();
    _syncService.deleteSubject(subjectId);
  }

  Future<void> addTopic(String subjectId, String title, {String? description}) async {
    final subjectTopics = _topics.where((t) => t.subjectId == subjectId).toList();
    final nextSortOrder = subjectTopics.isEmpty
        ? 0
        : subjectTopics
                .map((t) => t.sortOrder)
                .fold<int>(0, (prev, curr) => curr > prev ? curr : prev) +
            1;

    final newTopic = ChapterTopic(
      id: _uuid.v4(),
      subjectId: subjectId,
      title: title,
      description: description,
      sortOrder: nextSortOrder,
    );
    _topics.add(newTopic);
    await _saveData();
    notifyListeners();
    _syncService.pushTopic(newTopic);
  }

  Future<void> updateTopic(ChapterTopic topic) async {
    final index = _topics.indexWhere((t) => t.id == topic.id);
    if (index != -1) {
      _topics[index] = topic;
      await _saveData();
      notifyListeners();
      _syncService.pushTopic(topic);
    }
  }

  Future<void> deleteTopic(String topicId, TaskProvider taskProvider) async {
    // Cascade: delete the revision task linked to this topic (if any)
    final topicIndex = _topics.indexWhere((t) => t.id == topicId);
    if (topicIndex != -1) {
      final taskId = _topics[topicIndex].associatedTaskId;
      if (taskId != null) {
        taskProvider.deleteTask(taskId);
      }
    }
    _topics.removeWhere((t) => t.id == topicId);
    await _saveData();
    notifyListeners();
    _syncService.deleteTopic(topicId);
  }

  /// Reorders a topic within a subject from [oldIndex] to [newIndex]
  /// and updates sort orders locally and in Supabase.
  Future<void> reorderTopic(String subjectId, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final subjectTopics = topicsForSelectedSubject;
    if (oldIndex < 0 ||
        oldIndex >= subjectTopics.length ||
        newIndex < 0 ||
        newIndex >= subjectTopics.length) {
      return;
    }

    final movedTopic = subjectTopics.removeAt(oldIndex);
    subjectTopics.insert(newIndex, movedTopic);

    final updatedTopics = <ChapterTopic>[];
    for (int i = 0; i < subjectTopics.length; i++) {
      final updated = subjectTopics[i].copyWith(sortOrder: i);
      updatedTopics.add(updated);

      final idx = _topics.indexWhere((t) => t.id == updated.id);
      if (idx != -1) {
        _topics[idx] = updated;
      }
    }

    await _saveData();
    notifyListeners();

    _syncService.pushTopics(updatedTopics);
  }

  // ─── Spaced Repetition Logic & Task Integration ─────────────────────────────

  /// Marks a topic complete or advances its revision stage.
  /// Schedules next revision date and creates a revision task in [TaskProvider].
  Future<void> completeTopic(String topicId, TaskProvider taskProvider) async {
    final index = _topics.indexWhere((t) => t.id == topicId);
    if (index == -1) return;

    final topic = _topics[index];
    final currentStage = topic.revisionStage;
    final nextStage = currentStage >= 5 ? 5 : currentStage + 1;

    DateTime? nextDate;
    if (nextStage == 1) {
      nextDate = DateTime.now().add(Duration(days: _settings.stage1Days));
    } else if (nextStage == 2) {
      nextDate = DateTime.now().add(Duration(days: _settings.stage2Days));
    } else if (nextStage == 3) {
      nextDate = DateTime.now().add(Duration(days: _settings.stage3Days));
    } else if (nextStage == 4) {
      nextDate = DateTime.now().add(Duration(days: _settings.stage4Days));
    } else {
      nextDate = null; // Mastered!
    }

    // Remove the old associated task before creating a new one
    final oldTaskId = topic.associatedTaskId;
    if (oldTaskId != null) {
      taskProvider.deleteTask(oldTaskId);
    }

    String? createdTaskId;
    if (_settings.autoCreateTasks && nextStage < 5 && nextDate != null) {
      final formattedDueDate = TaskDateFormatter.format(nextDate);
      final taskTitle = 'Revise: ${topic.title}';
      final taskDesc = '#Revision  •  Stage $nextStage Spaced Repetition';

      createdTaskId = await taskProvider.addTask(
        title: taskTitle,
        description: taskDesc,
        dueDate: formattedDueDate,
      );
    }

    _topics[index] = topic.copyWith(
      isCompleted: true,
      revisionStage: nextStage,
      lastRevisedAt: DateTime.now(),
      nextRevisionDate: nextDate,
      associatedTaskId: createdTaskId,
    );

    await _saveData();
    notifyListeners();
    _syncService.pushTopic(_topics[index]);
  }

  /// Triggered bi-directionally when a Task linked to a revision topic is completed in [TaskProvider].
  Future<void> syncFromTaskCompletion(String taskId, TaskProvider taskProvider) async {
    final index = _topics.indexWhere((t) => t.associatedTaskId == taskId);
    if (index == -1) return;

    final topic = _topics[index];
    // Automatically complete topic to advance to next stage
    await completeTopic(topic.id, taskProvider);
  }
}
