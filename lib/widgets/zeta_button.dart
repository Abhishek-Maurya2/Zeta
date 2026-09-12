import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Proportional measurements and styling presets for Zeta buttons.
class ZetaButtonScale {
  final double height;
  final double defaultFontSize;
  final double defaultIconSize;
  final double iconGap;
  final double hPadding;

  const ZetaButtonScale({
    required this.height,
    required this.defaultFontSize,
    required this.defaultIconSize,
    required this.iconGap,
    required this.hPadding,
  });

  /// Resolves the proportional scale metrics for a given [M3EButtonSize].
  static ZetaButtonScale resolve(M3EButtonSize size) {
    switch (size.name) {
      case 'xs':
        return const ZetaButtonScale(
          height: 32,
          defaultFontSize: 12.0,
          defaultIconSize: 16.0,
          iconGap: 6.0,
          hPadding: 12.0,
        );
      case 'sm':
        return const ZetaButtonScale(
          height: 40,
          defaultFontSize: 14.0,
          defaultIconSize: 20.0,
          iconGap: 8.0,
          hPadding: 16.0,
        );
      case 'md':
        return const ZetaButtonScale(
          height: 48,
          defaultFontSize: 16.0,
          defaultIconSize: 24.0,
          iconGap: 8.0,
          hPadding: 20.0,
        );
      case 'lg':
        return const ZetaButtonScale(
          height: 64,
          defaultFontSize: 18.0,
          defaultIconSize: 28.0,
          iconGap: 10.0,
          hPadding: 24.0,
        );
      case 'xl':
        return const ZetaButtonScale(
          height: 80,
          defaultFontSize: 22.0,
          defaultIconSize: 34.0,
          iconGap: 12.0,
          hPadding: 28.0,
        );
      default:
        return const ZetaButtonScale(
          height: 40,
          defaultFontSize: 14.0,
          defaultIconSize: 20.0,
          iconGap: 8.0,
          hPadding: 16.0,
        );
    }
  }
}

/// A Material 3 Expressive button with proportional label/icon scaling
/// and explicit manual controls for [labelFontSize] and [iconSize].
class ZetaButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final String? labelText;
  final M3EButtonSize size;
  final M3EButtonStyle style;
  final M3EButtonShape shape;
  final double? labelFontSize;
  final FontWeight? labelFontWeight;
  final double? iconSize;
  final double? iconGap;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final M3EButtonDecoration? decoration;
  final String? tooltip;
  final String? semanticLabel;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onLongPress;

  const ZetaButton({
    super.key,
    required this.onPressed,
    this.child,
    this.icon,
    this.label,
    this.labelText,
    this.size = M3EButtonSize.sm,
    this.style = M3EButtonStyle.filled,
    this.shape = M3EButtonShape.round,
    this.labelFontSize,
    this.labelFontWeight,
    this.iconSize,
    this.iconGap,
    this.height,
    this.width,
    this.padding,
    this.decoration,
    this.tooltip,
    this.semanticLabel,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  });

  /// Factory constructor for buttons with an icon and label.
  factory ZetaButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    required Widget icon,
    Widget? label,
    String? labelText,
    M3EButtonSize size = M3EButtonSize.sm,
    M3EButtonStyle style = M3EButtonStyle.filled,
    M3EButtonShape shape = M3EButtonShape.round,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? iconSize,
    double? iconGap,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
    M3EButtonDecoration? decoration,
    String? tooltip,
    String? semanticLabel,
    bool enabled = true,
    FocusNode? focusNode,
    bool autofocus = false,
    VoidCallback? onLongPress,
  }) {
    return ZetaButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
      label: label,
      labelText: labelText,
      size: size,
      style: style,
      shape: shape,
      labelFontSize: labelFontSize,
      labelFontWeight: labelFontWeight,
      iconSize: iconSize,
      iconGap: iconGap,
      height: height,
      width: width,
      padding: padding,
      decoration: decoration,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      onLongPress: onLongPress,
    );
  }

  /// Convenience factory for filled button style.
  factory ZetaButton.filled({
    Key? key,
    required VoidCallback? onPressed,
    Widget? icon,
    Widget? label,
    String? labelText,
    M3EButtonSize size = M3EButtonSize.sm,
    M3EButtonShape shape = M3EButtonShape.round,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? iconSize,
    double? iconGap,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
    M3EButtonDecoration? decoration,
    String? tooltip,
    bool enabled = true,
    Widget? child,
  }) {
    return ZetaButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
      label: label,
      labelText: labelText,
      size: size,
      style: M3EButtonStyle.filled,
      shape: shape,
      labelFontSize: labelFontSize,
      labelFontWeight: labelFontWeight,
      iconSize: iconSize,
      iconGap: iconGap,
      height: height,
      width: width,
      padding: padding,
      decoration: decoration,
      tooltip: tooltip,
      enabled: enabled,
      child: child,
    );
  }

  /// Convenience factory for tonal button style.
  factory ZetaButton.tonal({
    Key? key,
    required VoidCallback? onPressed,
    Widget? icon,
    Widget? label,
    String? labelText,
    M3EButtonSize size = M3EButtonSize.sm,
    M3EButtonShape shape = M3EButtonShape.round,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? iconSize,
    double? iconGap,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
    M3EButtonDecoration? decoration,
    String? tooltip,
    bool enabled = true,
    Widget? child,
  }) {
    return ZetaButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
      label: label,
      labelText: labelText,
      size: size,
      style: M3EButtonStyle.tonal,
      shape: shape,
      labelFontSize: labelFontSize,
      labelFontWeight: labelFontWeight,
      iconSize: iconSize,
      iconGap: iconGap,
      height: height,
      width: width,
      padding: padding,
      decoration: decoration,
      tooltip: tooltip,
      enabled: enabled,
      child: child,
    );
  }

  /// Convenience factory for outlined button style.
  factory ZetaButton.outlined({
    Key? key,
    required VoidCallback? onPressed,
    Widget? icon,
    Widget? label,
    String? labelText,
    M3EButtonSize size = M3EButtonSize.sm,
    M3EButtonShape shape = M3EButtonShape.round,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? iconSize,
    double? iconGap,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
    M3EButtonDecoration? decoration,
    String? tooltip,
    bool enabled = true,
    Widget? child,
  }) {
    return ZetaButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
      label: label,
      labelText: labelText,
      size: size,
      style: M3EButtonStyle.outlined,
      shape: shape,
      labelFontSize: labelFontSize,
      labelFontWeight: labelFontWeight,
      iconSize: iconSize,
      iconGap: iconGap,
      height: height,
      width: width,
      padding: padding,
      decoration: decoration,
      tooltip: tooltip,
      enabled: enabled,
      child: child,
    );
  }

  /// Convenience factory for text button style.
  factory ZetaButton.text({
    Key? key,
    required VoidCallback? onPressed,
    Widget? icon,
    Widget? label,
    String? labelText,
    M3EButtonSize size = M3EButtonSize.sm,
    M3EButtonShape shape = M3EButtonShape.round,
    double? labelFontSize,
    FontWeight? labelFontWeight,
    double? iconSize,
    double? iconGap,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
    M3EButtonDecoration? decoration,
    String? tooltip,
    bool enabled = true,
    Widget? child,
  }) {
    return ZetaButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
      label: label,
      labelText: labelText,
      size: size,
      style: M3EButtonStyle.text,
      shape: shape,
      labelFontSize: labelFontSize,
      labelFontWeight: labelFontWeight,
      iconSize: iconSize,
      iconGap: iconGap,
      height: height,
      width: width,
      padding: padding,
      decoration: decoration,
      tooltip: tooltip,
      enabled: enabled,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = ZetaButtonScale.resolve(size);
    final effectiveHeight = height ?? scale.height;
    final effectiveFontSize = labelFontSize ?? scale.defaultFontSize;
    final effectiveIconSize = iconSize ?? scale.defaultIconSize;
    final effectiveIconGap = iconGap ?? scale.iconGap;
    final effectiveHPadding = padding != null ? null : scale.hPadding;

    final baseLabelStyle = Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

    final styledTextTheme = baseLabelStyle.copyWith(
      fontSize: effectiveFontSize,
      fontWeight: labelFontWeight ?? baseLabelStyle.fontWeight,
    );

    // Build the icon widget with forced icon size so Icon(size: ...) doesn't override
    Widget? resolvedIcon;
    if (icon != null) {
      if (icon is Icon) {
        final ic = icon as Icon;
        resolvedIcon = Icon(
          ic.icon,
          size: effectiveIconSize,
          color: ic.color,
          fill: ic.fill,
          weight: ic.weight,
          grade: ic.grade,
          opticalSize: ic.opticalSize,
          shadows: ic.shadows,
          semanticLabel: ic.semanticLabel,
          textDirection: ic.textDirection,
          applyTextScaling: ic.applyTextScaling,
        );
      } else {
        resolvedIcon = IconTheme.merge(
          data: IconThemeData(size: effectiveIconSize),
          child: icon!,
        );
      }
    }

    // Build the label widget
    Widget? resolvedLabel;
    if (labelText != null) {
      resolvedLabel = Text(
        labelText!,
        style: styledTextTheme,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (label != null) {
      if (label is Text) {
        final t = label as Text;
        final mergedStyle = (t.style != null)
            ? t.style!.copyWith(
                fontSize: effectiveFontSize,
                fontWeight: labelFontWeight ?? t.style!.fontWeight,
              )
            : styledTextTheme;
        if (t.textSpan != null) {
          resolvedLabel = Text.rich(
            t.textSpan!,
            style: mergedStyle,
            strutStyle: t.strutStyle,
            textAlign: t.textAlign,
            textDirection: t.textDirection,
            locale: t.locale,
            softWrap: t.softWrap,
            overflow: t.overflow ?? TextOverflow.ellipsis,
            textScaler: t.textScaler,
            maxLines: t.maxLines ?? 1,
            semanticsLabel: t.semanticsLabel,
            textWidthBasis: t.textWidthBasis,
            selectionColor: t.selectionColor,
          );
        } else {
          resolvedLabel = Text(
            t.data ?? '',
            style: mergedStyle,
            strutStyle: t.strutStyle,
            textAlign: t.textAlign,
            textDirection: t.textDirection,
            locale: t.locale,
            softWrap: t.softWrap,
            overflow: t.overflow ?? TextOverflow.ellipsis,
            textScaler: t.textScaler,
            maxLines: t.maxLines ?? 1,
            semanticsLabel: t.semanticsLabel,
            textWidthBasis: t.textWidthBasis,
            selectionColor: t.selectionColor,
          );
        }
      } else {
        resolvedLabel = DefaultTextStyle.merge(
          style: styledTextTheme,
          overflow: TextOverflow.ellipsis,
          child: label!,
        );
      }
    }

    // Assemble button child
    Widget? effectiveChild;
    if (resolvedIcon != null && resolvedLabel != null) {
      effectiveChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          resolvedIcon,
          SizedBox(width: effectiveIconGap),
          Flexible(child: resolvedLabel),
        ],
      );
    } else if (resolvedIcon != null) {
      effectiveChild = resolvedIcon;
    } else if (resolvedLabel != null) {
      effectiveChild = resolvedLabel;
    } else if (child != null) {
      effectiveChild = DefaultTextStyle.merge(
        style: styledTextTheme,
        child: child!,
      );
    }

    // Use M3EButtonSize.custom to inject height, padding, and icon sizing
    final customButtonSize = M3EButtonSize.custom(
      height: effectiveHeight,
      hPadding: effectiveHPadding,
      iconSize: effectiveIconSize,
      iconGap: effectiveIconGap,
      width: width,
    );

    final mergedDecoration = (decoration ?? const M3EButtonDecoration());

    return M3EButton(
      onPressed: onPressed,
      style: style,
      size: customButtonSize,
      shape: shape,
      enabled: enabled,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      onLongPress: onLongPress,
      decoration: mergedDecoration,
      child: effectiveChild,
    );
  }
}

/// A Material 3 Expressive icon button with proportional sizing
/// and manual control over [iconSize] and [buttonSize].
class ZetaIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final M3EIconButtonSize size;
  final M3EIconButtonVariant variant;
  final M3EIconButtonShapeVariant shape;
  final double? iconSize;
  final double? buttonSize;
  final String? tooltip;
  final String? semanticLabel;
  final bool? isSelected;
  final Widget? selectedIcon;
  final Color? color;
  final Color? backgroundColor;
  final bool enableFeedback;

  const ZetaIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = M3EIconButtonSize.sm,
    this.variant = M3EIconButtonVariant.standard,
    this.shape = M3EIconButtonShapeVariant.round,
    this.iconSize,
    this.buttonSize,
    this.tooltip,
    this.semanticLabel,
    this.isSelected,
    this.selectedIcon,
    this.color,
    this.backgroundColor,
    this.enableFeedback = true,
  });

  /// Factory for standard icon button.
  const ZetaIconButton.standard({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = M3EIconButtonSize.sm,
    this.shape = M3EIconButtonShapeVariant.round,
    this.iconSize,
    this.buttonSize,
    this.tooltip,
    this.semanticLabel,
    this.isSelected,
    this.selectedIcon,
    this.color,
    this.backgroundColor,
    this.enableFeedback = true,
  }) : variant = M3EIconButtonVariant.standard;

  /// Factory for filled icon button.
  const ZetaIconButton.filled({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = M3EIconButtonSize.sm,
    this.shape = M3EIconButtonShapeVariant.round,
    this.iconSize,
    this.buttonSize,
    this.tooltip,
    this.semanticLabel,
    this.isSelected,
    this.selectedIcon,
    this.color,
    this.backgroundColor,
    this.enableFeedback = true,
  }) : variant = M3EIconButtonVariant.filled;

  /// Factory for tonal icon button.
  const ZetaIconButton.tonal({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = M3EIconButtonSize.sm,
    this.shape = M3EIconButtonShapeVariant.round,
    this.iconSize,
    this.buttonSize,
    this.tooltip,
    this.semanticLabel,
    this.isSelected,
    this.selectedIcon,
    this.color,
    this.backgroundColor,
    this.enableFeedback = true,
  }) : variant = M3EIconButtonVariant.tonal;

  /// Factory for outlined icon button.
  const ZetaIconButton.outlined({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = M3EIconButtonSize.sm,
    this.shape = M3EIconButtonShapeVariant.round,
    this.iconSize,
    this.buttonSize,
    this.tooltip,
    this.semanticLabel,
    this.isSelected,
    this.selectedIcon,
    this.color,
    this.backgroundColor,
    this.enableFeedback = true,
  }) : variant = M3EIconButtonVariant.outlined;

  static double _defaultIconSizeFor(M3EIconButtonSize size) {
    switch (size) {
      case M3EIconButtonSize.xs:
        return 18.0;
      case M3EIconButtonSize.sm:
        return 22.0;
      case M3EIconButtonSize.md:
        return 26.0;
      case M3EIconButtonSize.lg:
        return 32.0;
      case M3EIconButtonSize.xl:
        return 40.0;
    }
  }

  static double _defaultVisualDimensionFor(M3EIconButtonSize size) {
    switch (size) {
      case M3EIconButtonSize.xs:
        return 32.0;
      case M3EIconButtonSize.sm:
        return 40.0;
      case M3EIconButtonSize.md:
        return 48.0;
      case M3EIconButtonSize.lg:
        return 56.0;
      case M3EIconButtonSize.xl:
        return 64.0;
    }
  }

  Widget _buildIcon(Widget rawIcon, double targetSize, Color? targetColor) {
    if (rawIcon is Icon) {
      return Icon(
        rawIcon.icon,
        size: targetSize,
        color: targetColor ?? rawIcon.color,
        fill: rawIcon.fill,
        weight: rawIcon.weight,
        grade: rawIcon.grade,
        opticalSize: rawIcon.opticalSize,
        shadows: rawIcon.shadows,
        semanticLabel: rawIcon.semanticLabel,
        textDirection: rawIcon.textDirection,
        applyTextScaling: rawIcon.applyTextScaling,
      );
    }
    return IconTheme.merge(
      data: IconThemeData(size: targetSize, color: targetColor),
      child: rawIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? _defaultIconSizeFor(size);
    final effectiveVisualDim = buttonSize ?? _defaultVisualDimensionFor(size);
    final effectiveVisualSize = Size(effectiveVisualDim, effectiveVisualDim);

    final resolvedIcon = _buildIcon(icon, effectiveIconSize, color);
    final resolvedSelectedIcon = selectedIcon != null
        ? _buildIcon(selectedIcon!, effectiveIconSize, color)
        : null;

    final dec = (backgroundColor != null || color != null)
        ? M3EIconButtonDecoration(
            backgroundColor: backgroundColor != null
                ? WidgetStateProperty.all(backgroundColor)
                : null,
            foregroundColor: color != null
                ? WidgetStateProperty.all(color)
                : null,
          )
        : null;

    return M3EIconButton(
      icon: resolvedIcon,
      onPressed: onPressed,
      size: size,
      variant: variant,
      shape: shape,
      visualSize: effectiveVisualSize,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      isSelected: isSelected,
      selectedIcon: resolvedSelectedIcon,
      enableFeedback: enableFeedback,
      decoration: dec,
    );
  }
}

/// An Extended FAB widget that allows manual control over [labelFontSize],
/// [iconSize], height, padding, and corner radius.
class ZetaExtendedFab extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool extended;
  final M3EFabColor color;
  final double? labelFontSize;
  final FontWeight? labelFontWeight;
  final double? iconSize;
  final double height;
  final double cornerRadius;
  final double extendedHorizontalPadding;
  final double collapsedHorizontalPadding;
  final double iconLabelGap;
  final double? elevation;
  final double? hoverElevation;
  final String? tooltip;

  const ZetaExtendedFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.extended = true,
    this.color = M3EFabColor.primary,
    this.labelFontSize,
    this.labelFontWeight,
    this.iconSize,
    this.height = 56.0,
    this.cornerRadius = 16.0,
    this.extendedHorizontalPadding = 20.0,
    this.collapsedHorizontalPadding = 16.0,
    this.iconLabelGap = 12.0,
    this.elevation,
    this.hoverElevation,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (height >= 60 ? 28.0 : 24.0);
    final effectiveFontSize = labelFontSize ?? (height >= 60 ? 16.0 : 14.5);

    // Build icon with explicit size
    Widget resolvedIcon;
    if (icon is Icon) {
      final ic = icon as Icon;
      resolvedIcon = Icon(
        ic.icon,
        size: effectiveIconSize,
        color: ic.color,
        fill: ic.fill,
        weight: ic.weight,
        grade: ic.grade,
        opticalSize: ic.opticalSize,
        shadows: ic.shadows,
        semanticLabel: ic.semanticLabel,
        textDirection: ic.textDirection,
        applyTextScaling: ic.applyTextScaling,
      );
    } else {
      resolvedIcon = IconTheme.merge(
        data: IconThemeData(size: effectiveIconSize),
        child: icon,
      );
    }

    final baseTheme = Theme.of(context);
    final m3eTheme = M3EThemeData.fromMaterial(baseTheme);

    // Get current label typography from textTheme
    final baseLabelStyle = baseTheme.textTheme.labelLarge ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    final customLabelStyle = baseLabelStyle.copyWith(
      fontSize: effectiveFontSize,
      fontWeight: labelFontWeight ?? FontWeight.w600,
    );

    // Inject custom type scale and fabTheme into M3ETheme
    final customTypeScale = M3ETypeScale.fromTextTheme(
      baseTheme.textTheme.copyWith(
        labelLarge: customLabelStyle,
      ),
    );

    final customFabTheme = m3eTheme.fabTheme.copyWith(
      extended: M3EExtendedFabTheme(
        height: height,
        cornerRadius: cornerRadius,
        extendedHorizontalPadding: extendedHorizontalPadding,
        collapsedHorizontalPadding: collapsedHorizontalPadding,
        iconSize: effectiveIconSize,
        iconLabelGap: iconLabelGap,
      ),
    );

    final modifiedM3ETheme = m3eTheme.copyWith(
      typeScale: customTypeScale,
      fabTheme: customFabTheme,
    );

    return M3ETheme(
      data: modifiedM3ETheme,
      child: M3EExtendedFab(
        label: label,
        icon: resolvedIcon,
        onPressed: onPressed,
        color: color,
        extended: extended,
        elevation: elevation,
        hoverElevation: hoverElevation,
      ),
    );
  }
}

/// A standard Floating Action Button with manual control over [iconSize] and dimensions.
class ZetaFab extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final M3EFabSize size;
  final M3EFabColor color;
  final double? iconSize;
  final double? cornerRadius;
  final double? elevation;
  final double? hoverElevation;
  final String? tooltip;

  const ZetaFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = M3EFabSize.medium,
    this.color = M3EFabColor.primary,
    this.iconSize,
    this.cornerRadius,
    this.elevation,
    this.hoverElevation,
    this.tooltip,
  });

  static double _defaultIconSizeFor(M3EFabSize size) {
    switch (size) {
      case M3EFabSize.small:
        return 20.0;
      case M3EFabSize.medium:
        return 24.0;
      case M3EFabSize.large:
        return 32.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? _defaultIconSizeFor(size);

    Widget resolvedIcon;
    if (icon is Icon) {
      final ic = icon as Icon;
      resolvedIcon = Icon(
        ic.icon,
        size: effectiveIconSize,
        color: ic.color,
        fill: ic.fill,
        weight: ic.weight,
        grade: ic.grade,
        opticalSize: ic.opticalSize,
        shadows: ic.shadows,
        semanticLabel: ic.semanticLabel,
        textDirection: ic.textDirection,
        applyTextScaling: ic.applyTextScaling,
      );
    } else {
      resolvedIcon = IconTheme.merge(
        data: IconThemeData(size: effectiveIconSize),
        child: icon,
      );
    }

    return M3EFab(
      icon: resolvedIcon,
      onPressed: onPressed,
      size: size,
      color: color,
      cornerRadius: cornerRadius,
      elevation: elevation,
      hoverElevation: hoverElevation,
      tooltip: tooltip,
    );
  }
}
