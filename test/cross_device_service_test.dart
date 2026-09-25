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

    test('parses incoming payload with rich contextData correctly', () {
      final payload = {
        'deviceId': 'phone_xyz',
        'deviceName': 'Galaxy S24',
        'platform': 'android',
        'page': 'tasks',
        'itemId': 'task_123',
        'title': 'Math Homework',
        'detail': 'Due tomorrow',
        'contextData': {
          'taskDraft': {
            'title': 'Math Homework',
            'description': 'Page 42 questions 1-10',
            'dueDate': 'Tomorrow',
            'dueTime': '05:00 PM',
            'hasTime': true,
            'subtasks': ['Q1', 'Q2'],
            'isCreating': false,
          },
          'settingsCategory': 'crossDevice',
          'pomodoroTab': 'analysis',
        },
        'timestamp': 1727273570000,
      };

      final event = CrossDeviceResumeEvent.fromMap(payload);
      expect(event.contextData, isNotNull);
      expect(event.contextData!['pomodoroTab'], equals('analysis'));
      expect(event.contextData!['settingsCategory'], equals('crossDevice'));

      final draft = event.contextData!['taskDraft'] as Map;
      expect(draft['title'], equals('Math Homework'));
      expect(draft['description'], equals('Page 42 questions 1-10'));
      expect(draft['subtasks'], equals(['Q1', 'Q2']));

      final map = event.toMap();
      expect(map['contextData'], isNotNull);
      expect(map['contextData']['pomodoroTab'], equals('analysis'));
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

    test('Quota Saver activates on inactivity and resets on user activity', () {
      final service = CrossDeviceService.instance;
      service.recordUserActivity();
      expect(service.isQuotaSaverActive.value, isFalse);

      // Simulate quota saver activation
      service.isQuotaSaverActive.value = true;
      expect(service.isQuotaSaverActive.value, isTrue);

      // User activity resets quota saver
      service.recordUserActivity();
      expect(service.isQuotaSaverActive.value, isFalse);
    });
  });
}
