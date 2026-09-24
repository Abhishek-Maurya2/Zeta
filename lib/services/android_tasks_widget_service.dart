import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../components/task_edit_pane.dart';
import '../models/task.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/task_date_formatter.dart';

/// Keeps Android's native home-screen widget in sync with Flutter task data.
class AndroidTasksWidgetService {
  AndroidTasksWidgetService._();

  static final AndroidTasksWidgetService instance =
      AndroidTasksWidgetService._();
  static const MethodChannel _channel = MethodChannel('zeta/tasks_widget');

  BuildContext? _context;
  TaskProvider? _taskProvider;
  ThemeProvider? _themeProvider;
  bool _initialized = false;
  bool _publishing = false;
  bool _publishAgain = false;

  Future<void> initialize(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _context = context;
    _taskProvider = context.read<TaskProvider>();
    _themeProvider = context.read<ThemeProvider>();
    if (!_initialized) {
      _initialized = true;
      _taskProvider!.addListener(_onProviderChanged);
      _themeProvider!.addListener(_onProviderChanged);
      _channel.setMethodCallHandler(_handleNativeCall);
    }

    unawaited(_publishWidgetState());
    try {
      final action = await _channel.invokeMapMethod<String, dynamic>(
        'getInitialWidgetAction',
      );
      if (action != null) await _handleWidgetAction(action);
    } on MissingPluginException {
      // The bridge only exists in the Android app build.
    } on PlatformException {
      // Keep the app usable if an older installed build lacks the bridge.
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onWidgetAction' && call.arguments is Map) {
      await _handleWidgetAction(
        Map<String, dynamic>.from(call.arguments as Map),
      );
    }
  }

  void _onProviderChanged() {
    unawaited(_publishWidgetState());
  }

  Future<void> _handleWidgetAction(Map<String, dynamic> action) async {
    final context = _context;
    final taskProvider = _taskProvider;
    if (context == null || !context.mounted || taskProvider == null) return;

    await taskProvider.loadFuture;
    if (!context.mounted) return;

    final actionName = action['action']?.toString();
    final taskId = action['taskId']?.toString();
    if (actionName == 'toggle' && taskId != null && taskId.isNotEmpty) {
      taskProvider.toggleTask(taskId);
      return;
    }

    Task? task;
    if (actionName == 'edit' && taskId != null && taskId.isNotEmpty) {
      for (final candidate in taskProvider.allTasks) {
        if (candidate.id == taskId) {
          task = candidate;
          break;
        }
      }
      if (task == null) return;
    } else if (actionName != 'create') {
      return;
    }

    context.read<NavigationProvider>().setActivePage(PageId.tasks);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    await TaskEditPane.show(context, task: task);
  }

  Future<void> _publishWidgetState() async {
    if (!_initialized) return;
    if (_publishing) {
      _publishAgain = true;
      return;
    }

    _publishing = true;
    try {
      final context = _context;
      final taskProvider = _taskProvider;
      if (context == null || !context.mounted || taskProvider == null) return;
      await taskProvider.loadFuture;
      if (!context.mounted) return;

      final tasks = taskProvider.allTasks.where((task) => !task.completed).toList()
        ..sort(_compareTasksForWidget);
      final taskRows = tasks.map((task) {
        return {
          'id': task.id,
          'title': task.title,
          'due': _formatDue(task),
          'completed': task.completed,
        };
      }).toList();

      final systemSeedValue = await _readDeviceSeedColor();
      final currentScheme = Theme.of(context).colorScheme;
      final seedColor = systemSeedValue == null
          ? (_themeProvider?.useSystemColor == true
                ? currentScheme.primary
                : _themeProvider?.seedColor ?? currentScheme.primary)
          : Color(systemSeedValue);
      final scheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      );
      final payload = <String, Object>{
        'tasks': jsonEncode(taskRows),
        'background': scheme.primary.toARGB32(),
        'foreground': scheme.onPrimary.toARGB32(),
        'accent': scheme.primaryContainer.toARGB32(),
        'accentForeground': scheme.onPrimaryContainer.toARGB32(),
      };
      await _channel.invokeMethod<void>('updateWidget', payload);
    } on MissingPluginException {
      // The bridge only exists in the Android app build.
    } on PlatformException {
      // A widget update failure should not interrupt the app.
    } finally {
      _publishing = false;
      if (_publishAgain) {
        _publishAgain = false;
        unawaited(_publishWidgetState());
      }
    }
  }

  Future<int?> _readDeviceSeedColor() async {
    try {
      return await _channel.invokeMethod<int>('getDeviceSeedColor');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  String _formatDue(Task task) {
    final hasDueDate = task.dueDate?.trim().isNotEmpty == true;
    final dueTime = task.dueTime?.trim();
    final hasDueTime = dueTime?.isNotEmpty == true;
    if (hasDueDate) {
      final date = TaskDateFormatter.formatString(task.dueDate!);
      return hasDueTime ? '$date · $dueTime' : date;
    }
    return hasDueTime ? dueTime! : '';
  }

  int _compareTasksForWidget(Task a, Task b) {
    final aDue = a.dueDate == null ? null : TaskDateFormatter.parse(a.dueDate!);
    final bDue = b.dueDate == null ? null : TaskDateFormatter.parse(b.dueDate!);
    if (aDue != null && bDue != null) {
      final byDue = aDue.compareTo(bDue);
      if (byDue != 0) return byDue;
    } else if (aDue != null) {
      return -1;
    } else if (bDue != null) {
      return 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  void dispose() {
    if (_initialized) {
      _taskProvider?.removeListener(_onProviderChanged);
      _themeProvider?.removeListener(_onProviderChanged);
      _channel.setMethodCallHandler(null);
    }
    _initialized = false;
    _context = null;
    _taskProvider = null;
    _themeProvider = null;
  }
}
