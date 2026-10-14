import 'app_database.dart';
import 'daos/task_dao.dart';
import 'daos/session_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/revision_dao.dart';
import 'daos/sync_outbox_dao.dart';
import 'account_scope.dart';

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

  void setAccountScope(String userId) {
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
