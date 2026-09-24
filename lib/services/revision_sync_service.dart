import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/revision.dart';
import 'supabase_service.dart';
import 'network_service.dart';
import 'preferences_service.dart';

/// Service responsible for bi-directional synchronization between local Revision
/// data and Supabase `public.revision_subjects` and `public.revision_topics` tables.
class RevisionSyncService {
  static final RevisionSyncService _instance = RevisionSyncService._internal();
  factory RevisionSyncService() => _instance;
  RevisionSyncService._internal() {
    _networkSubscription =
        NetworkService().onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        unawaited(processPendingQueue());
      }
    });
  }

  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription<bool>? _networkSubscription;
  bool _isSyncing = false;
  bool _isProcessingPendingQueue = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;
  bool hasPendingSubject(String id) =>
      _pendingIds(_pendingSubjectUpsertsKey).contains(id);
  bool hasPendingTopic(String id) =>
      _pendingIds(_pendingTopicUpsertsKey).contains(id);
  Future<Subject?> Function(String id)? getSubjectForSync;
  Future<ChapterTopic?> Function(String id)? getTopicForSync;

  static const _pendingSubjectUpsertsKey =
      PreferencesService.keyPendingRevisionSubjectUpserts;
  static const _pendingTopicUpsertsKey =
      PreferencesService.keyPendingRevisionTopicUpserts;

  Set<String> _pendingIds(String key) =>
      Set<String>.from(PreferencesService.instance.getStringList(key) ?? const []);

  Future<void> _savePendingIds(String key, Set<String> ids) async {
    if (ids.isEmpty) {
      await PreferencesService.instance.remove(key);
    } else {
      await PreferencesService.instance.setStringList(key, ids.toList());
    }
  }

  Future<void> _removePendingId(String key, String id) async {
    final current = _pendingIds(key);
    if (current.remove(id)) await _savePendingIds(key, current);
  }

  Future<void> enqueueSubjectDeletion(String id) async {
    final upserts = _pendingIds(_pendingSubjectUpsertsKey)..remove(id);
    await _savePendingIds(_pendingSubjectUpsertsKey, upserts);
    final deletes = _getPendingSubjectDeletions()..add(id);
    await _savePendingSubjectDeletions(deletes);
    unawaited(processPendingQueue());
  }

  Future<void> enqueueTopicDeletion(String id) async {
    final upserts = _pendingIds(_pendingTopicUpsertsKey)..remove(id);
    await _savePendingIds(_pendingTopicUpsertsKey, upserts);
    final deletes = _getPendingTopicDeletions()..add(id);
    await _savePendingTopicDeletions(deletes);
    unawaited(processPendingQueue());
  }

  /// Persist local changes as an outbox entry before attempting network I/O.
  Future<void> enqueueSubjectUpsert(Subject subject) async {
    final pending = _pendingIds(_pendingSubjectUpsertsKey)..add(subject.id);
    await _savePendingIds(_pendingSubjectUpsertsKey, pending);
    unawaited(processPendingQueue());
  }

  Future<void> enqueueTopicUpsert(ChapterTopic topic) async {
    final pending = _pendingIds(_pendingTopicUpsertsKey)..add(topic.id);
    await _savePendingIds(_pendingTopicUpsertsKey, pending);
    unawaited(processPendingQueue());
  }

  Future<void> enqueueTopicsUpsert(List<ChapterTopic> topics) async {
    if (topics.isEmpty) return;
    final pending = _pendingIds(_pendingTopicUpsertsKey)
      ..addAll(topics.map((topic) => topic.id));
    await _savePendingIds(_pendingTopicUpsertsKey, pending);
    unawaited(processPendingQueue());
  }

  Set<String> _getPendingSubjectDeletions() {
    final list = PreferencesService.instance
        .getStringList(PreferencesService.keyPendingSubjectDeletions);
    return list != null ? Set<String>.from(list) : <String>{};
  }

  Future<void> _savePendingSubjectDeletions(Set<String> set) async {
    await PreferencesService.instance.setStringList(
        PreferencesService.keyPendingSubjectDeletions, set.toList());
  }

  void _enqueuePendingSubjectDeletion(String id) {
    final set = _getPendingSubjectDeletions();
    set.add(id);
    unawaited(_savePendingSubjectDeletions(set));
  }

  void _removePendingSubjectDeletion(String id) {
    final set = _getPendingSubjectDeletions();
    if (set.remove(id)) {
      unawaited(_savePendingSubjectDeletions(set));
    }
  }

  Set<String> _getPendingTopicDeletions() {
    final list = PreferencesService.instance
        .getStringList(PreferencesService.keyPendingTopicDeletions);
    return list != null ? Set<String>.from(list) : <String>{};
  }

  Future<void> _savePendingTopicDeletions(Set<String> set) async {
    await PreferencesService.instance.setStringList(
        PreferencesService.keyPendingTopicDeletions, set.toList());
  }

  void _enqueuePendingTopicDeletion(String id) {
    final set = _getPendingTopicDeletions();
    set.add(id);
    unawaited(_savePendingTopicDeletions(set));
  }

  void _removePendingTopicDeletion(String id) {
    final set = _getPendingTopicDeletions();
    if (set.remove(id)) {
      unawaited(_savePendingTopicDeletions(set));
    }
  }

  Future<void> processPendingQueue() async {
    if (_isProcessingPendingQueue) return;
    _isProcessingPendingQueue = true;
    try {
      await _ensureInitialized();
      if (!_supabaseService.isInitialized || !NetworkService().isOnline) return;

      // Upserts are replayed from SQLite, the canonical local store. Keep IDs
      // in the outbox until Supabase confirms each write.
      final loadSubject = getSubjectForSync;
      if (loadSubject != null) {
        for (final id in _pendingIds(_pendingSubjectUpsertsKey).toList()) {
          final subject = await loadSubject(id);
          if (subject == null) {
            await _removePendingId(_pendingSubjectUpsertsKey, id);
          } else if (await _pushSubjectNow(subject)) {
            await _removePendingId(_pendingSubjectUpsertsKey, id);
          }
        }
      }

      final loadTopic = getTopicForSync;
      if (loadTopic != null) {
        for (final id in _pendingIds(_pendingTopicUpsertsKey).toList()) {
          final topic = await loadTopic(id);
          if (topic == null) {
            await _removePendingId(_pendingTopicUpsertsKey, id);
          } else if (await _pushTopicNow(topic)) {
            await _removePendingId(_pendingTopicUpsertsKey, id);
          }
        }
      }

      // 1. Process pending topic deletions
      final pendingTopics = _getPendingTopicDeletions();
      if (pendingTopics.isNotEmpty) {
        final toRemove = <String>[];
        for (final id in pendingTopics) {
          try {
            await _supabaseService.client
                .from('revision_topics')
                .delete()
                .eq('id', id)
                .timeout(const Duration(seconds: 15));
            toRemove.add(id);
          } catch (_) {}
        }
        if (toRemove.isNotEmpty) {
          final remaining = _getPendingTopicDeletions()..removeAll(toRemove);
          await _savePendingTopicDeletions(remaining);
        }
      }

      // 2. Process pending subject deletions
      final pendingSubjects = _getPendingSubjectDeletions();
      if (pendingSubjects.isNotEmpty) {
        final toRemove = <String>[];
        for (final id in pendingSubjects) {
          try {
            await _supabaseService.client
                .from('revision_topics')
                .delete()
                .eq('subject_id', id)
                .timeout(const Duration(seconds: 15));
            await _supabaseService.client
                .from('revision_subjects')
                .delete()
                .eq('id', id)
                .timeout(const Duration(seconds: 15));
            toRemove.add(id);
          } catch (_) {}
        }
        if (toRemove.isNotEmpty) {
          final remaining = _getPendingSubjectDeletions()..removeAll(toRemove);
          await _savePendingSubjectDeletions(remaining);
        }
      }
    } finally {
      _isProcessingPendingQueue = false;
    }
  }

  Future<void> _ensureInitialized() async {
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return;
    if (!_supabaseService.isInitialized) {
      try {
        await _supabaseService.init();
      } catch (e) {
        debugPrint('RevisionSyncService: Failed to initialize SupabaseService: $e');
      }
    }
  }

  /// Pull subjects from Supabase `public.revision_subjects` table.
  Future<List<Subject>> pullSubjects() async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) {
      _lastError = 'Supabase is unavailable or the device is offline.';
      return [];
    }

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      final List<Subject> subjects = [];
      const pageSize = 1000;
      var offset = 0;
      while (true) {
        final response = await _supabaseService.client
            .from('revision_subjects')
            .select()
            .or('user_id.eq.$userId,user_id.eq.singleton')
            .order('created_at', ascending: true)
            .range(offset, offset + pageSize - 1);
        final rows = response as List<dynamic>;
        for (final row in rows) {
          subjects.add(Subject.fromSupabaseRow(row as Map<String, dynamic>));
        }
        if (rows.length < pageSize) break;
        offset += pageSize;
      }
      NetworkService().markOnline();
      _lastSyncedAt = DateTime.now();
      final pendingDeletes = _getPendingSubjectDeletions();
      final filtered = pendingDeletes.isEmpty
          ? subjects
          : subjects.where((s) => !pendingDeletes.contains(s.id)).toList();
      return filtered;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('RevisionSyncService: pullSubjects error - $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        NetworkService().markOffline();
      }
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull topics from Supabase `public.revision_topics` table.
  Future<List<ChapterTopic>> pullTopics() async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) {
      _lastError = 'Supabase is unavailable or the device is offline.';
      return [];
    }

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      final List<ChapterTopic> topics = [];
      const pageSize = 1000;
      var offset = 0;
      while (true) {
        final response = await _supabaseService.client
            .from('revision_topics')
            .select()
            .or('user_id.eq.$userId,user_id.eq.singleton')
            .order('sort_order', ascending: true)
            .order('created_at', ascending: true)
            .range(offset, offset + pageSize - 1);
        final rows = response as List<dynamic>;
        for (final row in rows) {
          topics.add(ChapterTopic.fromSupabaseRow(row as Map<String, dynamic>));
        }
        if (rows.length < pageSize) break;
        offset += pageSize;
      }
      NetworkService().markOnline();
      _lastSyncedAt = DateTime.now();
      final pendingDeletes = _getPendingTopicDeletions();
      final filtered = pendingDeletes.isEmpty
          ? topics
          : topics.where((t) => !pendingDeletes.contains(t.id)).toList();
      return filtered;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('RevisionSyncService: pullTopics error - $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        NetworkService().markOffline();
      }
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes a subject to Supabase.
  Future<bool> pushSubject(Subject subject) async {
    return _pushSubjectNow(subject);
  }

  Future<bool> _pushSubjectNow(Subject subject) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) return false;

    try {
      final userId = _supabaseService.effectiveUserId;
      final row = subject.toSupabaseRow(defaultUserId: userId);
      await _supabaseService.client.from('revision_subjects').upsert(row);
      NetworkService().markOnline();
      return true;
      } catch (e) {
        _lastError = e.toString();
        debugPrint('RevisionSyncService: pushSubject error - $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        NetworkService().markOffline();
      }
      return false;
    }
  }

  /// Deletes a subject and its associated topics from Supabase.
  Future<bool> deleteSubject(String subjectId) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) {
      _enqueuePendingSubjectDeletion(subjectId);
      return false;
    }

    try {
      await _supabaseService.client
          .from('revision_topics')
          .delete()
          .eq('subject_id', subjectId)
          .timeout(const Duration(seconds: 15));
      await _supabaseService.client
          .from('revision_subjects')
          .delete()
          .eq('id', subjectId)
          .timeout(const Duration(seconds: 15));
      _removePendingSubjectDeletion(subjectId);
      NetworkService().markOnline();
      return true;
    } catch (e) {
      debugPrint('RevisionSyncService: deleteSubject error - $e');
      _enqueuePendingSubjectDeletion(subjectId);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        NetworkService().markOffline();
      }
      return false;
    }
  }

  /// Pushes a topic to Supabase.
  Future<bool> pushTopic(ChapterTopic topic) async {
    return _pushTopicNow(topic);
  }

  Future<bool> _pushTopicNow(ChapterTopic topic) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) return false;

    try {
      final userId = _supabaseService.effectiveUserId;
      final row = topic.toSupabaseRow(defaultUserId: userId);
      await _supabaseService.client.from('revision_topics').upsert(row);
      NetworkService().markOnline();
      return true;
      } catch (e) {
        _lastError = e.toString();
        debugPrint('RevisionSyncService: pushTopic error - $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        NetworkService().markOffline();
      }
      return false;
    }
  }

  /// Pushes a batch of topics to Supabase (e.g. after reordering).
  Future<bool> pushTopics(List<ChapterTopic> topics) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized || !NetworkService().isOnline || topics.isEmpty) return false;

    try {
      final userId = _supabaseService.effectiveUserId;
      final rows =
          topics.map((t) => t.toSupabaseRow(defaultUserId: userId)).toList();
      await _supabaseService.client.from('revision_topics').upsert(rows);
      NetworkService().markOnline();
      return true;
    } catch (e) {
      debugPrint('RevisionSyncService: pushTopics error - $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        NetworkService().markOffline();
      }
      return false;
    }
  }

  /// Deletes a topic from Supabase.
  Future<bool> deleteTopic(String topicId) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized || !NetworkService().isOnline) {
      _enqueuePendingTopicDeletion(topicId);
      return false;
    }

    try {
      await _supabaseService.client
          .from('revision_topics')
          .delete()
          .eq('id', topicId)
          .timeout(const Duration(seconds: 15));
      _removePendingTopicDeletion(topicId);
      NetworkService().markOnline();
      return true;
    } catch (e) {
      debugPrint('RevisionSyncService: deleteTopic error - $e');
      _enqueuePendingTopicDeletion(topicId);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        NetworkService().markOffline();
      }
      return false;
    }
  }

  void dispose() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
  }
}
