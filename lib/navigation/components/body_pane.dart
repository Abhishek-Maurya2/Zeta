import 'package:flutter/material.dart';
import '../../components/m3e_page_transition.dart';
import '../../providers/navigation_provider.dart';
import '../../pages/home_page.dart';
import '../../pages/tasks_page.dart';
import '../../pages/revision_page.dart';
import '../../pages/pomodoro_page.dart';
import '../../pages/bin_page.dart';
import '../../pages/settings_page.dart';

/// Body router pane that manages animated page transitions between main destinations.
class BodyPane extends StatefulWidget {
  final PageId activePage;
  const BodyPane({super.key, required this.activePage});

  @override
  State<BodyPane> createState() => _BodyPaneState();
}

class _BodyPaneState extends State<BodyPane> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _getPageIndex(widget.activePage);
    _previousIndex = _currentIndex;
  }

  @override
  void didUpdateWidget(covariant BodyPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePage != widget.activePage) {
      setState(() {
        _previousIndex = _getPageIndex(oldWidget.activePage);
        _currentIndex = _getPageIndex(widget.activePage);
      });
    }
  }

  int _getPageIndex(PageId page) {
    final idx = kNavDestinations.indexWhere((d) => d.id == page);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    return M3EPageTransition(
      currentIndex: _currentIndex,
      previousIndex: _previousIndex,
      transitionType: M3EPageTransitionType.sharedAxisX,
      duration: const Duration(milliseconds: 580),
      child: _buildPage(widget.activePage),
    );
  }

  Widget _buildPage(PageId page) {
    switch (page) {
      case PageId.home:
        return const HomePage(key: ValueKey('home'));
      case PageId.tasks:
        return const TasksPage(key: ValueKey('tasks'));
      case PageId.revision:
        return const RevisionPage(key: ValueKey('revision'));
      case PageId.pomodoro:
        return const PomodoroPage(key: ValueKey('pomodoro'));
      case PageId.bin:
        return const BinPage(key: ValueKey('bin'));
      case PageId.settings:
        return const SettingsPage(key: ValueKey('settings'));
    }
  }
}
