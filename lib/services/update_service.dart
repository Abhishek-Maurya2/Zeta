import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/update_model.dart';
import 'supabase_service.dart';

/// Service responsible for querying releases, downloading update binaries,
/// and launching platform installers.
///
/// Supports:
/// 1. Private GitHub Repositories (Authenticated API with S3 pre-signed redirect handling).
/// 2. Supabase Edge Function proxy (for token-free client security).
/// 3. Public GitHub Repositories (standard anonymous access).
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String prefKeyGithubToken = 'zeta_update_github_token';
  static const String prefKeyGithubOwner = 'zeta_update_github_owner';
  static const String prefKeyGithubRepo = 'zeta_update_github_repo';
  static const String prefKeyAutoCheck = 'zeta_update_auto_check';
  static const String prefKeyUseSupabaseProxy = 'zeta_update_use_supabase_proxy';

  // Defaults
  static const String defaultOwner = 'Abhishek-Maurya2';
  static const String defaultRepo = 'antimatter';

  // Optional compile-time token injected via --dart-define=GITHUB_UPDATE_TOKEN=...
  static const String _compileTimeToken = String.fromEnvironment('GITHUB_UPDATE_TOKEN');

  String _owner = defaultOwner;
  String _repo = defaultRepo;
  String? _customToken;
  bool _useSupabaseProxy = false;
  bool _autoCheck = true;

  String get owner => _owner;
  String get repo => _repo;
  bool get useSupabaseProxy => _useSupabaseProxy;
  bool get autoCheck => _autoCheck;

  /// Returns the effective GitHub token (custom preference > compile-time define > null).
  String? get effectiveToken {
    if (_customToken != null && _customToken!.trim().isNotEmpty) {
      return _customToken!.trim();
    }
    if (_compileTimeToken.isNotEmpty) {
      return _compileTimeToken;
    }
    return null;
  }

  bool get hasToken => effectiveToken != null && effectiveToken!.isNotEmpty;

  /// Loads configuration from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _owner = prefs.getString(prefKeyGithubOwner) ?? defaultOwner;
      _repo = prefs.getString(prefKeyGithubRepo) ?? defaultRepo;
      _customToken = prefs.getString(prefKeyGithubToken);
      _useSupabaseProxy = prefs.getBool(prefKeyUseSupabaseProxy) ?? false;
      _autoCheck = prefs.getBool(prefKeyAutoCheck) ?? true;
    } catch (e) {
      debugPrint('UpdateService.init warning: $e');
    }
  }

  /// Updates repository settings and persists to storage.
  Future<void> saveSettings({
    String? owner,
    String? repo,
    String? token,
    bool? useSupabaseProxy,
    bool? autoCheck,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (owner != null) {
      _owner = owner.trim();
      await prefs.setString(prefKeyGithubOwner, _owner);
    }
    if (repo != null) {
      _repo = repo.trim();
      await prefs.setString(prefKeyGithubRepo, _repo);
    }
    if (token != null) {
      _customToken = token.trim();
      await prefs.setString(prefKeyGithubToken, _customToken!);
    }
    if (useSupabaseProxy != null) {
      _useSupabaseProxy = useSupabaseProxy;
      await prefs.setBool(prefKeyUseSupabaseProxy, _useSupabaseProxy);
    }
    if (autoCheck != null) {
      _autoCheck = autoCheck;
      await prefs.setBool(prefKeyAutoCheck, _autoCheck);
    }
  }

  /// Resolves the current app's semantic version.
  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        if (info.buildNumber.isNotEmpty) {
          return '${info.version}+${info.buildNumber}';
        }
        return info.version;
      }
    } catch (e) {
      debugPrint('UpdateService.getCurrentVersion failed: $e');
    }
    return '1.0.0+1';
  }

  /// Checks for the latest release from GitHub or Supabase proxy.
  Future<AppUpdateInfo> checkForUpdates() async {
    final currentVersion = await getCurrentVersion();

    if (_useSupabaseProxy) {
      return _checkViaSupabaseProxy(currentVersion);
    } else {
      return _checkViaGitHubApi(currentVersion);
    }
  }

  /// Check updates directly through GitHub API (supports private repos with Bearer token).
  Future<AppUpdateInfo> _checkViaGitHubApi(String currentVersion) async {
    final url = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };

    final token = effectiveToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseReleaseData(data, currentVersion);
    } else if (response.statusCode == 404) {
      if (token == null || token.isEmpty) {
        throw Exception(
          'Release not found (404). If this repository is private, please provide a GitHub Personal Access Token.',
        );
      }
      throw Exception('No releases found for $_owner/$_repo.');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        'GitHub authentication error (${response.statusCode}). Check your token permissions or rate limit.',
      );
    } else {
      throw Exception('Failed to check for updates (HTTP ${response.statusCode})');
    }
  }

  /// Check updates via Supabase Edge Function proxy.
  Future<AppUpdateInfo> _checkViaSupabaseProxy(String currentVersion) async {
    try {
      final client = SupabaseService().client;
      final res = await client.functions.invoke(
        'app-update',
        queryParameters: {'owner': _owner, 'repo': _repo},
      );

      if (res.status == 200 && res.data != null) {
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        return _parseReleaseData(data as Map<String, dynamic>, currentVersion);
      } else {
        throw Exception('Supabase proxy returned status ${res.status}');
      }
    } catch (e) {
      debugPrint('UpdateService Supabase proxy error: $e. Falling back to direct GitHub API.');
      return _checkViaGitHubApi(currentVersion);
    }
  }

  /// Parses GitHub release JSON data into AppUpdateInfo.
  AppUpdateInfo _parseReleaseData(Map<String, dynamic> data, String currentVersion) {
    final rawTag = (data['tag_name'] as String?) ?? '';
    final cleanTag = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
    final versionOnly = cleanTag.split('-build').first;

    final releaseNotes = (data['body'] as String?) ?? 'No release notes provided.';
    final publishedAtStr = data['published_at'] as String?;
    final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

    final assetsRaw = data['assets'] as List<dynamic>? ?? [];
    final assets = assetsRaw
        .whereType<Map<String, dynamic>>()
        .map((j) => UpdateAsset.fromJson(j))
        .toList();

    UpdateAsset? apkAsset;
    UpdateAsset? exeAsset;

    for (final a in assets) {
      if (a.isApk) apkAsset = a;
      if (a.isExe) exeAsset = a;
    }

    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: versionOnly,
      tagName: rawTag,
      releaseNotes: releaseNotes,
      publishedAt: publishedAt,
      assets: assets,
      apkAsset: apkAsset,
      exeAsset: exeAsset,
    );
  }

  /// Downloads the specified asset binary and reports progress.
  ///
  /// Correctly handles GitHub private asset downloads:
  /// Requests the asset API endpoint with `Accept: application/octet-stream`
  /// and `followRedirects: false` to retrieve the short-lived S3 pre-signed URL,
  /// then streams the binary from S3 without credentials.
  Future<String> downloadAsset({
    required UpdateAsset asset,
    required String latestVersion,
    required void Function(DownloadProgress progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;
    final dir = isWindows
        ? (await getDownloadsDirectory() ?? await getTemporaryDirectory())
        : await getTemporaryDirectory();

    final ext = asset.extension.isNotEmpty ? asset.extension : (isWindows ? 'exe' : 'apk');
    final fileName = 'zeta-v$latestVersion.$ext';
    final filePath = '${dir.path}${Platform.pathSeparator}$fileName';

    final dio = Dio();
    String downloadUrl = asset.browserDownloadUrl;
    final token = effectiveToken;

    // For private repositories, resolve the signed download URL from GitHub API
    if (token != null && token.isNotEmpty && asset.apiUrl.isNotEmpty) {
      try {
        final redirectResponse = await dio.get<void>(
          asset.apiUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/octet-stream',
            },
            followRedirects: false,
            validateStatus: (status) => status != null && status >= 200 && status < 400,
          ),
        );

        final location = redirectResponse.headers.value('location');
        if (location != null && location.isNotEmpty) {
          downloadUrl = location;
        }
      } catch (e) {
        debugPrint('UpdateService: Private asset redirection note: $e, using direct downloadUrl');
      }
    }

    final startTime = DateTime.now();

    // Stream download the binary
    await dio.download(
      downloadUrl,
      filePath,
      cancelToken: cancelToken,
      // Do not send GitHub Bearer token to Amazon S3 (it causes 400 Bad Request)
      options: Options(
        headers: downloadUrl.contains('amazonaws.com')
            ? {}
            : (token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {}),
      ),
      onReceiveProgress: (received, total) {
        final elapsedSeconds =
            DateTime.now().difference(startTime).inMilliseconds / 1000.0;
        final speed = elapsedSeconds > 0 ? (received / 1024) / elapsedSeconds : 0.0;
        final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;

        onProgress(
          DownloadProgress(
            progress: progress,
            speedKbps: speed,
            receivedBytes: received,
            totalBytes: total,
          ),
        );
      },
    );

    return filePath;
  }

  /// Launches the installer for the downloaded binary file.
  Future<OpenResult> installUpdate(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Downloaded installer file does not exist at $filePath');
    }

    return OpenFilex.open(filePath);
  }
}
