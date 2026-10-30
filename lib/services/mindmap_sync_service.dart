import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_provider.dart';
import '../pages/space/models/mindmap.dart';
import 'network_service.dart';
import 'supabase_service.dart';

/// Service responsible for bi-directional synchronization between local Space mindmaps
/// and Supabase `public.mindmaps` table, including real-time change subscriptions.
class MindmapSyncService {
  static final MindmapSyncService _instance = MindmapSyncService._internal();
  factory MindmapSyncService() => _instance;

  MindmapSyncService._internal() {
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
  RealtimeChannel? _realtimeChannel;
  StreamSubscription<bool>? _networkSubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  void Function(MindMap mindmap, String eventType)? onRemoteChange;
  Future<void> Function(MindMap mindmap, DateTime syncedAt)? onMindMapSynced;
  Future<MindMap?> Function(String id)? getMindMapForSync;
  Future<void> Function()? onNetworkReconnect;

  void endAccountSession() {
    onRemoteChange = null;
    onMindMapSynced = null;
    getMindMapForSync = null;
    onNetworkReconnect = null;
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _isSyncing = false;
  }

  Future<void> _ensureInitialized() async {
    if (!_supabaseService.isInitialized) {
      try {
        await _supabaseService.init();
      } catch (e) {
        debugPrint('MindmapSyncService: Failed to initialize SupabaseService: $e');
      }
    }
  }

  /// Processes durable cloud mutation intent from SQLite outbox.
  Future<void> processPendingQueue() async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      return;
    }

    final userId = _supabaseService.effectiveUserId;
    final pending = await _outbox.pendingForAccount(userId, feature: 'space');
    if (pending.isEmpty) return;

    // 1. Process deletes
    final deleteEntries =
        pending.where((item) => item.operation == 'delete').toList();
    if (deleteEntries.isNotEmpty) {
      final ids = deleteEntries.map((e) => e.entityId).toList();
      try {
        await _supabaseService.client
            .from('mindmaps')
            .delete()
            .inFilter('id', ids)
            .timeout(const Duration(seconds: 15));
        for (final entry in deleteEntries) {
          await _outbox.complete(entry.id, entry.createdAtMs);
        }
      } catch (error) {
        for (final entry in deleteEntries) {
          await _outbox.recordFailure(entry.id, entry.createdAtMs, error);
        }
      }
    }

    // 2. Process upserts
    final upsertEntries =
        pending.where((item) => item.operation == 'upsert').toList();
    for (final entry in upsertEntries) {
      try {
        final mindmap = await getMindMapForSync?.call(entry.entityId) ??
            await DatabaseProvider.instance.mindmapDao.getMindMap(entry.entityId);
        if (mindmap == null) {
          await _outbox.complete(entry.id, entry.createdAtMs);
        } else if (await pushMindMap(mindmap)) {
          await _outbox.complete(entry.id, entry.createdAtMs);
        } else {
          await _outbox.recordFailure(
            entry.id,
            entry.createdAtMs,
            _lastError ?? 'Mindmap push failed.',
          );
        }
      } catch (error) {
        await _outbox.recordFailure(entry.id, entry.createdAtMs, error);
      }
    }
  }

  /// Debounced push of a mindmap to reduce network noise during rapid node edits.
  void schedulePush(MindMap mindmap, {Duration delay = const Duration(milliseconds: 600)}) {
    _debounceTimers[mindmap.id]?.cancel();
    _debounceTimers[mindmap.id] = Timer(delay, () {
      _debounceTimers.remove(mindmap.id);
      unawaited(pushMindMap(mindmap));
    });
  }

  /// Push a single mindmap to Supabase.
  Future<bool> pushMindMap(MindMap mindmap) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      return false;
    }

    final userId = _supabaseService.effectiveUserId;
    final row = mindmap.toSupabaseRow(userId: userId);

    try {
      await _supabaseService.client
          .from('mindmaps')
          .upsert(row)
          .timeout(const Duration(seconds: 20));

      final syncedAt = DateTime.now();
      await DatabaseProvider.instance.mindmapDao.markMindMapSynced(
        mindmap.id,
        syncedAt,
        expectedUpdatedAtMs: mindmap.updatedAtMs,
      );
      await onMindMapSynced?.call(mindmap, syncedAt);
      _lastSyncedAt = syncedAt;
      NetworkService().markOnline();
      return true;
    } catch (e) {
      debugPrint('MindmapSyncService: pushMindMap failed - $e');
      _lastError = e.toString();
      NetworkService().markOffline();
      return false;
    }
  }

  /// Pull all mindmaps from Supabase for current user and reconcile with local SQLite.
  Future<List<MindMap>> pullMindMaps() async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      _lastError = 'Supabase is unavailable or the device is offline.';
      return [];
    }

    _isSyncing = true;
    try {
      final userId = _supabaseService.effectiveUserId;
      final response = await _supabaseService.client
          .from('mindmaps')
          .select()
          .eq('user_id', userId)
          .order('updated_at_ms', ascending: false)
          .timeout(const Duration(seconds: 25));

      final remoteMaps = (response as List<dynamic>)
          .map((r) => MindMap.fromSupabaseRow(r as Map<String, dynamic>))
          .toList();

      final dao = DatabaseProvider.instance.mindmapDao;
      final localMaps = await dao.getActiveMindMaps();
      final localMapById = {for (final m in localMaps) m.id: m};

      final syncedAt = DateTime.now();
      for (final remote in remoteMaps) {
        final local = localMapById[remote.id];
        if (local == null) {
          // New remote mindmap: save locally
          await dao.upsertMindMap(remote);
          await dao.markMindMapSynced(
            remote.id,
            syncedAt,
            expectedUpdatedAtMs: remote.updatedAtMs,
          );
        } else if (remote.updatedAtMs > local.updatedAtMs) {
          // Remote is newer (LWW): update local
          await dao.upsertMindMap(remote);
          await dao.markMindMapSynced(
            remote.id,
            syncedAt,
            expectedUpdatedAtMs: remote.updatedAtMs,
          );
        } else if (local.updatedAtMs > remote.updatedAtMs) {
          // Local is newer: enqueue push to cloud
          await dao.upsertMindMapAndQueue(local);
        }
      }

      _lastSyncedAt = syncedAt;
      _lastError = null;
      NetworkService().markOnline();
      return remoteMaps;
    } catch (e) {
      debugPrint('MindmapSyncService: pullMindMaps failed - $e');
      _lastError = e.toString();
      NetworkService().markOffline();
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Sets up Supabase Realtime subscription for live mindmap updates across devices.
  void setupRealtime() {
    _realtimeChannel?.unsubscribe();
    if (!_supabaseService.isInitialized || !_supabaseService.isAuthenticated) return;

    final userId = _supabaseService.effectiveUserId;
    _realtimeChannel = _supabaseService.client
        .channel('public:mindmaps:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mindmaps',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleRemoteChange(payload);
          },
        )
        .subscribe();
  }

  Future<void> _handleRemoteChange(PostgresChangePayload payload) async {
    final eventType = payload.eventType;
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;
    final dao = DatabaseProvider.instance.mindmapDao;

    if (eventType == PostgresChangeEvent.delete) {
      final id = (oldRecord['id'] ?? newRecord['id']) as String?;
      if (id != null) {
        await dao.deleteMindMap(id);
      }
      return;
    }

    if (newRecord.isNotEmpty) {
      final remoteMap = MindMap.fromSupabaseRow(newRecord);
      final local = await dao.getMindMap(remoteMap.id);

      // Last-Write-Wins (LWW)
      if (local == null || remoteMap.updatedAtMs >= local.updatedAtMs) {
        await dao.upsertMindMap(remoteMap);
        await dao.markMindMapSynced(
          remoteMap.id,
          DateTime.now(),
          expectedUpdatedAtMs: remoteMap.updatedAtMs,
        );
        onRemoteChange?.call(remoteMap, eventType.name);
      }
    }
  }

  void dispose() {
    _networkSubscription?.cancel();
    endAccountSession();
  }
}

