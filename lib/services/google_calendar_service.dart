import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/tasks/v1.dart' as gtasks;
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../utils/task_date_formatter.dart';
import 'supabase_service.dart';

/// Represents a subtask item update pulled from Google Tasks.
class GoogleSubtaskUpdate {
  final String parentGoogleTaskId;
  final Subtask subtask;

  GoogleSubtaskUpdate({
    required this.parentGoogleTaskId,
    required this.subtask,
  });
}

/// Result of pulling remote tasks from Google Tasks API.
class GoogleTasksSyncResult {
  final List<Task> remoteTasks;
  final List<GoogleSubtaskUpdate> remoteSubtasks;
  final List<String> deletedTaskIds;
  final DateTime syncTimestamp;
  final bool isFullSync;

  GoogleTasksSyncResult({
    required this.remoteTasks,
    this.remoteSubtasks = const [],
    required this.deletedTaskIds,
    required this.syncTimestamp,
    this.isFullSync = false,
  });
}

/// Custom HTTP client injecting OAuth Bearer token into headers.
class _OAuthHttpClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _OAuthHttpClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Service managing synchronization with Google Calendar and Google Tasks APIs.
class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final SupabaseService _supabase = SupabaseService();

  // Token cache
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _calendarId;
  String? _clientId;
  String? _clientSecret;
  String? _accountEmail;
  bool _syncCalendarEnabled = true;
  bool _syncTasksEnabled = true;
  bool _isLoaded = false;

  bool get syncCalendarEnabled => _syncCalendarEnabled;
  bool get syncTasksEnabled => _syncTasksEnabled;
  String? get accountEmail => _accountEmail;
  bool get isConnected => _accessToken != null || _refreshToken != null;

  /// Loads token credentials from `public.google_sync_tokens` in Supabase.
  Future<void> loadTokens({bool forceReload = false}) async {
    if (_isLoaded && !forceReload) return;
    if (!_supabase.isInitialized) return;

    try {
      final userId = _supabase.effectiveUserId;
      var row = await _supabase.client
          .from('google_sync_tokens')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // If no row for effectiveUserId (e.g. unauthenticated), fallback to singleton row
      if (row == null && userId != 'singleton') {
        row = await _supabase.client
            .from('google_sync_tokens')
            .select()
            .eq('user_id', 'singleton')
            .maybeSingle();
      }

      if (row != null) {
        _accessToken = row['access_token'] as String?;
        _refreshToken = row['refresh_token'] as String?;
        if (row['access_token_expires_at'] != null) {
          _expiresAt = DateTime.tryParse(
            row['access_token_expires_at'].toString(),
          );
        }
        _calendarId = (row['calendar_id'] as String?)?.isNotEmpty == true
            ? row['calendar_id'] as String
            : 'primary';
        _clientId = row['client_id'] as String? ?? '834983932254-nphb7j3vaegpnpcsn5d97dbblhrsj14f.apps.googleusercontent.com';
        _clientSecret =
            row['client_secret'] as String? ??
            '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';
        _accountEmail = row['account_email'] as String?;
        _syncCalendarEnabled = row['sync_calendar_enabled'] as bool? ?? true;
        _syncTasksEnabled = row['sync_tasks_enabled'] as bool? ?? true;
        _isLoaded = true;

        debugPrint(
          'GoogleCalendarService: Loaded tokens for ${_accountEmail ?? userId}',
        );
      }
    } catch (e) {
      debugPrint('GoogleCalendarService: Error loading tokens - $e');
    }
  }

  /// Ensures an active, non-expired access token is available.
  Future<String?> _getValidAccessToken() async {
    await loadTokens();

    if (_accessToken == null && _refreshToken == null) {
      return null;
    }

    // Check if current token is valid (with 3-minute grace period)
    final now = DateTime.now();
    if (_accessToken != null &&
        _expiresAt != null &&
        _expiresAt!.isAfter(now.add(const Duration(minutes: 3)))) {
      return _accessToken;
    }

    // Attempt refresh if refresh_token and client credentials are present
    if (_refreshToken != null && _clientId != null && _clientSecret != null) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _accessToken;
      }
    }

    return _accessToken;
  }

  /// Exchanges the refresh token for a fresh access token at Google's OAuth endpoint.
  Future<bool> _refreshAccessToken() async {
    try {
      debugPrint(
        'GoogleCalendarService: Refreshing Google OAuth access token...',
      );
      final response = await http
          .post(
            Uri.parse('https://oauth2.googleapis.com/token'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'client_id': _clientId,
              'client_secret': _clientSecret,
              'refresh_token': _refreshToken,
              'grant_type': 'refresh_token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        final newExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        _accessToken = newAccessToken;
        _expiresAt = newExpiresAt;

        // Persist back to Supabase
        final userId = _supabase.effectiveUserId;
        try {
          await _supabase.client.from('google_sync_tokens').upsert({
            'user_id': userId,
            'access_token': newAccessToken,
            'access_token_expires_at': newExpiresAt.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          debugPrint(
            'GoogleCalendarService: Warning updating refreshed token in DB: $e',
          );
        }

        debugPrint(
          'GoogleCalendarService: Token refreshed successfully (expires in ${expiresIn}s)',
        );
        return true;
      } else {
        debugPrint(
          'GoogleCalendarService: Failed to refresh token. HTTP ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('GoogleCalendarService: Exception during token refresh - $e');
      return false;
    }
  }

  /// Sync a Zeta task to Google Calendar — disabled per user request (Google Tasks only).
  Future<String?> syncTaskToCalendar(Task task) async {
    return null;
  }

  /// Delete a Google Calendar event — disabled per user request.
  Future<void> deleteCalendarEvent(String eventId) async {
    // No-op: Calendar sync removed
  }

  /// Sync a Zeta task to Google Tasks.
  /// Subtasks are natively synchronized as Google Tasks child tasks via the `parent` API parameter.
  /// Notes/descriptions strictly store user description only without appending subtasks or due dates.
  /// Returns the Google Tasks item ID if synced, or null.
  Future<String?> syncTaskToGoogleTasks(Task task) async {
    if (!_syncTasksEnabled) return null;
    if (task.title.trim().isEmpty) return null;

    final token = await _getValidAccessToken();
    if (token == null) return null;

    // If task is deleted, remove from Google Tasks (Google Tasks cascades deletion to child tasks)
    if (task.deletedAt != null) {
      if (task.googleTaskId != null) {
        await deleteGoogleTask(task.googleTaskId!);
      }
      return null;
    }

    final client = _OAuthHttpClient(token);
    try {
      final tasksApi = gtasks.TasksApi(client);

      final cleanNotes = Task.sanitizeDescription(task.description);
      final gtask = gtasks.Task();
      gtask.title = task.title.trim();
      // In Google Tasks API, to overwrite/clear any legacy description containing subtask text,
      // explicitly pass empty string '' if cleanNotes is null or empty.
      gtask.notes = cleanNotes ?? '';
      gtask.status = task.completed ? 'completed' : 'needsAction';

      if (task.dueDate != null && task.dueDate!.trim().isNotEmpty) {
        gtask.due = formatTaskDueForGoogleTasks(task);
      }

      String parentTaskId;
      if (task.googleTaskId != null && task.googleTaskId!.isNotEmpty) {
        try {
          final updated = await tasksApi.tasks.patch(
            gtask,
            '@default',
            task.googleTaskId!,
          );
          parentTaskId = updated.id ?? task.googleTaskId!;
          debugPrint(
            'GoogleCalendarService: Patched Google Task $parentTaskId for "${task.title}"',
          );
        } on gtasks.DetailedApiRequestError catch (e) {
          if (e.status != 404) rethrow;
          final created = await tasksApi.tasks.insert(gtask, '@default');
          parentTaskId = created.id!;
          debugPrint(
            'GoogleCalendarService: Re-created missing Google Task $parentTaskId for "${task.title}"',
          );
        }
      } else {
        final created = await tasksApi.tasks.insert(gtask, '@default');
        parentTaskId = created.id!;
        debugPrint(
          'GoogleCalendarService: Created Google Task $parentTaskId for "${task.title}"',
        );
      }

      task.googleTaskId = parentTaskId;
      task.lastSyncedAt = DateTime.now();

      // ─── Synchronize Subtasks natively with Google Tasks via `parent` parameter ───
      final activeSubtaskGTaskIds = <String>{};

      for (final subtask in task.subtasks) {
        if (subtask.title.trim().isEmpty) continue;
        final subGTask = gtasks.Task();
        subGTask.title = subtask.title.trim();
        subGTask.status = subtask.completed ? 'completed' : 'needsAction';

        if (subtask.googleTaskId != null && subtask.googleTaskId!.isNotEmpty) {
          try {
            final updatedSub = await tasksApi.tasks.patch(
              subGTask,
              '@default',
              subtask.googleTaskId!,
            );
            try {
              await tasksApi.tasks.move(
                '@default',
                subtask.googleTaskId!,
                parent: parentTaskId,
              );
            } catch (_) {}

            if (updatedSub.id != null)
              activeSubtaskGTaskIds.add(updatedSub.id!);
          } on gtasks.DetailedApiRequestError catch (e) {
            if (e.status == 404) {
              final createdSub = await tasksApi.tasks.insert(
                subGTask,
                '@default',
                parent: parentTaskId,
              );
              subtask.googleTaskId = createdSub.id;
              if (createdSub.id != null) {
                activeSubtaskGTaskIds.add(createdSub.id!);
                try {
                  await tasksApi.tasks.move(
                    '@default',
                    createdSub.id!,
                    parent: parentTaskId,
                  );
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('GoogleCalendarService: Subtask patch note - $e');
          }
        } else {
          try {
            final createdSub = await tasksApi.tasks.insert(
              subGTask,
              '@default',
              parent: parentTaskId,
            );
            subtask.googleTaskId = createdSub.id;
            if (createdSub.id != null) {
              activeSubtaskGTaskIds.add(createdSub.id!);
              try {
                await tasksApi.tasks.move(
                  '@default',
                  createdSub.id!,
                  parent: parentTaskId,
                );
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('GoogleCalendarService: Subtask insert note - $e');
          }
        }
      }

      return parentTaskId;
    } catch (e) {
      debugPrint(
        'GoogleCalendarService: Failed to sync Google Task for "${task.title}" - $e',
      );
      return null;
    } finally {
      client.close();
    }
  }

  /// Pull all tasks from Google Tasks `@default` tasklist.
  /// If [since] is provided, only retrieves tasks updated since that timestamp.
  /// Returns a [GoogleTasksSyncResult] with top-level tasks, remote subtasks, and deleted IDs.
  Future<GoogleTasksSyncResult?> pullGoogleTasks({DateTime? since}) async {
    if (!_syncTasksEnabled) return null;

    final token = await _getValidAccessToken();
    if (token == null) return null;

    final client = _OAuthHttpClient(token);
    final fetchStart = DateTime.now();
    try {
      final tasksApi = gtasks.TasksApi(client);
      final allItems = <gtasks.Task>[];
      String? pageToken;

      do {
        final taskPage = await tasksApi.tasks.list(
          '@default',
          showCompleted: true,
          showHidden: true,
          showDeleted: true,
          maxResults: 100,
          pageToken: pageToken,
          updatedMin: since?.toUtc().toIso8601String(),
        );

        if (taskPage.items != null) {
          allItems.addAll(taskPage.items!);
        }
        pageToken = taskPage.nextPageToken;
      } while (pageToken != null &&
          pageToken.isNotEmpty &&
          allItems.length < 500);

      debugPrint(
        'GoogleCalendarService: Pulled ${allItems.length} raw Google Tasks items.',
      );

      final topLevelItems = <gtasks.Task>[];
      final subtasksByParentId = <String, List<gtasks.Task>>{};
      final deletedTaskIds = <String>[];

      for (final item in allItems) {
        if (item.id == null) continue;
        if (item.deleted == true) {
          deletedTaskIds.add(item.id!);
          continue; // NEVER treat deleted items as active tasks
        }
        // NOTE: Do NOT ignore item.hidden == true! In Google Tasks API, completed
        // subtasks (and cleared completed tasks) are marked with hidden: true.
        // Skipping hidden items caused completed subtasks to be completely dropped.
        final itemTitle = item.title?.trim() ?? '';
        if (itemTitle.isEmpty) {
          continue; // NEVER process empty-titled tasks
        }
        if (item.parent != null && item.parent!.isNotEmpty) {
          subtasksByParentId.putIfAbsent(item.parent!, () => []).add(item);
        } else {
          topLevelItems.add(item);
        }
      }

      final List<GoogleSubtaskUpdate> parsedSubtasks = [];
      subtasksByParentId.forEach((parentId, rawList) {
        for (final s in rawList) {
          if (s.deleted != true && (s.title?.trim().isNotEmpty ?? false)) {
            parsedSubtasks.add(
              GoogleSubtaskUpdate(
                parentGoogleTaskId: parentId,
                subtask: Subtask(
                  id: s.id ?? const Uuid().v4(),
                  title: s.title!.trim(),
                  completed: s.status == 'completed',
                  googleTaskId: s.id,
                ),
              ),
            );
          }
        }
      });

      final List<Task> parsedTasks = [];

      for (final gtask in topLevelItems) {
        final title = gtask.title?.trim() ?? '';
        if (title.isEmpty) continue;
        final dueInfo = parseGoogleTaskDue(gtask.due);
        final rawSubtasks = subtasksByParentId[gtask.id] ?? [];

        final subtasks = rawSubtasks
            .where(
              (s) => s.deleted != true && (s.title?.trim().isNotEmpty ?? false),
            )
            .map((s) {
              return Subtask(
                id: s.id ?? const Uuid().v4(),
                title: s.title!.trim(),
                completed: s.status == 'completed',
                googleTaskId: s.id,
              );
            })
            .toList();

        final updatedDt = gtask.updated != null
            ? DateTime.tryParse(gtask.updated!)?.toLocal()
            : null;

        final task = Task(
          id: const Uuid().v4(),
          title: title,
          description: (gtask.notes != null && gtask.notes!.trim().isNotEmpty)
              ? gtask.notes!.trim()
              : null,
          completed: gtask.status == 'completed',
          dueDate: dueInfo.dueDate,
          hasTime: dueInfo.hasTime,
          dueTime: dueInfo.dueTime,
          subtasks: subtasks,
          googleTaskId: gtask.id,
          googleEtag: gtask.etag,
          createdAt: updatedDt ?? DateTime.now(),
          updatedAt: updatedDt ?? DateTime.now(),
          deletedAt: null,
          lastSyncedAt: DateTime.now(),
        );

        parsedTasks.add(task);
      }

      return GoogleTasksSyncResult(
        remoteTasks: parsedTasks,
        remoteSubtasks: parsedSubtasks,
        deletedTaskIds: deletedTaskIds,
        syncTimestamp: fetchStart.subtract(const Duration(seconds: 5)),
        isFullSync: since == null,
      );
    } catch (e) {
      debugPrint('GoogleCalendarService: pullGoogleTasks failed - $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Delete a Google Task item.
  Future<void> deleteGoogleTask(String googleTaskId) async {
    final token = await _getValidAccessToken();
    if (token == null) return;

    final client = _OAuthHttpClient(token);
    try {
      final tasksApi = gtasks.TasksApi(client);
      await tasksApi.tasks.delete('@default', googleTaskId);
      debugPrint('GoogleCalendarService: Deleted Google Task $googleTaskId');
    } catch (e) {
      debugPrint('GoogleCalendarService: deleteGoogleTask note - $e');
    } finally {
      client.close();
    }
  }

  /// Update sync preferences for Calendar and Tasks.
  Future<void> updateSyncPreferences({bool? calendar, bool? tasks}) async {
    if (calendar != null) _syncCalendarEnabled = calendar;
    if (tasks != null) _syncTasksEnabled = tasks;

    if (!_supabase.isInitialized) return;

    try {
      final userId = _supabase.effectiveUserId;
      await _supabase.client.from('google_sync_tokens').upsert({
        'user_id': userId,
        'sync_calendar_enabled': _syncCalendarEnabled,
        'sync_tasks_enabled': _syncTasksEnabled,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint(
        'GoogleCalendarService: Updated sync preferences (Calendar: $_syncCalendarEnabled, Tasks: $_syncTasksEnabled)',
      );
    } catch (e) {
      debugPrint('GoogleCalendarService: Error saving sync preferences - $e');
    }
  }

  /// Parses a Google Tasks RFC 3339 `due` string into Zeta's dueDate.
  ///
  /// Google Tasks API explicitly does NOT support time — the `due` field is
  /// date-only. Any time component is always stripped by Google's servers.
  /// Therefore this method always returns hasTime: false and dueTime: null.
  /// Time is exclusively sourced from the linked Google Calendar event.
  ///
  /// All-day dates are stored as midnight UTC (e.g. `2026-09-15T00:00:00.000Z`).
  /// UTC year/month/day are extracted directly to avoid timezone day-shifting.
  static ({String? dueDate, bool hasTime, String? dueTime}) parseGoogleTaskDue(
    String? dueStr,
  ) {
    if (dueStr == null || dueStr.trim().isEmpty) {
      return (dueDate: null, hasTime: false, dueTime: null);
    }
    try {
      final parsed = DateTime.parse(dueStr.trim());
      // Always use UTC date components — Google Tasks only stores the date.
      final date = DateTime(parsed.year, parsed.month, parsed.day);
      return (
        dueDate: TaskDateFormatter.format(date),
        hasTime: false, // Time is NEVER available from Google Tasks API
        dueTime: null, // Fetch time from Google Calendar event instead
      );
    } catch (_) {
      return (dueDate: null, hasTime: false, dueTime: null);
    }
  }

  /// Formats a Zeta task's dueDate into a date-only RFC 3339 string for the Google Tasks `due` field.
  ///
  /// Google Tasks API only supports dates — time is always discarded by Google's servers.
  /// Time sync is handled exclusively via Google Calendar. This method always produces
  /// a midnight-UTC timestamp representing the date, regardless of whether the task has a time.
  static String? formatTaskDueForGoogleTasks(Task task) {
    if (task.dueDate == null || task.dueDate!.trim().isEmpty) return null;
    final parsedDate = parseTaskDateTime(task);
    if (parsedDate == null) return null;

    // Always date-only: Google Tasks silently strips any time component.
    final year = parsedDate.year.toString().padLeft(4, '0');
    final month = parsedDate.month.toString().padLeft(2, '0');
    final day = parsedDate.day.toString().padLeft(2, '0');
    return '$year-$month-${day}T00:00:00.000Z';
  }

  /// Fetches the start datetime of a Google Calendar event — disabled per user request.
  Future<DateTime?> pullCalendarEventDateTime(String eventId) async {
    return null;
  }

  /// Helper to combine dueDate and dueTime into a local DateTime.
  static DateTime? parseTaskDateTime(Task task) {
    if (task.dueDate == null || task.dueDate!.trim().isEmpty) return null;

    var rawDueDate = task.dueDate!.trim();
    String? extractedTime = task.dueTime?.trim();

    if (rawDueDate.contains('•')) {
      final parts = rawDueDate.split('•');
      rawDueDate = parts[0].trim();
      if ((extractedTime == null || extractedTime.isEmpty) &&
          parts.length > 1) {
        extractedTime = parts[1].trim();
      }
    }

    final baseDate = TaskDateFormatter.parse(rawDueDate);
    if (baseDate == null) return null;

    final hasTime =
        task.hasTime || (extractedTime != null && extractedTime.isNotEmpty);

    if (hasTime && extractedTime != null && extractedTime.isNotEmpty) {
      final timeStr = extractedTime;
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?$',
        caseSensitive: false,
      ).firstMatch(timeStr);

      if (match != null) {
        int h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final s = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        final period = match.group(4)?.toUpperCase();
        if (period == 'PM' && h < 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
        return DateTime(baseDate.year, baseDate.month, baseDate.day, h, m, s);
      }
    }

    return DateTime(baseDate.year, baseDate.month, baseDate.day);
  }
}
