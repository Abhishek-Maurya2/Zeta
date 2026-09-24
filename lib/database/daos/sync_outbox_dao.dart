import 'package:drift/drift.dart';

import '../app_database.dart';

class SyncOutboxEntry {
  final String id;
  final String userId;
  final String feature;
  final String entityType;
  final String entityId;
  final String operation;
  final int createdAtMs;
  final int attempts;

  const SyncOutboxEntry({
    required this.id,
    required this.userId,
    required this.feature,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.createdAtMs,
    required this.attempts,
  });

  factory SyncOutboxEntry.fromRow(QueryRow row) => SyncOutboxEntry(
    id: row.read<String>('id'),
    userId: row.read<String>('user_id'),
    feature: row.read<String>('feature'),
    entityType: row.read<String>('entity_type'),
    entityId: row.read<String>('entity_id'),
    operation: row.read<String>('operation'),
    createdAtMs: row.read<int>('created_at_ms'),
    attempts: row.read<int>('attempts'),
  );
}

/// Durable, account-scoped outbox for remote mutations.
class SyncOutboxDao {
  final AppDatabase _db;

  SyncOutboxDao(this._db);

  String _id(
    String userId,
    String feature,
    String entityType,
    String entityId,
  ) => '$userId|$feature|$entityType|$entityId';

  Future<void> enqueue({
    required String userId,
    required String feature,
    required String entityType,
    required String entityId,
    required String operation,
  }) async {
    final id = _id(userId, feature, entityType, entityId);
    await _db.customStatement(
      'INSERT INTO sync_outbox (id,user_id,feature,entity_type,entity_id,operation,created_at_ms,attempts,last_error) VALUES (?,?,?,?,?,?,?,0,NULL) ON CONFLICT(id) DO UPDATE SET operation=excluded.operation,created_at_ms=MAX(excluded.created_at_ms,sync_outbox.created_at_ms+1),attempts=0,last_error=NULL',
      [
        id,
        userId,
        feature,
        entityType,
        entityId,
        operation,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  Future<List<SyncOutboxEntry>> pendingForAccount(
    String userId, {
    String? feature,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT id,user_id,feature,entity_type,entity_id,operation,created_at_ms,attempts FROM sync_outbox WHERE user_id=?${feature == null ? '' : ' AND feature=?'} ORDER BY created_at_ms,id',
          variables: [
            Variable.withString(userId),
            if (feature != null) Variable.withString(feature),
          ],
        )
        .get();
    return rows.map(SyncOutboxEntry.fromRow).toList();
  }

  Future<bool> hasPending({
    required String userId,
    required String feature,
    required String entityType,
    required String entityId,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT 1 AS found FROM sync_outbox WHERE id=? LIMIT 1',
          variables: [
            Variable.withString(_id(userId, feature, entityType, entityId)),
          ],
        )
        .get();
    return rows.isNotEmpty;
  }

  Future<void> complete(String id, int expectedCreatedAtMs) =>
      _db.customStatement(
        'DELETE FROM sync_outbox WHERE id=? AND created_at_ms=?',
        [id, expectedCreatedAtMs],
      );

  Future<void> recordFailure(
    String id,
    int expectedCreatedAtMs,
    Object error,
  ) => _db.customStatement(
    'UPDATE sync_outbox SET attempts=attempts+1,last_error=? WHERE id=? AND created_at_ms=?',
    [error.toString(), id, expectedCreatedAtMs],
  );

  Future<void> removeAll({
    required String userId,
    required String feature,
    required String entityType,
  }) => _db.customStatement(
    'DELETE FROM sync_outbox WHERE user_id=? AND feature=? AND entity_type=?',
    [userId, feature, entityType],
  );
}
