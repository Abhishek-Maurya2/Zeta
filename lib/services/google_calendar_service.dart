import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis/tasks/v1.dart' as gtasks;
import '../models/task.dart';
import '../utils/task_date_formatter.dart';
import 'supabase_service.dart';

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

    final parsedDate = _parseTaskDateTime(task);
    if (parsedDate == null) return null;

    final client = _OAuthHttpClient(token);
    try {
      final calendarApi = gcal.CalendarApi(client);
      final calendarId = _calendarId ?? 'primary';

      // Build event description with subtask checklist
      final descBuffer = StringBuffer();
      if (task.description?.isNotEmpty == true) {
        descBuffer.writeln(task.description);
        descBuffer.writeln();
      }
      if (task.subtasks.isNotEmpty) {
        descBuffer.writeln('Subtasks:');
        for (final sub in task.subtasks) {
          descBuffer.writeln('${sub.completed ? '[x]' : '[ ]'} ${sub.title}');
        }
      }

      final event = gcal.Event();
      event.id = eventId;
      event.summary = task.completed ? '✓ ${task.title}' : task.title;
      event.description = descBuffer.isEmpty ? null : descBuffer.toString().trim();

      if (task.hasTime) {
        final startUtc = parsedDate.toUtc();
        final endUtc = parsedDate.add(const Duration(minutes: 30)).toUtc();
        event.start = gcal.EventDateTime(dateTime: startUtc);
        event.end = gcal.EventDateTime(dateTime: endUtc);
      } else {
        event.start = gcal.EventDateTime(
          date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
        );
        event.end = gcal.EventDateTime(
          date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
        );
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
  /// Returns the Google Tasks item ID if synced, or null.
  Future<String?> syncTaskToGoogleTasks(Task task) async {
    if (!_syncTasksEnabled) return null;

    final token = await _getValidAccessToken();
    if (token == null) return null;

    // If task is deleted, remove from Google Tasks
    if (task.deletedAt != null) {
      if (task.googleTaskId != null) {
        await deleteGoogleTask(task.googleTaskId!);
      }
      return null;
    }

    final client = _OAuthHttpClient(token);
    try {
      final tasksApi = gtasks.TasksApi(client);

      // Build task notes
      final notesBuffer = StringBuffer();
      if (task.description?.isNotEmpty == true) {
        notesBuffer.writeln(task.description);
        notesBuffer.writeln();
      }
      if (task.subtasks.isNotEmpty) {
        notesBuffer.writeln('Subtasks:');
        for (final sub in task.subtasks) {
          notesBuffer.writeln('${sub.completed ? '[x]' : '[ ]'} ${sub.title}');
        }
      }

      final gtask = gtasks.Task();
      gtask.title = task.title;
      gtask.notes = notesBuffer.isEmpty ? null : notesBuffer.toString().trim();
      gtask.status = task.completed ? 'completed' : 'needsAction';

      if (task.dueDate != null && task.dueDate!.trim().isNotEmpty) {
        final parsedDate = _parseTaskDateTime(task);
        if (parsedDate != null) {
          gtask.due = parsedDate.toUtc().toIso8601String();
        }
      }

      if (task.googleTaskId != null && task.googleTaskId!.isNotEmpty) {
        try {
          final updated = await tasksApi.tasks.patch(gtask, '@default', task.googleTaskId!);
          debugPrint('GoogleCalendarService: Patched Google Task ${updated.id} for "${task.title}"');
          return updated.id;
        } on gtasks.DetailedApiRequestError catch (e) {
          if (e.status != 404) rethrow;
          // If 404, fall through to create new task
        }
      }

      final created = await tasksApi.tasks.insert(gtask, '@default');
      debugPrint('GoogleCalendarService: Created Google Task ${created.id} for "${task.title}"');
      return created.id;
    } catch (e) {
      debugPrint('GoogleCalendarService: Failed to sync Google Task for "${task.title}" - $e');
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

  /// Helper to combine dueDate and dueTime into a DateTime.
  DateTime? _parseTaskDateTime(Task task) {
    if (task.dueDate == null || task.dueDate!.trim().isEmpty) return null;
    final baseDate = TaskDateFormatter.parse(task.dueDate!);
    if (baseDate == null) return null;

    if (task.hasTime && task.dueTime != null && task.dueTime!.trim().isNotEmpty) {
      final timeStr = task.dueTime!.trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false).firstMatch(timeStr);
      if (match != null) {
        int h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();
        if (period == 'PM' && h < 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
        return DateTime(baseDate.year, baseDate.month, baseDate.day, h, m);
      }
    }

    return baseDate;
  }
}
