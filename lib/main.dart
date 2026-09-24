import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as flutter_localizations;
import 'package:material_ui/material_ui.dart';
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
import 'navigation/app_scaffold.dart';
import 'pages/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/network_service.dart';
import 'services/preferences_service.dart';
import 'database/database_provider.dart';
import 'database/migration_service.dart';
import 'services/quick_actions_service.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/auth_gate.dart';

bool get _isTestMode =>
    WidgetsBinding.instance.runtimeType.toString().contains('Test');

void main([List<String> args = const <String>[]]) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    unawaited(BrowserContextMenu.disableContextMenu());
  }
  if (args.isNotEmpty) {
    QuickActionsService.instance.setInitialArgs(args);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Initialize preferences & local SQLite database
  await PreferencesService.instance.init();
  DatabaseProvider.instance.init();

  // Await the one-time SharedPreferences → SQLite migration.
  // This ensures data is in SQLite BEFORE any provider reads from the DB.
  // On subsequent launches this is a near-instant no-op (flag already set).
  await MigrationService(DatabaseProvider.instance.db).runIfNeeded();

  // Asynchronously initialize services without blocking the initial frame
  unawaited(NetworkService().checkConnectivity());
  unawaited(NotificationService.instance.init());
  runApp(const ZetaApp());
}

class ZetaApp extends StatelessWidget {
  final bool? showSplash;

  const ZetaApp({super.key, this.showSplash});

  @override
  Widget build(BuildContext context) {
    final effectiveShowSplash = showSplash ?? !_isTestMode;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(
          create: (ctx) =>
              ThemeProvider(weatherProvider: ctx.read<WeatherProvider>()),
        ),
      ],
      child: _ZetaAppShell(showSplash: effectiveShowSplash),
    );
  }
}

class _ZetaAppShell extends StatelessWidget {
  final bool showSplash;

  const _ZetaAppShell({required this.showSplash});

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
          title: 'Zeta',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          localizationsDelegates: const [
            flutter_localizations.GlobalMaterialLocalizations.delegate,
            flutter_localizations.GlobalWidgetsLocalizations.delegate,
            flutter_localizations.GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScaleFactor)),
              child: child ?? const SizedBox.shrink(),
            );
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
          home: ZetaAppRoot(showSplash: showSplash),
        );
      },
    );
  }
}

/// Root widget hosting the underlying [AuthGate] / [AppScaffold] and the animated [SplashScreen] overlay.
/// When the splash finishes its exit animation, it dissolves cleanly with zero frame drop.
class ZetaAppRoot extends StatefulWidget {
  final bool showSplash;

  const ZetaAppRoot({super.key, this.showSplash = true});

  @override
  State<ZetaAppRoot> createState() => _ZetaAppRootState();
}

class _ZetaAppRootState extends State<ZetaAppRoot> {
  static bool _hasCompletedInitialSplash = false;
  late bool _displaySplash;

  @override
  void initState() {
    super.initState();
    _displaySplash = widget.showSplash && !_hasCompletedInitialSplash;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AuthGate(
          authenticatedBuilder: (_) => const _AuthenticatedApp(),
          bypassAuth: _isTestMode,
        ),
        if (_displaySplash)
          SplashScreen(
            onInitializationComplete: () {
              _hasCompletedInitialSplash = true;
              if (mounted) {
                setState(() {
                  _displaySplash = false;
                });
              }
            },
          ),
      ],
    );
  }
}

class _AuthenticatedApp extends StatelessWidget {
  const _AuthenticatedApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
      child: const AppScaffold(),
    );
  }
}
