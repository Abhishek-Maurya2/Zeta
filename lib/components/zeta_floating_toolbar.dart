import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/motion_tokens.dart';

/// Slide direction for enter/exit motion.
enum ZetaToolbarSlideDirection {
  none,
  up,
  down,
  left,
  right,
}

/// Visual styling configuration for [ZetaFloatingToolbar].
class ZetaToolbarStyle {
  final double blurSigma;
  final double alpha;
  final Color? backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;
  final double gap;
  final double elevation;

  const ZetaToolbarStyle({
    this.blurSigma = 10.0,
    this.alpha = 0.78,
    this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(100)),
    this.border,
    this.shadows,
    this.padding,
    this.gap = 4.0,
    this.elevation = 0.0,
  });

  ZetaToolbarStyle copyWith({
    double? blurSigma,
    double? alpha,
    Color? backgroundColor,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? shadows,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? elevation,
  }) {
    return ZetaToolbarStyle(
      blurSigma: blurSigma ?? this.blurSigma,
      alpha: alpha ?? this.alpha,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      border: border ?? this.border,
      shadows: shadows ?? this.shadows,
      padding: padding ?? this.padding,
      gap: gap ?? this.gap,
      elevation: elevation ?? this.elevation,
    );
  }
}

/// Physics-based spring motion parameters for [ZetaFloatingToolbar].
class ZetaToolbarMotion {
  /// Expressive spatial spring (380.0 stiffness, 0.85 damping ratio).
  static const SpringDescription spatialSpring = SpringDescription(
    mass: 1.0,
    stiffness: M3MotionSpring.spatialStiffness,
    damping: 33.13910077235047,
  );

  /// Expressive effects spring (700.0 stiffness, 0.70 damping ratio).
  static const SpringDescription effectsSpring = SpringDescription(
    mass: 1.0,
    stiffness: M3MotionSpring.effectsStiffness,
    damping: 37.04051835490427,
  );

  final SpringDescription spring;
  final ZetaToolbarSlideDirection slideDirection;
  final double slideDistance;
  final bool scale;
  final bool fade;
  final bool enabled;

  const ZetaToolbarMotion({
    this.spring = spatialSpring,
    this.slideDirection = ZetaToolbarSlideDirection.down,
    this.slideDistance = 32.0,
    this.scale = true,
    this.fade = true,
    this.enabled = true,
  });

  ZetaToolbarMotion copyWith({
    SpringDescription? spring,
    ZetaToolbarSlideDirection? slideDirection,
    double? slideDistance,
    bool? scale,
    bool? fade,
    bool? enabled,
  }) {
    return ZetaToolbarMotion(
      spring: spring ?? this.spring,
      slideDirection: slideDirection ?? this.slideDirection,
      slideDistance: slideDistance ?? this.slideDistance,
      scale: scale ?? this.scale,
      fade: fade ?? this.fade,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Representation of an item within [ZetaFloatingToolbar].
class ZetaToolbarItem {
  final String? id;
  final IconData? icon;
  final IconData? activeIcon;
  final String? label;
  final String? tooltip;
  final bool isSelected;
  final bool isDestructive;
  final Widget? badge;
  final VoidCallback? onPressed;
  final Widget? customChild;

  const ZetaToolbarItem({
    this.id,
    this.icon,
    this.activeIcon,
    this.label,
    this.tooltip,
    this.isSelected = false,
    this.isDestructive = false,
    this.badge,
    this.onPressed,
    this.customChild,
  });
}

/// Frosted-glass floating toolbar with real Material 3 spring physics.
///
/// Supports both item-driven ([ZetaFloatingToolbar]) and custom child
/// ([ZetaFloatingToolbar.custom]) constructors.
class ZetaFloatingToolbar extends StatefulWidget {
  final List<ZetaToolbarItem>? items;
  final Widget? child;
  final ZetaToolbarStyle style;
  final ZetaToolbarMotion motion;
  final bool visible;
  final MainAxisSize mainAxisSize;
  final Widget? leading;
  final Widget? trailing;

  const ZetaFloatingToolbar({
    super.key,
    required this.items,
    this.style = const ZetaToolbarStyle(),
    this.motion = const ZetaToolbarMotion(),
    this.visible = true,
    this.mainAxisSize = MainAxisSize.min,
    this.leading,
    this.trailing,
  }) : child = null;

  const ZetaFloatingToolbar.custom({
    super.key,
    required this.child,
    this.style = const ZetaToolbarStyle(),
    this.motion = const ZetaToolbarMotion(),
    this.visible = true,
  })  : items = null,
        mainAxisSize = MainAxisSize.min,
        leading = null,
        trailing = null;

  @override
  State<ZetaFloatingToolbar> createState() => _ZetaFloatingToolbarState();
}

class _ZetaFloatingToolbarState extends State<ZetaFloatingToolbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
      value: widget.visible ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant ZetaFloatingToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (!widget.motion.enabled) {
        _controller.value = widget.visible ? 1.0 : 0.0;
      } else {
        final target = widget.visible ? 1.0 : 0.0;
        final simulation = SpringSimulation(
          widget.motion.spring,
          _controller.value,
          target,
          0.0,
        );
        _controller.animateWith(simulation);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _calculateSlideOffset(double progress) {
    final double distance = widget.motion.slideDistance * (1.0 - progress);
    switch (widget.motion.slideDirection) {
      case ZetaToolbarSlideDirection.up:
        return Offset(0, -distance);
      case ZetaToolbarSlideDirection.down:
        return Offset(0, distance);
      case ZetaToolbarSlideDirection.left:
        return Offset(-distance, 0);
      case ZetaToolbarSlideDirection.right:
        return Offset(distance, 0);
      case ZetaToolbarSlideDirection.none:
        return Offset.zero;
    }
  }

  Widget _buildItem(BuildContext context, ZetaToolbarItem item) {
    if (item.customChild != null) {
      return item.customChild!;
    }

    final colorScheme = Theme.of(context).colorScheme;

    Color foregroundColor;
    if (item.isDestructive) {
      foregroundColor = colorScheme.error;
    } else if (item.isSelected) {
      foregroundColor = colorScheme.onSurface;
    } else {
      foregroundColor = colorScheme.onSurfaceVariant;
    }

    final iconWidget = item.icon != null
        ? Icon(
            item.isSelected ? (item.activeIcon ?? item.icon) : item.icon,
            size: item.isSelected ? 24 : 22,
            color: foregroundColor,
          )
        : null;

    Widget content;
    if (iconWidget != null && item.label != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 6),
          Text(
            item.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: item.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: foregroundColor,
            ),
          ),
        ],
      );
    } else if (iconWidget != null) {
      content = iconWidget;
    } else if (item.label != null) {
      content = Text(
        item.label!,
        style: TextStyle(
          fontSize: 14,
          fontWeight: item.isSelected ? FontWeight.w700 : FontWeight.w500,
          color: foregroundColor,
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }

    if (item.badge != null) {
      content = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          content,
          Positioned(
            top: -4,
            right: -4,
            child: item.badge!,
          ),
        ],
      );
    }

    Widget button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: item.onPressed,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: item.isSelected ? 14 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: item.isSelected
                ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: content,
        ),
      ),
    );

    if (item.tooltip != null) {
      button = Tooltip(
        message: item.tooltip!,
        child: button,
      );
    }

    return button;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseBg = widget.style.backgroundColor ?? colorScheme.surfaceContainer;
    final resolvedBg = baseBg.withValues(alpha: widget.style.alpha);

    final defaultBorder = Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.18)
          : colorScheme.outlineVariant.withValues(alpha: 0.35),
      width: 1.0,
    );

    final defaultShadows = <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: widget.style.elevation > 0 ? 0.16 : 0.10),
        blurRadius: widget.style.elevation > 0 ? 24 : 18,
        spreadRadius: 0,
        offset: Offset(0, widget.style.elevation > 0 ? 8 : 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      final items = widget.items ?? const [];
      final itemWidgets = <Widget>[];

      if (widget.leading != null) {
        itemWidgets.add(widget.leading!);
      }

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (i > 0 || widget.leading != null) {
          itemWidgets.add(SizedBox(width: widget.style.gap));
        }
        itemWidgets.add(_buildItem(context, item));
      }

      if (widget.trailing != null) {
        if (items.isNotEmpty || widget.leading != null) {
          itemWidgets.add(SizedBox(width: widget.style.gap));
        }
        itemWidgets.add(widget.trailing!);
      }

      content = Row(
        mainAxisSize: widget.mainAxisSize,
        children: itemWidgets,
      );
    }

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.style.borderRadius,
        boxShadow: widget.style.shadows ?? defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: widget.style.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.style.blurSigma,
            sigmaY: widget.style.blurSigma,
          ),
          child: Container(
            padding: widget.style.padding ??
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: resolvedBg,
              borderRadius: widget.style.borderRadius,
              border: widget.style.border ?? defaultBorder,
            ),
            child: content,
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        final bool isEffectivelyHidden = progress <= 0.001 && !widget.visible;

        if (isEffectivelyHidden) {
          return const SizedBox.shrink();
        }

        Widget animatedChild = child!;

        // Slide
        if (widget.motion.slideDirection != ZetaToolbarSlideDirection.none) {
          final Offset offset = _calculateSlideOffset(progress);
          animatedChild = Transform.translate(
            offset: offset,
            child: animatedChild,
          );
        }

        // Scale
        if (widget.motion.scale) {
          final double scale = (0.85 + 0.15 * progress).clamp(0.0, 2.0);
          animatedChild = Transform.scale(
            scale: scale,
            child: animatedChild,
          );
        }

        // Fade
        if (widget.motion.fade) {
          final double opacity = progress.clamp(0.0, 1.0);
          animatedChild = Opacity(
            opacity: opacity,
            child: animatedChild,
          );
        }

        return IgnorePointer(
          ignoring: !widget.visible && progress < 0.5,
          child: animatedChild,
        );
      },
      child: surface,
    );
  }
}
