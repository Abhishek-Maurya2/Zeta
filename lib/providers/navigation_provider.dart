import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../pages/settings/components/settings_category.dart';

/// Top-level destinations available in the app shell.
enum PageId { home, tasks, revision, pomodoro, bin, settings }

/// Owns the destination route list and the small amount of shell navigation state.
class NavigationProvider extends ChangeNotifier {
  final List<PageId> _pageStack = [PageId.home];
  List<PageId> get pageStack => List.unmodifiable(_pageStack);

  PageId get activePage =>
      _pageStack.isNotEmpty ? _pageStack.last : PageId.home;

  SettingsCategory? _selectedSettingsCategory;
  SettingsCategory? get selectedSettingsCategory => _selectedSettingsCategory;

  bool _isRailExpanded = true;
  bool get isRailExpanded => _isRailExpanded;

  /// Whether a destination route or Settings category can be popped.
  bool get canPop =>
      (activePage == PageId.settings && _selectedSettingsCategory != null) ||
      _pageStack.length > 1;

  void setActivePage(PageId page) {
    if (activePage == page) return;

    if (page == PageId.home) {
      _pageStack.clear();
      _pageStack.add(PageId.home);
    } else {
      _pageStack.remove(page);
      _pageStack.add(page);
    }

    if (page != PageId.settings) {
      _selectedSettingsCategory = null;
    }
    notifyListeners();
  }

  /// Pops the navigation hierarchy:
  /// 1. If inside a Settings category section -> pops to Settings main page.
  /// 2. If on a pushed page (e.g. Settings, Bin, or another destination) ->
  ///    pops back to the page from where it was opened.
  /// Returns true if a pop was handled, false otherwise.
  bool pop() {
    // 1. Pop settings category first
    if (activePage == PageId.settings && _selectedSettingsCategory != null) {
      _selectedSettingsCategory = null;
      notifyListeners();
      return true;
    }

    // 2. Pop page stack
    if (_pageStack.length > 1) {
      _pageStack.removeLast();
      if (activePage != PageId.settings) {
        _selectedSettingsCategory = null;
      }
      notifyListeners();
      return true;
    }

    return false;
  }

  void setSettingsCategory(SettingsCategory? category) {
    if (_selectedSettingsCategory != category) {
      _selectedSettingsCategory = category;
      notifyListeners();
    }
  }

  void clearSettingsCategory() {
    if (_selectedSettingsCategory != null) {
      _selectedSettingsCategory = null;
      notifyListeners();
    }
  }

  void toggleRailExpanded() {
    _isRailExpanded = !_isRailExpanded;
    notifyListeners();
  }

  void setRailExpanded(bool expanded) {
    if (_isRailExpanded != expanded) {
      _isRailExpanded = expanded;
      notifyListeners();
    }
  }

  String? _resumeItemId;
  String? get resumeItemId => _resumeItemId;

  void resumeTo({
    required PageId page,
    String? itemId,
    SettingsCategory? category,
  }) {
    if (page == PageId.home) {
      _pageStack.clear();
      _pageStack.add(PageId.home);
    } else {
      _pageStack.remove(page);
      _pageStack.add(page);
    }
    _selectedSettingsCategory = category;
    _resumeItemId = itemId;
    notifyListeners();
  }

  void clearResumeItemId() {
    if (_resumeItemId != null) {
      _resumeItemId = null;
      notifyListeners();
    }
  }
}

/// Navigation destination data used by both NavigationRail and BottomNavBar.
class NavDestination {
  final PageId id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<NavDestination> kNavDestinations = [
  NavDestination(
    id: PageId.home,
    label: 'Home',
    icon: Symbols.home_app_logo_rounded,
    selectedIcon: Symbols.home_app_logo_rounded,
  ),
  NavDestination(
    id: PageId.tasks,
    label: 'Tasks',
    icon: Symbols.checklist_rounded,
    selectedIcon: Symbols.task_alt_rounded,
  ),
  NavDestination(
    id: PageId.revision,
    label: 'Subjects',
    icon: Symbols.book_5_rounded,
    selectedIcon: Symbols.menu_book_rounded,
  ),
  NavDestination(
    id: PageId.pomodoro,
    label: 'Pomodoro',
    icon: Symbols.timer_play_rounded,
    selectedIcon: Symbols.timer_rounded,
  ),
  NavDestination(
    id: PageId.bin,
    label: 'Bin',
    icon: Symbols.delete_outline_rounded,
    selectedIcon: Symbols.delete_rounded,
  ),
  NavDestination(
    id: PageId.settings,
    label: 'Settings',
    icon: Symbols.settings_rounded,
    selectedIcon: Symbols.settings_rounded,
  ),
];
