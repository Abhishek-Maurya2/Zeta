import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeta/features/navigation/presentation/state/navigation_providers.dart';
import 'package:zeta/features/settings/presentation/state/settings_split_pane_provider.dart';
import 'package:zeta/pages/settings/components/settings_category.dart';
import 'package:zeta/providers/navigation_provider.dart';

void main() {
  group('Riverpod NavigationNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial navigation state has home and no category', () {
      final state = container.read(navigationNotifierProvider);
      expect(state.activePage, equals(PageId.home));
      expect(state.pageStack, equals([PageId.home]));
      expect(state.selectedSettingsCategory, isNull);
      expect(state.canPop, isFalse);
    });

    test('pushPage and pop work declaratively for settings categories', () {
      final notifier = container.read(navigationNotifierProvider.notifier);

      notifier.setActivePage(PageId.tasks);
      expect(container.read(activePageProvider), equals(PageId.tasks));

      notifier.pushPage(PageId.settings, category: SettingsCategory.appearance);
      expect(container.read(activePageProvider), equals(PageId.settings));
      expect(
        container.read(selectedSettingsCategoryProvider),
        equals(SettingsCategory.appearance),
      );
      expect(container.read(canPopNavigationProvider), isTrue);

      // Popping from settings category clears category first
      final poppedCategory = notifier.pop();
      expect(poppedCategory, isTrue);
      expect(container.read(activePageProvider), equals(PageId.settings));
      expect(container.read(selectedSettingsCategoryProvider), isNull);

      // Popping from settings returns to Tasks
      final poppedSettings = notifier.pop();
      expect(poppedSettings, isTrue);
      expect(container.read(activePageProvider), equals(PageId.tasks));

      // Popping from Tasks returns to Home
      final poppedTasks = notifier.pop();
      expect(poppedTasks, isTrue);
      expect(container.read(activePageProvider), equals(PageId.home));
      expect(container.read(canPopNavigationProvider), isFalse);
    });
  });

  group('Riverpod SettingsSplitPaneNotifier', () {
    test('SettingsSplitPaneState handles width and collapse smoothly', () {
      const state = SettingsSplitPaneState();
      expect(state.isPaneCollapsed, isFalse);
      expect(state.hasCustomWidth, isFalse);

      final updated = state.copyWith(
        paneWidth: 350.0,
        hasCustomWidth: true,
      );
      expect(updated.paneWidth, equals(350.0));
      expect(updated.hasCustomWidth, isTrue);
    });
  });
}
