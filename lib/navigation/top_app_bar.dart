import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'components/top_bar_brand.dart';
import 'components/top_bar_search.dart';
import 'components/top_bar_avatar.dart';
import '../theme/breakpoints.dart';

/// Top App Bar mirroring Sharva's header:
/// - Leading: Navigation menu toggle + Sharva logo brand + App name
/// - Center: Material 3 Expressive Search Anchor with search icon, shortcut badge [/], and standard theme switch button in trailing
/// - Trailing: Profile avatar with emerald status ring
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

  /// Opens the search bar — callable via GlobalKey from AppScaffold.
  void openSearch() {
    if (_searchController.isAttached && !_searchController.isOpen) {
      _searchController.openView();
    }
  }

  /// Closes the search bar if open.
  void closeSearch() {
    if (_searchController.isAttached && _searchController.isOpen) {
      _searchController.closeView(null);
    }
  }

  /// Whether the search view is currently open.
  bool get isSearchOpen =>
      _searchController.isAttached && _searchController.isOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: isCompact ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
      ),
      child: Row(
        children: [
          const TopBarBrand(),
          SizedBox(width: isCompact ? 1 : 10),
          TopBarSearch(searchController: _searchController),
          SizedBox(width: isCompact ? 1 : 10),
          const TopBarAvatar(),
        ],
      ),
    );
  }
}
