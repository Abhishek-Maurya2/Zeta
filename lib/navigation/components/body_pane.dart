import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
import '../../pages/home_page.dart';
import '../../pages/tasks_page.dart';
import '../../pages/revision_page.dart';
import '../../pages/pomodoro_page.dart';
import '../../pages/bin_page.dart';
import '../../pages/settings_page.dart';

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
    if (key is! ValueKey<PageId>) return;

    final navigation = context.read<NavigationProvider>();
    if (navigation.activePage == key.value && navigation.canPop) {
      navigation.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageStack = context.watch<NavigationProvider>().pageStack;
    final pageSurfaceColor = Theme.of(context).scaffoldBackgroundColor;

    // For predictive back, Android only reveals the immediate previous route underneath the top route.
    // Mounting only the top 2 routes in the Navigator keeps predictive back working smoothly
    // while preventing the entire multi-page navigation history from living in RAM and continuously rebuilding.
    final visiblePages = pageStack.length > 2
        ? pageStack.sublist(pageStack.length - 2)
        : pageStack;

    return NavigatorPopHandler<void>(
      enabled: !backHandledByScaffold,
      onPopWithResult: (_) {
        if (backHandledByScaffold) return;
        navigatorKey.currentState?.pop();
      },
      child: Navigator(
        key: navigatorKey,
        pages: [
          for (final page in visiblePages)
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
      case PageId.revision:
        return const RevisionPage();
      case PageId.pomodoro:
        return const PomodoroPage();
      case PageId.bin:
        return const BinPage();
      case PageId.settings:
        return const SettingsPage();
    }
  }
}
