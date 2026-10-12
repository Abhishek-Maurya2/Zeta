import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/pages/settings/components/settings_category.dart';
import 'package:zeta/providers/navigation_provider.dart';

void main() {
  group('NavigationProvider stack and back navigation', () {
    late NavigationProvider nav;

    setUp(() {
      nav = NavigationProvider();
    });

    test('initial state starts at home with empty back history', () {
      expect(nav.activePage, equals(PageId.home));
      expect(nav.pageStack, equals([PageId.home]));
      expect(nav.canPop, isFalse);
      expect(nav.pop(), isFalse);
    });

    test('navigating from Tasks to Settings pops back to Tasks, not Home', () {
      // 1. User navigates to Tasks
      nav.setActivePage(PageId.tasks);
      expect(nav.activePage, equals(PageId.tasks));
      expect(nav.pageStack, equals([PageId.home, PageId.tasks]));
      expect(nav.canPop, isTrue);

      // 2. User opens Settings (e.g. from search or profile menu)
      nav.setActivePage(PageId.settings);
      expect(nav.activePage, equals(PageId.settings));
      expect(nav.pageStack, equals([PageId.home, PageId.tasks, PageId.settings]));
      expect(nav.canPop, isTrue);

      // 3. User selects a settings category
      nav.setSettingsCategory(SettingsCategory.appearance);
      expect(nav.selectedSettingsCategory, equals(SettingsCategory.appearance));
      expect(nav.canPop, isTrue);

      // 4. Back in settings category -> returns to Settings root
      final popCategoryResult = nav.pop();
      expect(popCategoryResult, isTrue);
      expect(nav.activePage, equals(PageId.settings));
      expect(nav.selectedSettingsCategory, isNull);
      expect(nav.pageStack, equals([PageId.home, PageId.tasks, PageId.settings]));

      // 5. Back in Settings root -> returns to Tasks (from where settings was opened)
      final popSettingsResult = nav.pop();
      expect(popSettingsResult, isTrue);
      expect(nav.activePage, equals(PageId.tasks));
      expect(nav.pageStack, equals([PageId.home, PageId.tasks]));

      // 6. Back on Tasks -> returns to Home
      final popTasksResult = nav.pop();
      expect(popTasksResult, isTrue);
      expect(nav.activePage, equals(PageId.home));
      expect(nav.pageStack, equals([PageId.home]));
      expect(nav.canPop, isFalse);

      // 7. Back on Home -> cannot pop further (signals app exit)
      expect(nav.pop(), isFalse);
    });

    test('opening settings from weather header directly with category pops to settings then home', () {
      // Opened from Home -> Weather widget
      nav.pushPage(PageId.settings, category: SettingsCategory.weather);
      expect(nav.activePage, equals(PageId.settings));
      expect(nav.selectedSettingsCategory, equals(SettingsCategory.weather));

      // 1st back: pops category -> Settings root
      expect(nav.pop(), isTrue);
      expect(nav.activePage, equals(PageId.settings));
      expect(nav.selectedSettingsCategory, isNull);

      // 2nd back: pops Settings -> Home
      expect(nav.pop(), isTrue);
      expect(nav.activePage, equals(PageId.home));
      expect(nav.canPop, isFalse);
    });

    test('opening settings from Subjects (Revision) pops back to Subjects', () {
      nav.setActivePage(PageId.revision);
      nav.setActivePage(PageId.settings);

      expect(nav.activePage, equals(PageId.settings));
      expect(nav.pop(), isTrue);
      expect(nav.activePage, equals(PageId.revision));
    });

    test('opening settings from Bin pops back to Bin', () {
      nav.setActivePage(PageId.tasks);
      nav.setActivePage(PageId.bin);
      nav.setActivePage(PageId.settings);

      expect(nav.activePage, equals(PageId.settings));
      expect(nav.pop(), isTrue);
      expect(nav.activePage, equals(PageId.bin));
      expect(nav.pop(), isTrue);
      expect(nav.activePage, equals(PageId.tasks));
    });

    test('opening Bin from Tasks pops back to Tasks', () {
      nav.setActivePage(PageId.tasks);
      nav.setActivePage(PageId.bin);

      expect(nav.activePage, equals(PageId.bin));
      expect(nav.pop(), isTrue);
      expect(nav.activePage, equals(PageId.tasks));
    });

    test('navigating back sets isNavigatingBack flag for backward animations', () {
      nav.setActivePage(PageId.tasks);
      expect(nav.isNavigatingBack, isFalse);

      nav.setActivePage(PageId.settings);
      expect(nav.isNavigatingBack, isFalse);

      nav.pop();
      expect(nav.isNavigatingBack, isTrue);
      expect(nav.activePage, equals(PageId.tasks));
    });
  });
}
