import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/update_provider.dart';
import 'theme/app_theme.dart';
import 'navigation/app_scaffold.dart';
import 'pages/splash_screen.dart';
import 'services/supabase_service.dart';

bool get _isTestMode =>
    WidgetsBinding.instance.runtimeType.toString().contains('Test');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  // Asynchronously initialize Supabase without blocking the initial frame
  unawaited(SupabaseService().init());
  runApp(const ZetaApp());
}

class ZetaApp extends StatelessWidget {
  final bool? showSplash;

  const ZetaApp({
    super.key,
    this.showSplash,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShowSplash = showSplash ?? !_isTestMode;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: _ZetaAppView(showSplash: effectiveShowSplash),
    );
  }
}

class _ZetaAppView extends StatelessWidget {
  final bool showSplash;

  const _ZetaAppView({required this.showSplash});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final double textScaleFactor = themeProvider.fontScale == 'compact'
        ? 0.92
        : themeProvider.fontScale == 'large'
        ? 1.08
        : 1.0;

    return MaterialApp(
      title: 'Zeta',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: AppTheme.light(
        themeProvider.seedColor,
        themeProvider.variant,
        themeProvider.cornerStyle,
        themeProvider.highContrast,
        themeProvider.compactDensity,
        themeProvider.animations,
        themeProvider.headingsTypography,
        themeProvider.titlesTypography,
        themeProvider.bodyTypography,
        themeProvider.labelsTypography,
      ),
      darkTheme: AppTheme.dark(
        themeProvider.seedColor,
        themeProvider.variant,
        themeProvider.cornerStyle,
        themeProvider.highContrast,
        themeProvider.compactDensity,
        themeProvider.animations,
        themeProvider.headingsTypography,
        themeProvider.titlesTypography,
        themeProvider.bodyTypography,
        themeProvider.labelsTypography,
      ),
      home: ZetaAppRoot(showSplash: showSplash),
    );
  }
}

/// Root widget hosting the underlying [AppScaffold] and the animated [SplashScreen] overlay.
/// When the splash finishes its exit animation, it dissolves cleanly with zero frame drop.
class ZetaAppRoot extends StatefulWidget {
  final bool showSplash;

  const ZetaAppRoot({super.key, this.showSplash = true});

  @override
  State<ZetaAppRoot> createState() => _ZetaAppRootState();
}

class _ZetaAppRootState extends State<ZetaAppRoot> {
  late bool _displaySplash;

  @override
  void initState() {
    super.initState();
    _displaySplash = widget.showSplash;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppScaffold(),
        if (_displaySplash)
          SplashScreen(
            onInitializationComplete: () {
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
