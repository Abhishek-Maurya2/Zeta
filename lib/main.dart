import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'theme/app_theme.dart';
import 'navigation/app_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
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

    return MaterialApp(
      title: 'Zeta',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(
        themeProvider.seedColor,
        themeProvider.variant,
        themeProvider.cornerStyle,
        themeProvider.fontChoice,
        themeProvider.highContrast,
      ),
      darkTheme: AppTheme.dark(
        themeProvider.seedColor,
        themeProvider.variant,
        themeProvider.cornerStyle,
        themeProvider.fontChoice,
        themeProvider.highContrast,
      ),
      home: const AppScaffold(),
    );
  }
}
