import 'package:drift/drift.dart';
import '../../models/revision.dart';
import '../app_database.dart';

/// Data Access Object for [RevisionSubjectsTable] and [RevisionTopicsTable].
class RevisionDao {
  final AppDatabase _db;

  RevisionDao(this._db);

  // ─── Subjects ─────────────────────────────────────────────────────────────

  Future<List<Subject>> getAllSubjects() async {
    final rows = await (_db.select(_db.revisionSubjectsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
        .get();
    return rows.map(AppDatabase.rowToSubject).toList();
  }

  Future<void> upsertSubject(Subject subject) async {
    await _db.into(_db.revisionSubjectsTable).insertOnConflictUpdate(
      AppDatabase.subjectToCompanion(subject),
    );
  }

  Future<Subject?> getSubject(String subjectId) async {
    final row = await (_db.select(_db.revisionSubjectsTable)
          ..where((s) => s.id.equals(subjectId)))
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
    await (_db.delete(_db.revisionTopicsTable)
          ..where((t) => t.subjectId.equals(subjectId)))
        .go();
  }

  Future<void> deleteSubject(String subjectId) async {
    await _db.transaction(() async {
      // Cascading delete topics for this subject
      await deleteTopicsForSubject(subjectId);
      await (_db.delete(_db.revisionSubjectsTable)
            ..where((t) => t.id.equals(subjectId)))
          .go();
    });
  }

  // ─── Topics ───────────────────────────────────────────────────────────────

  Future<List<ChapterTopic>> getAllTopics() async {
    final rows = await (_db.select(_db.revisionTopicsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(AppDatabase.rowToTopic).toList();
  }

  Future<List<ChapterTopic>> getTopicsForSubject(String subjectId) async {
    final rows = await (_db.select(_db.revisionTopicsTable)
          ..where((t) => t.subjectId.equals(subjectId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(AppDatabase.rowToTopic).toList();
  }

  Future<ChapterTopic?> getTopic(String topicId) async {
    final row = await (_db.select(_db.revisionTopicsTable)
          ..where((t) => t.id.equals(topicId)))
        .getSingleOrNull();
    if (row == null) return null;
    return AppDatabase.rowToTopic(row);
  }

  Future<void> upsertTopic(ChapterTopic topic) async {
    await _db.into(_db.revisionTopicsTable).insertOnConflictUpdate(
      AppDatabase.topicToCompanion(topic),
    );
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

  Future<void> deleteTopic(String topicId) async {
    await (_db.delete(_db.revisionTopicsTable)
          ..where((t) => t.id.equals(topicId)))
        .go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.revisionTopicsTable).go();
    await _db.delete(_db.revisionSubjectsTable).go();
  }
}
