import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pomodoro.dart';
import '../database/database_provider.dart';
import 'supabase_service.dart';
import 'network_service.dart';

/// Service responsible for bi-directional synchronization between local Pomodoro
/// sessions and Supabase `public.pomodoro_sessions` table, including real-time change subscriptions.
class PomodoroSyncService {
  static final PomodoroSyncService _instance = PomodoroSyncService._internal();
  factory PomodoroSyncService() => _instance;
  PomodoroSyncService._internal() {
    _networkSubscription = NetworkService().onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        final reconnect = onNetworkReconnect;
        unawaited(reconnect != null ? reconnect() : processPendingQueue());
      }
    });
  }

  final SupabaseService _supabaseService = SupabaseService();
  final _outbox = DatabaseProvider.instance.syncOutboxDao;
  final Map<String, Timer> _debounceTimers = {};
  RealtimeChannel? _sessionsRealtimeChannel;
  StreamSubscription<bool>? _networkSubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  void Function(PomodoroSessionLog session, String eventType)?
  onRemoteSessionChange;
  Future<void> Function(PomodoroSessionLog session, DateTime syncedAt)?
  onSessionSynced;
  Future<PomodoroSessionLog?> Function(String sessionId)? getSessionForSync;
  Future<void> Function()? onNetworkReconnect;

  final List<PomodoroSessionLog> _pendingQueue = [];

  void endAccountSession() {
    _pendingQueue.clear();
    onRemoteSessionChange = null;
    onSessionSynced = null;
    getSessionForSync = null;
    onNetworkReconnect = null;
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _sessionsRealtimeChannel?.unsubscribe();
    _sessionsRealtimeChannel = null;
    _isSyncing = false;
  }

  Future<void> _ensureInitialized() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (isTest) return;
    if (!_supabaseService.isInitialized) {
      try {
        await _supabaseService.init();
      } catch (e) {
        debugPrint(
          'PomodoroSyncService: Failed to initialize SupabaseService: $e',
        );
      }
    }
  }

  /// Processes in-memory retries and any durable cloud deletion intent.
  /// The repository loads durable unsynced sessions from SQLite.
  Future<void> processPendingQueue() async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      return;
    }

    final pending = await _outbox.pendingForAccount(
      _supabaseService.effectiveUserId,
      feature: 'pomodoro',
    );
    final pendingClear = pending.where(
      (entry) => entry.operation == 'clear' && entry.entityType == 'session',
    );
    if (pendingClear.isNotEmpty) {
      try {
        final userId = _supabaseService.effectiveUserId;
        await _supabaseService.client
            .from('pomodoro_sessions')
            .delete()
            .eq('user_id', userId)
            .timeout(const Duration(seconds: 15));
        for (final entry in pendingClear) {
          await _outbox.complete(entry.id, entry.createdAtMs);
        }
        // Clearing is a barrier: never replay a stale local session in the
        // same queue pass.
        return;
      } catch (e) {
        _lastError = e.toString();
        return;
      }
    }

    for (final entry in pending.where((item) => item.operation == 'delete')) {
      try {
        await _supabaseService.client
            .from('pomodoro_sessions')
            .delete()
            .eq('id', entry.entityId)
            .timeout(const Duration(seconds: 15));
        await _outbox.complete(entry.id, entry.createdAtMs);
      } catch (error) {
        await _outbox.recordFailure(entry.id, entry.createdAtMs, error);
      }
    }

    for (final entry in pending.where((item) => item.operation == 'upsert')) {
      try {
        final session = await getSessionForSync?.call(entry.entityId);
        if (session == null) {
          await _outbox.complete(entry.id, entry.createdAtMs);
        } else if (await pushSession(session)) {
          await _outbox.complete(entry.id, entry.createdAtMs);
        } else {
          await _outbox.recordFailure(
            entry.id,
            entry.createdAtMs,
            _lastError ?? 'Pomodoro session push failed.',
          );
        }
      } catch (error) {
        await _outbox.recordFailure(entry.id, entry.createdAtMs, error);
      }
    }

    if (_pendingQueue.isEmpty) return;
    final toProcess = List<PomodoroSessionLog>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final session in toProcess) {
      final success = await pushSession(session);
      if (!success && !_pendingQueue.any((s) => s.id == session.id)) {
        _pendingQueue.add(session);
      }
    }
  }

  /// Pull pomodoro sessions from Supabase `public.pomodoro_sessions` table.
  ///
  /// Pass [since] to fetch only sessions completed after that timestamp
  /// (incremental sync).  On first launch, [since] is null and we fetch the
  /// most recent [limit] sessions.
  Future<List<PomodoroSessionLog>> pullSessions({
    int limit = 200,
    DateTime? since,
  }) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      _lastError = 'Supabase is unavailable or the device is offline.';
      return [];
    }
    final hasPendingClear = await _hasPendingClear();
    if (hasPendingClear) {
      await processPendingQueue();
      if (await _hasPendingClear()) {
        _lastError = 'Pending Pomodoro history clear has not synced yet.';
        return [];
      }
    }

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      final List<PomodoroSessionLog> sessions = [];
      final pageSize = limit <= 0 ? 1000 : (limit < 1000 ? limit : 1000);
      var offset = 0;
      while (true) {
        var query = _supabaseService.client
            .from('pomodoro_sessions')
            .select()
            .eq('user_id', userId);
        if (since != null) {
          query = query.gte('completed_at', since.toUtc().toIso8601String());
        }
        final response = await query
            .order('completed_at', ascending: false)
            .range(offset, offset + pageSize - 1)
            .timeout(const Duration(seconds: 15));
        final rows = response as List<dynamic>;
        for (final row in rows) {
          sessions.add(
            PomodoroSessionLog.fromSupabaseRow(row as Map<String, dynamic>),
          );
        }
        if (rows.length < pageSize || (limit > 0 && sessions.length >= limit)) {
          break;
        }
        offset += pageSize;
      }

      _lastSyncedAt = DateTime.now();
      NetworkService().markOnline();
      debugPrint(
        'PomodoroSyncService: Pulled ${sessions.length} sessions '
        '(since=${since?.toIso8601String() ?? "all"}).',
      );
      return sessions;
    } catch (e) {
      _lastError = e.toString();
      NetworkService().markOffline();
      debugPrint('PomodoroSyncService: pullSessions failed - $e');
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Push a single session to Supabase with retries and offline fallback.
  Future<bool> pushSession(PomodoroSessionLog session) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      if (!_pendingQueue.any((s) => s.id == session.id)) {
        _pendingQueue.add(session);
      }
      return false;
    }

    final userId = _supabaseService.effectiveUserId;
    final row = session.toSupabaseRow(userId: userId);

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _supabaseService.client
            .from('pomodoro_sessions')
            .upsert(row)
            .timeout(const Duration(seconds: 15));
        debugPrint(
          'PomodoroSyncService: Upserted session ${session.id} (${session.mode.label}, ${session.minutes}m)',
        );
        _lastSyncedAt = DateTime.now();
        _pendingQueue.removeWhere((s) => s.id == session.id);
        await onSessionSynced?.call(session, _lastSyncedAt!);
        NetworkService().markOnline();
        return true;
      } catch (e) {
        retryCount++;
        debugPrint(
          'PomodoroSyncService: Push attempt $retryCount failed for ${session.id}: $e',
        );
        if (retryCount >= maxRetries) {
          _lastError = e.toString();
          NetworkService().markOffline();
          if (!_pendingQueue.any((s) => s.id == session.id)) {
            _pendingQueue.add(session);
          }
          return false;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    return false;
  }

  /// Batch push a list of sessions (e.g. for initial local-to-cloud migration).
  Future<int> batchPushSessions(List<PomodoroSessionLog> sessions) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !NetworkService().isOnline ||
        sessions.isEmpty) {
      return 0;
    }

    final userId = _supabaseService.effectiveUserId;
    final rows = sessions.map((s) => s.toSupabaseRow(userId: userId)).toList();

    try {
      await _supabaseService.client
          .from('pomodoro_sessions')
          .upsert(rows)
          .timeout(const Duration(seconds: 25));
      debugPrint(
        'PomodoroSyncService: Batch upserted ${rows.length} sessions.',
      );
      final syncedAt = DateTime.now();
      for (final session in sessions) {
        await onSessionSynced?.call(session, syncedAt);
      }
      NetworkService().markOnline();
      return rows.length;
    } catch (e) {
      debugPrint('PomodoroSyncService: batchPushSessions failed - $e');
      _lastError = e.toString();
      NetworkService().markOffline();
      return 0;
    }
  }

  /// Delete a single session record from Supabase.
  Future<bool> deleteSession(String sessionId) async {
    await enqueueSessionDeletion(sessionId);
    await processPendingQueue();
    final userId = _supabaseService.effectiveUserId;
    final stillPending = await _outbox.hasPending(
      userId: userId,
      feature: 'pomodoro',
      entityType: 'session',
      entityId: sessionId,
    );
    return !stillPending;
  }

  Future<void> enqueueSessionDeletion(String sessionId) async {
    final userId = _supabaseService.effectiveUserId;
    await _outbox.enqueue(
      userId: userId,
      feature: 'pomodoro',
      entityType: 'session',
      entityId: sessionId,
      operation: 'delete',
    );
  }

  /// Clears all pomodoro sessions for current user in Supabase.
  Future<bool> clearSessions() async {
    await enqueueClearSessions();
    await processPendingQueue();
    return !await _hasPendingClear();
  }

  Future<void> enqueueClearSessions() async {
    await _outbox.enqueue(
      userId: _supabaseService.effectiveUserId,
      feature: 'pomodoro',
      entityType: 'session',
      entityId: '_all',
      operation: 'clear',
    );
  }

  Future<bool> _hasPendingClear() async =>
      (await _outbox.pendingForAccount(
        _supabaseService.effectiveUserId,
        feature: 'pomodoro',
      )).any(
        (entry) => entry.operation == 'clear' && entry.entityType == 'session',
      );

  /// Subscribes to Realtime PostgreSQL changes on `public.pomodoro_sessions`.
  ///
  /// Applies a server-side `user_id` row filter so only changes belonging to
  /// the current user are delivered.
  void subscribeToRealtime({
    void Function(PomodoroSessionLog session, String eventType)?
    onSessionChange,
  }) {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (isTest || !_supabaseService.isInitialized) return;
    if (onSessionChange != null) onRemoteSessionChange = onSessionChange;

    final userId = _supabaseService.effectiveUserId;

    try {
      _sessionsRealtimeChannel?.unsubscribe();
    } catch (_) {}
    _sessionsRealtimeChannel = _supabaseService.client
        .channel('public:pomodoro_sessions:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pomodoro_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final eventType = payload.eventType.name;
              if (payload.newRecord.isNotEmpty) {
                final session = PomodoroSessionLog.fromSupabaseRow(
                  payload.newRecord,
                );
                onRemoteSessionChange?.call(session, eventType);
              } else if (payload.oldRecord.isNotEmpty) {
                final session = PomodoroSessionLog.fromSupabaseRow(
                  payload.oldRecord,
                );
                onRemoteSessionChange?.call(session, eventType);
              }
            } catch (e) {
              debugPrint(
                'PomodoroSyncService: Error handling realtime session payload: $e',
              );
            }
          },
        )
        .subscribe();

    debugPrint(
      'PomodoroSyncService: Subscribed to Realtime channel public:pomodoro_sessions (user=$userId)',
    );
  }

  /// Clean up resources on disposal.
  void dispose() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest && _supabaseService.isInitialized) {
      try {
        _sessionsRealtimeChannel?.unsubscribe();
      } catch (_) {}
    }
    _sessionsRealtimeChannel = null;
  }
}
