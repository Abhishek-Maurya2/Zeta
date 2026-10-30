import 'package:drift/drift.dart';

import '../../pages/space/models/mindmap.dart';
import '../app_database.dart';
import '../account_scope.dart';
import 'sync_outbox_dao.dart';

/// Data Access Object for the [MindmapsTable].
///
/// All reads and writes for Space mindmaps go through here, keeping the provider
/// and repository storage-agnostic and enabling reactive streams and offline outbox queuing.
class MindmapDao {
  final AppDatabase _db;

  MindmapDao(this._db);

  Expression<bool> _owner(GeneratedColumn<String> userId) =>
      AccountScope.userId == null
          ? userId.isNull()
          : userId.equals(AccountScope.userId!);

  // ─── Reads ─────────────────────────────────────────────────────────────────

  /// Returns all active mindmaps (not in bin/deleted), ordered by updatedAt descending.
  Future<List<MindMap>> getActiveMindMaps() async {
    final rows = await (_db.select(_db.mindmapsTable)
          ..where((t) => t.deletedAtMs.isNull() & _owner(t.userId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAtMs)]))
        .get();
    return rows.map(AppDatabase.rowToMindMap).toList();
  }

  /// Returns all soft-deleted mindmaps (in bin).
  Future<List<MindMap>> getBinMindMaps() async {
    final rows = await (_db.select(_db.mindmapsTable)
          ..where((t) => t.deletedAtMs.isNotNull() & _owner(t.userId))
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAtMs)]))
        .get();
    return rows.map(AppDatabase.rowToMindMap).toList();
  }

  /// Reactive stream of active mindmaps.
  Stream<List<MindMap>> watchActiveMindMaps() {
    return (_db.select(_db.mindmapsTable)
          ..where((t) => t.deletedAtMs.isNull() & _owner(t.userId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAtMs)]))
        .watch()
        .map((rows) => rows.map(AppDatabase.rowToMindMap).toList());
  }

  /// Fetches a single mindmap by ID.
  Future<MindMap?> getMindMap(String id) async {
    final row = await (_db.select(_db.mindmapsTable)
          ..where((t) => t.id.equals(id) & _owner(t.userId)))
        .getSingleOrNull();
    return row == null ? null : AppDatabase.rowToMindMap(row);
  }

  /// Count of active mindmaps for current account.
  Future<int> countActiveMindMaps() async {
    final countExp = _db.mindmapsTable.id.count();
    final query = _db.selectOnly(_db.mindmapsTable)
      ..addColumns([countExp])
      ..where(_db.mindmapsTable.deletedAtMs.isNull() & _owner(_db.mindmapsTable.userId));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Returns mindmaps modified offline that have not yet been synced to Supabase.
  Future<List<MindMap>> getUnsyncedMindMaps() async {
    final rows = await (_db.select(_db.mindmapsTable)
          ..where(
            (t) =>
                (t.lastSyncedAtMs.isNull() |
                    t.updatedAtMs.isBiggerThan(t.lastSyncedAtMs)) &
                _owner(t.userId),
          ))
        .get();
    return rows.map(AppDatabase.rowToMindMap).toList();
  }

  /// Marks a mindmap row as synced at [syncedAt].
  Future<bool> markMindMapSynced(
    String id,
    DateTime syncedAt, {
    required int expectedUpdatedAtMs,
  }) async {
    final changed = await (_db.update(_db.mindmapsTable)
          ..where(
            (t) =>
                t.id.equals(id) &
                t.updatedAtMs.equals(expectedUpdatedAtMs) &
                _owner(t.userId),
          ))
        .write(
          MindmapsTableCompanion(
            lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
          ),
        );
    return changed > 0;
  }

  // ─── Writes ────────────────────────────────────────────────────────────────

  /// Upserts a single mindmap.
  Future<void> upsertMindMap(MindMap map) async {
    await _db
        .into(_db.mindmapsTable)
        .insertOnConflictUpdate(AppDatabase.mindMapToCompanion(map));
  }

  /// Upserts a mindmap and records the mutation in [SyncOutboxDao].
  Future<void> upsertMindMapAndQueue(MindMap map) async {
    await _db.transaction(() async {
      await upsertMindMap(map);
      await _queueMindMap(map.id, 'upsert');
    });
  }

  /// Batch-upserts multiple mindmaps.
  Future<void> upsertAll(List<MindMap> maps) async {
    await _db.batch((batch) {
      for (final m in maps) {
        batch.insert(
          _db.mindmapsTable,
          AppDatabase.mindMapToCompanion(m),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Batch-upserts and enqueues all mindmaps.
  Future<void> upsertAllAndQueue(List<MindMap> maps) async {
    await _db.transaction(() async {
      await upsertAll(maps);
      for (final m in maps) {
        await _queueMindMap(m.id, 'upsert');
      }
    });
  }

  /// Hard-deletes a mindmap from local SQLite and queues the cloud deletion.
  Future<void> deleteMindMapAndQueue(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.mindmapsTable)
            ..where((t) => t.id.equals(id) & _owner(t.userId)))
          .go();
      await _queueMindMap(id, 'delete');
    });
  }

  /// Hard-deletes without queuing (used for cloud deletion application).
  Future<void> deleteMindMap(String id) async {
    await (_db.delete(_db.mindmapsTable)
          ..where((t) => t.id.equals(id) & _owner(t.userId)))
        .go();
  }

  Future<void> _queueMindMap(String id, String operation) async {
    final userId = AccountScope.userId;
    if (userId == null) return;
    await SyncOutboxDao(_db).enqueue(
      userId: userId,
      feature: 'space',
      entityType: 'mindmap',
      entityId: id,
      operation: operation,
    );
  }
}

