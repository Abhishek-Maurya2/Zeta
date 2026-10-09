import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'components/top_bar_brand.dart';
import 'components/top_bar_search.dart';
import 'components/top_bar_avatar.dart';
import '../theme/breakpoints.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/haptics.dart';

class TopAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBarWidget({super.key});

  @override
  State<TopAppBarWidget> createState() => TopAppBarWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class TopAppBarWidgetState extends State<TopAppBarWidget> {
  late final M3ESearchController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = M3ESearchController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void openSearch() {
    if (_searchController.isAttached && !_searchController.isOpen) {
      _searchController.openView();
    }
  }

  void closeSearch() {
    if (_searchController.isAttached && _searchController.isOpen) {
      _searchController.closeView(null);
    }
  }

  bool get isSearchOpen =>
      _searchController.isAttached && _searchController.isOpen;

  @override
  Widget build(BuildContext context) {
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final navProvider = context.watch<NavigationProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final isSearchOpenState = _searchController.isAttached && _searchController.isOpen;
    if (!isSearchOpenState && _searchController.text != taskProvider.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentlyOpen = _searchController.isAttached && _searchController.isOpen;
        if (!currentlyOpen && _searchController.text != taskProvider.searchQuery) {
          _searchController.text = taskProvider.searchQuery;
        }
      });
    }

    return M3EAppBar.search(
      searchController: _searchController,
      barHintText: isCompact ? 'Search' : 'Search Tasks, Notes, Subjects',
      variant: M3EAppBarVariant.small,
      hideMode: M3EAppBarHideMode.actions,
      hideOnScroll: isCompact,
      density: M3EAppBarDensity.regular,
      shapeFamily: M3EAppBarShapeFamily.round,
      centerTitle: true,
      wrapActions: false,
      safeArea: true,
      leading: const TopBarBrand(),
      actions: const [TopBarAvatar()],
      barLeading: isCompact
          ? null
          : const Icon(M3EIcons.search, fontWeight: FontWeight.bold),
      onSubmitted: (query) {
        final trimmed = query.trim();
        if (trimmed.isNotEmpty) {
          taskProvider.setSearchQuery(trimmed);
          navProvider.setActivePage(PageId.tasks);
          if (_searchController.isAttached && _searchController.isOpen) {
            _searchController.closeView(trimmed);
          }
        }
      },
      barTrailing: [
        if (taskProvider.searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
          Tooltip(
            message: 'Clear search',
            child: M3EIconButton(
              variant: M3EIconButtonVariant.standard,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                ZetaHaptics.light();
                _searchController.clear();
                taskProvider.clearSearchQuery();
              },
            ),
          ),
        if (!isCompact && taskProvider.searchQuery.isEmpty && _searchController.text.isEmpty)
          Tooltip(
            message: 'Press / to search',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '/',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'RobotoMono',
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: Icon(
            fontWeight: FontWeight.bold,
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () {
            ZetaHaptics.light();
            themeProvider.toggleTheme(isDark);
          },
        ),
      ],
      suggestionsBuilder: (context, controller) {
        return TopBarSearch.buildSuggestions(
          context,
          controller,
          navProvider,
          taskProvider,
          textTheme,
          colorScheme,
        );
      },
    );
  }
}
