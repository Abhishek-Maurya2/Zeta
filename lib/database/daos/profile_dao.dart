import 'package:drift/drift.dart';
import '../app_database.dart';

/// Data Access Object for user profile persistence in SQLite.
class ProfileDao {
  final AppDatabase _db;

  ProfileDao(this._db);

  /// Returns the profile for [id] (defaults to 'singleton').
  Future<ProfilesTableData?> getProfile([String id = 'singleton']) async {
    return (_db.select(_db.profilesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upserts profile details (displayName, email, avatarImage) into SQLite.
  Future<void> upsertProfile({
    String id = 'singleton',
    required String displayName,
    required String email,
    String? avatarImage,
    DateTime? updatedAt,
  }) async {
    await _db.into(_db.profilesTable).insertOnConflictUpdate(
          ProfilesTableCompanion(
            id: Value(id),
            displayName: Value(displayName),
            email: Value(email),
            avatarImage: Value(avatarImage),
            updatedAtMs: Value(
              updatedAt?.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
  }
}
