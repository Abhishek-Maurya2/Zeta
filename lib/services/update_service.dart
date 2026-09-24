import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/update_model.dart';
import 'supabase_service.dart';
import 'preferences_service.dart';

/// Service responsible for querying releases, downloading update binaries,
/// and launching platform installers.
///
/// Release metadata and binaries are obtained from the Supabase Edge Function.

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String prefKeyGithubOwner = 'zeta_update_github_owner';
  static const String prefKeyGithubRepo = 'zeta_update_github_repo';
  static const String prefKeyAutoCheck = 'zeta_update_auto_check';

  // Defaults
  static const String defaultOwner = 'Abhishek-Maurya2';
  static const String defaultRepo = 'Zeta';

  String _owner = defaultOwner;
  String _repo = defaultRepo;
  bool _autoCheck = true;

  String get owner => _owner;
  String get repo => _repo;
  bool get autoCheck => _autoCheck;

  /// Loads non-secret updater settings. The GitHub token stays server-side.
  Future<void> init() async {
    try {
      final prefs = PreferencesService.instance;
      _owner = prefs.getString(prefKeyGithubOwner) ?? defaultOwner;
      _repo = prefs.getString(prefKeyGithubRepo) ?? defaultRepo;
      _autoCheck = prefs.getBool(prefKeyAutoCheck) ?? true;
      // Remove tokens saved by older clients; private credentials now remain
      // in Supabase and are consumed only by the server-side updater.
      await prefs.remove('zeta_update_github_token');
    } catch (e) {
      debugPrint('UpdateService.init warning: $e');
    }
  }

  /// Updates repository settings and persists to storage.
  Future<void> saveSettings({
    String? owner,
    String? repo,
    bool? autoCheck,
  }) async {
    final prefs = PreferencesService.instance;
    if (owner != null) {
      _owner = owner.trim();
      await prefs.setString(prefKeyGithubOwner, _owner);
    }
    if (repo != null) {
      _repo = repo.trim();
      await prefs.setString(prefKeyGithubRepo, _repo);
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
        if (info.buildNumber.isNotEmpty && info.buildNumber != '0') {
          return '${info.version}+${info.buildNumber}';
        }
        return info.version;
      }
    } catch (e) {
      debugPrint('UpdateService.getCurrentVersion failed: $e');
    }
    return '1.0.5+5';
  }

  /// Checks for the latest release from GitHub or Supabase proxy.
  Future<AppUpdateInfo> checkForUpdates() async {
    final currentVersion = await getCurrentVersion();

    return _checkViaSupabaseProxy(currentVersion);
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
      debugPrint('UpdateService Supabase proxy error: $e');
      rethrow;
    }
  }

  /// Parses GitHub release JSON data into AppUpdateInfo.
  AppUpdateInfo _parseReleaseData(
    Map<String, dynamic> data,
    String currentVersion,
  ) {
    final rawTag = (data['tag_name'] as String?) ?? '';
    final cleanTag = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
    final versionOnly = cleanTag.split('-build').first;

    final releaseNotes =
        (data['body'] as String?) ?? 'No release notes provided.';
    final publishedAtStr = data['published_at'] as String?;
    final publishedAt = publishedAtStr != null
        ? DateTime.tryParse(publishedAtStr)
        : null;

    final assetsRaw = data['assets'] as List<dynamic>? ?? [];
    final assets = assetsRaw
        .whereType<Map<String, dynamic>>()
        .map((j) => UpdateAsset.fromJson(j))
        .toList();

    UpdateAsset? apkAsset;
    UpdateAsset? exeAsset;

    for (final a in assets) {
      if (a.isApk) {
        apkAsset = a;
        break;
      }
    }

    // Prioritize Windows setup/installer executable (.exe)
    // 1. Look for .exe containing 'setup' or 'install' (e.g. zeta-setup-1.0.1.exe)
    // 2. Fall back to any other .exe asset
    // 3. Fall back to .msix asset if no .exe exists
    // Note: .zip files are explicitly excluded so that the installer setup file is always selected.
    final exeAssets = assets.where((a) => a.isExe).toList();
    if (exeAssets.isNotEmpty) {
      exeAsset = exeAssets.firstWhere(
        (a) => a.isWindowsSetup,
        orElse: () => exeAssets.first,
      );
    } else {
      final msixAssets = assets.where((a) => a.isMsix).toList();
      if (msixAssets.isNotEmpty) {
        exeAsset = msixAssets.first;
      }
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

  @visibleForTesting
  AppUpdateInfo parseReleaseData(
    Map<String, dynamic> data,
    String currentVersion,
  ) => _parseReleaseData(data, currentVersion);

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

    // Use the asset's actual filename if available to preserve setup name (e.g. zeta-setup-1.0.1.exe)
    final String fileName;
    if (asset.name.isNotEmpty) {
      fileName = asset.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    } else {
      final ext = asset.extension.isNotEmpty
          ? asset.extension
          : (isWindows ? 'exe' : 'apk');
      fileName = isWindows
          ? 'zeta-setup-v$latestVersion.$ext'
          : 'zeta-v$latestVersion.$ext';
    }
    String filePath = '${dir.path}${Platform.pathSeparator}$fileName';

    // Remove existing file if present; if locked, generate unique timestamped filename
    final existingFile = File(filePath);
    if (await existingFile.exists()) {
      try {
        await existingFile.delete();
      } catch (e) {
        debugPrint(
          'UpdateService: Target file locked ($e), using unique filename',
        );
        final dotIndex = fileName.lastIndexOf('.');
        final base = dotIndex != -1
            ? fileName.substring(0, dotIndex)
            : fileName;
        final ext = dotIndex != -1 ? fileName.substring(dotIndex) : '';
        filePath =
            '${dir.path}${Platform.pathSeparator}${base}_${DateTime.now().millisecondsSinceEpoch}$ext';
      }
    }

    final dio = Dio();
    String downloadUrl = asset.browserDownloadUrl;
    final supabase = SupabaseService();
    final sessionToken = supabase.currentSession?.accessToken;
    final response = await dio.get<void>(
      '${SupabaseService.supaUrl}/functions/v1/app-update',
      queryParameters: {'owner': _owner, 'repo': _repo, 'asset_id': asset.id},
      options: Options(
        headers: {
          'apikey': SupabaseService.supaAnonKey,
          if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
          'Accept': 'application/octet-stream',
        },
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    final location = response.headers.value('location');
    if (location == null || location.isEmpty) {
      throw Exception('The update proxy did not return a download URL.');
    }
    downloadUrl = location;

    final startTime = DateTime.now();

    // Stream download the binary
    await dio.download(
      downloadUrl,
      filePath,
      cancelToken: cancelToken,
      // Do not send GitHub Bearer token to Amazon S3 (it causes 400 Bad Request)
      options: Options(headers: {}),
      onReceiveProgress: (received, total) {
        final elapsedSeconds =
            DateTime.now().difference(startTime).inMilliseconds / 1000.0;
        final speed = elapsedSeconds > 0
            ? (received / 1024) / elapsedSeconds
            : 0.0;
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

    // On Windows, launch .exe setup files using detached cmd start so that:
    // 1. Windows UAC elevation is prompted if required.
    // 2. The setup wizard runs in an independent process group and remains running
    //    even if Zeta is closed or restarted during installation.
    if (Platform.isWindows && filePath.toLowerCase().endsWith('.exe')) {
      try {
        await Process.start(
          'cmd',
          ['/c', 'start', '', filePath],
          runInShell: false,
          mode: ProcessStartMode.detached,
        );
        return OpenResult(
          type: ResultType.done,
          message: 'Installer launched successfully',
        );
      } catch (e) {
        debugPrint(
          'Windows detached start failed: $e, falling back to OpenFilex',
        );
      }
    }

    return OpenFilex.open(filePath);
  }
}
