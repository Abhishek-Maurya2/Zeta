import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:zeta/core/core.dart';

import '../../../components/glass_surface.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/motion_tokens.dart';
import '../../../utils/haptics.dart';
import '../models/mindmap.dart';
import '../providers/space_provider.dart';

/// Refined top floating toolbar for the Space mindmap canvas
/// with frosted tinted glass trigger and frosted tinted glass dropdown panel.
class SpaceFloatingToolbar extends StatefulWidget {
  const SpaceFloatingToolbar({super.key});

  @override
  State<SpaceFloatingToolbar> createState() => _SpaceFloatingToolbarState();
}

class _SpaceFloatingToolbarState extends State<SpaceFloatingToolbar>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final Object _tapRegionGroupId = Object();
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isOpen = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: M3MotionDuration.short4,
      reverseDuration: M3MotionDuration.short3,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: M3MotionEasing.emphasizedDecelerate,
      reverseCurve: M3MotionEasing.emphasizedAccelerate,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: M3MotionEasing.emphasizedDecelerate,
        reverseCurve: M3MotionEasing.emphasizedAccelerate,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _open() {
    if (_isOpen) return;
    setState(() {
      _isOpen = true;
      _query = '';
      _searchController.clear();
    });
    _portalController.show();
    _animController.forward();
  }

  void _close() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _animController.reverse().then((_) {
      if (mounted && !_isOpen) {
        _portalController.hide();
      }
    });
  }

  void _toggle() {
    ZetaHaptics.selection();
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  Widget _buildPanel(
    BuildContext context,
    List<MindMap> mindMaps,
    MindMap? activeMap,
    SpaceProvider provider,
  ) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final filtered = _query.trim().isEmpty
        ? mindMaps
        : mindMaps
              .where(
                (m) => m.title.toLowerCase().contains(
                  _query.trim().toLowerCase(),
                ),
              )
              .toList();

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 8),
        child: TapRegion(
          groupId: _tapRegionGroupId,
          onTapOutside: (_) => _close(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 250,
                  maxWidth: 260,
                  maxHeight: 380,
                ),
                child: GlassSurface(
                  borderRadius: BorderRadius.circular(24),
                  blurSigma: 8,
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.28),
                    width: 1,
                  ),
                  material: true,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _query = val),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Symbols.search_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Mindmap items list
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No mindmaps found',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: SingleChildScrollView(
                              child: M3EList(
                                itemCount: filtered.length,
                                gap: 3,
                                outerRadius: 16,
                                innerRadius: 6,
                                colorBuilder: (index) {
                                  final item = filtered[index];
                                  final isSelected = item.id == activeMap?.id;
                                  return isSelected
                                      ? colorScheme.primaryContainer.withValues(
                                          alpha: 0.8,
                                        )
                                      : colorScheme.surface.withValues(
                                          alpha: 0.3,
                                        );
                                },
                                onTap: (index) {
                                  final item = filtered[index];
                                  ZetaHaptics.selection();
                                  provider.selectMindMap(item.id);
                                  _close();
                                },
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected = item.id == activeMap?.id;
                                  return M3EListItem(
                                    headline: item.title,
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();
    final navProvider = context.watch<NavigationProvider>();
    final activeMap = provider.activeMindMap;
    final mindMaps = provider.mindMaps;
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isCompact = context.isCompact;

    if (mindMaps.isEmpty && !navProvider.canPop) {
      return const SizedBox.shrink();
    }

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (overlayContext) =>
          _buildPanel(overlayContext, mindMaps, activeMap, provider),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TapRegion(
          groupId: _tapRegionGroupId,
          child: GlassSurface(
            borderRadius: BorderRadius.circular(32),
            blurSigma: 12,
            color: colorScheme.tertiaryContainer.withValues(alpha: 0.52),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
              width: 1,
            ),
            material: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (navProvider.canPop && isCompact)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      tooltip: 'Back',
                      onPressed: () {
                        ZetaHaptics.light();
                        navProvider.pop();
                      },
                    ),
                  if (mindMaps.isNotEmpty)
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _toggle,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: isCompact ? 170 : 210,
                          maxWidth: isCompact ? 230 : 270,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Symbols.hub_rounded,
                                      size: 18,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        activeMap?.title ?? 'Mindmap',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.labelLarge?.copyWith(
                                          fontFamily: 'GoogleSansFlex',
                                          fontWeight: FontWeight.w700,
                                          color:
                                              colorScheme.onTertiaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: _isOpen ? 0.5 : 0.0,
                                duration: M3MotionDuration.short4,
                                curve: M3MotionEasing.emphasizedDecelerate,
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  size: 20,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
