import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/models/update_model.dart';
import 'package:zeta/services/update_service.dart';

void main() {
  group('UpdateAsset Model Tests', () {
    test('parses asset json accurately', () {
      final json = {
        'id': 12345,
        'name': 'zeta-release-v1.1.0.apk',
        'size': 45678900,
        'browser_download_url': 'https://github.com/owner/repo/releases/download/v1.1.0/app.apk',
        'url': 'https://api.github.com/repos/owner/repo/releases/assets/12345',
      };

      final asset = UpdateAsset.fromJson(json);

      expect(asset.id, 12345);
      expect(asset.name, 'zeta-release-v1.1.0.apk');
      expect(asset.extension, 'apk');
      expect(asset.isApk, isTrue);
      expect(asset.isExe, isFalse);
      expect(asset.formattedSize, contains('MB'));
      expect(asset.apiUrl, 'https://api.github.com/repos/owner/repo/releases/assets/12345');
    });

    test('identifies exe extension and setup correctly', () {
      final json = {
        'id': 67890,
        'name': 'zeta-setup.exe',
        'size': 25000000,
        'browser_download_url': 'https://github.com/owner/repo/releases/download/v1.1.0/setup.exe',
        'url': 'https://api.github.com/repos/owner/repo/releases/assets/67890',
      };

      final asset = UpdateAsset.fromJson(json);

      expect(asset.isExe, isTrue);
      expect(asset.isApk, isFalse);
      expect(asset.isZip, isFalse);
      expect(asset.isWindowsSetup, isTrue);
      expect(asset.extension, 'exe');
    });

    test('distinguishes zip archives from executables', () {
      final json = {
        'id': 99999,
        'name': 'zeta-windows-v1.1.0.zip',
        'size': 65000000,
        'browser_download_url': 'https://github.com/owner/repo/releases/download/v1.1.0/zeta.zip',
        'url': 'https://api.github.com/repos/owner/repo/releases/assets/99999',
      };

      final asset = UpdateAsset.fromJson(json);

      expect(asset.isZip, isTrue);
      expect(asset.isExe, isFalse);
      expect(asset.isWindowsSetup, isFalse);
      expect(asset.extension, 'zip');
    });
  });

  group('AppUpdateInfo Version Comparison Tests', () {
    test('detects when newer semantic version is available', () {
      const update = AppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        tagName: 'v1.0.1',
        releaseNotes: 'Bug fixes',
      );

      expect(update.isUpdateAvailable, isTrue);
    });

    test('detects up to date when versions match', () {
      const update = AppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        tagName: 'v1.0.0',
        releaseNotes: 'Current version',
      );

      expect(update.isUpdateAvailable, isFalse);
    });

    test('detects up to date when current version is higher (development build)', () {
      const update = AppUpdateInfo(
        currentVersion: '1.1.0',
        latestVersion: '1.0.9',
        tagName: 'v1.0.9',
        releaseNotes: 'Previous version',
      );

      expect(update.isUpdateAvailable, isFalse);
    });

    test('correctly handles build number comparisons', () {
      const update1 = AppUpdateInfo(
        currentVersion: '1.0.0+1',
        latestVersion: '1.0.0+2',
        tagName: 'v1.0.0+2',
        releaseNotes: 'Build increment',
      );
      expect(update1.isUpdateAvailable, isTrue);

      const update2 = AppUpdateInfo(
        currentVersion: '1.0.0+3',
        latestVersion: '1.0.0+2',
        tagName: 'v1.0.0+2',
        releaseNotes: 'Build increment',
      );
      expect(update2.isUpdateAvailable, isFalse);
    });

    test('handles leading v in version strings gracefully', () {
      const update = AppUpdateInfo(
        currentVersion: 'v1.0.0',
        latestVersion: 'v1.2.0',
        tagName: 'v1.2.0',
        releaseNotes: 'Major feature',
      );

      expect(update.isUpdateAvailable, isTrue);
    });
  });

  group('DownloadProgress Formatting Tests', () {
    test('formats speed in KB/s and MB/s appropriately', () {
      const p1 = DownloadProgress(
        progress: 0.25,
        speedKbps: 512,
        receivedBytes: 1048576,
        totalBytes: 4194304,
      );
      expect(p1.speedText, '512 KB/s');
      expect(p1.transferredText, '1.0 MB / 4.0 MB');

      const p2 = DownloadProgress(
        progress: 0.75,
        speedKbps: 2048,
        receivedBytes: 3145728,
        totalBytes: 4194304,
      );
      expect(p2.speedText, '2.0 MB/s');
    });
  });

  group('Release Parsing and Windows EXE Prioritization Tests', () {
    test('prioritizes zeta-setup.exe over zeta-windows.zip', () {
      final releaseJson = {
        'tag_name': 'v1.2.0',
        'body': 'Release notes for 1.2.0',
        'published_at': '2026-09-14T10:00:00Z',
        'assets': [
          {
            'id': 1,
            'name': 'zeta-windows-1.2.0.zip',
            'size': 60000000,
            'browser_download_url': 'https://github.com/Abhishek-Maurya2/Zeta/releases/download/v1.2.0/zeta-windows-1.2.0.zip',
            'url': 'https://api.github.com/repos/Abhishek-Maurya2/Zeta/releases/assets/1',
          },
          {
            'id': 2,
            'name': 'zeta-setup-1.2.0.exe',
            'size': 25000000,
            'browser_download_url': 'https://github.com/Abhishek-Maurya2/Zeta/releases/download/v1.2.0/zeta-setup-1.2.0.exe',
            'url': 'https://api.github.com/repos/Abhishek-Maurya2/Zeta/releases/assets/2',
          },
          {
            'id': 3,
            'name': 'zeta-1.2.0.apk',
            'size': 30000000,
            'browser_download_url': 'https://github.com/Abhishek-Maurya2/Zeta/releases/download/v1.2.0/zeta-1.2.0.apk',
            'url': 'https://api.github.com/repos/Abhishek-Maurya2/Zeta/releases/assets/3',
          },
        ],
      };

      final service = UpdateService();
      final info = service.parseReleaseData(releaseJson, '1.0.0');

      expect(info.exeAsset, isNotNull);
      expect(info.exeAsset!.name, 'zeta-setup-1.2.0.exe');
      expect(info.exeAsset!.isExe, isTrue);
      expect(info.exeAsset!.isWindowsSetup, isTrue);
      expect(info.apkAsset, isNotNull);
      expect(info.apkAsset!.name, 'zeta-1.2.0.apk');
    });

    test('ignores zip files and returns null exeAsset when no exe exists', () {
      final releaseJson = {
        'tag_name': 'v1.2.0',
        'body': 'Notes',
        'assets': [
          {
            'id': 1,
            'name': 'zeta-windows-1.2.0.zip',
            'size': 60000000,
            'browser_download_url': 'https://github.com/Abhishek-Maurya2/Zeta/releases/download/v1.2.0/zeta-windows-1.2.0.zip',
            'url': 'https://api.github.com/repos/Abhishek-Maurya2/Zeta/releases/assets/1',
          },
        ],
      };

      final service = UpdateService();
      final info = service.parseReleaseData(releaseJson, '1.0.0');

      expect(info.exeAsset, isNull);
    });

    test('prioritizes setup installer exe over generic exe when both exist', () {
      final releaseJson = {
        'tag_name': 'v1.2.0',
        'body': 'Notes',
        'assets': [
          {
            'id': 1,
            'name': 'zeta.exe',
            'size': 20000000,
            'browser_download_url': 'https://github.com/Abhishek-Maurya2/Zeta/releases/download/v1.2.0/zeta.exe',
            'url': 'https://api.github.com/repos/Abhishek-Maurya2/Zeta/releases/assets/1',
          },
          {
            'id': 2,
            'name': 'Zeta-v1.2.0-Windows-Setup.exe',
            'size': 25000000,
            'browser_download_url': 'https://github.com/Abhishek-Maurya2/Zeta/releases/download/v1.2.0/Zeta-v1.2.0-Windows-Setup.exe',
            'url': 'https://api.github.com/repos/Abhishek-Maurya2/Zeta/releases/assets/2',
          },
        ],
      };

      final service = UpdateService();
      final info = service.parseReleaseData(releaseJson, '1.0.0');

      expect(info.exeAsset, isNotNull);
      expect(info.exeAsset!.name, 'Zeta-v1.2.0-Windows-Setup.exe');
      expect(info.exeAsset!.isWindowsSetup, isTrue);
    });
  });
}
