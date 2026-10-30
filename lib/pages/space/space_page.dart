import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import 'components/space_canvas.dart';
import '../../providers/theme_provider.dart';

/// Primary page coordinator for the Space (Mindmap) feature.
/// Hosts the full-bleed [SpaceCanvas] containing the dotmatrix grid,
/// top floating toolbar, canvas controls, and M3E FAB menu.
class SpacePage extends StatelessWidget {
  const SpacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      body: const SpaceCanvas(),
    );
  }
}
