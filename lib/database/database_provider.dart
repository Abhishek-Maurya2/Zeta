import 'app_database.dart';
import 'daos/task_dao.dart';
import 'daos/session_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/revision_dao.dart';
import 'daos/sync_outbox_dao.dart';
import 'account_scope.dart';

import 'package:drift/drift.dart';

/// Global singleton accessor for the drift SQLite database and its DAOs.
///
/// Usage:
/// ```dart
/// await DatabaseProvider.instance.taskDao.getActiveTasks();
/// ```
class DatabaseProvider {
  DatabaseProvider._();
  static final DatabaseProvider _instance = DatabaseProvider._();
  static DatabaseProvider get instance => _instance;

  AppDatabase? _db;
  TaskDao? _taskDao;
  SessionDao? _sessionDao;
  ProfileDao? _profileDao;
  RevisionDao? _revisionDao;
  SyncOutboxDao? _syncOutboxDao;

  bool _initialized = false;

  /// Must be called once before any DAO is accessed (call from main.dart).
  void init([AppDatabase? customDb]) {
    if (_initialized && customDb == null) return;
    _db = customDb ?? AppDatabase();
    _taskDao = TaskDao(_db!);
    _sessionDao = SessionDao(_db!);
    _profileDao = ProfileDao(_db!);
    _revisionDao = RevisionDao(_db!);
    _syncOutboxDao = SyncOutboxDao(_db!);
    _initialized = true;
  }

  TaskDao get taskDao {
    if (!_initialized) init();
    return _taskDao!;
  }

  SessionDao get sessionDao {
    if (!_initialized) init();
    return _sessionDao!;
  }

  ProfileDao get profileDao {
    if (!_initialized) init();
    return _profileDao!;
  }

  RevisionDao get revisionDao {
    if (!_initialized) init();
    return _revisionDao!;
  }

  SyncOutboxDao get syncOutboxDao {
    if (!_initialized) init();
    return _syncOutboxDao!;
  }

  AppDatabase get db {
    if (!_initialized) init();
    return _db!;
  }

  /// Assigns rows imported from the former shared workspace to the first
  /// account that signs in on this installation.
  Future<void> claimLegacyRows(String userId) async {
    final database = db;
    await database.transaction(() async {
      const legacyOwner = Value('singleton');
      await (database.update(database.tasksTable)..where(
            (t) => t.userId.isNull() | t.userId.equals(legacyOwner.value),
          ))
          .write(TasksTableCompanion(userId: Value(userId)));
      await (database.update(database.pomodoroSessionsTable)..where(
            (t) => t.userId.isNull() | t.userId.equals(legacyOwner.value),
          ))
          .write(PomodoroSessionsTableCompanion(userId: Value(userId)));
      await (database.update(database.revisionSubjectsTable)..where(
            (t) => t.userId.isNull() | t.userId.equals(legacyOwner.value),
          ))
          .write(RevisionSubjectsTableCompanion(userId: Value(userId)));
      await (database.update(database.revisionTopicsTable)..where(
            (t) => t.userId.isNull() | t.userId.equals(legacyOwner.value),
          ))
          .write(RevisionTopicsTableCompanion(userId: Value(userId)));

      final legacyProfile = await profileDao.getProfile('singleton');
      if (legacyProfile != null) {
        final accountProfile = await profileDao.getProfile(userId);
        await profileDao.upsertProfile(
          id: userId,
          displayName: accountProfile?.displayName.isNotEmpty == true
              ? accountProfile!.displayName
              : legacyProfile.displayName,
          email: accountProfile?.email.isNotEmpty == true
              ? accountProfile!.email
              : legacyProfile.email,
          avatarImage: accountProfile?.avatarImage ?? legacyProfile.avatarImage,
        );
        await profileDao.deleteProfile('singleton');
      }
    });
    AccountScope.userId = userId;
  }

  void clearAccountScope() {
    AccountScope.userId = null;
  }

  /// Closes the database connection. Call only on app shutdown.
  Future<void> close() async {
    if (_initialized) {
      await _db?.close();
      _initialized = false;
    }
  }
}
