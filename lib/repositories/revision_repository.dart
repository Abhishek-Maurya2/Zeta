import 'dart:async';
import '../models/revision.dart';
import '../database/daos/revision_dao.dart';
import '../database/database_provider.dart';
import '../services/revision_sync_service.dart';
import '../utils/app_logger.dart';

/// Repository coordinating local SQLite revision subjects/topics with cloud sync.
class RevisionRepository {
  final RevisionDao _revisionDao;
  final RevisionSyncService _syncService;

  RevisionRepository({
    RevisionDao? revisionDao,
    RevisionSyncService? syncService,
  })  : _revisionDao = revisionDao ?? DatabaseProvider.instance.revisionDao,
        _syncService = syncService ?? RevisionSyncService();

  RevisionDao get revisionDao => _revisionDao;
  RevisionSyncService get syncService => _syncService;

  bool get isSyncing => _syncService.isSyncing;
  DateTime? get lastSyncedAt => _syncService.lastSyncedAt;
  String? get syncError => _syncService.lastError;

  Future<List<Subject>> getSubjects() => _revisionDao.getAllSubjects();

  Future<List<ChapterTopic>> getTopicsForSubject(String subjectId) =>
      _revisionDao.getTopicsForSubject(subjectId);

  Future<List<ChapterTopic>> getAllTopics() => _revisionDao.getAllTopics();

  Future<void> saveSubject(Subject subject, {bool pushToCloud = true}) async {
    await _revisionDao.upsertSubject(subject);
    if (pushToCloud) {
      unawaited(_syncService.pushSubject(subject));
    }
  }

  Future<void> saveTopic(ChapterTopic topic, {bool pushToCloud = true}) async {
    await _revisionDao.upsertTopic(topic);
    if (pushToCloud) {
      unawaited(_syncService.pushTopic(topic));
    }
  }

  Future<void> deleteSubject(String subjectId, {bool pushToCloud = true}) async {
    await _revisionDao.deleteSubject(subjectId);
    if (pushToCloud) {
      unawaited(_syncService.deleteSubject(subjectId));
    }
  }

  Future<void> deleteTopic(String topicId, {bool pushToCloud = true}) async {
    await _revisionDao.deleteTopic(topicId);
    if (pushToCloud) {
      unawaited(_syncService.deleteTopic(topicId));
    }
  }

  Future<void> syncWithCloud({bool force = false}) async {
    try {
      final remoteSubjects = await _syncService.pullSubjects();
      if (remoteSubjects.isNotEmpty) {
        await _revisionDao.upsertAllSubjects(remoteSubjects);
      }
      final remoteTopics = await _syncService.pullTopics();
      if (remoteTopics.isNotEmpty) {
        await _revisionDao.upsertAllTopics(remoteTopics);
      }
    } catch (e, st) {
      AppLogger.error('RevisionRepository sync failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
