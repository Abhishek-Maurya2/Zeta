import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis/tasks/v1.dart' as gtasks;
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../utils/task_date_formatter.dart';
import 'supabase_service.dart';

/// Result of pulling remote tasks from Google Tasks API.
class GoogleTasksSyncResult {
  final List<Task> remoteTasks;
  final List<String> deletedTaskIds;
  final DateTime syncTimestamp;

  GoogleTasksSyncResult({
    required this.remoteTasks,
    required this.deletedTaskIds,
    required this.syncTimestamp,
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
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
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
          _expiresAt = DateTime.tryParse(row['access_token_expires_at'].toString());
        }
        _calendarId = (row['calendar_id'] as String?)?.isNotEmpty == true
            ? row['calendar_id'] as String
            : 'primary';
        _clientId = row['client_id'] as String? ??
            '834983932254-nphb7j3vaegpnpcsn5d97dbblhrsj14f.apps.googleusercontent.com';
        _clientSecret = row['client_secret'] as String? ?? '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';
        _accountEmail = row['account_email'] as String?;
        _syncCalendarEnabled = row['sync_calendar_enabled'] as bool? ?? true;
        _syncTasksEnabled = row['sync_tasks_enabled'] as bool? ?? true;
        _isLoaded = true;

        debugPrint('GoogleCalendarService: Loaded tokens for ${_accountEmail ?? userId}');
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
    if (_accessToken != null && _expiresAt != null && _expiresAt!.isAfter(now.add(const Duration(minutes: 3)))) {
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
      debugPrint('GoogleCalendarService: Refreshing Google OAuth access token...');
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': _refreshToken,
          'grant_type': 'refresh_token',
        },
      ).timeout(const Duration(seconds: 15));

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
          debugPrint('GoogleCalendarService: Warning updating refreshed token in DB: $e');
        }

        debugPrint('GoogleCalendarService: Token refreshed successfully (expires in ${expiresIn}s)');
        return true;
      } else {
        debugPrint('GoogleCalendarService: Failed to refresh token. HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('GoogleCalendarService: Exception during token refresh - $e');
      return false;
    }
  }

  /// Creates a valid base32hex/alphanumeric Google Calendar event ID from Zeta task UUID.
  String _deterministicEventId(String taskId) {
    // Google Calendar event ID requires characters: [a-v0-9] and length 5-1024.
    final clean = taskId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    if (clean.length < 5) {
      return clean.padLeft(16, '0');
    }
    return clean;
  }

  /// Sync a Zeta task to Google Calendar.
  /// Returns the Google Calendar event ID if synced, or null.
  Future<String?> syncTaskToCalendar(Task task) async {
    if (!_syncCalendarEnabled) return null;

    final token = await _getValidAccessToken();
    if (token == null) return null;

    final eventId = task.googleEventId ?? _deterministicEventId(task.id);

    // If task is soft-deleted or has no due date, delete existing event if any
    if (task.deletedAt != null || task.dueDate == null || task.dueDate!.trim().isEmpty) {
      await deleteCalendarEvent(eventId);
      return null;
    }

    final parsedDate = parseTaskDateTime(task);
    if (parsedDate == null) return null;

    final client = _OAuthHttpClient(token);
    try {
      final calendarApi = gcal.CalendarApi(client);
      final calendarId = _calendarId ?? 'primary';

      final hasTime =
          task.hasTime || (task.dueTime != null && task.dueTime!.trim().isNotEmpty);

      final event = gcal.Event();
      event.id = eventId;
      event.summary = task.completed ? '✓ ${task.title}' : task.title;
      event.description = (task.description != null && task.description!.trim().isNotEmpty)
          ? task.description!.trim()
          : null;

      if (hasTime) {
        final startUtc = parsedDate.toUtc();
        final endUtc = parsedDate.add(const Duration(minutes: 30)).toUtc();
        event.start = gcal.EventDateTime(dateTime: startUtc);
        event.end = gcal.EventDateTime(dateTime: endUtc);
      } else {
        final startDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        final endDate = startDate.add(const Duration(days: 1)); // Google Calendar all-day end date is exclusive
        event.start = gcal.EventDateTime(date: startDate);
        event.end = gcal.EventDateTime(date: endDate);
      }

      // Try patching first, if 404 insert
      try {
        await calendarApi.events.patch(event, calendarId, eventId);
        debugPrint('GoogleCalendarService: Patched event $eventId for "${task.title}"');
      } on gcal.DetailedApiRequestError catch (e) {
        if (e.status == 404) {
          await calendarApi.events.insert(event, calendarId);
          debugPrint('GoogleCalendarService: Inserted event $eventId for "${task.title}"');
        } else {
          rethrow;
        }
      }

      return eventId;
    } catch (e) {
      debugPrint('GoogleCalendarService: Failed to sync event for "${task.title}" - $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Delete a Google Calendar event.
  Future<void> deleteCalendarEvent(String eventId) async {
    final token = await _getValidAccessToken();
    if (token == null) return;

    final client = _OAuthHttpClient(token);
    try {
      final calendarApi = gcal.CalendarApi(client);
      final calendarId = _calendarId ?? 'primary';
      await calendarApi.events.delete(calendarId, eventId);
      debugPrint('GoogleCalendarService: Deleted calendar event $eventId');
    } catch (e) {
      // 404 or 410 (already gone) is safe to ignore
      debugPrint('GoogleCalendarService: deleteCalendarEvent note - $e');
    } finally {
      client.close();
    }
  }

  /// Sync a Zeta task to Google Tasks.
  /// Subtasks are natively synchronized as Google Tasks child tasks via the `parent` API parameter.
  /// Notes/descriptions strictly store user description only without appending subtasks or due dates.
  /// Returns the Google Tasks item ID if synced, or null.
  Future<String?> syncTaskToGoogleTasks(Task task) async {
    if (!_syncTasksEnabled) return null;

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
      gtask.title = task.title;
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
          final updated = await tasksApi.tasks.patch(gtask, '@default', task.googleTaskId!);
          parentTaskId = updated.id ?? task.googleTaskId!;
          debugPrint('GoogleCalendarService: Patched Google Task $parentTaskId for "${task.title}"');
        } on gtasks.DetailedApiRequestError catch (e) {
          if (e.status != 404) rethrow;
          final created = await tasksApi.tasks.insert(gtask, '@default');
          parentTaskId = created.id!;
          debugPrint('GoogleCalendarService: Re-created missing Google Task $parentTaskId for "${task.title}"');
        }
      } else {
        final created = await tasksApi.tasks.insert(gtask, '@default');
        parentTaskId = created.id!;
        debugPrint('GoogleCalendarService: Created Google Task $parentTaskId for "${task.title}"');
      }

      task.googleTaskId = parentTaskId;
      task.lastSyncedAt = DateTime.now();

      // ─── Synchronize Subtasks natively with Google Tasks via `parent` parameter ───
      final activeSubtaskGTaskIds = <String>{};

      for (final subtask in task.subtasks) {
        final subGTask = gtasks.Task();
        subGTask.title = subtask.title;
        subGTask.status = subtask.completed ? 'completed' : 'needsAction';

        if (subtask.googleTaskId != null && subtask.googleTaskId!.isNotEmpty) {
          try {
            final updatedSub = await tasksApi.tasks.patch(
              subGTask,
              '@default',
              subtask.googleTaskId!,
            );
            // In Google Tasks API, tasks.patch does NOT set the parent relationship.
            // Move ensures the task is properly parented under parentTaskId as a subtask in Google Tasks.
            try {
              await tasksApi.tasks.move(
                '@default',
                subtask.googleTaskId!,
                parent: parentTaskId,
              );
            } catch (moveErr) {
              debugPrint('GoogleCalendarService: Subtask move note - $moveErr');
            }

            if (updatedSub.id != null) activeSubtaskGTaskIds.add(updatedSub.id!);
            debugPrint('GoogleCalendarService: Patched subtask ${updatedSub.id} for "${subtask.title}"');
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
              debugPrint('GoogleCalendarService: Inserted subtask ${createdSub.id} under parent $parentTaskId');
            } else {
              debugPrint('GoogleCalendarService: Subtask patch error - $e');
            }
          } catch (e) {
            debugPrint('GoogleCalendarService: Subtask patch error - $e');
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
            debugPrint('GoogleCalendarService: Inserted subtask ${createdSub.id} under parent $parentTaskId');
          } catch (e) {
            debugPrint('GoogleCalendarService: Subtask insert error - $e');
          }
        }
      }

      // Clean up remote orphan subtasks in Google Tasks that were deleted in Zeta
      try {
        final existingList = await tasksApi.tasks.list(
          '@default',
          showCompleted: true,
          showHidden: true,
          maxResults: 100,
        );
        if (existingList.items != null) {
          for (final item in existingList.items!) {
            if (item.parent == parentTaskId && item.id != null) {
              if (!activeSubtaskGTaskIds.contains(item.id)) {
                await tasksApi.tasks.delete('@default', item.id!);
                debugPrint('GoogleCalendarService: Deleted orphan Google subtask ${item.id}');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('GoogleCalendarService: Subtask cleanup note - $e');
      }

      return parentTaskId;
    } catch (e) {
      debugPrint('GoogleCalendarService: Failed to sync Google Task for "${task.title}" - $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Pull all tasks from Google Tasks `@default` tasklist.
  /// If [since] is provided, only retrieves tasks updated since that timestamp.
  /// Returns a [GoogleTasksSyncResult] with top-level tasks (including native subtasks) and deleted IDs.
  Future<GoogleTasksSyncResult?> pullGoogleTasks({DateTime? since}) async {
    if (!_syncTasksEnabled) return null;

    final token = await _getValidAccessToken();
    if (token == null) return null;

    final client = _OAuthHttpClient(token);
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
      } while (pageToken != null && pageToken.isNotEmpty && allItems.length < 500);

      debugPrint('GoogleCalendarService: Pulled ${allItems.length} raw Google Tasks items.');

      final topLevelItems = <gtasks.Task>[];
      final subtasksByParentId = <String, List<gtasks.Task>>{};
      final deletedTaskIds = <String>[];

      for (final item in allItems) {
        if (item.id == null) continue;
        if (item.deleted == true) {
          deletedTaskIds.add(item.id!);
        }
        if (item.parent != null && item.parent!.isNotEmpty) {
          subtasksByParentId.putIfAbsent(item.parent!, () => []).add(item);
        } else {
          topLevelItems.add(item);
        }
      }

      final List<Task> parsedTasks = [];

      for (final gtask in topLevelItems) {
        final isDeleted = gtask.deleted == true;
        final dueInfo = parseGoogleTaskDue(gtask.due);
        final rawSubtasks = subtasksByParentId[gtask.id] ?? [];

        final subtasks = rawSubtasks.where((s) => s.deleted != true).map((s) {
          return Subtask(
            id: s.id ?? const Uuid().v4(),
            title: s.title ?? '',
            completed: s.status == 'completed',
            googleTaskId: s.id,
          );
        }).toList();

        final updatedDt = gtask.updated != null
            ? DateTime.tryParse(gtask.updated!)?.toLocal()
            : null;

        final task = Task(
          id: const Uuid().v4(),
          title: gtask.title ?? '',
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
          deletedAt: isDeleted ? (updatedDt ?? DateTime.now()) : null,
          lastSyncedAt: DateTime.now(),
        );

        parsedTasks.add(task);
      }

      return GoogleTasksSyncResult(
        remoteTasks: parsedTasks,
        deletedTaskIds: deletedTaskIds,
        syncTimestamp: DateTime.now(),
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
      debugPrint('GoogleCalendarService: Updated sync preferences (Calendar: $_syncCalendarEnabled, Tasks: $_syncTasksEnabled)');
    } catch (e) {
      debugPrint('GoogleCalendarService: Error saving sync preferences - $e');
    }
  }

  /// Parses a Google Tasks RFC 3339 `due` string into Zeta's (dueDate, hasTime, dueTime).
  ///
  /// Google Tasks stores all-day due dates as midnight UTC (e.g. `2026-09-15T00:00:00.000Z`).
  /// To avoid timezone offset day shifting (e.g. Sept 15 UTC becoming Sept 14 in Western timezones),
  /// all-day dates extract the UTC year, month, and day directly.
  /// If the timestamp contains a non-zero time, it is converted to local time.
  static ({String? dueDate, bool hasTime, String? dueTime}) parseGoogleTaskDue(String? dueStr) {
    if (dueStr == null || dueStr.trim().isEmpty) {
      return (dueDate: null, hasTime: false, dueTime: null);
    }
    try {
      final clean = dueStr.trim();
      final parsed = DateTime.parse(clean);
      final isAllDayUtc = (clean.endsWith('T00:00:00.000Z') || clean.endsWith('T00:00:00Z')) &&
          parsed.hour == 0 &&
          parsed.minute == 0 &&
          parsed.second == 0;

      if (isAllDayUtc) {
        final date = DateTime(parsed.year, parsed.month, parsed.day);
        return (
          dueDate: TaskDateFormatter.format(date),
          hasTime: false,
          dueTime: null,
        );
      } else {
        final local = parsed.toLocal();
        final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
        final period = local.hour >= 12 ? 'PM' : 'AM';
        final minuteStr = local.minute.toString().padLeft(2, '0');
        return (
          dueDate: TaskDateFormatter.format(local),
          hasTime: true,
          dueTime: '${hour.toString().padLeft(2, '0')}:$minuteStr $period',
        );
      }
    } catch (_) {
      return (dueDate: null, hasTime: false, dueTime: null);
    }
  }

  /// Formats a Zeta task's dueDate and dueTime into RFC 3339 for Google Tasks `due` endpoint.
  static String? formatTaskDueForGoogleTasks(Task task) {
    if (task.dueDate == null || task.dueDate!.trim().isEmpty) return null;
    final parsedDate = parseTaskDateTime(task);
    if (parsedDate == null) return null;

    final hasTime = task.hasTime || (task.dueTime != null && task.dueTime!.trim().isNotEmpty);
    if (hasTime) {
      return parsedDate.toUtc().toIso8601String();
    } else {
      final year = parsedDate.year.toString().padLeft(4, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final day = parsedDate.day.toString().padLeft(2, '0');
      return '$year-$month-${day}T00:00:00.000Z';
    }
  }

  /// Helper to combine dueDate and dueTime into a local DateTime.
  static DateTime? parseTaskDateTime(Task task) {
    if (task.dueDate == null || task.dueDate!.trim().isEmpty) return null;

    var rawDueDate = task.dueDate!.trim();
    String? extractedTime = task.dueTime?.trim();

    if (rawDueDate.contains('•')) {
      final parts = rawDueDate.split('•');
      rawDueDate = parts[0].trim();
      if ((extractedTime == null || extractedTime.isEmpty) && parts.length > 1) {
        extractedTime = parts[1].trim();
      }
    }

    final baseDate = TaskDateFormatter.parse(rawDueDate);
    if (baseDate == null) return null;

    final hasTime = task.hasTime || (extractedTime != null && extractedTime.isNotEmpty);

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
