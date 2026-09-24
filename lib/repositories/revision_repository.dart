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
        _syncService = syncService ?? RevisionSyncService() {
    _syncService.getSubjectForSync = _revisionDao.getSubject;
    _syncService.getTopicForSync = _revisionDao.getTopic;
  }

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
      await _syncService.enqueueSubjectUpsert(subject);
    }
  }

  Future<void> saveTopic(ChapterTopic topic, {bool pushToCloud = true}) async {
    await _revisionDao.upsertTopic(topic);
    if (pushToCloud) {
      await _syncService.enqueueTopicUpsert(topic);
    }
  }

  Future<void> saveTopicsBatch(List<ChapterTopic> topics, {bool pushToCloud = true}) async {
    await _revisionDao.upsertAllTopics(topics);
    if (pushToCloud) {
      await _syncService.enqueueTopicsUpsert(topics);
    }
  }

  Future<void> deleteSubject(String subjectId, {bool pushToCloud = true}) async {
    await _revisionDao.deleteSubject(subjectId);
    if (pushToCloud) {
      await _syncService.enqueueSubjectDeletion(subjectId);
    }
  }

  Future<void> deleteTopic(String topicId, {bool pushToCloud = true}) async {
    await _revisionDao.deleteTopic(topicId);
    if (pushToCloud) {
      await _syncService.enqueueTopicDeletion(topicId);
    }
  }

  Future<void> syncWithCloud({bool force = false}) async {
    try {
      await _syncService.processPendingQueue();
      final remoteSubjects = await _syncService.pullSubjects();
      final subjectPullFailed = _syncService.lastError != null;
      final remoteTopics = await _syncService.pullTopics();
      final topicPullFailed = _syncService.lastError != null;

      // A failed or incomplete pull is not an authoritative snapshot. Keep all
      // local rows until both tables have been read successfully.
      if (subjectPullFailed || topicPullFailed) return;

      final remoteSubIds = remoteSubjects.map((s) => s.id).toSet();
      final subjectsToApply = remoteSubjects
          .where((s) => !_syncService.hasPendingSubject(s.id))
          .toList();
      if (subjectsToApply.isNotEmpty) {
        await _revisionDao.upsertAllSubjects(subjectsToApply);
      }
      final localSubjects = await _revisionDao.getAllSubjects();
      for (final local in localSubjects) {
        if (!remoteSubIds.contains(local.id) &&
            !_syncService.hasPendingSubject(local.id)) {
          await _revisionDao.deleteSubject(local.id);
        }
      }

      final remoteTopicIds = remoteTopics.map((t) => t.id).toSet();
      final topicsToApply = remoteTopics
          .where((t) => !_syncService.hasPendingTopic(t.id))
          .toList();
      if (topicsToApply.isNotEmpty) {
        await _revisionDao.upsertAllTopics(topicsToApply);
      }
      final localTopics = await _revisionDao.getAllTopics();
      for (final local in localTopics) {
        if (!remoteTopicIds.contains(local.id) &&
            !_syncService.hasPendingTopic(local.id)) {
          await _revisionDao.deleteTopic(local.id);
        }
      }
    } catch (e, st) {
      AppLogger.error('RevisionRepository sync failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  void dispose() {
    _syncService.dispose();
  }
}
