import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:zeta/core/core.dart';

import '../../../utils/haptics.dart';
import '../../../theme/breakpoints.dart';
import 'settings_category.dart';
import 'settings_detail_pane.dart';

/// Full-screen destination route for a specific settings category on single-pane viewports.
///
/// Pushed as a dedicated route on top of the root settings list so Android predictive
/// back gestures reveal the root settings page preview seamlessly underneath.
class SettingsCategoryDetailScreen extends StatelessWidget {
  final SettingsCategory category;

  const SettingsCategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isCompact = context.isCompact;
    final activeCategoryMeta =
        kSettingsCategories.firstWhere((c) => c.id == category);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: CustomScrollView(
        key: ValueKey<String>('settings_compact_${category.name}'),
        slivers: [
          M3EAppBar.sliver(
            titleText: activeCategoryMeta.label,
            backgroundColor: colorScheme.surfaceContainerLow,
            centerTitle: true,
            variant: M3EAppBarVariant.large,
            hideMode: M3EAppBarHideMode.actions,
            leading: M3EIconButton(
              variant: M3EIconButtonVariant.standard,
              width: M3EIconButtonWidth.wide,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                ZetaHaptics.light();
                Navigator.of(context).maybePop();
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact
                  ? ZetaBreakpoints.marginCompact
                  : ZetaBreakpoints.marginExpanded,
              vertical: 8,
            ),
            sliver: SliverToBoxAdapter(
              child: SettingsDetailPane(
                activeCategory: category,
                activeCategoryMeta: activeCategoryMeta,
                isTwoPane: false,
                isCompact: isCompact,
                onToast: (message) {
                  M3ESnackbar.show(
                    context,
                    message: message,
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
