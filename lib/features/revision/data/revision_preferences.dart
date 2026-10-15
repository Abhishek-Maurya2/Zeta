import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_client.dart';

/// Modular preferences for Revision domain.
class RevisionPreferences {
  static const String keyRevisionSettings = 'zeta_revision_settings_v1';

  final PreferencesClient _client;

  RevisionPreferences(this._client);

  Map<String, dynamic> getSettings() {
    final raw = _client.getString(keyRevisionSettings);
    if (raw == null) return const {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _client.setString(keyRevisionSettings, jsonEncode(settings));
  }
}

final revisionPreferencesProvider = Provider<RevisionPreferences>((ref) {
  final client = ref.watch(preferencesClientProvider);
  return RevisionPreferences(client);
});
