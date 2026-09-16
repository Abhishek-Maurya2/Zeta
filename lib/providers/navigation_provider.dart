import 'package:material_ui/material_ui.dart';
import '../components/settings/settings_category.dart';

/// Page identifiers mirroring Sharva's PageId type.
enum PageId { home, tasks, revision, pomodoro, bin, settings }

/// Mirrors Sharva's useNavigationStore — manages active page, rail state, drawer state, and settings navigation.
class NavigationProvider extends ChangeNotifier {
  PageId _activePage = PageId.home;
  PageId get activePage => _activePage;

  SettingsCategory? _selectedSettingsCategory;
  SettingsCategory? get selectedSettingsCategory => _selectedSettingsCategory;

  bool _isRailExpanded = true;
  bool get isRailExpanded => _isRailExpanded;

  void setActivePage(PageId page) {
    if (_activePage != page) {
      _activePage = page;
      if (page != PageId.settings) {
        _selectedSettingsCategory = null;
      }
      notifyListeners();
    }
  }

  void setSettingsCategory(SettingsCategory? category) {
    _selectedSettingsCategory = category;
    notifyListeners();
  }

  void clearSettingsCategory() {
    _selectedSettingsCategory = null;
    notifyListeners();
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
  NavDestination(id: PageId.home, label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
  NavDestination(id: PageId.tasks, label: 'Tasks', icon: Icons.check_circle_outline, selectedIcon: Icons.check_circle),
  NavDestination(id: PageId.revision, label: 'Revision', icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book),
  NavDestination(id: PageId.pomodoro, label: 'Pomodoro', icon: Icons.timer_outlined, selectedIcon: Icons.timer),
  NavDestination(id: PageId.bin, label: 'Bin', icon: Icons.delete_outline, selectedIcon: Icons.delete),
  NavDestination(id: PageId.settings, label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings),
];
