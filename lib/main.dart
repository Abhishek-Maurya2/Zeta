import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as flutter_localizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/update_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/revision_provider.dart';
import 'theme/app_theme.dart';
import 'utils/app_snackbar.dart';
import 'navigation/app_scaffold.dart';
import 'pages/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/network_service.dart';
import 'services/preferences_service.dart';
import 'database/database_provider.dart';
import 'services/quick_actions_service.dart';
import 'services/windows_tray_service.dart';
import 'services/app_exit_service.dart';
import 'utils/performance_trace.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/auth_gate.dart';

bool get _isTestMode =>
    WidgetsBinding.instance.runtimeType.toString().contains('Test');

void main([List<String> args = const <String>[]]) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppExitService.instance.init();
  if (kIsWeb) {
    unawaited(BrowserContextMenu.disableContextMenu());
  }
  if (args.isNotEmpty) {
    QuickActionsService.instance.setInitialArgs(args);
    if (args.contains('--background')) {
      WindowsTrayService.instance.setInitialTrayState(true);
    }
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Preferences are needed to build the theme. Open SQLite behind the first
  // frame so database setup cannot leave the native launch window blank.
  await traceAsync(
    'startup.preferences',
    () => PreferencesService.instance.init(),
  );
  DatabaseProvider.instance.init();
  final databaseReady = Completer<void>();
  runApp(ProviderScope(child: ZetaApp(databaseReady: databaseReady.future)));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_finishStartup(databaseReady));
  });
}

Future<void> _finishStartup(Completer<void> databaseReady) async {
  unawaited(
    traceAsync(
      'startup.connectivity_check',
      () => NetworkService().checkConnectivity(),
    ),
  );
  unawaited(
    traceAsync(
      'startup.notifications_init',
      () => NotificationService.instance.init(),
    ),
  );

  try {
    await traceAsync(
      'startup.database_open',
      () => DatabaseProvider.instance.db.customSelect('SELECT 1').get(),
    );
  } catch (error, stackTrace) {
    debugPrint('Startup database open error: $error\n$stackTrace');
  } finally {
    if (!databaseReady.isCompleted) databaseReady.complete();
  }
}

class ZetaApp extends StatelessWidget {
  final bool? showSplash;
  final Future<void>? databaseReady;

  const ZetaApp({super.key, this.showSplash, this.databaseReady});

  @override
  Widget build(BuildContext context) {
    final effectiveShowSplash = showSplash ?? !_isTestMode;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(databaseReady: databaseReady),
        ),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(
          create: (ctx) =>
              ThemeProvider(weatherProvider: ctx.read<WeatherProvider>()),
        ),
      ],
      child: _ZetaAppShell(
        showSplash: effectiveShowSplash,
        databaseReady: databaseReady,
      ),
    );
  }
}

class _ZetaAppShell extends StatelessWidget {
  final bool showSplash;
  final Future<void>? databaseReady;

  const _ZetaAppShell({required this.showSplash, required this.databaseReady});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ThemeProvider, ThemeMode>(
      (p) => p.themeMode,
    );
    final useSystemColor = context.select<ThemeProvider, bool>(
      (p) => p.useSystemColor,
    );
    final seedColor = context.select<ThemeProvider, Color>((p) => p.seedColor);
    final variant = context.select<ThemeProvider, M3EColorVariant>(
      (p) => p.variant,
    );
    final cornerStyle = context.select<ThemeProvider, String>(
      (p) => p.cornerStyle,
    );
    final highContrast = context.select<ThemeProvider, bool>(
      (p) => p.highContrast,
    );
    final compactDensity = context.select<ThemeProvider, bool>(
      (p) => p.compactDensity,
    );
    final animations = context.select<ThemeProvider, bool>((p) => p.animations);
    final fontScale = context.select<ThemeProvider, String>((p) => p.fontScale);

    final headings = context.select<ThemeProvider, RoleTypographyConfig>(
      (p) => p.headingsTypography,
    );
    final titles = context.select<ThemeProvider, RoleTypographyConfig>(
      (p) => p.titlesTypography,
    );
    final body = context.select<ThemeProvider, RoleTypographyConfig>(
      (p) => p.bodyTypography,
    );
    final labels = context.select<ThemeProvider, RoleTypographyConfig>(
      (p) => p.labelsTypography,
    );

    final double textScaleFactor = fontScale == 'compact'
        ? 0.92
        : fontScale == 'large'
        ? 1.08
        : 1.0;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final effectiveLightSeed = (useSystemColor && lightDynamic != null)
            ? lightDynamic.primary
            : seedColor;
        final effectiveDarkSeed = (useSystemColor && darkDynamic != null)
            ? darkDynamic.primary
            : effectiveLightSeed;

        return MaterialApp(
          navigatorKey: AppExitService.navigatorKey,
          scaffoldMessengerKey: AppSnackbar.scaffoldMessengerKey,
          title: 'Zeta',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          localizationsDelegates: const [
            flutter_localizations.GlobalMaterialLocalizations.delegate,
            flutter_localizations.GlobalWidgetsLocalizations.delegate,
            flutter_localizations.GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          builder: (context, child) {
            final mediaQuery = MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScaleFactor)),
              child: child ?? const SizedBox.shrink(),
            );
            return _AuthenticatedProvidersWrapper(child: mediaQuery);
          },
          theme: AppTheme.light(
            effectiveLightSeed,
            variant,
            cornerStyle,
            highContrast,
            compactDensity,
            animations,
            headings,
            titles,
            body,
            labels,
          ),
          darkTheme: AppTheme.dark(
            effectiveDarkSeed,
            variant,
            cornerStyle,
            highContrast,
            compactDensity,
            animations,
            headings,
            titles,
            body,
            labels,
          ),
          home: ZetaAppRoot(
            showSplash: showSplash,
            startupReady: databaseReady,
          ),
        );
      },
    );
  }
}

/// Hosts the app and bridges the native launch screen through essential local
/// startup work. Auth restoration continues in the visible app loading state.
class ZetaAppRoot extends StatefulWidget {
  final bool showSplash;
  final Future<void>? startupReady;

  const ZetaAppRoot({super.key, this.showSplash = true, this.startupReady});

  @override
  State<ZetaAppRoot> createState() => _ZetaAppRootState();
}

class _ZetaAppRootState extends State<ZetaAppRoot> {
  static bool _hasCompletedInitialSplash = false;
  late bool _displaySplash;
  bool _startupReady = false;
  bool _isFadingOut = false;

  @override
  void initState() {
    super.initState();
    _displaySplash = widget.showSplash && !_hasCompletedInitialSplash;
    _startupReady = widget.startupReady == null;
    widget.startupReady?.then(
      (_) {
        if (!mounted) return;
        setState(() => _startupReady = true);
        _checkAndTriggerDismissal();
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() => _startupReady = true);
        _checkAndTriggerDismissal();
      },
    );
    if (_startupReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndTriggerDismissal();
      });
    }
  }

  void _checkAndTriggerDismissal() {
    if (!_displaySplash || _isFadingOut) return;
    if (_startupReady) {
      setState(() {
        _isFadingOut = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AuthGate(
          authenticatedBuilder: (_) => const AppScaffold(),
          bypassAuth: _isTestMode,
        ),
        if (_displaySplash)
          AnimatedOpacity(
            opacity: _isFadingOut ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            onEnd: () {
              if (mounted) {
                setState(() {
                  _displaySplash = false;
                  _hasCompletedInitialSplash = true;
                });
              }
            },
            child: IgnorePointer(
              ignoring: _isFadingOut,
              child: const SplashScreen(),
            ),
          ),
      ],
    );
  }
}

class _AuthenticatedProvidersWrapper extends StatelessWidget {
  final Widget child;

  const _AuthenticatedProvidersWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    final userId = context.select<AuthProvider, String?>((a) => a.user?.id);
    final isAuthenticated = _isTestMode || status == AuthStatus.signedIn;

    if (!isAuthenticated) {
      return child;
    }

    return MultiProvider(
      key: ValueKey(userId ?? 'authenticated_session'),
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
        ChangeNotifierProxyProvider<TaskProvider, RevisionProvider>(
          create: (_) => RevisionProvider(),
          update: (_, taskProvider, revProvider) {
            final provider = revProvider ?? RevisionProvider();
            taskProvider.onTaskCompletedCallback = (taskId) {
              provider.syncFromTaskCompletion(taskId, taskProvider);
            };
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<TaskProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, taskProvider, notifProvider) {
            final provider = notifProvider ?? NotificationProvider();
            provider.updateTasks(taskProvider.allTasks);
            return provider;
          },
        ),
      ],
      child: child,
    );
  }
}
