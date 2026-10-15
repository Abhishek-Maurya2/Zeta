import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/account_scope.dart';
import '../../../database/database_provider.dart';
import '../../../database/daos/session_dao.dart';
import '../../../models/pomodoro.dart';
import '../../../core/sync/sync_coordinator.dart';

/// Clean Architecture Repository for Pomodoro domain.
class PomodoroRepository {
  final SessionDao _sessionDao;
  final SyncCoordinator? _syncCoordinator;

  PomodoroRepository({
    SessionDao? sessionDao,
    SyncCoordinator? syncCoordinator,
  })  : _sessionDao = sessionDao ?? DatabaseProvider.instance.sessionDao,
        // ignore: prefer_initializing_formals
        _syncCoordinator = syncCoordinator;

  /// Watch recent sessions reactively from Drift SQLite.
  Stream<List<PomodoroSessionLog>> watchRecentSessions({int limit = 200}) {
    return _sessionDao.watchRecentSessions(limit: limit);
  }

  /// Get recent sessions.
  Future<List<PomodoroSessionLog>> getRecentSessions({int limit = 200}) {
    return _sessionDao.getSessions(limit: limit);
  }

  /// Save completed session log locally and enqueue outbox sync.
  Future<void> logSession(PomodoroSessionLog session) async {
    await _sessionDao.upsertSession(session);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'pomodoro',
        entityType: 'session',
        entityId: session.id,
        operation: 'upsert',
      );
      _syncCoordinator?.triggerSync();
    }
  }

  /// Delete a session log.
  Future<void> deleteSession(String sessionId) async {
    await _sessionDao.deleteSession(sessionId);
    final userId = AccountScope.userId;
    if (userId != null) {
      await DatabaseProvider.instance.syncOutboxDao.enqueue(
        userId: userId,
        feature: 'pomodoro',
        entityType: 'session',
        entityId: sessionId,
        operation: 'delete',
      );
      _syncCoordinator?.triggerSync();
    }
  }
}

final pomodoroRepositoryProvider = Provider<PomodoroRepository>((ref) {
  final syncCoordinator = ref.watch(syncCoordinatorProvider.notifier);
  return PomodoroRepository(syncCoordinator: syncCoordinator);
});
