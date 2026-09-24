import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/revision.dart';
import '../database/database_provider.dart';
import 'supabase_service.dart';
import 'network_service.dart';

/// Service responsible for bi-directional synchronization between local Revision
/// data and Supabase `public.revision_subjects` and `public.revision_topics` tables.
class RevisionSyncService {
  static final RevisionSyncService _instance = RevisionSyncService._internal();
  factory RevisionSyncService() => _instance;
  RevisionSyncService._internal() {
    _networkSubscription = NetworkService().onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        unawaited(processPendingQueue());
      }
    });
  }

  final SupabaseService _supabaseService = SupabaseService();
  final _outbox = DatabaseProvider.instance.syncOutboxDao;
  StreamSubscription<bool>? _networkSubscription;
  bool _isSyncing = false;
  bool _isProcessingPendingQueue = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;
  Future<bool> hasPendingSubject(String id) => _outbox.hasPending(
    userId: _supabaseService.effectiveUserId,
    feature: 'revisions',
    entityType: 'subject',
    entityId: id,
  );
  Future<bool> hasPendingTopic(String id) => _outbox.hasPending(
    userId: _supabaseService.effectiveUserId,
    feature: 'revisions',
    entityType: 'topic',
    entityId: id,
  );
  Future<Subject?> Function(String id)? getSubjectForSync;
  Future<ChapterTopic?> Function(String id)? getTopicForSync;

  void endAccountSession() {
    getSubjectForSync = null;
    getTopicForSync = null;
    _isSyncing = false;
  }

  Future<void> enqueueSubjectDeletion(String id) async {
    await _enqueueRevision(id, 'subject', 'delete');
    unawaited(processPendingQueue());
  }

  Future<void> enqueueTopicDeletion(String id) async {
    await _enqueueRevision(id, 'topic', 'delete');
    unawaited(processPendingQueue());
  }

  Future<void> _enqueueRevision(String id, String entity, String operation) =>
      _outbox.enqueue(
        userId: _supabaseService.effectiveUserId,
        feature: 'revisions',
        entityType: entity,
        entityId: id,
        operation: operation,
      );

  Future<void> processPendingQueue() async {
    if (_isProcessingPendingQueue) return;
    _isProcessingPendingQueue = true;
    try {
      await _ensureInitialized();
      if (!_supabaseService.isInitialized ||
          !_supabaseService.isAuthenticated ||
          !NetworkService().isOnline) {
        return;
      }

      for (final item in await _outbox.pendingForAccount(
        _supabaseService.effectiveUserId,
        feature: 'revisions',
      )) {
        try {
          bool succeeded;
          if (item.operation == 'upsert' && item.entityType == 'subject') {
            final loader = getSubjectForSync;
            if (loader == null) continue;
            final subject = await loader(item.entityId);
            succeeded = subject == null || await _pushSubjectNow(subject);
          } else if (item.operation == 'upsert' && item.entityType == 'topic') {
            final loader = getTopicForSync;
            if (loader == null) continue;
            final topic = await loader(item.entityId);
            succeeded = topic == null || await _pushTopicNow(topic);
          } else if (item.operation == 'delete' && item.entityType == 'topic') {
            await _supabaseService.client
                .from('revision_topics')
                .delete()
                .eq('id', item.entityId)
                .timeout(const Duration(seconds: 15));
            succeeded = true;
          } else if (item.operation == 'delete' &&
              item.entityType == 'subject') {
            await _supabaseService.client
                .from('revision_topics')
                .delete()
                .eq('subject_id', item.entityId)
                .timeout(const Duration(seconds: 15));
            await _supabaseService.client
                .from('revision_subjects')
                .delete()
                .eq('id', item.entityId)
                .timeout(const Duration(seconds: 15));
            succeeded = true;
          } else {
            succeeded = true;
          }
          if (succeeded) await _outbox.complete(item.id, item.createdAtMs);
        } catch (error) {
          await _outbox.recordFailure(item.id, item.createdAtMs, error);
        }
      }
    } finally {
      _isProcessingPendingQueue = false;
    }
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
          'RevisionSyncService: Failed to initialize SupabaseService: $e',
        );
      }
    }
  }

  /// Pull subjects from Supabase `public.revision_subjects` table.
  Future<List<Subject>> pullSubjects() async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
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
            .eq('user_id', userId)
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
      final pendingDeletes =
          (await _outbox.pendingForAccount(userId, feature: 'revisions'))
              .where(
                (item) =>
                    item.entityType == 'subject' && item.operation == 'delete',
              )
              .map((item) => item.entityId)
              .toSet();
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
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
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
            .eq('user_id', userId)
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
      final pendingDeletes =
          (await _outbox.pendingForAccount(userId, feature: 'revisions'))
              .where(
                (item) =>
                    item.entityType == 'topic' && item.operation == 'delete',
              )
              .map((item) => item.entityId)
              .toSet();
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
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      return false;
    }

    try {
      final userId = _supabaseService.effectiveUserId;
      final row = subject.toSupabaseRow(userId: userId);
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
    await enqueueSubjectDeletion(subjectId);
    await processPendingQueue();
    return !await hasPendingSubject(subjectId);
  }

  /// Pushes a topic to Supabase.
  Future<bool> pushTopic(ChapterTopic topic) async {
    return _pushTopicNow(topic);
  }

  Future<bool> _pushTopicNow(ChapterTopic topic) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline) {
      return false;
    }

    try {
      final userId = _supabaseService.effectiveUserId;
      final row = topic.toSupabaseRow(userId: userId);
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
    if (!_supabaseService.isInitialized ||
        !_supabaseService.isAuthenticated ||
        !NetworkService().isOnline ||
        topics.isEmpty) {
      return false;
    }

    try {
      final userId = _supabaseService.effectiveUserId;
      final rows = topics.map((t) => t.toSupabaseRow(userId: userId)).toList();
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
    await enqueueTopicDeletion(topicId);
    await processPendingQueue();
    return !await hasPendingTopic(topicId);
  }

  void dispose() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
  }
}
