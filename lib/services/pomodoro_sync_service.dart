import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pomodoro.dart';
import 'supabase_service.dart';

/// Service responsible for bi-directional synchronization between local Pomodoro
/// sessions and Supabase `public.pomodoro_sessions` table, including real-time change subscriptions.
class PomodoroSyncService {
  static final PomodoroSyncService _instance = PomodoroSyncService._internal();
  factory PomodoroSyncService() => _instance;
  PomodoroSyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final Map<String, Timer> _debounceTimers = {};
  RealtimeChannel? _sessionsRealtimeChannel;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  void Function(PomodoroSessionLog session, String eventType)? onRemoteSessionChange;

  final List<PomodoroSessionLog> _pendingQueue = [];

  Future<void> _ensureInitialized() async {
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return;
    if (!_supabaseService.isInitialized) {
      try {
        await _supabaseService.init();
      } catch (e) {
        debugPrint('PomodoroSyncService: Failed to initialize SupabaseService: $e');
      }
    }
  }

  /// Processes any queued offline sessions that previously failed to push.
  Future<void> processPendingQueue() async {
    await _ensureInitialized();
    if (_pendingQueue.isEmpty || !_supabaseService.isInitialized) return;
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
  Future<List<PomodoroSessionLog>> pullSessions({int limit = 1000}) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized) return [];

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      final response = await _supabaseService.client
          .from('pomodoro_sessions')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 15));

      final List<PomodoroSessionLog> sessions = [];
      for (final row in response as List<dynamic>) {
        try {
          sessions.add(
            PomodoroSessionLog.fromSupabaseRow(row as Map<String, dynamic>),
          );
        } catch (e) {
          debugPrint('PomodoroSyncService: Error parsing session row - $e');
        }
      }

      _lastSyncedAt = DateTime.now();
      debugPrint(
        'PomodoroSyncService: Pulled ${sessions.length} sessions successfully.',
      );
      unawaited(processPendingQueue());
      return sessions;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('PomodoroSyncService: pullSessions failed - $e');
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Push a single session to Supabase with retries and offline fallback.
  Future<bool> pushSession(PomodoroSessionLog session) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized) {
      if (!_pendingQueue.any((s) => s.id == session.id)) {
        _pendingQueue.add(session);
      }
      return false;
    }

    final userId = _supabaseService.effectiveUserId;
    final row = session.toSupabaseRow(defaultUserId: userId);

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
        return true;
      } catch (e) {
        retryCount++;
        debugPrint(
          'PomodoroSyncService: Push attempt $retryCount failed for ${session.id}: $e',
        );
        if (retryCount >= maxRetries) {
          _lastError = e.toString();
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
    if (!_supabaseService.isInitialized || sessions.isEmpty) return 0;

    final userId = _supabaseService.effectiveUserId;
    final rows =
        sessions.map((s) => s.toSupabaseRow(defaultUserId: userId)).toList();

    try {
      await _supabaseService.client
          .from('pomodoro_sessions')
          .upsert(rows)
          .timeout(const Duration(seconds: 25));
      debugPrint('PomodoroSyncService: Batch upserted ${rows.length} sessions.');
      return rows.length;
    } catch (e) {
      debugPrint('PomodoroSyncService: batchPushSessions failed - $e');
      _lastError = e.toString();
      return 0;
    }
  }

  /// Delete a single session record from Supabase.
  Future<bool> deleteSession(String sessionId) async {
    if (!_supabaseService.isInitialized) return false;

    try {
      await _supabaseService.client
          .from('pomodoro_sessions')
          .delete()
          .eq('id', sessionId);
      debugPrint('PomodoroSyncService: Deleted session $sessionId');
      return true;
    } catch (e) {
      debugPrint('PomodoroSyncService: deleteSession failed for $sessionId - $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Clears all pomodoro sessions for current user in Supabase.
  Future<bool> clearSessions() async {
    if (!_supabaseService.isInitialized) return false;

    try {
      final userId = _supabaseService.effectiveUserId;
      await _supabaseService.client
          .from('pomodoro_sessions')
          .delete()
          .eq('user_id', userId);
      debugPrint('PomodoroSyncService: Cleared sessions for user $userId');
      return true;
    } catch (e) {
      debugPrint('PomodoroSyncService: clearSessions failed - $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Subscribes to Realtime PostgreSQL changes on `public.pomodoro_sessions`.
  void subscribeToRealtime({
    void Function(PomodoroSessionLog session, String eventType)? onSessionChange,
  }) {
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || !_supabaseService.isInitialized) return;
    if (onSessionChange != null) onRemoteSessionChange = onSessionChange;

    try {
      _sessionsRealtimeChannel?.unsubscribe();
    } catch (_) {}
    _sessionsRealtimeChannel = _supabaseService.client
        .channel('public:pomodoro_sessions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pomodoro_sessions',
          callback: (payload) {
            try {
              final eventType = payload.eventType.name;
              if (payload.newRecord.isNotEmpty) {
                final session =
                    PomodoroSessionLog.fromSupabaseRow(payload.newRecord);
                onRemoteSessionChange?.call(session, eventType);
              } else if (payload.oldRecord.isNotEmpty) {
                final session =
                    PomodoroSessionLog.fromSupabaseRow(payload.oldRecord);
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
      'PomodoroSyncService: Subscribed to Realtime channel public:pomodoro_sessions',
    );
  }

  /// Clean up resources on disposal.
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest && _supabaseService.isInitialized) {
      try {
        _sessionsRealtimeChannel?.unsubscribe();
      } catch (_) {}
    }
    _sessionsRealtimeChannel = null;
  }
}
