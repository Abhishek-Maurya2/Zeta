import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_client.dart';
import '../../../models/pomodoro.dart';

/// Modular preferences for the Pomodoro domain.
class PomodoroPreferences {
  static const String keyPomodoroSettings = 'zeta_pomodoro_settings_v1';
  static const String keyPomodoroState = 'zeta_pomodoro_active_state_v1';

  final PreferencesClient _client;

  PomodoroPreferences(this._client);

  PomodoroSettings getSettings() {
    final raw = _client.getString(keyPomodoroSettings);
    if (raw == null) return const PomodoroSettings();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PomodoroSettings.fromJson(map);
    } catch (_) {
      return const PomodoroSettings();
    }
  }

  Future<void> saveSettings(PomodoroSettings settings) async {
    final raw = jsonEncode(settings.toJson());
    await _client.setString(keyPomodoroSettings, raw);
  }

  Map<String, dynamic>? getSavedActiveState() {
    final raw = _client.getString(keyPomodoroState);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveState(Map<String, dynamic> state) async {
    await _client.setString(keyPomodoroState, jsonEncode(state));
  }

  Future<void> clearActiveState() async {
    await _client.remove(keyPomodoroState);
  }
}

final pomodoroPreferencesProvider = Provider<PomodoroPreferences>((ref) {
  final client = ref.watch(preferencesClientProvider);
  return PomodoroPreferences(client);
});
