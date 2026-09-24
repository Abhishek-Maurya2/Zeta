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
        _syncService = syncService ?? PomodoroSyncService() {
    _syncService.onSessionSynced = _markSessionSynced;
    _syncService.onNetworkReconnect = processPendingSync;
  }

  Future<void> _markSessionSynced(
    PomodoroSessionLog session,
    DateTime syncedAt,
  ) async {
    await _sessionDao.markSessionSynced(session.id, syncedAt);
  }

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

  Future<void> deleteSession(String sessionId, {bool pushToCloud = true}) async {
    await _sessionDao.deleteSession(sessionId);
    if (pushToCloud) unawaited(_syncService.deleteSession(sessionId));
  }

  Future<void> clearSessions({bool clearCloud = true}) async {
    if (clearCloud) {
      // Persist the cloud deletion intent before clearing the local source of
      // truth so an offline clear cannot be undone by the next pull.
      await _syncService.enqueueClearSessions();
    }
    await _sessionDao.clearAll();
  }

  void subscribeToRealtime({
    required void Function(PomodoroSessionLog session, String eventType) onSessionChange,
  }) {
    _syncService.subscribeToRealtime(onSessionChange: onSessionChange);
  }

  Future<void> syncWithCloud({bool force = false}) async {
    try {
      await processPendingSync();
      // Completion timestamps are not a safe change cursor: another device can
      // add a backdated session. Pull a complete paginated snapshot instead.
      final remote = await _syncService.pullSessions(limit: 0);
      if (_syncService.lastError != null) return;
      final remoteIds = remote.map((session) => session.id).toSet();
      final local = await _sessionDao.getAllSessions();
      for (final session in local) {
        if (session.lastSyncedAt != null && !remoteIds.contains(session.id)) {
          await _sessionDao.deleteSession(session.id);
        }
      }
      if (remote.isNotEmpty) {
        await _sessionDao.upsertAll(remote);
      }
    } catch (e, st) {
      AppLogger.error('PomodoroRepository sync failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> processPendingSync() async {
    await _syncService.processPendingQueue();
    final unsynced = await _sessionDao.getUnsyncedSessions();
    if (unsynced.isNotEmpty) {
      await _syncService.batchPushSessions(unsynced);
    }
  }

  void dispose() {
    _syncService.dispose();
  }
}
