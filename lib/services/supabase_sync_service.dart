import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import 'supabase_service.dart';

/// Service responsible for bi-directional synchronization between local tasks and the
/// Supabase `public.tasks` table, including real-time change subscriptions.
class SupabaseSyncService {
  static final SupabaseSyncService _instance = SupabaseSyncService._internal();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final Map<String, Timer> _debounceTimers = {};
  RealtimeChannel? _realtimeChannel;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  void Function(Task task, String eventType)? onRemoteChange;

  /// Pull tasks from Supabase `public.tasks` table.
  /// If [since] is provided, only retrieves tasks updated since that timestamp.
  Future<List<Task>> pullTasks({DateTime? since}) async {
    if (!_supabaseService.isInitialized) return [];

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      var query = _supabaseService.client
          .from('tasks')
          .select()
          .eq('user_id', userId);

      if (since != null) {
        query = query.gte('updated_at', since.toUtc().toIso8601String());
      }

      final response = await query.order('created_at', ascending: false).timeout(
            const Duration(seconds: 15),
          );

      final List<Task> tasks = [];
      for (final row in response as List<dynamic>) {
        try {
          tasks.add(Task.fromSupabaseRow(row as Map<String, dynamic>));
        } catch (e) {
          debugPrint('SupabaseSyncService: Error parsing task row - $e');
        }
      }

      _lastSyncedAt = DateTime.now();
      debugPrint('SupabaseSyncService: Pulled ${tasks.length} tasks successfully.');
      return tasks;
    } catch (e) {
      _lastError = e.toString();
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
    if (!_supabaseService.isInitialized) return false;

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
        return true;
      } catch (e) {
        retryCount++;
        debugPrint('SupabaseSyncService: Push attempt $retryCount failed for ${task.id}: $e');
        if (retryCount >= maxRetries) {
          _lastError = e.toString();
          return false;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    return false;
  }

  /// Soft deletes or permanently deletes a task in Supabase.
  Future<bool> deleteTask(String taskId, {bool soft = true}) async {
    if (!_supabaseService.isInitialized) return false;

    try {
      if (soft) {
        await _supabaseService.client.from('tasks').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', taskId);
        debugPrint('SupabaseSyncService: Soft-deleted task $taskId');
      } else {
        await _supabaseService.client.from('tasks').delete().eq('id', taskId);
        debugPrint('SupabaseSyncService: Permanently deleted task $taskId');
      }
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncService: deleteTask failed for $taskId - $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Subscribes to Realtime PostgreSQL changes on `public.tasks` table.
  void subscribeToRealtime({void Function(Task task, String eventType)? onChange}) {
    if (!_supabaseService.isInitialized) return;
    if (onChange != null) onRemoteChange = onChange;

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _supabaseService.client
        .channel('public:tasks')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
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
    debugPrint('SupabaseSyncService: Subscribed to Realtime channel public:tasks');
  }

  /// Clean up resources on disposal.
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }
}
