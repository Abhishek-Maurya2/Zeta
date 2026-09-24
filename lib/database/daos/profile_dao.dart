import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data Access Object for user profile persistence in SQLite.
class ProfileDao {
  final AppDatabase _db;

  ProfileDao(this._db);

  /// Returns the profile belonging to [id].
  Future<ProfilesTableData?> getProfile(String id) async {
    return (_db.select(
      _db.profilesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Upserts profile details (displayName, email, avatarImage) into SQLite.
  Future<void> upsertProfile({
    required String id,
    required String displayName,
    required String email,
    String? avatarImage,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
  }) async {
    await _db
        .into(_db.profilesTable)
        .insertOnConflictUpdate(
          ProfilesTableCompanion(
            id: Value(id),
            displayName: Value(displayName),
            email: Value(email),
            avatarImage: Value(avatarImage),
            updatedAtMs: Value(
              updatedAt?.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
            lastSyncedAtMs: Value(lastSyncedAt?.millisecondsSinceEpoch),
          ),
        );
  }

  Future<bool> markSynced({
    required String id,
    required DateTime expectedUpdatedAt,
    required DateTime syncedAt,
    required String? avatarImage,
  }) async {
    final changed =
        await (_db.update(_db.profilesTable)..where(
              (p) =>
                  p.id.equals(id) &
                  p.updatedAtMs.equals(
                    expectedUpdatedAt.millisecondsSinceEpoch,
                  ),
            ))
            .write(
              ProfilesTableCompanion(
                avatarImage: Value(avatarImage),
                lastSyncedAtMs: Value(syncedAt.millisecondsSinceEpoch),
              ),
            );
    return changed > 0;
  }

  Future<void> deleteProfile(String id) async {
    await (_db.delete(_db.profilesTable)..where((t) => t.id.equals(id))).go();
  }
}
