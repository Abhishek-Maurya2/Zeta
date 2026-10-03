import 'package:flutter/material.dart';

import '../../components/m3e_page_transition.dart';
import '../../providers/navigation_provider.dart';
import '../../pages/home_page.dart';
import '../../pages/tasks_page.dart';
import '../../pages/revision_page.dart';
import '../../pages/pomodoro_page.dart';
import '../../pages/bin_page.dart';
import '../../pages/settings_page.dart';
import '../../components/task_edit_pane.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../providers/task_provider.dart';

import 'package:provider/provider.dart';

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
  final M3ESideSheetController _sheetController = M3ESideSheetController();

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
    final isEditPaneOpen = context.select<TaskProvider, bool>(
      (p) => p.isEditPaneOpen,
    );
    if (isEditPaneOpen && !_sheetController.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_sheetController.isOpen) _sheetController.open();
      });
    } else if (!isEditPaneOpen && _sheetController.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetController.isOpen) _sheetController.close();
      });
    }

    final bodyContent = M3EPageTransition(
      currentIndex: _currentIndex,
      previousIndex: _previousIndex,
      transitionType: M3EPageTransitionType.sharedAxisX,
      duration: const Duration(milliseconds: 580),
      child: _buildPage(widget.activePage),
    );

    return M3ESideSheetLayout(
      controller: _sheetController,
      onOpenChanged: (isOpen) {
        if (!isOpen && isEditPaneOpen) {
          context.read<TaskProvider>().closeEditPane();
        }
      },
      body: bodyContent,
      sheet: M3ESideSheet.standard(
        title: 'Edit Task',
        showCloseButton: true,
        width: 400,
        scrollable: false,
        body: Consumer<TaskProvider>(
          builder: (context, tp, _) => TaskEditFormContent(
            key: ValueKey(
              '${tp.editingTask?.id ?? 'new_task'}_${tp.editingInitialTitle ?? ''}_${tp.editingInitialDescription ?? ''}',
            ),
            task: tp.editingTask,
            initialTitle: tp.editingInitialTitle,
            initialDescription: tp.editingInitialDescription,
            initialDueDate: tp.editingInitialDueDate,
            initialDueTime: tp.editingInitialDueTime,
            initialHasTime: tp.editingInitialHasTime,
            initialSubtasks: tp.editingInitialSubtasks,
            onClose: () {
              tp.closeEditPane();
            },
          ),
        ),
      ),
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
