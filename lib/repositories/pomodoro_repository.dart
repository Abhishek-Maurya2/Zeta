import 'dart:async';
import '../models/pomodoro.dart';
import '../database/daos/session_dao.dart';
import '../database/database_provider.dart';
import '../services/pomodoro_sync_service.dart';
import '../utils/app_logger.dart';

/// Repository coordinating local SQLite Pomodoro session logs with cloud sync.
class PomodoroRepository {
  final SessionDao _sessionDao;
  final PomodoroSyncService _syncService;

  PomodoroRepository({
    SessionDao? sessionDao,
    PomodoroSyncService? syncService,
  })  : _sessionDao = sessionDao ?? DatabaseProvider.instance.sessionDao,
        _syncService = syncService ?? PomodoroSyncService();

  SessionDao get sessionDao => _sessionDao;
  PomodoroSyncService get syncService => _syncService;

  bool get isSyncing => _syncService.isSyncing;
  DateTime? get lastSyncedAt => _syncService.lastSyncedAt;
  String? get syncError => _syncService.lastError;

  Future<List<PomodoroSessionLog>> getRecentSessions({int limit = 1000}) {
    return _sessionDao.getSessions(limit: limit);
  }

  Future<void> saveSession(PomodoroSessionLog session, {bool pushToCloud = true}) async {
    await _sessionDao.upsertSession(session);
    if (pushToCloud) {
      unawaited(_syncService.pushSession(session));
    }
  }

  Future<void> saveSessionsBatch(List<PomodoroSessionLog> sessions, {bool pushToCloud = true}) async {
    await _sessionDao.upsertAll(sessions);
    if (pushToCloud) {
      for (final s in sessions) {
        unawaited(_syncService.pushSession(s));
      }
    }
  }

  Future<void> syncWithCloud({bool force = false}) async {
    try {
      await _syncService.processPendingQueue();
      final remote = await _syncService.pullSessions();
      if (remote.isNotEmpty) {
        await _sessionDao.upsertAll(remote);
      }
    } catch (e, st) {
      AppLogger.error('PomodoroRepository sync failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
