import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/daos/sync_outbox_dao.dart';
import '../../database/database_provider.dart';
import '../../services/network_service.dart';
import '../../services/supabase_service.dart';
import '../../models/task.dart';

/// Sync state model exposed to Riverpod consumers with zero unnecessary re-renders.
@immutable
class SyncState {
  final bool isSyncing;
  final bool isOnline;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final int pendingOutboxCount;

  const SyncState({
    this.isSyncing = false,
    this.isOnline = true,
    this.lastSyncedAt,
    this.lastError,
    this.pendingOutboxCount = 0,
  });

  SyncState copyWith({
    bool? isSyncing,
    bool? isOnline,
    DateTime? lastSyncedAt,
    String? lastError,
    int? pendingOutboxCount,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
    );
  }
}

/// Unified local-first sync coordinator.
/// Drains durable SQLite outbox to Supabase with exponential backoff,
/// listens to Realtime deltas, and resolves conflicts using Last-Write-Wins (LWW).
class SyncCoordinator extends StateNotifier<SyncState> {
  final SupabaseService _supabaseService;
  final NetworkService _networkService;
  
  StreamSubscription<bool>? _networkSub;
  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;
  bool _isDraining = false;

  SyncCoordinator({
    SupabaseService? supabaseService,
    NetworkService? networkService,
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _networkService = networkService ?? NetworkService(),
        super(const SyncState()) {
    _init();
  }

  void _init() {
    state = state.copyWith(isOnline: _networkService.isOnline);
    _networkSub = _networkService.onConnectivityChanged.listen((online) {
      state = state.copyWith(isOnline: online);
      if (online) {
        triggerSync();
      }
    });

    _updatePendingCount();
    if (_networkService.isOnline) {
      triggerSync();
    }
  }

  SyncOutboxDao get _outbox => DatabaseProvider.instance.syncOutboxDao;

  Future<void> _updatePendingCount() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      state = state.copyWith(pendingOutboxCount: 0);
      return;
    }
    final list = await _outbox.pendingForAccount(user.id);
    state = state.copyWith(pendingOutboxCount: list.length);
  }

  /// Debounced sync trigger to batch micro-transactions and prevent CPU spikes.
  void triggerSync({Duration debounce = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      unawaited(_drainOutbox());
    });
  }

  /// Drains the persistent outbox table in order of timestamp.
  Future<void> _drainOutbox() async {
    if (_isDraining || !state.isOnline) return;
    if (!_supabaseService.isInitialized) return;
    final client = _supabaseService.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    _isDraining = true;
    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final entries = await _outbox.pendingForAccount(user.id);
      if (entries.isEmpty) {
        state = state.copyWith(
          isSyncing: false,
          lastSyncedAt: DateTime.now(),
          pendingOutboxCount: 0,
        );
        _isDraining = false;
        return;
      }

      for (final entry in entries.take(20)) {
        if (!state.isOnline) break;

        try {
          await _processEntry(entry, user.id);
          await _outbox.complete(entry.id, entry.createdAtMs);
        } catch (e) {
          debugPrint('[SyncCoordinator] Error syncing entry ${entry.id}: $e');
          await _outbox.recordFailure(entry.id, entry.createdAtMs, e);
          break;
        }
      }

      final remaining = (await _outbox.pendingForAccount(user.id)).length;
      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
        pendingOutboxCount: remaining,
      );

      if (remaining > 0 && state.isOnline) {
        triggerSync(debounce: const Duration(seconds: 1));
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    } finally {
      _isDraining = false;
    }
  }

  Future<void> _processEntry(SyncOutboxEntry entry, String userId) async {
    if (!_supabaseService.isInitialized) return;
    final client = _supabaseService.client;

    if (entry.feature == 'tasks') {
      if (entry.operation == 'delete') {
        await client.from('tasks').delete().eq('id', entry.entityId);
      } else {
        final task = await DatabaseProvider.instance.taskDao.getTask(entry.entityId);
        if (task != null) {
          final payload = task.toSupabaseRow(userId: userId);
          await client.from('tasks').upsert(payload);
          await DatabaseProvider.instance.taskDao.markTaskSynced(
            task.id,
            DateTime.now(),
            expectedUpdatedAt: task.updatedAt,
          );
        }
      }
    }
  }

  /// Start Realtime subscription on Supabase for the current authenticated user.
  void setupRealtime(String userId) {
    _realtimeChannel?.unsubscribe();
    if (!_supabaseService.isInitialized) return;
    final client = _supabaseService.client;

    _realtimeChannel = client
        .channel('public:sync:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleRemoteTaskChange(payload);
          },
        )
        .subscribe();
  }

  Future<void> _handleRemoteTaskChange(PostgresChangePayload payload) async {
    try {
      final eventType = payload.eventType;
      if (eventType == PostgresChangeEvent.delete) {
        final oldRecord = payload.oldRecord;
        final id = oldRecord['id'] as String?;
        if (id != null) {
          await DatabaseProvider.instance.taskDao.hardDelete(id);
        }
      } else {
        final newRecord = payload.newRecord;
        final remoteTask = Task.fromSupabaseRow(newRecord);
        final localTask =
            await DatabaseProvider.instance.taskDao.getTask(remoteTask.id);

        if (localTask == null || remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          await DatabaseProvider.instance.taskDao.upsertTask(remoteTask);
          await DatabaseProvider.instance.taskDao.markTaskSynced(
            remoteTask.id,
            DateTime.now(),
            expectedUpdatedAt: remoteTask.updatedAt,
          );
        }
      }
    } catch (e) {
      debugPrint('[SyncCoordinator] Failed to reconcile remote task delta: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _networkSub?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

/// Riverpod provider for unified sync coordination.
final syncCoordinatorProvider =
    StateNotifierProvider<SyncCoordinator, SyncState>((ref) {
  return SyncCoordinator();
});
