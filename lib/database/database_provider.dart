import 'app_database.dart';
import 'daos/task_dao.dart';
import 'daos/session_dao.dart';

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

  bool _initialized = false;

  /// Must be called once before any DAO is accessed (call from main.dart).
  void init([AppDatabase? customDb]) {
    if (_initialized && customDb == null) return;
    _db = customDb ?? AppDatabase();
    _taskDao = TaskDao(_db!);
    _sessionDao = SessionDao(_db!);
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

  AppDatabase get db {
    if (!_initialized) init();
    return _db!;
  }

  /// Closes the database connection. Call only on app shutdown.
  Future<void> close() async {
    if (_initialized) {
      await _db?.close();
      _initialized = false;
    }
  }
}
