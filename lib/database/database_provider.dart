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

  late final AppDatabase _db;
  late final TaskDao taskDao;
  late final SessionDao sessionDao;

  bool _initialized = false;

  /// Must be called once before any DAO is accessed (call from main.dart).
  void init() {
    if (_initialized) return;
    _db = AppDatabase();
    taskDao = TaskDao(_db);
    sessionDao = SessionDao(_db);
    _initialized = true;
  }

  AppDatabase get db => _db;

  /// Closes the database connection. Call only on app shutdown.
  Future<void> close() async {
    if (_initialized) {
      await _db.close();
    }
  }
}
