import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import 'components/space_header_bar.dart';
import 'components/space_canvas.dart';
import 'components/create_mindmap_dialog.dart';
import 'providers/space_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/haptics.dart';

/// Primary page coordinator for the Space (Mindmap) feature.
class SpacePage extends StatefulWidget {
  const SpacePage({super.key});

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage> {
  final _fabController = M3EExtendedFabController();

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateMindMap() async {
    ZetaHaptics.medium();
    final title = await CreateMindMapDialog.show(context);
    if (title != null && mounted) {
      await context.read<SpaceProvider>().createMindMap(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch ThemeProvider to react to theme and brightness changes
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);
    final colorScheme = context.colorScheme;
    final isCompact = context.isCompact;

    return Scaffold(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      body: const Column(
        children: [
          // Header Bar with M3EDropdownMenu, Undo/Redo, and Layout Controls
          SpaceHeaderBar(),

          // Interactive Dotmatrix Canvas
          Expanded(
            child: SpaceCanvas(),
          ),
        ],
      ),
      // Floating Action Button to create a new mindmap
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: isCompact ? 72 : 16, right: 8),
        child: M3EExtendedFab(
          controller: _fabController,
          appear: true,
          scaleAlignment: AlignmentDirectional.bottomEnd,
          onPressed: _handleCreateMindMap,
          icon: const Icon(Icons.add_rounded),
          label: 'New Map',
          size: M3EExtendedFabSize.small,
          color: M3EFabColor.primary,
        ),
      ),
    );
  }
}
