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
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await SupabaseService().init();
  runApp(const ZetaApp());
}

class ZetaApp extends StatelessWidget {
  const ZetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: const _ZetaAppView(),
    );
  }
}

class _ZetaAppView extends StatelessWidget {
  const _ZetaAppView();

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
      home: const AppScaffold(),
    );
  }
}
