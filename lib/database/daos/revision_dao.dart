import 'package:drift/drift.dart';

import '../../models/revision.dart';
import '../app_database.dart';
import '../account_scope.dart';
import 'sync_outbox_dao.dart';

/// Data Access Object for [RevisionSubjectsTable] and [RevisionTopicsTable].
class RevisionDao {
  final AppDatabase _db;

  RevisionDao(this._db);

  Expression<bool> _owner(GeneratedColumn<String> userId) =>
      AccountScope.userId == null
      ? userId.isNull()
      : userId.equals(AccountScope.userId!);

  // ─── Subjects ─────────────────────────────────────────────────────────────

  Future<List<Subject>> getAllSubjects() async {
    final rows =
        await (_db.select(_db.revisionSubjectsTable)
              ..where((t) => _owner(t.userId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
            .get();
    return rows.map(AppDatabase.rowToSubject).toList();
  }

  Future<void> upsertSubject(Subject subject) async {
    await _db
        .into(_db.revisionSubjectsTable)
        .insertOnConflictUpdate(AppDatabase.subjectToCompanion(subject));
  }

  Future<void> upsertSubjectAndQueue(Subject subject) async {
    await _db.transaction(() async {
      await upsertSubject(subject);
      await _queue('subject', subject.id, 'upsert');
    });
  }

  Future<Subject?> getSubject(String subjectId) async {
    final row =
        await (_db.select(_db.revisionSubjectsTable)
              ..where((s) => s.id.equals(subjectId) & _owner(s.userId)))
            .getSingleOrNull();
    return row == null ? null : AppDatabase.rowToSubject(row);
  }

  Future<void> upsertAllSubjects(List<Subject> subjects) async {
    await _db.batch((batch) {
      for (final s in subjects) {
        batch.insert(
          _db.revisionSubjectsTable,
          AppDatabase.subjectToCompanion(s),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteTopicsForSubject(String subjectId) async {
    await (_db.delete(
      _db.revisionTopicsTable,
    )..where((t) => t.subjectId.equals(subjectId) & _owner(t.userId))).go();
  }

  Future<void> deleteSubject(String subjectId) async {
    await _db.transaction(() async {
      // Cascading delete topics for this subject
      await deleteTopicsForSubject(subjectId);
      await (_db.delete(
        _db.revisionSubjectsTable,
      )..where((t) => t.id.equals(subjectId) & _owner(t.userId))).go();
    });
  }

  Future<void> deleteSubjectAndQueue(String subjectId) async {
    await _db.transaction(() async {
      final childTopics = await getTopicsForSubject(subjectId);
      for (final topic in childTopics) {
        await _queue('topic', topic.id, 'delete');
      }
      await _queue('subject', subjectId, 'delete');
      await deleteTopicsForSubject(subjectId);
      await (_db.delete(
        _db.revisionSubjectsTable,
      )..where((t) => t.id.equals(subjectId) & _owner(t.userId))).go();
    });
  }

  // ─── Topics ───────────────────────────────────────────────────────────────

  Future<List<ChapterTopic>> getAllTopics() async {
    final rows =
        await (_db.select(_db.revisionTopicsTable)
              ..where((t) => _owner(t.userId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(AppDatabase.rowToTopic).toList();
  }

  Future<List<ChapterTopic>> getTopicsForSubject(String subjectId) async {
    final rows =
        await (_db.select(_db.revisionTopicsTable)
              ..where((t) => t.subjectId.equals(subjectId) & _owner(t.userId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(AppDatabase.rowToTopic).toList();
  }

  Future<ChapterTopic?> getTopic(String topicId) async {
    final row = await (_db.select(
      _db.revisionTopicsTable,
    )..where((t) => t.id.equals(topicId) & _owner(t.userId))).getSingleOrNull();
    if (row == null) return null;
    return AppDatabase.rowToTopic(row);
  }

  Future<void> upsertTopic(ChapterTopic topic) async {
    await _db
        .into(_db.revisionTopicsTable)
        .insertOnConflictUpdate(AppDatabase.topicToCompanion(topic));
  }

  Future<void> upsertTopicAndQueue(ChapterTopic topic) async {
    await _db.transaction(() async {
      await upsertTopic(topic);
      await _queue('topic', topic.id, 'upsert');
    });
  }

  Future<void> upsertAllTopics(List<ChapterTopic> topics) async {
    await _db.batch((batch) {
      for (final t in topics) {
        batch.insert(
          _db.revisionTopicsTable,
          AppDatabase.topicToCompanion(t),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> upsertAllTopicsAndQueue(List<ChapterTopic> topics) async {
    await _db.transaction(() async {
      await upsertAllTopics(topics);
      for (final topic in topics) {
        await _queue('topic', topic.id, 'upsert');
      }
    });
  }

  Future<void> deleteTopic(String topicId) async {
    await (_db.delete(
      _db.revisionTopicsTable,
    )..where((t) => t.id.equals(topicId) & _owner(t.userId))).go();
  }

  Future<void> deleteTopicAndQueue(String topicId) async {
    await _db.transaction(() async {
      await _queue('topic', topicId, 'delete');
      await deleteTopic(topicId);
    });
  }

  Future<void> _queue(String entity, String id, String operation) async {
    final userId = AccountScope.userId;
    if (userId == null) return;
    await SyncOutboxDao(_db).enqueue(
      userId: userId,
      feature: 'revisions',
      entityType: entity,
      entityId: id,
      operation: operation,
    );
  }

  Future<void> clearAll() async {
    await (_db.delete(
      _db.revisionTopicsTable,
    )..where((t) => _owner(t.userId))).go();
    await (_db.delete(
      _db.revisionSubjectsTable,
    )..where((t) => _owner(t.userId))).go();
  }
}
