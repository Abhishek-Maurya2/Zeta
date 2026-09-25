import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/providers/navigation_provider.dart';
import 'package:zeta/services/preferences_service.dart';
import 'package:zeta/services/cross_device_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.instance.init();
  });

  group('Cross-Device Preferences Tests', () {
    test('default preference values are set correctly', () {
      final prefs = PreferencesService.instance;
      expect(prefs.isCrossDeviceEnabled, isTrue);
      expect(prefs.crossDeviceRole, equals('both'));
      expect(prefs.crossDeviceShowToasts, isTrue);
      expect(prefs.crossDeviceCooldownSec, equals(30));
    });

    test('can toggle cross-device settings', () async {
      final prefs = PreferencesService.instance;
      await prefs.setCrossDeviceEnabled(false);
      expect(prefs.isCrossDeviceEnabled, isFalse);

      await prefs.setCrossDeviceRole('send_only');
      expect(prefs.crossDeviceRole, equals('send_only'));

      await prefs.setCrossDeviceShowToasts(false);
      expect(prefs.crossDeviceShowToasts, isFalse);

      await prefs.setCrossDeviceDeviceName('Living Room PC');
      expect(prefs.crossDeviceDeviceName, equals('Living Room PC'));
    });
  });

  group('CrossDeviceResumeEvent & NavigationProvider Tests', () {
    test('parses incoming payload into CrossDeviceResumeEvent correctly', () {
      final payload = {
        'deviceId': 'phone_xyz',
        'deviceName': 'Galaxy S24',
        'platform': 'android',
        'page': 'tasks',
        'itemId': 'task_123',
        'title': 'Math Homework',
        'detail': 'Due tomorrow',
        'timestamp': 1727273570000,
      };

      final event = CrossDeviceResumeEvent.fromMap(payload);
      expect(event.deviceId, equals('phone_xyz'));
      expect(event.deviceName, equals('Galaxy S24'));
      expect(event.platform, equals('android'));
      expect(event.page, equals(PageId.tasks));
      expect(event.itemId, equals('task_123'));
      expect(event.title, equals('Math Homework'));
    });

    test('NavigationProvider.resumeTo correctly switches page and records itemId', () {
      final nav = NavigationProvider();
      expect(nav.activePage, equals(PageId.home));
      expect(nav.resumeItemId, isNull);

      nav.resumeTo(page: PageId.tasks, itemId: 'task_999');
      expect(nav.activePage, equals(PageId.tasks));
      expect(nav.resumeItemId, equals('task_999'));

      nav.clearResumeItemId();
      expect(nav.resumeItemId, isNull);
    });
  });
}
