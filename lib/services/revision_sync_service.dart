import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/revision.dart';
import 'supabase_service.dart';

/// Service responsible for bi-directional synchronization between local Revision
/// data and Supabase `public.revision_subjects` and `public.revision_topics` tables.
class RevisionSyncService {
  static final RevisionSyncService _instance = RevisionSyncService._internal();
  factory RevisionSyncService() => _instance;
  RevisionSyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _lastError;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

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
    if (!_supabaseService.isInitialized) return [];

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      final response = await _supabaseService.client
          .from('revision_subjects')
          .select()
          .or('user_id.eq.$userId,user_id.eq.singleton')
          .order('created_at', ascending: true);

      final List<Subject> subjects = [];
      for (final row in response as List<dynamic>) {
        try {
          subjects.add(Subject.fromSupabaseRow(row as Map<String, dynamic>));
        } catch (e) {
          debugPrint('RevisionSyncService: Error parsing subject row - $e');
        }
      }
      _lastSyncedAt = DateTime.now();
      return subjects;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('RevisionSyncService: pullSubjects error - $e');
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull topics from Supabase `public.revision_topics` table.
  Future<List<ChapterTopic>> pullTopics() async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized) return [];

    _isSyncing = true;
    _lastError = null;

    try {
      final userId = _supabaseService.effectiveUserId;
      final response = await _supabaseService.client
          .from('revision_topics')
          .select()
          .or('user_id.eq.$userId,user_id.eq.singleton')
          .order('sort_order', ascending: true);

      final List<ChapterTopic> topics = [];
      for (final row in response as List<dynamic>) {
        try {
          topics.add(ChapterTopic.fromSupabaseRow(row as Map<String, dynamic>));
        } catch (e) {
          debugPrint('RevisionSyncService: Error parsing topic row - $e');
        }
      }
      _lastSyncedAt = DateTime.now();
      return topics;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('RevisionSyncService: pullTopics error - $e');
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes a subject to Supabase.
  Future<bool> pushSubject(Subject subject) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized) return false;

    try {
      final userId = _supabaseService.effectiveUserId;
      final row = subject.toSupabaseRow(defaultUserId: userId);
      await _supabaseService.client.from('revision_subjects').upsert(row);
      return true;
    } catch (e) {
      debugPrint('RevisionSyncService: pushSubject error - $e');
      return false;
    }
  }

  /// Deletes a subject and its associated topics from Supabase.
  Future<bool> deleteSubject(String subjectId) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized) return false;

    try {
      await _supabaseService.client
          .from('revision_topics')
          .delete()
          .eq('subject_id', subjectId);
      await _supabaseService.client
          .from('revision_subjects')
          .delete()
          .eq('id', subjectId);
      return true;
    } catch (e) {
      debugPrint('RevisionSyncService: deleteSubject error - $e');
      return false;
    }
  }

  /// Pushes a topic to Supabase.
  Future<bool> pushTopic(ChapterTopic topic) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized) return false;

    try {
      final userId = _supabaseService.effectiveUserId;
      final row = topic.toSupabaseRow(defaultUserId: userId);
      await _supabaseService.client.from('revision_topics').upsert(row);
      return true;
    } catch (e) {
      debugPrint('RevisionSyncService: pushTopic error - $e');
      return false;
    }
  }

  /// Deletes a topic from Supabase.
  Future<bool> deleteTopic(String topicId) async {
    await _ensureInitialized();
    if (!_supabaseService.isInitialized) return false;

    try {
      await _supabaseService.client
          .from('revision_topics')
          .delete()
          .eq('id', topicId);
      return true;
    } catch (e) {
      debugPrint('RevisionSyncService: deleteTopic error - $e');
      return false;
    }
  }
}
