import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../utils/haptics.dart';

/// Shows an expressive menu popup with glassmorphism backdrop blur and translucent styling.
Future<T?> showGlassM3EMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required List<M3EMenuNode> children,
  M3EMenuAnchorPosition position = M3EMenuAnchorPosition.bottomEnd,
  M3EMenuColorStyle colorStyle = M3EMenuColorStyle.vibrant,
  T? selectedValue,
  bool closeOnSelect = true,
  double? preferredWidth,
  FocusNode? callerFocusNode,
  M3EMenuTheme? themeOverride,
  double? menuHeightOverride,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final count = M3EMenuPlacer.approximateItemCount(children);

  final menuTheme = themeOverride ??
      M3EMenuTheme(
        elevation: 0,
        backgroundColor: colorScheme.tertiaryContainer.withValues(
          alpha: 0.50,
        ),
      );

  final zeroElevTheme = menuTheme.copyWith(elevation: 0);

  final placement = M3EMenuPlacer.compute(
    screenSize: MediaQuery.sizeOf(context),
    anchorRect: anchor,
    theme: zeroElevTheme,
    position: position,
    textDirection: Directionality.of(context),
    approximateItemCount: count,
    preferredWidth: preferredWidth,
  );

  double menuHeight = 16.0;
  for (int i = 0; i < children.length; i++) {
    final node = children[i];
    if (node is M3EMenuDivider) {
      menuHeight += 9.0;
    } else {
      menuHeight += 52.0;
    }
  }
  menuHeight = (menuHeightOverride ?? menuHeight).clamp(
    zeroElevTheme.entryHeight * 2,
    zeroElevTheme.maxHeight,
  );

  const shadowPad = 0.0;
  final menuWidth = placement.width - shadowPad * 2;
  final menuLeft = placement.left + shadowPad;
  final menuTop = placement.top != null ? placement.top! + shadowPad : null;
  final menuBottom = placement.bottom != null
      ? placement.bottom! + shadowPad
      : null;

  final blurOverlay = OverlayEntry(
    builder: (ctx) => IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: menuLeft,
            top: menuTop,
            bottom: menuBottom,
            width: menuWidth,
            height: menuHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                zeroElevTheme.containerRadius,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      zeroElevTheme.containerRadius,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Overlay.of(context, rootOverlay: true).insert(blurOverlay);

  try {
    return await showM3EMenu<T>(
      context: context,
      anchor: anchor,
      children: children,
      position: position,
      colorStyle: colorStyle,
      selectedValue: selectedValue,
      closeOnSelect: closeOnSelect,
      preferredWidth: preferredWidth,
      callerFocusNode: callerFocusNode,
      themeOverride: zeroElevTheme,
    );
  } finally {
    blurOverlay.remove();
  }
}

/// Drop-in replacement for [M3EMenu] that uses glassmorphism styling
/// (localized backdrop blur, translucent background, and zero elevation).
class GlassM3EMenu extends StatefulWidget {
  const GlassM3EMenu({
    required this.anchorBuilder,
    this.children,
    this.entries,
    this.position = M3EMenuAnchorPosition.bottomEnd,
    this.colorStyle = M3EMenuColorStyle.vibrant,
    this.preferredWidth,
    this.closeOnSelect = true,
    this.onSelected,
    this.selectedValue,
    this.themeOverride,
    this.menuHeightOverride,
    super.key,
  }) : assert(
         children != null || entries != null,
         'Provide children or entries.',
       );

  /// Convenience constructor for a flat list of action [M3EMenuEntry]s.
  factory GlassM3EMenu.entries({
    Key? key,
    required M3EMenuAnchorBuilder anchorBuilder,
    required List<M3EMenuEntry> entries,
    M3EMenuAnchorPosition position = M3EMenuAnchorPosition.bottomEnd,
    M3EMenuColorStyle colorStyle = M3EMenuColorStyle.vibrant,
    bool closeOnSelect = true,
    ValueChanged<Object?>? onSelected,
    Object? selectedValue,
    double? preferredWidth,
    M3EMenuTheme? themeOverride,
    double? menuHeightOverride,
  }) {
    return GlassM3EMenu(
      key: key,
      anchorBuilder: anchorBuilder,
      entries: entries,
      position: position,
      colorStyle: colorStyle,
      closeOnSelect: closeOnSelect,
      onSelected: onSelected,
      selectedValue: selectedValue,
      preferredWidth: preferredWidth,
      themeOverride: themeOverride,
      menuHeightOverride: menuHeightOverride,
    );
  }

  final M3EMenuAnchorBuilder anchorBuilder;
  final List<M3EMenuNode>? children;
  final List<M3EMenuEntry>? entries;
  final M3EMenuAnchorPosition position;
  final M3EMenuColorStyle colorStyle;
  final double? preferredWidth;
  final bool closeOnSelect;
  final ValueChanged<Object?>? onSelected;
  final Object? selectedValue;
  final M3EMenuTheme? themeOverride;
  final double? menuHeightOverride;

  List<M3EMenuNode> get _nodes => children ?? entries ?? const [];

  @override
  State<GlassM3EMenu> createState() => _GlassM3EMenuState();
}

class _GlassM3EMenuState extends State<GlassM3EMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _open = false;

  Future<void> _openMenu() async {
    if (_open) return;
    final BuildContext? anchorContext = _anchorKey.currentContext;
    final Rect? anchor = anchorContext == null
        ? null
        : m3eOverlayRectFor(anchorContext);
    if (anchor == null) return;

    setState(() => _open = true);
    ZetaHaptics.light();

    final result = await showGlassM3EMenu<Object>(
      context: context,
      anchor: anchor,
      children: widget._nodes,
      position: widget.position,
      colorStyle: widget.colorStyle,
      closeOnSelect: widget.closeOnSelect,
      selectedValue: widget.selectedValue,
      preferredWidth: widget.preferredWidth,
      themeOverride: widget.themeOverride,
      menuHeightOverride: widget.menuHeightOverride,
    );

    if (mounted) {
      setState(() => _open = false);
    }
    if (result != null) {
      widget.onSelected?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return M3EComponentTheme(
      builder: (BuildContext context) {
        return KeyedSubtree(
          key: _anchorKey,
          child: widget.anchorBuilder(context, _openMenu),
        );
      },
    );
  }
}
