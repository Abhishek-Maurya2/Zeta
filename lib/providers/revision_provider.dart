import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/revision.dart';
import '../providers/task_provider.dart';
import '../utils/task_date_formatter.dart';
import '../services/revision_sync_service.dart';

class RevisionProvider with ChangeNotifier {
  static const String _subjectsKey = 'zeta_revision_subjects_v2';
  static const String _topicsKey = 'zeta_revision_topics_v2';
  final Uuid _uuid = const Uuid();
  final RevisionSyncService _syncService = RevisionSyncService();

  List<Subject> _subjects = [];
  List<ChapterTopic> _topics = [];
  String? _selectedSubjectId;
  bool _isLoading = true;

  RevisionProvider() {
    _loadData();
  }

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<ChapterTopic> get topics => List.unmodifiable(_topics);
  String? get selectedSubjectId => _selectedSubjectId;
  bool get isLoading => _isLoading;

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
    } catch (e) {
      debugPrint('Error saving Revision data: $e');
    }
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

  Future<void> deleteSubject(String subjectId) async {
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

  Future<void> deleteTopic(String topicId) async {
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
    final nextStage = currentStage >= 4 ? 4 : currentStage + 1;

    DateTime? nextDate;
    if (nextStage == 1) {
      nextDate = DateTime.now().add(const Duration(days: 1));
    } else if (nextStage == 2) {
      nextDate = DateTime.now().add(const Duration(days: 3));
    } else if (nextStage == 3) {
      nextDate = DateTime.now().add(const Duration(days: 7));
    } else {
      nextDate = null; // Mastered!
    }

    String? createdTaskId;
    if (nextStage < 4 && nextDate != null) {
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
      associatedTaskId: createdTaskId ?? topic.associatedTaskId,
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
