import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../pages/bin_page.dart';
import '../../pages/home_page.dart';
import '../../pages/pomodoro_page.dart';
import '../../pages/settings/components/settings_category_detail_screen.dart';
import '../../pages/settings_page.dart';
import '../../pages/space_page.dart';
import '../../pages/tasks_page.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/breakpoints.dart';

/// Hosts destination pages as real routes so Android can preview route pops.
class BodyPane extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final bool backHandledByScaffold;

  const BodyPane({
    super.key,
    required this.navigatorKey,
    this.backHandledByScaffold = false,
  });

  void _handlePageRemoved(BuildContext context, Page<Object?> page) {
    final key = page.key;
    if (key is ValueKey<String> && key.value.startsWith('settings_category_')) {
      final navigation = context.read<NavigationProvider>();
      navigation.clearSettingsCategory();
      return;
    }

    if (key is! ValueKey<PageId>) return;

    final navigation = context.read<NavigationProvider>();
    if (navigation.activePage == key.value && navigation.canPop) {
      navigation.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final pageStack = navProvider.pageStack;
    final selectedCategory = navProvider.selectedSettingsCategory;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isSinglePane = sizeClass.isSinglePane;
    final pageSurfaceColor = Theme.of(context).scaffoldBackgroundColor;
    final effectivePages = pageStack.isEmpty ? const [PageId.home] : pageStack;
    final isSettingsActive =
        effectivePages.isNotEmpty && effectivePages.last == PageId.settings;

    return NavigatorPopHandler<void>(
      enabled: !backHandledByScaffold,
      onPopWithResult: (_) {
        if (backHandledByScaffold) return;
        navigatorKey.currentState?.pop();
      },
      child: Navigator(
        key: navigatorKey,
        pages: [
          for (final page in effectivePages)
            MaterialPage<void>(
              key: ValueKey<PageId>(page),
              // Keep the outgoing page opaque while predictive back reveals
              // the route underneath; page content can contain transparent gaps.
              child: SizedBox.expand(
                child: ColoredBox(
                  color: pageSurfaceColor,
                  child: _buildPage(page),
                ),
              ),
            ),
          if (isSinglePane && isSettingsActive && selectedCategory != null)
            MaterialPage<void>(
              key: ValueKey<String>(
                'settings_category_${selectedCategory.name}',
              ),
              child: SizedBox.expand(
                child: ColoredBox(
                  color: pageSurfaceColor,
                  child: SettingsCategoryDetailScreen(
                    category: selectedCategory,
                  ),
                ),
              ),
            ),
        ],
        onDidRemovePage: (page) => _handlePageRemoved(context, page),
      ),
    );
  }

  Widget _buildPage(PageId page) {
    switch (page) {
      case PageId.home:
        return const HomePage();
      case PageId.tasks:
        return const TasksPage();
      case PageId.pomodoro:
        return const PomodoroPage();
      case PageId.space:
        return const SpacePage();
      case PageId.bin:
        return const BinPage();
      case PageId.settings:
        return const SettingsPage();
    }
  }
}
