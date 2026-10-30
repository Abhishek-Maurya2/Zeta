import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import 'components/space_canvas.dart';
import '../../providers/navigation_provider.dart';

import '../../utils/haptics.dart';

/// Primary page coordinator for the Space (Mindmap) feature.
/// Opens as a dedicated destination route (like Settings) with predictive back handling.
class SpacePage extends StatelessWidget {
  const SpacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final colorScheme = context.colorScheme;

    return PopScope(
      canPop: !navProvider.canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navProvider.canPop) {
          ZetaHaptics.light();
          navProvider.pop();
        }
      },
      child: Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
        body: const SpaceCanvas(),
      ),
    );
  }
}
