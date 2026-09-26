import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../utils/haptics.dart';
import 'tasks_dismissible_list.dart';

/// Loads 5 completed tasks at a time, loading the next batch of 5
/// when the user reaches the bottom of the list or requests more.
class TasksCompletedPaginatedList extends StatefulWidget {
  final List<Task> tasks;
  final TaskProvider provider;
  final void Function(
    BuildContext context,
    Offset position,
    Task task,
    TaskProvider provider,
  )
  onContextMenu;

  final bool embedded;

  const TasksCompletedPaginatedList({
    super.key,
    required this.tasks,
    required this.provider,
    required this.onContextMenu,
    this.embedded = true,
  });

  @override
  State<TasksCompletedPaginatedList> createState() =>
      _TasksCompletedPaginatedListState();
}

class _TasksCompletedPaginatedListState
    extends State<TasksCompletedPaginatedList> {
  static const int _batchSize = 5;

  int _displayedCount = _batchSize;
  bool _isLoading = false;
  ScrollPosition? _scrollPosition;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    _displayedCount = _batchSize;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (_scrollPosition != newPosition) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(covariant TasksCompletedPaginatedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks.length != oldWidget.tasks.length) {
      if (_displayedCount > widget.tasks.length) {
        _displayedCount = widget.tasks.length
            .clamp(_batchSize, double.infinity)
            .toInt();
        if (_displayedCount > widget.tasks.length) {
          _displayedCount = widget.tasks.length;
        }
      }
    }
  }

  void _onScroll() {
    if (!mounted || _isLoading) return;
    if (_displayedCount >= widget.tasks.length) return;

    final pos = _scrollPosition;
    if (pos == null) return;

    // Trigger when user scrolls near the bottom
    // if (pos.pixels >= pos.maxScrollExtent - 120) {
    //   _loadNextBatch();
    // }
  }

  void _loadNextBatch() {
    if (_isLoading || _displayedCount >= widget.tasks.length) return;
    setState(() {
      _isLoading = true;
    });

    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _displayedCount = (_displayedCount + _batchSize).clamp(
          0,
          widget.tasks.length,
        );
        _isLoading = false;
      });
      ZetaHaptics.light();
    });
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    _loadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = widget.tasks.length;
    final hasMore = totalTasks > _displayedCount;
    final visibleTasks = widget.tasks.take(_displayedCount).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Completed Tasks List ───────────────────────────────────
        TasksDismissibleList(
          tasks: visibleTasks,
          provider: widget.provider,
          onContextMenu: widget.onContextMenu,
          embedded: widget.embedded,
        ),

        // ─── Bottom Loading Trigger / Indicator ─────────────────────
        if (hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: M3ELoadingIndicator(
                      variant: M3ELoadingIndicatorVariant.defaultStyle,
                      elevation: 0,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: M3EIconButton(
                      onPressed: _loadNextBatch,
                      variant: M3EIconButtonVariant.filled,
                      width: M3EIconButtonWidth.wide,
                      icon: const Icon(Icons.expand_more_rounded, size: 25),
                      tooltip: 'Load ${totalTasks - _displayedCount} more',
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}
