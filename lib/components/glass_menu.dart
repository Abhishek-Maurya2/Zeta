import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zeta/core/core.dart';

import 'glass_surface.dart';
import '../utils/haptics.dart';

export 'package:material_3_expressive/material_3_expressive.dart'
    show
        M3EMenuNode,
        M3EMenuEntry,
        M3EMenuSelectable,
        M3EMenuToggleable,
        M3EMenuDivider,
        M3EMenuGroup,
        M3EMenuSubmenu,
        M3EMenuWidget,
        M3EMenuAnchorPosition,
        M3EMenuColorStyle,
        M3EMenuTheme,
        M3EMenuPlacement,
        M3EMenuPlacer;

/// Aliases for M3E menu types to provide uniform Glass naming.
typedef GlassMenuNode = M3EMenuNode;
typedef GlassMenuEntry = M3EMenuEntry;
typedef GlassMenuSelectable = M3EMenuSelectable;
typedef GlassMenuToggleable = M3EMenuToggleable;
typedef GlassMenuDivider = M3EMenuDivider;
typedef GlassMenuGroup = M3EMenuGroup;
typedef GlassMenuSubmenu = M3EMenuSubmenu;
typedef GlassMenuWidget = M3EMenuWidget;
typedef GlassMenuAnchorPosition = M3EMenuAnchorPosition;
typedef GlassMenuColorStyle = M3EMenuColorStyle;
typedef GlassMenuTheme = M3EMenuTheme;
typedef GlassMenuAnchorBuilder = Widget Function(
  BuildContext context,
  VoidCallback open,
);

/// Individual option in a [GlassMenuActionRow].
class GlassMenuActionItem {
  final Widget? icon;
  final IconData? iconData;
  final String? label;
  final String? tooltip;
  final Object? value;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;
  final bool selected;
  final Widget? badge;
  final Color? color;

  const GlassMenuActionItem({
    this.icon,
    this.iconData,
    this.label,
    this.tooltip,
    this.value,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
    this.selected = false,
    this.badge,
    this.color,
  }) : assert(icon != null || iconData != null, 'Provide either icon or iconData');
}

/// Horizontal action row node for quick actions (e.g., Space node quick actions).
///
/// Lays out actions in a clean, balanced horizontal row with rounded selection tiles,
/// full ink response, haptic feedback, and clean dismissal.
class GlassMenuActionRow extends M3EMenuWidget {
  final List<GlassMenuActionItem> actions;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool closeOnSelect;
  final bool showDividers;

  const GlassMenuActionRow({
    required this.actions,
    this.height = 54.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
    this.closeOnSelect = true,
    this.showDividers = false,
    super.semanticLabel = 'Quick action row',
  }) : super(child: const SizedBox.shrink());
}

/// Shows a custom menu popup with a frosted [GlassSurface], exact M3 Expressive UI,
/// smooth spring animations, and native support for horizontal action rows.
Future<T?> showGlassMenu<T>({
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
  double blurSigma = 8.0,
  BorderRadius? borderRadius,
  Color? backgroundColor,
  Border? border,
  Color? barrierColor,
}) {
  final completer = Completer<T?>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      return _GlassMenuPopup<T>(
        anchor: anchor,
        children: children,
        position: position,
        colorStyle: colorStyle,
        selectedValue: selectedValue,
        closeOnSelect: closeOnSelect,
        preferredWidth: preferredWidth,
        callerFocusNode: callerFocusNode,
        themeOverride: themeOverride,
        menuHeightOverride: menuHeightOverride,
        blurSigma: blurSigma,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        border: border,
        barrierColor: barrierColor,
        onDismiss: (T? value) {
          if (!completer.isCompleted) {
            completer.complete(value);
          }
        },
        onRemove: () {
          entry.remove();
        },
      );
    },
  );

  Overlay.of(context, rootOverlay: true).insert(entry);
  return completer.future;
}

/// Drop-in backward compatible function name for [showGlassMenu].
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
  double blurSigma = 8.0,
  BorderRadius? borderRadius,
  Color? backgroundColor,
  Border? border,
  Color? barrierColor,
}) {
  return showGlassMenu<T>(
    context: context,
    anchor: anchor,
    children: children,
    position: position,
    colorStyle: colorStyle,
    selectedValue: selectedValue,
    closeOnSelect: closeOnSelect,
    preferredWidth: preferredWidth,
    callerFocusNode: callerFocusNode,
    themeOverride: themeOverride,
    menuHeightOverride: menuHeightOverride,
    blurSigma: blurSigma,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
    border: border,
    barrierColor: barrierColor,
  );
}

/// Custom expressive menu widget utilizing a frosted [GlassSurface] container.
class GlassMenu extends StatefulWidget {
  const GlassMenu({
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
    this.blurSigma = 8.0,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.barrierColor,
    super.key,
  }) : assert(
         children != null || entries != null,
         'Provide children or entries.',
       );

  factory GlassMenu.entries({
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
    double blurSigma = 8.0,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Border? border,
    Color? barrierColor,
  }) {
    return GlassMenu(
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
      blurSigma: blurSigma,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      border: border,
      barrierColor: barrierColor,
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
  final double blurSigma;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final Color? barrierColor;

  List<M3EMenuNode> get _nodes => children ?? entries ?? const [];

  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends State<GlassMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _open = false;

  Rect? _rootOverlayRect(BuildContext anchorContext) {
    final object = anchorContext.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) {
      return null;
    }

    final rootOverlay = Overlay.of(context, rootOverlay: true);
    final overlayObject = rootOverlay.context.findRenderObject();
    return MatrixUtils.transformRect(
      object.getTransformTo(overlayObject),
      Offset.zero & object.size,
    );
  }

  Future<void> _openMenu() async {
    if (_open) return;
    final BuildContext? anchorContext = _anchorKey.currentContext;
    final Rect? anchor =
        anchorContext == null ? null : _rootOverlayRect(anchorContext);
    if (anchor == null) return;

    setState(() => _open = true);
    ZetaHaptics.light();

    final result = await showGlassMenu<Object>(
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
      blurSigma: widget.blurSigma,
      borderRadius: widget.borderRadius,
      backgroundColor: widget.backgroundColor,
      border: widget.border,
      barrierColor: widget.barrierColor,
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

/// Drop-in backward compatible widget name for [GlassMenu].
class GlassM3EMenu extends GlassMenu {
  const GlassM3EMenu({
    required super.anchorBuilder,
    super.children,
    super.entries,
    super.position = M3EMenuAnchorPosition.bottomEnd,
    super.colorStyle = M3EMenuColorStyle.vibrant,
    super.preferredWidth,
    super.closeOnSelect = true,
    super.onSelected,
    super.selectedValue,
    super.themeOverride,
    super.menuHeightOverride,
    super.blurSigma = 8.0,
    super.borderRadius,
    super.backgroundColor,
    super.border,
    super.barrierColor,
    super.key,
  });

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
    double blurSigma = 8.0,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Border? border,
    Color? barrierColor,
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
      blurSigma: blurSigma,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      border: border,
      barrierColor: barrierColor,
    );
  }
}

class _GlassMenuPopup<T> extends StatefulWidget {
  final Rect anchor;
  final List<M3EMenuNode> children;
  final M3EMenuAnchorPosition position;
  final M3EMenuColorStyle colorStyle;
  final T? selectedValue;
  final bool closeOnSelect;
  final double? preferredWidth;
  final FocusNode? callerFocusNode;
  final M3EMenuTheme? themeOverride;
  final double? menuHeightOverride;
  final double blurSigma;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final Color? barrierColor;
  final ValueChanged<T?> onDismiss;
  final VoidCallback onRemove;

  const _GlassMenuPopup({
    required this.anchor,
    required this.children,
    required this.onDismiss,
    required this.onRemove,
    this.position = M3EMenuAnchorPosition.bottomEnd,
    this.colorStyle = M3EMenuColorStyle.vibrant,
    this.selectedValue,
    this.closeOnSelect = true,
    this.preferredWidth,
    this.callerFocusNode,
    this.themeOverride,
    this.menuHeightOverride,
    this.blurSigma = 8.0,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.barrierColor,
  });

  @override
  State<_GlassMenuPopup<T>> createState() => _GlassMenuPopupState<T>();
}

class _GlassMenuPopupState<T> extends State<_GlassMenuPopup<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _expandCurve;
  final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: 'GlassMenuPopupScope',
  );
  final FocusNode _keyFocus = FocusNode(
    skipTraversal: true,
    debugLabel: 'GlassMenuKeyFocus',
  );
  final ScrollController _scrollController = ScrollController();
  bool _isDismissing = false;
  bool _dismissCompleted = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 160),
    );

    _expandCurve = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    unawaited(_animCtrl.forward());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _focusScopeNode.dispose();
    _keyFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _dismiss([T? value]) async {
    if (_isDismissing) return;
    _isDismissing = true;

    try {
      await _animCtrl.reverse();
    } catch (_) {
      // Ignore animation interruption if unmounted.
    }

    if (!_dismissCompleted && mounted) {
      _dismissCompleted = true;
      widget.onDismiss(value);
      widget.onRemove();
      widget.callerFocusNode?.requestFocus();
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      unawaited(_dismiss(null));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ambientMenuTheme = M3ETheme.of(context).menuTheme;
    final baseMenuTheme = widget.themeOverride ?? ambientMenuTheme;
    final menuTheme = baseMenuTheme.copyWith(elevation: 0);

    final placement = M3EMenuPlacer.compute(
      screenSize: MediaQuery.sizeOf(context),
      anchorRect: widget.anchor,
      theme: menuTheme,
      position: widget.position,
      textDirection: Directionality.of(context),
      approximateItemCount: widget.children.length,
      preferredWidth: widget.preferredWidth,
    );

    // Increase max height constraint by 5% to give breathing room and prevent premature scrollbar
    final effectiveMaxHeight = (widget.menuHeightOverride != null
            ? widget.menuHeightOverride!.clamp(120.0, placement.maxHeight)
            : placement.maxHeight) *
        1.05;

    final effectiveBorderRadius = widget.borderRadius ??
        BorderRadius.circular(menuTheme.containerRadius);

    // Increased transparency for pure frosted glass
    final Color effectiveBg;
    if (widget.backgroundColor != null) {
      effectiveBg = widget.backgroundColor!;
    } else if (widget.colorStyle == M3EMenuColorStyle.vibrant) {
      effectiveBg = isDark
          ? colorScheme.tertiaryContainer.withValues(alpha: 0.35)
          : colorScheme.tertiaryContainer.withValues(alpha: 0.45);
    } else {
      effectiveBg = isDark
          ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.38)
          : colorScheme.surfaceContainer.withValues(alpha: 0.48);
    }

    final Border effectiveBorder;
    if (widget.border != null) {
      effectiveBorder = widget.border!;
    } else if (widget.colorStyle == M3EMenuColorStyle.vibrant) {
      effectiveBorder = Border.all(
        color: colorScheme.outlineVariant.withValues(
          alpha: isDark ? 0.25 : 0.20,
        ),
        width: 1.0,
      );
    } else {
      effectiveBorder = Border.all(
        color: colorScheme.outlineVariant.withValues(
          alpha: isDark ? 0.25 : 0.20,
        ),
        width: 1.0,
      );
    }

    return FocusScope(
      node: _focusScopeNode,
      child: Focus(
        autofocus: true,
        focusNode: _keyFocus,
        onKeyEvent: _onKeyEvent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Barrier / Scrim
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _dismiss(null),
                child: ColoredBox(
                  color: widget.barrierColor ?? Colors.transparent,
                ),
              ),
            ),

            // Anchored Menu Card - 0 elevation, no shadows, pure GlassSurface
            Positioned(
              left: placement.left,
              top: placement.top,
              bottom: placement.bottom,
              width: placement.width,
              child: AnimatedBuilder(
                animation: _expandCurve,
                builder: (context, child) {
                  final progress = _expandCurve.value;
                  return Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.88 + 0.12 * progress,
                      alignment: placement.scaleAlignment,
                      child: child,
                    ),
                  );
                },
                child: GlassSurface(
                  borderRadius: effectiveBorderRadius,
                  blurSigma: widget.blurSigma,
                  color: effectiveBg,
                  border: effectiveBorder,
                  material: true,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: menuTheme.minWidth,
                      maxWidth: placement.width,
                      maxHeight: effectiveMaxHeight,
                    ),
                    child: RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: false,
                      radius: const Radius.circular(4),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          vertical: menuTheme.verticalPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildNodes(
                            context: context,
                            nodes: widget.children,
                            menuTheme: menuTheme,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            isDark: isDark,
                          ),
                        ),
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
  }

  List<Widget> _buildNodes({
    required BuildContext context,
    required List<M3EMenuNode> nodes,
    required M3EMenuTheme menuTheme,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isDark,
  }) {
    final widgets = <Widget>[];

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      if (node is GlassMenuActionRow) {
        widgets.add(
          _buildActionRow(
            context: context,
            row: node,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        );
      } else if (node is M3EMenuEntry) {
        widgets.add(
          _buildEntryItem(
            context: context,
            entry: node,
            colorScheme: colorScheme,
            textTheme: textTheme,
            menuTheme: menuTheme,
          ),
        );
      } else if (node is M3EMenuSelectable) {
        widgets.add(
          _buildSelectableItem(
            context: context,
            item: node,
            colorScheme: colorScheme,
            textTheme: textTheme,
            menuTheme: menuTheme,
            isDark: isDark,
          ),
        );
      } else if (node is M3EMenuToggleable) {
        widgets.add(
          _buildToggleableItem(
            context: context,
            item: node,
            colorScheme: colorScheme,
            textTheme: textTheme,
            menuTheme: menuTheme,
          ),
        );
      } else if (node is M3EMenuDivider) {
        widgets.add(
          _buildDivider(
            colorScheme: colorScheme,
            menuTheme: menuTheme,
          ),
        );
      } else if (node is M3EMenuGroup) {
        widgets.addAll(
          _buildGroup(
            context: context,
            group: node,
            menuTheme: menuTheme,
            colorScheme: colorScheme,
            textTheme: textTheme,
            isDark: isDark,
          ),
        );
      } else if (node is M3EMenuSubmenu) {
        widgets.add(
          _buildSubmenuItem(
            context: context,
            submenu: node,
            colorScheme: colorScheme,
            textTheme: textTheme,
            menuTheme: menuTheme,
          ),
        );
      } else if (node is M3EMenuWidget) {
        widgets.add(
          _buildCustomWidget(
            context: context,
            item: node,
            menuTheme: menuTheme,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildActionRow({
    required BuildContext context,
    required GlassMenuActionRow row,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final actions = row.actions;
    if (actions.isEmpty) return const SizedBox.shrink();

    final actionWidgets = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0 && row.showDividers) {
        actionWidgets.add(
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: colorScheme.outlineVariant.withValues(alpha: 0.30),
          ),
        );
      }
      final action = actions[i];
      actionWidgets.add(
        Expanded(
          child: _buildActionTile(
            context: context,
            action: action,
            colorScheme: colorScheme,
            isDark: isDark,
            closeOnSelect: row.closeOnSelect,
          ),
        ),
      );
    }

    return Padding(
      padding: row.padding,
      child: SizedBox(
        height: row.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actionWidgets,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required GlassMenuActionItem action,
    required ColorScheme colorScheme,
    required bool isDark,
    required bool closeOnSelect,
  }) {
    final enabled = action.enabled;
    final selected = action.selected;
    final isDestructive = action.isDestructive;

    final Color foregroundColor;
    if (!enabled) {
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (isDestructive) {
      foregroundColor = colorScheme.error;
    } else if (selected) {
      foregroundColor = colorScheme.primary;
    } else if (action.color != null) {
      foregroundColor = action.color!;
    } else {
      foregroundColor = colorScheme.onSurface;
    }

    final Color? tileBg;
    if (selected) {
      tileBg = colorScheme.primaryContainer.withValues(
        alpha: isDark ? 0.35 : 0.45,
      );
    } else {
      tileBg = null;
    }

    final Border? tileBorder;
    if (selected) {
      tileBorder = Border.all(
        color: colorScheme.primary.withValues(alpha: 0.30),
        width: 1.0,
      );
    } else {
      tileBorder = null;
    }

    final Widget iconWidget = action.icon ??
        Icon(
          action.iconData,
          size: 20,
          fill: 1.0,
          color: foregroundColor,
        );

    final Widget content;
    if (action.label != null && action.label!.isNotEmpty) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(
              size: 20,
              color: foregroundColor,
              fill: 1.0,
            ),
            child: iconWidget,
          ),
          const SizedBox(height: 3),
          Text(
            action.label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: foregroundColor,
            ),
          ),
        ],
      );
    } else {
      content = Center(
        child: IconTheme(
          data: IconThemeData(
            size: 20,
            color: foregroundColor,
            fill: 1.0,
          ),
          child: iconWidget,
        ),
      );
    }

    Widget tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
        splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
        highlightColor: colorScheme.onSurface.withValues(alpha: 0.05),
        onTap: enabled
            ? () {
                ZetaHaptics.light();
                action.onTap?.call();
                if (closeOnSelect || action.value != null) {
                  unawaited(_dismiss(action.value as T?));
                }
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(10),
            border: tileBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (action.tooltip != null && action.tooltip!.isNotEmpty) {
      tile = Tooltip(
        message: action.tooltip!,
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildEntryItem({
    required BuildContext context,
    required M3EMenuEntry entry,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required M3EMenuTheme menuTheme,
  }) {
    final enabled = entry.enabled;
    final isDestructive = entry.isDestructive;

    final Color foregroundColor;
    if (!enabled) {
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (isDestructive) {
      foregroundColor = colorScheme.error;
    } else {
      foregroundColor = colorScheme.onSurface;
    }

    final Color iconColor = isDestructive
        ? colorScheme.error
        : (enabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurface.withValues(alpha: 0.38));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: menuTheme.stateLayerInset,
        vertical: 2.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(menuTheme.itemRadius),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.05),
          onTap: enabled
              ? () {
                  ZetaHaptics.light();
                  entry.onPressed?.call();
                  unawaited(_dismiss(entry.value as T?));
                }
              : null,
          child: Container(
            constraints: BoxConstraints(minHeight: menuTheme.entryHeight),
            padding: EdgeInsets.symmetric(
              horizontal: menuTheme.entryHorizontalPadding,
              vertical: menuTheme.entryVerticalPadding,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (entry.leading != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: menuTheme.iconSize,
                      color: iconColor,
                      fill: 1.0,
                    ),
                    child: entry.leading!,
                  ),
                  SizedBox(width: menuTheme.iconGap),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (entry.supportingText != null)
                        Text(
                          entry.supportingText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (entry.badge != null) ...[
                  const SizedBox(width: 8),
                  entry.badge!,
                ],
                if (entry.trailingText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    entry.trailingText!,
                    style: textTheme.labelSmall?.copyWith(
                      color: isDestructive
                          ? colorScheme.error.withValues(alpha: 0.85)
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (entry.trailing != null) ...[
                  const SizedBox(width: 8),
                  IconTheme(
                    data: IconThemeData(
                      size: menuTheme.iconSize,
                      color: iconColor,
                      fill: 1.0,
                    ),
                    child: entry.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableItem({
    required BuildContext context,
    required M3EMenuSelectable item,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required M3EMenuTheme menuTheme,
    required bool isDark,
  }) {
    final enabled = item.enabled;
    final selected = item.selected ||
        (widget.selectedValue != null && widget.selectedValue == item.value);

    final Color foregroundColor;
    if (!enabled) {
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (selected) {
      foregroundColor = colorScheme.primary;
    } else {
      foregroundColor = colorScheme.onSurface;
    }

    final Color? itemBg = selected
        ? colorScheme.primaryContainer.withValues(alpha: isDark ? 0.30 : 0.40)
        : null;

    final Color iconColor = selected
        ? colorScheme.primary
        : (enabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurface.withValues(alpha: 0.38));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: menuTheme.stateLayerInset,
        vertical: 2.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(menuTheme.itemRadius),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.05),
          onTap: enabled
              ? () {
                  ZetaHaptics.selection();
                  item.onPressed?.call();
                  unawaited(_dismiss(item.value as T?));
                }
              : null,
          child: Container(
            constraints: BoxConstraints(minHeight: menuTheme.entryHeight),
            decoration: BoxDecoration(
              color: itemBg,
              borderRadius: BorderRadius.circular(menuTheme.itemRadius),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: menuTheme.entryHorizontalPadding,
              vertical: menuTheme.entryVerticalPadding,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (item.leading != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: menuTheme.iconSize,
                      color: iconColor,
                      fill: 1.0,
                    ),
                    child: item.leading!,
                  ),
                  SizedBox(width: menuTheme.iconGap),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (item.supportingText != null)
                        Text(
                          item.supportingText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.badge != null) ...[
                  const SizedBox(width: 8),
                  item.badge!,
                ],
                if (item.trailingText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    item.trailingText!,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.70,
                      ),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (item.trailing != null) ...[
                  const SizedBox(width: 8),
                  IconTheme(
                    data: IconThemeData(
                      size: menuTheme.iconSize,
                      color: iconColor,
                      fill: 1.0,
                    ),
                    child: item.trailing!,
                  ),
                ] else if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Symbols.check_rounded,
                    size: menuTheme.iconSize,
                    fill: 1.0,
                    color: colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleableItem({
    required BuildContext context,
    required M3EMenuToggleable item,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required M3EMenuTheme menuTheme,
  }) {
    final enabled = item.enabled;
    final checked = item.checked;

    final Color foregroundColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final Color iconColor = checked
        ? colorScheme.primary
        : (enabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurface.withValues(alpha: 0.38));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: menuTheme.stateLayerInset,
        vertical: 2.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(menuTheme.itemRadius),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
          splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.05),
          onTap: enabled
              ? () {
                  ZetaHaptics.selection();
                  final next = !checked;
                  item.onChanged?.call(next);
                  if (widget.closeOnSelect) {
                    unawaited(_dismiss(next as T?));
                  }
                }
              : null,
          child: Container(
            constraints: BoxConstraints(minHeight: menuTheme.entryHeight),
            padding: EdgeInsets.symmetric(
              horizontal: menuTheme.entryHorizontalPadding,
              vertical: menuTheme.entryVerticalPadding,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  checked
                      ? Symbols.check_box_rounded
                      : Symbols.check_box_outline_blank_rounded,
                  size: menuTheme.iconSize,
                  fill: 1.0,
                  color: iconColor,
                ),
                SizedBox(width: menuTheme.iconGap),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (item.trailing != null) ...[
                  const SizedBox(width: 8),
                  item.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmenuItem({
    required BuildContext context,
    required M3EMenuSubmenu submenu,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required M3EMenuTheme menuTheme,
  }) {
    final enabled = submenu.enabled;
    final foregroundColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return Builder(
      builder: (BuildContext itemContext) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: menuTheme.stateLayerInset,
            vertical: 2.0,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(menuTheme.itemRadius),
              hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
              splashColor: colorScheme.onSurface.withValues(alpha: 0.12),
              highlightColor: colorScheme.onSurface.withValues(alpha: 0.05),
              onTap: enabled
                  ? () async {
                      final box = itemContext.findRenderObject() as RenderBox?;
                      if (box == null || !box.hasSize) return;
                      final rootOverlay = Overlay.of(
                        context,
                        rootOverlay: true,
                      );
                      final overlayObject =
                          rootOverlay.context.findRenderObject();
                      final itemRect = MatrixUtils.transformRect(
                        box.getTransformTo(overlayObject),
                        Offset.zero & box.size,
                      );

                      final result = await showGlassMenu<Object>(
                        context: context,
                        anchor: itemRect,
                        children: submenu.children,
                        position: M3EMenuAnchorPosition.end,
                        colorStyle: widget.colorStyle,
                        blurSigma: widget.blurSigma,
                      );

                      if (result != null) {
                        await _dismiss(result as T?);
                      }
                    }
                  : null,
              child: Container(
                constraints: BoxConstraints(minHeight: menuTheme.entryHeight),
                padding: EdgeInsets.symmetric(
                  horizontal: menuTheme.entryHorizontalPadding,
                  vertical: menuTheme.entryVerticalPadding,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    if (submenu.leading != null) ...[
                      IconTheme(
                        data: IconThemeData(
                          size: menuTheme.iconSize,
                          color: colorScheme.onSurfaceVariant,
                          fill: 1.0,
                        ),
                        child: submenu.leading!,
                      ),
                      SizedBox(width: menuTheme.iconGap),
                    ],
                    Expanded(
                      child: Text(
                        submenu.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    if (submenu.badge != null) ...[
                      const SizedBox(width: 8),
                      submenu.badge!,
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Symbols.chevron_right_rounded,
                      size: menuTheme.iconSize,
                      fill: 1.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider({
    required ColorScheme colorScheme,
    required M3EMenuTheme menuTheme,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: menuTheme.dividerVerticalPadding > 0
            ? menuTheme.dividerVerticalPadding
            : 4.0,
        horizontal: 8.0,
      ),
      child: Divider(
        height: menuTheme.dividerThickness,
        thickness: menuTheme.dividerThickness,
        color: colorScheme.outlineVariant.withValues(alpha: 0.30),
      ),
    );
  }

  List<Widget> _buildGroup({
    required BuildContext context,
    required M3EMenuGroup group,
    required M3EMenuTheme menuTheme,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isDark,
  }) {
    final list = <Widget>[];
    if (group.label != null && group.label!.isNotEmpty) {
      list.add(
        Padding(
          padding: EdgeInsets.only(
            left: menuTheme.entryHorizontalPadding + menuTheme.stateLayerInset,
            right: menuTheme.entryHorizontalPadding + menuTheme.stateLayerInset,
            top: 6.0,
            bottom: 4.0,
          ),
          child: Text(
            group.label!.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ),
      );
    }
    list.addAll(
      _buildNodes(
        context: context,
        nodes: group.children,
        menuTheme: menuTheme,
        colorScheme: colorScheme,
        textTheme: textTheme,
        isDark: isDark,
      ),
    );
    return list;
  }

  Widget _buildCustomWidget({
    required BuildContext context,
    required M3EMenuWidget item,
    required M3EMenuTheme menuTheme,
  }) {
    if (item.onPressed != null || item.value != null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: menuTheme.stateLayerInset,
          vertical: 2.0,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(menuTheme.itemRadius),
            onTap: item.enabled
                ? () {
                    ZetaHaptics.light();
                    item.onPressed?.call();
                    if (widget.closeOnSelect || item.value != null) {
                      unawaited(_dismiss(item.value as T?));
                    }
                  }
                : null,
            child: item.child,
          ),
        ),
      );
    }
    return item.child;
  }
}
