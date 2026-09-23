import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/pomodoro.dart';
import '../models/revision.dart';
import 'app_database.dart';
import 'daos/task_dao.dart';
import 'daos/session_dao.dart';
import 'daos/revision_dao.dart';

/// One-time migration that reads all data from SharedPreferences JSON blobs
/// and inserts it into the drift SQLite database.
///
/// This runs exactly once on first launch after the SQLite migration is
/// deployed.  After a successful migration the flag [_migrationKey] is set
/// so subsequent launches skip straight to SQLite.
class MigrationService {
  static const String _migrationKey = 'zeta_db_migration_v1_done';
  static const String _revisionMigrationKey = 'zeta_revision_migration_v1_done';
  static const String _tasksKey = 'zeta_tasks_v1';
  static const String _binTasksKey = 'zeta_bin_tasks_v1';
  static const String _sessionLogKey = 'zeta_pomodoro_session_log_v1';
  static const String _subjectsKey = 'zeta_revision_subjects_v2';
  static const String _topicsKey = 'zeta_revision_topics_v2';

  final TaskDao _taskDao;
  final SessionDao _sessionDao;
  final RevisionDao _revisionDao;

  MigrationService(AppDatabase db)
      : _taskDao = TaskDao(db),
        _sessionDao = SessionDao(db),
        _revisionDao = RevisionDao(db);

  /// Run migration if it hasn't already been done.
  /// Safe to call on every cold start — is a no-op after the first run.
  Future<void> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksMigrated = prefs.getBool(_migrationKey) == true;
    final revisionMigrated = prefs.getBool(_revisionMigrationKey) == true;

    if (tasksMigrated && revisionMigrated) return;

    debugPrint('MigrationService: Checking SharedPreferences → SQLite migrations…');

    try {
      if (!tasksMigrated) {
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

        await prefs.setBool(_migrationKey, true);
        debugPrint('MigrationService: Task & Session migration complete.');
      }

      // ── Revision subjects & topics ─────────────────────────────────────────
      if (!revisionMigrated) {
        final subjectsRaw = prefs.getString(_subjectsKey);
        if (subjectsRaw != null && subjectsRaw.isNotEmpty) {
          final list = jsonDecode(subjectsRaw) as List<dynamic>;
          final subjects = list
              .map((e) => Subject.fromJson(e as Map<String, dynamic>))
              .where((s) => s.name.trim().isNotEmpty)
              .toList();
          await _revisionDao.upsertAllSubjects(subjects);
          debugPrint(
              'MigrationService: Migrated ${subjects.length} revision subjects.');
        }

        final topicsRaw = prefs.getString(_topicsKey);
        if (topicsRaw != null && topicsRaw.isNotEmpty) {
          final list = jsonDecode(topicsRaw) as List<dynamic>;
          final topics = list
              .map((e) => ChapterTopic.fromJson(e as Map<String, dynamic>))
              .where((t) => t.title.trim().isNotEmpty)
              .toList();
          await _revisionDao.upsertAllTopics(topics);
          debugPrint(
              'MigrationService: Migrated ${topics.length} revision topics.');
        }

        await prefs.setBool(_revisionMigrationKey, true);
        debugPrint('MigrationService: Revision migration complete.');
      }

      // Note: We intentionally keep the SharedPreferences keys intact for now
      // as a safety backup.  They can be cleaned up in a future version once
      // the SQLite store is proven stable.
    } catch (e, st) {
      debugPrint('MigrationService: Migration failed — will retry next launch. Error: $e\n$st');
      // Do NOT set the flag on failure so we retry next time.
    }
  }
}
