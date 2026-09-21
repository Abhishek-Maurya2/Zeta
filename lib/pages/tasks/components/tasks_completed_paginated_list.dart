import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import 'tasks_dismissible_list.dart';

/// Shows only 5 completed tasks initially, displaying [M3ELoadingIndicator]
/// for at least 3 seconds before automatically loading the rest of the completed tasks.
class TasksCompletedPaginatedList extends StatefulWidget {
  final List<Task> tasks;
  final TaskProvider provider;
  final void Function(
    BuildContext context,
    Offset position,
    Task task,
    TaskProvider provider,
  ) onContextMenu;

  const TasksCompletedPaginatedList({
    super.key,
    required this.tasks,
    required this.provider,
    required this.onContextMenu,
  });

  @override
  State<TasksCompletedPaginatedList> createState() =>
      _TasksCompletedPaginatedListState();
}

class _TasksCompletedPaginatedListState
    extends State<TasksCompletedPaginatedList> {
  static const int _initialCount = 5;
  static const Duration _minLoadingDuration = Duration(seconds: 3);

  bool _loadedAll = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoLoad();
  }

  @override
  void didUpdateWidget(covariant TasksCompletedPaginatedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_loadedAll && widget.tasks.length > _initialCount && !_isLoading) {
      _startAutoLoad();
    }
  }

  void _startAutoLoad() {
    if (widget.tasks.length > _initialCount && !_loadedAll && !_isLoading) {
      _isLoading = true;
      _timer?.cancel();
      _timer = Timer(_minLoadingDuration, () {
        if (!mounted) return;
        setState(() {
          _loadedAll = true;
          _isLoading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = widget.tasks.length;
    final hasMore = totalTasks > _initialCount;

    // Show top 5 completed tasks initially, then all once loaded
    final visibleTasks = (_loadedAll || !hasMore)
        ? widget.tasks
        : widget.tasks.take(_initialCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Completed Tasks List ───────────────────────────────────
        TasksDismissibleList(
          tasks: visibleTasks,
          provider: widget.provider,
          onContextMenu: widget.onContextMenu,
        ),

        // ─── Automatic Loading Indicator (Visible for ≥ 3 seconds) ──
        if (hasMore && !_loadedAll) ...[
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: M3ELoadingIndicator(
                variant: M3ELoadingIndicatorVariant.contained,
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
