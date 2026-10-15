import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/account_scope.dart';
import '../../../database/database_provider.dart';
import '../../../database/daos/revision_dao.dart';
import '../../../models/revision.dart';
import '../../../core/sync/sync_coordinator.dart';

/// Clean Architecture Repository for Revision domain.
class RevisionRepository {
  final RevisionDao _revisionDao;
  final SyncCoordinator? _syncCoordinator;

  RevisionRepository({
    RevisionDao? revisionDao,
    SyncCoordinator? syncCoordinator,
  })  : _revisionDao = revisionDao ?? DatabaseProvider.instance.revisionDao,
        // ignore: prefer_initializing_formals
        _syncCoordinator = syncCoordinator;

  Stream<List<Subject>> watchSubjects() => _revisionDao.watchSubjects();

  Stream<List<ChapterTopic>> watchTopics(String subjectId) =>
      _revisionDao.watchTopicsForSubject(subjectId);

  Future<List<Subject>> getSubjects() => _revisionDao.getAllSubjects();

  Future<List<ChapterTopic>> getTopicsForSubject(String subjectId) =>
      _revisionDao.getTopicsForSubject(subjectId);

  Future<void> saveSubject(Subject subject) async {
    await _revisionDao.upsertSubject(subject);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'revisions',
        entityType: 'subject',
        entityId: subject.id,
        operation: 'upsert',
      );
      _syncCoordinator?.triggerSync();
    }
  }

  Future<void> saveTopic(ChapterTopic topic) async {
    await _revisionDao.upsertTopic(topic);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'revisions',
        entityType: 'topic',
        entityId: topic.id,
        operation: 'upsert',
      );
      _syncCoordinator?.triggerSync();
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    await _revisionDao.deleteSubject(subjectId);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'revisions',
        entityType: 'subject',
        entityId: subjectId,
        operation: 'delete',
      );
      _syncCoordinator?.triggerSync();
    }
  }

  Future<void> deleteTopic(String topicId) async {
    await _revisionDao.deleteTopic(topicId);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'revisions',
        entityType: 'topic',
        entityId: topicId,
        operation: 'delete',
      );
      _syncCoordinator?.triggerSync();
    }
  }
}

final revisionRepositoryProvider = Provider<RevisionRepository>((ref) {
  final syncCoordinator = ref.watch(syncCoordinatorProvider.notifier);
  return RevisionRepository(syncCoordinator: syncCoordinator);
});
