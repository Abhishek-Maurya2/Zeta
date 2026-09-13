import 'package:flutter/foundation.dart';

/// Represents a downloadable binary asset in a release (e.g. .apk or .exe).
class UpdateAsset {
  final int id;
  final String name;
  final int sizeBytes;
  final String browserDownloadUrl;
  final String apiUrl;
  final String extension;

  const UpdateAsset({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.browserDownloadUrl,
    required this.apiUrl,
    required this.extension,
  });

  factory UpdateAsset.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return UpdateAsset(
      id: json['id'] as int? ?? 0,
      name: name,
      sizeBytes: json['size'] as int? ?? 0,
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      apiUrl: json['url'] as String? ?? '',
      extension: ext,
    );
  }

  bool get isApk => extension == 'apk';
  bool get isExe => extension == 'exe' || extension == 'msix' || extension == 'zip';

  String get formattedSize {
    if (sizeBytes <= 0) return '';
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }
}

/// Information regarding current and latest available application versions.
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String tagName;
  final String releaseNotes;
  final DateTime? publishedAt;
  final List<UpdateAsset> assets;
  final UpdateAsset? apkAsset;
  final UpdateAsset? exeAsset;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tagName,
    required this.releaseNotes,
    this.publishedAt,
    this.assets = const [],
    this.apkAsset,
    this.exeAsset,
  });

  /// Check if the latest version is greater than the current version.
  bool get isUpdateAvailable {
    if (latestVersion.isEmpty || currentVersion.isEmpty) return false;
    return _compareVersions(latestVersion, currentVersion) > 0;
  }

  /// Resolve the asset corresponding to the current platform.
  UpdateAsset? get platformAsset {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return exeAsset;
    }
    return apkAsset;
  }

  /// Semantic version comparator with build number support (e.g. 1.0.0+1).
  static int _compareVersions(String v1, String v2) {
    // Normalise: strip 'v' prefixes
    final clean1 = v1.toLowerCase().replaceFirst('v', '').trim();
    final clean2 = v2.toLowerCase().replaceFirst('v', '').trim();

    final parts1 = clean1.split('+');
    final parts2 = clean2.split('+');

    final semver1 = parts1[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final semver2 = parts2[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (semver1.length < 3) {
      semver1.add(0);
    }
    while (semver2.length < 3) {
      semver2.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (semver1[i] > semver2[i]) return 1;
      if (semver1[i] < semver2[i]) return -1;
    }

    // Compare build numbers if semver numbers are identical
    final build1 = parts1.length > 1 ? (int.tryParse(parts1[1]) ?? 0) : 0;
    final build2 = parts2.length > 1 ? (int.tryParse(parts2[1]) ?? 0) : 0;

    return build1.compareTo(build2);
  }
}

/// Download metrics and state snapshot.
class DownloadProgress {
  final double progress; // 0.0 to 1.0
  final double speedKbps;
  final int receivedBytes;
  final int totalBytes;

  const DownloadProgress({
    required this.progress,
    required this.speedKbps,
    required this.receivedBytes,
    required this.totalBytes,
  });

  String get speedText {
    if (speedKbps > 1024) {
      return '${(speedKbps / 1024).toStringAsFixed(1)} MB/s';
    } else if (speedKbps > 0) {
      return '${speedKbps.toStringAsFixed(0)} KB/s';
    }
    return 'Calculating...';
  }

  String get transferredText {
    final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    if (totalBytes > 0) {
      return '$receivedMb MB / $totalMb MB';
    }
    return '$receivedMb MB';
  }
}
