import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Remote Supabase data source for account profiles and avatar objects.
/// Local persistence and offline retry policy belong to ProfileRepository.
class ProfileService {
  final SupabaseService _supabase;

  ProfileService({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService();

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return _supabase.client
        .from('profiles')
        .select('id, display_name, email, avatar_image, updated_at')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    await _supabase.client.from('profiles').upsert(profile);
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
    required String cacheVersion,
  }) async {
    final safeExtension = _safeExtension(extension);
    final path = '$userId/avatar.$safeExtension';
    await _supabase.client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(safeExtension),
          ),
        );
    final publicUrl = _supabase.client.storage
        .from('avatars')
        .getPublicUrl(path);
    return '$publicUrl?v=$cacheVersion';
  }

  Future<void> removeAvatar(String userId) async {
    await _supabase.client.storage.from('avatars').remove([
      '$userId/avatar.jpg',
      '$userId/avatar.jpeg',
      '$userId/avatar.png',
      '$userId/avatar.webp',
      '$userId/avatar.gif',
    ]);
  }

  String _safeExtension(String extension) {
    final normalized = extension.toLowerCase().replaceAll('.', '');
    return const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(normalized)
        ? normalized
        : 'png';
  }

  String _contentType(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/png',
  };
}
