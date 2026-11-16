import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/task_edit_pane.dart';
import '../models/task.dart';
import '../pages/bin_page.dart';
import '../pages/home_page.dart';
import '../pages/pomodoro_page.dart';
import '../pages/settings_page.dart';
import '../pages/space_page.dart';
import '../pages/tasks_page.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';

/// Master plan URL route path definitions for Zeta.
abstract final class AppRoutes {
  static const String home = '/';
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:id';
  static const String pomodoro = '/pomodoro';
  static const String pomodoroAmbient = '/pomodoro/ambient';
  static const String space = '/space';
  static const String bin = '/bin';
  static const String settings = '/settings';
  static const String settingsCategory = '/settings/:category';
}

/// Matched route data parsed from a declarative path or deep link.
class AppRouteMatch {
  final String location;
  final Uri uri;
  final PageId pageId;
  final Map<String, String> pathParameters;
  final Map<String, String> queryParameters;

  const AppRouteMatch({
    required this.location,
    required this.uri,
    required this.pageId,
    this.pathParameters = const {},
    this.queryParameters = const {},
  });

  String? get taskId => pathParameters['id'];

  SettingsCategory? get settingsCategory {
    final catName = pathParameters['category'];
    if (catName == null) return null;
    for (final cat in SettingsCategory.values) {
      if (cat.name.toLowerCase() == catName.toLowerCase()) {
        return cat;
      }
    }
    return null;
  }
}

/// Declarative route definition describing a route destination.
class AppRouteDefinition {
  final String path;
  final String name;
  final PageId pageId;
  final Widget Function(BuildContext context, AppRouteMatch match) builder;

  const AppRouteDefinition({
    required this.path,
    required this.name,
    required this.pageId,
    required this.builder,
  });
}

/// Declarative application router for Zeta.
///
/// Provides declarative routing structure matching the master plan while preserving
/// 100% backward compatibility with the existing [NavigationProvider], [BodyPane],
/// and [AppScaffold] architecture.
class AppRouter {
  AppRouter._();
  static final AppRouter instance = AppRouter._();

  static final List<AppRouteDefinition> routes = [
    AppRouteDefinition(
      path: AppRoutes.home,
      name: 'home',
      pageId: PageId.home,
      builder: (context, match) => const HomePage(),
    ),
    AppRouteDefinition(
      path: AppRoutes.tasks,
      name: 'tasks',
      pageId: PageId.tasks,
      builder: (context, match) => const TasksPage(),
    ),
    AppRouteDefinition(
      path: AppRoutes.taskDetail,
      name: 'taskDetail',
      pageId: PageId.tasks,
      builder: (context, match) => const TasksPage(),
    ),
    AppRouteDefinition(
      path: AppRoutes.pomodoro,
      name: 'pomodoro',
      pageId: PageId.pomodoro,
      builder: (context, match) => const PomodoroPage(),
    ),
    AppRouteDefinition(
      path: AppRoutes.space,
      name: 'space',
      pageId: PageId.space,
      builder: (context, match) => const SpacePage(),
    ),
    AppRouteDefinition(
      path: AppRoutes.bin,
      name: 'bin',
      pageId: PageId.bin,
      builder: (context, match) => const BinPage(),
    ),
    AppRouteDefinition(
      path: AppRoutes.settings,
      name: 'settings',
      pageId: PageId.settings,
      builder: (context, match) => const SettingsPage(),
    ),
    AppRouteDefinition(
      path: AppRoutes.settingsCategory,
      name: 'settingsCategory',
      pageId: PageId.settings,
      builder: (context, match) => const SettingsPage(),
    ),
  ];

  /// Parses a location string into a structured [AppRouteMatch].
  static AppRouteMatch parseLocation(String location) {
    final uri = Uri.parse(location.isEmpty ? AppRoutes.home : location);
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return AppRouteMatch(
        location: AppRoutes.home,
        uri: uri,
        pageId: PageId.home,
        queryParameters: uri.queryParameters,
      );
    }

    final root = segments.first.toLowerCase();

    switch (root) {
      case 'tasks':
        if (segments.length > 1) {
          return AppRouteMatch(
            location: location,
            uri: uri,
            pageId: PageId.tasks,
            pathParameters: {'id': segments[1]},
            queryParameters: uri.queryParameters,
          );
        }
        return AppRouteMatch(
          location: AppRoutes.tasks,
          uri: uri,
          pageId: PageId.tasks,
          queryParameters: uri.queryParameters,
        );

      case 'pomodoro':
        return AppRouteMatch(
          location: AppRoutes.pomodoro,
          uri: uri,
          pageId: PageId.pomodoro,
          queryParameters: uri.queryParameters,
        );

      case 'space':
        return AppRouteMatch(
          location: AppRoutes.space,
          uri: uri,
          pageId: PageId.space,
          queryParameters: uri.queryParameters,
        );

      case 'bin':
        return AppRouteMatch(
          location: AppRoutes.bin,
          uri: uri,
          pageId: PageId.bin,
          queryParameters: uri.queryParameters,
        );

      case 'settings':
        if (segments.length > 1) {
          return AppRouteMatch(
            location: location,
            uri: uri,
            pageId: PageId.settings,
            pathParameters: {'category': segments[1]},
            queryParameters: uri.queryParameters,
          );
        }
        return AppRouteMatch(
          location: AppRoutes.settings,
          uri: uri,
          pageId: PageId.settings,
          queryParameters: uri.queryParameters,
        );

      default:
        return AppRouteMatch(
          location: AppRoutes.home,
          uri: uri,
          pageId: PageId.home,
          queryParameters: uri.queryParameters,
        );
    }
  }

  /// Declarative navigation method replacing the current active route.
  static void go(BuildContext context, String location, {Object? extra}) {
    final match = parseLocation(location);
    final nav = context.read<NavigationProvider>();

    if (match.pageId == PageId.settings) {
      final category = match.settingsCategory;
      nav.pushPage(PageId.settings, category: category);
    } else {
      nav.setActivePage(match.pageId);
    }

    final taskId = match.taskId;
    if (taskId != null) {
      _handleOpenTaskById(context, taskId);
    }
  }

  /// Declarative navigation method pushing onto the navigation stack.
  static void push(BuildContext context, String location, {Object? extra}) {
    final match = parseLocation(location);
    final nav = context.read<NavigationProvider>();

    if (match.pageId == PageId.settings) {
      final category = match.settingsCategory;
      nav.pushPage(PageId.settings, category: category);
    } else {
      nav.pushPage(match.pageId);
    }

    final taskId = match.taskId;
    if (taskId != null) {
      _handleOpenTaskById(context, taskId);
    }
  }

  /// Pops the current route or Settings section.
  static bool pop(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    if (nav.canPop) {
      return nav.pop();
    }
    return Navigator.of(context).maybePop() as bool? ?? false;
  }

  /// Navigates directly to a target [PageId].
  static void goToPage(BuildContext context, PageId page) {
    context.read<NavigationProvider>().setActivePage(page);
  }

  /// Opens the task edit pane / modal bottom sheet for a given [task] or [taskId].
  static void openTask(BuildContext context, {Task? task, String? taskId}) {
    final nav = context.read<NavigationProvider>();
    if (nav.activePage != PageId.tasks) {
      nav.setActivePage(PageId.tasks);
    }

    if (task != null) {
      TaskEditPane.show(context, task: task);
    } else if (taskId != null) {
      _handleOpenTaskById(context, taskId);
    } else {
      TaskEditPane.show(context);
    }
  }

  /// Opens the settings page to a specific [SettingsCategory].
  static void openSettingsCategory(
    BuildContext context,
    SettingsCategory category,
  ) {
    final nav = context.read<NavigationProvider>();
    nav.pushPage(PageId.settings, category: category);
  }

  static void _handleOpenTaskById(BuildContext context, String taskId) {
    try {
      final taskProvider = context.read<TaskProvider>();
      Task? foundTask;
      for (final t in taskProvider.allTasks) {
        if (t.id == taskId) {
          foundTask = t;
          break;
        }
      }
      TaskEditPane.show(context, task: foundTask);
    } catch (_) {
      TaskEditPane.show(context);
    }
  }

  // Path generator helpers
  static String homePath() => AppRoutes.home;
  static String tasksPath() => AppRoutes.tasks;
  static String taskDetailPath(String id) => '/tasks/$id';
  static String pomodoroPath() => AppRoutes.pomodoro;
  static String spacePath() => AppRoutes.space;
  static String binPath() => AppRoutes.bin;
  static String settingsPath([SettingsCategory? category]) =>
      category == null ? AppRoutes.settings : '/settings/${category.name}';
}

/// Declarative context extensions for ergonomic navigation calls.
extension AppRouterExtension on BuildContext {
  void go(String location, {Object? extra}) =>
      AppRouter.go(this, location, extra: extra);

  void pushNamedRoute(String location, {Object? extra}) =>
      AppRouter.push(this, location, extra: extra);

  bool popRoute() => AppRouter.pop(this);
}

/// Standard Flutter RouteInformationParser supporting declarative URLs.
class AppRouteInformationParser extends RouteInformationParser<AppRouteMatch> {
  const AppRouteInformationParser();

  @override
  Future<AppRouteMatch> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return AppRouter.parseLocation(routeInformation.uri.toString());
  }

  @override
  RouteInformation? restoreRouteInformation(AppRouteMatch configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}
