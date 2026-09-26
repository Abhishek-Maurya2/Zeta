import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/attachment.dart';

class AttachmentParserService {
  AttachmentParserService._();
  static final AttachmentParserService instance = AttachmentParserService._();

  static const _uuid = Uuid();

  static final RegExp _youtubeRegex = RegExp(
    r'(?:youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );

  static final RegExp _driveRegex = RegExp(
    r'drive\.google\.com\/(?:'
    r'file\/d\/([a-zA-Z0-9_-]+)'
    r'|open\?id=([a-zA-Z0-9_-]+)'
    r'|document\/d\/([a-zA-Z0-9_-]+)'
    r'|spreadsheets\/d\/([a-zA-Z0-9_-]+)'
    r'|presentation\/d\/([a-zA-Z0-9_-]+)'
    r'|folders\/([a-zA-Z0-9_-]+)'
    r')',
    caseSensitive: false,
  );

  /// Cleans the input and prepends https:// if scheme is missing.
  String cleanUrl(String raw) {
    var url = raw.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  /// Parses a URL and produces an [AttachmentItem] with metadata.
  Future<AttachmentItem> parseUrl(String rawUrl, {String? customTitle}) async {
    final url = cleanUrl(rawUrl);
    final id = _uuid.v4();

    // 1. YouTube Detection
    final ytMatch = _youtubeRegex.firstMatch(url);
    if (ytMatch != null) {
      final videoId = ytMatch.group(1)!;
      String title = customTitle?.trim() ?? '';
      if (title.isEmpty) {
        title = await _fetchYouTubeTitle(url) ?? 'YouTube Video';
      }
      return AttachmentItem(
        id: id,
        url: url,
        title: title,
        type: AttachmentType.youtube,
        videoId: videoId,
      );
    }

    // 2. Google Drive Detection
    final driveMatch = _driveRegex.firstMatch(url);
    if (driveMatch != null || url.contains('drive.google.com') || url.contains('docs.google.com')) {
      final driveType = _detectDriveType(url);
      final defaultTitle = switch (driveType) {
        GoogleDriveType.document => 'Google Doc',
        GoogleDriveType.spreadsheets => 'Google Sheet',
        GoogleDriveType.presentation => 'Google Slides',
        GoogleDriveType.folder => 'Google Drive Folder',
        GoogleDriveType.genericFile => 'Google Drive File',
      };
      return AttachmentItem(
        id: id,
        url: url,
        title: (customTitle?.trim().isNotEmpty == true) ? customTitle!.trim() : defaultTitle,
        type: AttachmentType.googleDrive,
        driveType: driveType.toDbString(),
      );
    }

    // 3. Generic Link
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {}

    final host = uri?.host ?? 'Web Link';
    final favicon = host.isNotEmpty ? 'https://www.google.com/s2/favicons?domain=$host&sz=64' : null;

    String title = customTitle?.trim() ?? '';
    if (title.isEmpty) {
      title = await _fetchPageTitle(url) ?? _readableHost(host);
    }

    return AttachmentItem(
      id: id,
      url: url,
      title: title,
      type: AttachmentType.link,
      faviconUrl: favicon,
    );
  }

  /// Synchronously classifies the type of URL (YouTube, Google Drive, or Web Link).
  static AttachmentType detectType(String rawUrl) {
    final url = rawUrl.trim();
    if (_youtubeRegex.hasMatch(url)) {
      return AttachmentType.youtube;
    }
    if (_driveRegex.hasMatch(url) || url.contains('drive.google.com') || url.contains('docs.google.com')) {
      return AttachmentType.googleDrive;
    }
    return AttachmentType.link;
  }

  /// Synchronously classifies the Google Drive resource type.
  static GoogleDriveType detectGoogleDriveType(String rawUrl) {
    final lower = rawUrl.toLowerCase();
    if (lower.contains('/document/')) return GoogleDriveType.document;
    if (lower.contains('/spreadsheets/')) return GoogleDriveType.spreadsheets;
    if (lower.contains('/presentation/')) return GoogleDriveType.presentation;
    if (lower.contains('/folders/')) return GoogleDriveType.folder;
    return GoogleDriveType.genericFile;
  }

  GoogleDriveType _detectDriveType(String url) => detectGoogleDriveType(url);

  Future<String?> _fetchYouTubeTitle(String url) async {
    try {
      final oEmbedUrl = Uri.parse('https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json');
      final res = await http.get(oEmbedUrl).timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['title'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchPageTitle(String url) async {
    if (kIsWeb) return null; // Avoid CORS failure on Web
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final body = res.body;
        // Try og:title first
        final ogMatch = RegExp(r'''<meta\s+property=["']og:title["']\s+content=["'](.*?)["']''', caseSensitive: false)
            .firstMatch(body);
        if (ogMatch != null && ogMatch.group(1)?.trim().isNotEmpty == true) {
          return _cleanHtmlEntities(ogMatch.group(1)!.trim());
        }

        // Try standard <title>
        final titleMatch = RegExp(r'''<title>(.*?)</title>''', caseSensitive: false, dotAll: true)
            .firstMatch(body);
        if (titleMatch != null && titleMatch.group(1)?.trim().isNotEmpty == true) {
          return _cleanHtmlEntities(titleMatch.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' '));
        }
      }
    } catch (_) {}
    return null;
  }

  String _cleanHtmlEntities(String raw) {
    return raw
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  String _readableHost(String host) {
    var h = host;
    if (h.startsWith('www.')) h = h.substring(4);
    if (h.isEmpty) return 'Web Link';
    final parts = h.split('.');
    if (parts.isNotEmpty) {
      final name = parts[0];
      if (name.isNotEmpty) {
        return name[0].toUpperCase() + name.substring(1);
      }
    }
    return h;
  }
}
