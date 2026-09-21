import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/pomodoro.dart';
import 'app_database.dart';
import 'daos/task_dao.dart';
import 'daos/session_dao.dart';

/// One-time migration that reads all data from SharedPreferences JSON blobs
/// and inserts it into the drift SQLite database.
///
/// This runs exactly once on first launch after the SQLite migration is
/// deployed.  After a successful migration the flag [_migrationKey] is set
/// so subsequent launches skip straight to SQLite.
class MigrationService {
  static const String _migrationKey = 'zeta_db_migration_v1_done';
  static const String _tasksKey = 'zeta_tasks_v1';
  static const String _binTasksKey = 'zeta_bin_tasks_v1';
  static const String _sessionLogKey = 'zeta_pomodoro_session_log_v1';

  final TaskDao _taskDao;
  final SessionDao _sessionDao;

  MigrationService(AppDatabase db)
      : _taskDao = TaskDao(db),
        _sessionDao = SessionDao(db);

  /// Run migration if it hasn't already been done.
  /// Safe to call on every cold start — is a no-op after the first run.
  Future<void> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationKey) == true) return;

    debugPrint('MigrationService: Running one-time SharedPreferences → SQLite migration…');

    try {
      // ── Tasks ──────────────────────────────────────────────────────────────
      final tasksRaw = prefs.getString(_tasksKey);
      if (tasksRaw != null) {
        final list = jsonDecode(tasksRaw) as List<dynamic>;
        final tasks = list
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .where((t) => t.title.trim().isNotEmpty)
            .toList();
        await _taskDao.upsertAll(tasks);
        debugPrint('MigrationService: Migrated ${tasks.length} active tasks.');
      }

      // ── Bin tasks ──────────────────────────────────────────────────────────
      final binRaw = prefs.getString(_binTasksKey);
      if (binRaw != null) {
        final list = jsonDecode(binRaw) as List<dynamic>;
        final binTasks = list
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .where((t) => t.title.trim().isNotEmpty)
            .toList();
        await _taskDao.upsertAll(binTasks);
        debugPrint('MigrationService: Migrated ${binTasks.length} bin tasks.');
      }

      // ── Pomodoro sessions ──────────────────────────────────────────────────
      final sessionRaw = prefs.getString(_sessionLogKey);
      if (sessionRaw != null) {
        final list = jsonDecode(sessionRaw) as List<dynamic>;
        final sessions = list
            .map((e) => PomodoroSessionLog.fromJson(e as Map<String, dynamic>))
            .where((s) => !s.id.startsWith('sample-'))
            .toList();
        await _sessionDao.upsertAll(sessions);
        debugPrint('MigrationService: Migrated ${sessions.length} pomodoro sessions.');
      }

      // Mark migration as done
      await prefs.setBool(_migrationKey, true);
      debugPrint('MigrationService: Migration complete.');

      // Note: We intentionally keep the SharedPreferences keys intact for now
      // as a safety backup.  They can be cleaned up in a future version once
      // the SQLite store is proven stable.
    } catch (e, st) {
      debugPrint('MigrationService: Migration failed — will retry next launch. Error: $e\n$st');
      // Do NOT set the flag on failure so we retry next time.
    }
  }
}
