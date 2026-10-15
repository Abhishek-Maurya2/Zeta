import 'package:zeta/core/core.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
import '../../theme/breakpoints.dart';
import '../../utils/haptics.dart';
import '../../components/zeta_logo.dart';

class TopBarBrand extends StatelessWidget {
  const TopBarBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;
    final showBrandText = !isCompact && !sizeClass.isMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompact)
          Tooltip(
            message: navProvider.isRailExpanded
                ? 'Collapse navigation'
                : 'Expand navigation',
            child: M3EIconButton(
              variant: M3EIconButtonVariant.standard,
              icon: Icon(
                navProvider.isRailExpanded
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
              ),
              onPressed: () {
                ZetaHaptics.light();
                navProvider.toggleRailExpanded();
              },
            ),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ZetaHaptics.selection();
            navProvider.setActivePage(PageId.home);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ZetaLogo(size: isCompact ? 37 : 45),
                if (showBrandText) ...[
                  const SizedBox(width: 15),
                  Text(
                    'Zeta',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                      fontSize: 30,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
