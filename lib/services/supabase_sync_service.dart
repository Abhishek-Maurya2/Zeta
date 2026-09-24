import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import 'supabase_service.dart';
import 'network_service.dart';
import 'preferences_service.dart';

/// Service responsible for bi-directional synchronization between local tasks and the
/// Supabase `public.tasks` table, including real-time change subscriptions.
class SupabaseSyncService {
  static final SupabaseSyncService _instance = SupabaseSyncService._internal();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._internal() {
    _networkSubscription =
        NetworkService().onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        final reconnect = onNetworkReconnect;
        unawaited(reconnect != null ? reconnect() : processPendingQueue());
      }
    });
  }

  final SupabaseService _supabaseService = SupabaseService();
  final Map<String, Timer> _debounceTimers = {};
  RealtimeChannel? _realtimeChannel;
  StreamSubscription<bool>? _networkSubscription;
  bool _isSyncing = false;
  bool _isProcessingPendingQueue = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  void Function(Task task, String eventType)? onRemoteChange;
  Future<void> Function(Task task, DateTime syncedAt)? onTaskSynced;
  Future<void> Function()? onNetworkReconnect;

  final List<Task> _pendingQueue = [];

  Set<String> _getPendingPermanentDeletions() {
    final list = PreferencesService.instance.getStringList(PreferencesService.keyPendingPermanentDeletions);
    return list != null ? Set<String>.from(list) : <String>{};
  }

  Future<void> _savePendingPermanentDeletions(Set<String> set) async {
    await PreferencesService.instance.setStringList(PreferencesService.keyPendingPermanentDeletions, set.toList());
  }

  Future<void> queuePermanentDeletions(Iterable<String> taskIds) async {
    final pending = _getPendingPermanentDeletions()..addAll(taskIds);
    await _savePendingPermanentDeletions(pending);
    unawaited(processPendingQueue());
  }

  /// Processes any queued offline tasks that previously failed to push,
  /// including tasks modified offline stored in SQLite and pending permanent deletions.
  Future<void> processPendingQueue() async {
    if (!_supabaseService.isInitialized || _isProcessingPendingQueue) return;
    _isProcessingPendingQueue = true;
    try {
      // 1. Process pending permanent deletions
      final pendingDeletions = _getPendingPermanentDeletions();
      if (pendingDeletions.isNotEmpty) {
        final toRemove = <String>[];
        for (final id in pendingDeletions) {
          try {
            await _supabaseService.client
                .from('tasks')
                .delete()
                .eq('id', id)
                .timeout(const Duration(seconds: 15));
            toRemove.add(id);
            debugPrint('SupabaseSyncService: Successfully flushed pending permanent delete for $id');
          } catch (_) {}
        }
        if (toRemove.isNotEmpty) {
          final remaining = _getPendingPermanentDeletions()..removeAll(toRemove);
          await _savePendingPermanentDeletions(remaining);
        }
      }

      // 2. Process in-memory retries. Durable unsynced rows are loaded by the
      // repository, which owns the local database boundary.
      if (_pendingQueue.isEmpty) return;
      final toProcess = List<Task>.from(_pendingQueue);
      _pendingQueue.clear();
      for (final task in toProcess) {
        final success = await pushTask(task);
        if (!success && !_pendingQueue.any((t) => t.id == task.id)) {
          _pendingQueue.add(task);
        }
      }
    } finally {
      _isProcessingPendingQueue = false;
    }
  }

  /// Pull tasks from Supabase `public.tasks` table.
  /// If [since] is provided, only retrieves tasks updated since that timestamp.
  Future<List<Task>> pullTasks({DateTime? since}) async {
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) {
      _lastError = 'Supabase is unavailable or the device is offline.';
      return [];
    }

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      const pageSize = 1000;
      int offset = 0;
      final List<Task> tasks = [];
      bool hasMore = true;

      while (hasMore) {
        var query = _supabaseService.client
            .from('tasks')
            .select()
            .eq('user_id', userId);

        if (since != null) {
          query = query.gte('updated_at', since.toUtc().toIso8601String());
        }

        final response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + pageSize - 1)
            .timeout(const Duration(seconds: 15));

        final rows = response as List<dynamic>;
        for (final row in rows) {
          tasks.add(Task.fromSupabaseRow(row as Map<String, dynamic>));
        }

        if (rows.length < pageSize) {
          hasMore = false;
        } else {
          offset += pageSize;
        }
      }

      _lastSyncedAt = DateTime.now();
      NetworkService().markOnline();
      final pendingDeletions = _getPendingPermanentDeletions();
      final filteredTasks = pendingDeletions.isEmpty
          ? tasks
          : tasks.where((t) => !pendingDeletions.contains(t.id)).toList();
      debugPrint('SupabaseSyncService: Pulled ${filteredTasks.length} tasks successfully (filtered ${tasks.length - filteredTasks.length} pending deletes).');
      return filteredTasks;
    } catch (e) {
      _lastError = e.toString();
      NetworkService().markOffline();
      debugPrint('SupabaseSyncService: pullTasks failed - $e');
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Push a single task to Supabase with automatic 500ms debouncing.
  void scheduleDebouncedPush(Task task) {
    _debounceTimers[task.id]?.cancel();
    _debounceTimers[task.id] = Timer(const Duration(milliseconds: 500), () async {
      await pushTask(task);
      _debounceTimers.remove(task.id);
    });
  }

  /// Immediately pushes a task to Supabase with retries.
  Future<bool> pushTask(Task task) async {
    _debounceTimers[task.id]?.cancel();
    _debounceTimers.remove(task.id);
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) {
      if (!_pendingQueue.any((t) => t.id == task.id)) {
        _pendingQueue.add(task);
      }
      return false;
    }

    final userId = _supabaseService.effectiveUserId;
    final row = task.toSupabaseRow(defaultUserId: userId);

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        await _supabaseService.client
            .from('tasks')
            .upsert(row)
            .timeout(const Duration(seconds: 15));
        debugPrint('SupabaseSyncService: Upserted task "${task.title}" (${task.id})');
        _lastSyncedAt = DateTime.now();
        _pendingQueue.removeWhere((t) => t.id == task.id);
        await onTaskSynced?.call(task, _lastSyncedAt!);
        task.lastSyncedAt = _lastSyncedAt;
        NetworkService().markOnline();
        return true;
      } catch (e) {
        retryCount++;
        debugPrint('SupabaseSyncService: Push attempt $retryCount failed for ${task.id}: $e');
        if (retryCount >= maxRetries) {
          _lastError = e.toString();
          NetworkService().markOffline();
          if (!_pendingQueue.any((t) => t.id == task.id)) {
            _pendingQueue.add(task);
          }
          return false;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    return false;
  }

  /// Soft deletes or permanently deletes a task in Supabase.
  Future<bool> deleteTask(String taskId, {bool soft = true}) async {
    if (!soft) {
      await queuePermanentDeletions([taskId]);
      return false;
    }
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) {
      return false;
    }

    try {
      await _supabaseService.client.from('tasks').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', taskId).timeout(const Duration(seconds: 15));
      debugPrint('SupabaseSyncService: Soft-deleted task $taskId');
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncService: deleteTask failed for $taskId - $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Subscribes to Realtime PostgreSQL changes on `public.tasks` table.
  ///
  /// Applies a server-side `user_id` row filter so only changes belonging to
  /// the current user are delivered — avoids unnecessary traffic in shared
  /// Supabase projects.
  void subscribeToRealtime({void Function(Task task, String eventType)? onChange}) {
    if (!_supabaseService.isInitialized) return;
    if (onChange != null) onRemoteChange = onChange;

    final userId = _supabaseService.effectiveUserId;

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _supabaseService.client
        .channel('public:tasks:$userId')
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
            try {
              final eventType = payload.eventType.name;
              if (payload.newRecord.isNotEmpty) {
                final task = Task.fromSupabaseRow(payload.newRecord);
                onRemoteChange?.call(task, eventType);
              } else if (payload.oldRecord.isNotEmpty) {
                final task = Task.fromSupabaseRow(payload.oldRecord);
                onRemoteChange?.call(task, eventType);
              }
            } catch (e) {
              debugPrint('SupabaseSyncService: Error handling realtime payload: $e');
            }
          },
        )
        .subscribe();
    debugPrint('SupabaseSyncService: Subscribed to Realtime channel public:tasks (user=$userId)');
  }

  /// Clean up resources on disposal.
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _networkSubscription?.cancel();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }
}
