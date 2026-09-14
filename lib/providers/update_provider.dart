import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

import '../models/update_model.dart';
import '../services/update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  downloaded,
  error,
}

/// Provider managing application update state and downloading workflows.
class UpdateProvider extends ChangeNotifier {
  final UpdateService _service = UpdateService();

  UpdateStatus _status = UpdateStatus.idle;
  AppUpdateInfo? _updateInfo;
  DownloadProgress? _downloadProgress;
  String? _downloadedFilePath;
  String? _errorMessage;
  CancelToken? _cancelToken;
  DateTime? _lastCheckedAt;

  UpdateStatus get status => _status;
  AppUpdateInfo? get updateInfo => _updateInfo;
  DownloadProgress? get downloadProgress => _downloadProgress;
  String? get downloadedFilePath => _downloadedFilePath;
  String? get errorMessage => _errorMessage;
  DateTime? get lastCheckedAt => _lastCheckedAt;

  bool get isChecking => _status == UpdateStatus.checking;
  bool get isDownloading => _status == UpdateStatus.downloading;
  bool get isDownloaded => _status == UpdateStatus.downloaded;
  bool get isUpdateAvailable => _status == UpdateStatus.updateAvailable;
  bool get isUpToDate => _status == UpdateStatus.upToDate;
  bool get hasError => _status == UpdateStatus.error;

  String get owner => _service.owner;
  String get repo => _service.repo;
  bool get hasToken => _service.hasToken;
  String? get token => _service.effectiveToken;
  bool get useSupabaseProxy => _service.useSupabaseProxy;
  bool get autoCheck => _service.autoCheck;

  UpdateProvider() {
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    if (_service.autoCheck) {
      // Delay slightly to allow the app to initialize before checking
      Future.delayed(const Duration(seconds: 2), () {
        checkForUpdates(silent: true);
      });
    }
  }

  /// Checks for available releases.
  Future<void> checkForUpdates({bool silent = false}) async {
    if (_status == UpdateStatus.downloading) return;

    _status = UpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _service.checkForUpdates();
      _updateInfo = info;
      _lastCheckedAt = DateTime.now();

      if (info.isUpdateAvailable) {
        _status = UpdateStatus.updateAvailable;
      } else {
        _status = UpdateStatus.upToDate;
      }
    } catch (e) {
      _lastCheckedAt = DateTime.now();
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (silent) {
        _status = UpdateStatus.idle;
      } else {
        _status = UpdateStatus.error;
      }
    }

    notifyListeners();
  }

  /// Starts downloading the platform binary asset.
  Future<void> startDownload() async {
    final info = _updateInfo;
    if (info == null) return;

    final asset = info.platformAsset;
    if (asset == null) {
      _errorMessage = 'No compatible release asset found for this platform.';
      _status = UpdateStatus.error;
      notifyListeners();
      return;
    }

    _status = UpdateStatus.downloading;
    _downloadProgress = const DownloadProgress(
      progress: 0.0,
      speedKbps: 0.0,
      receivedBytes: 0,
      totalBytes: 0,
    );
    _downloadedFilePath = null;
    _errorMessage = null;
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      final filePath = await _service.downloadAsset(
        asset: asset,
        latestVersion: info.latestVersion,
        cancelToken: _cancelToken,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      _downloadedFilePath = filePath;
      _status = UpdateStatus.downloaded;
      notifyListeners();

      // Automatically launch the package installer
      await install();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _status = UpdateStatus.updateAvailable;
        _downloadProgress = null;
      } else {
        _status = UpdateStatus.error;
        _errorMessage = 'Download failed: ${e.toString().replaceFirst('Exception: ', '')}';
      }
      notifyListeners();
    } finally {
      _cancelToken = null;
    }
  }

  /// Cancels an active download.
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User cancelled download');
    }
  }

  /// Launches the downloaded installer file.
  Future<OpenResult?> install() async {
    final path = _downloadedFilePath;
    if (path == null) return null;

    try {
      final res = await _service.installUpdate(path);
      if (res.type == ResultType.error) {
        _errorMessage = 'Failed to launch installer: ${res.message}';
        notifyListeners();
      }
      return res;
    } catch (e) {
      _errorMessage = 'Failed to launch installer: $e';
      notifyListeners();
      return null;
    }
  }

  /// Updates repository settings.
  Future<void> saveSettings({
    String? owner,
    String? repo,
    String? token,
    bool? useSupabaseProxy,
    bool? autoCheck,
  }) async {
    await _service.saveSettings(
      owner: owner,
      repo: repo,
      token: token,
      useSupabaseProxy: useSupabaseProxy,
      autoCheck: autoCheck,
    );
    notifyListeners();
  }

  /// Clears any current error.
  void clearError() {
    _errorMessage = null;
    if (_status == UpdateStatus.error) {
      _status = _updateInfo?.isUpdateAvailable == true
          ? UpdateStatus.updateAvailable
          : UpdateStatus.idle;
    }
    notifyListeners();
  }
}
