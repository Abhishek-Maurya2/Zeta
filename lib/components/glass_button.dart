import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'glass_surface.dart';

/// Expressive action button with a shared translucent glass surface.
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double blurSigma;
  final M3EButtonSize size;
  final bool isDestructive;
  final bool isPrimary;
  final bool iconOnly;
  final M3EIconButtonWidth iconButtonWidth;
  final M3EIconButtonVariant iconButtonVariant;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius = 20,
    this.blurSigma = 6,
    this.size = M3EButtonSize.sm,
    this.isDestructive = false,
    this.isPrimary = false,
    this.iconOnly = false,
    this.iconButtonWidth = M3EIconButtonWidth.wide,
    this.iconButtonVariant = M3EIconButtonVariant.standard,
  });

  const GlassButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconButtonWidth = M3EIconButtonWidth.wide,
    this.iconButtonVariant = M3EIconButtonVariant.standard,
    this.borderColor,
    this.borderRadius = 20,
    this.blurSigma = 6,
  }) : child = const SizedBox.shrink(),
       backgroundColor = null,
       foregroundColor = null,
       size = M3EButtonSize.sm,
       isDestructive = false,
       isPrimary = false,
       iconOnly = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color background;
    final Color foreground;
    if (isDestructive) {
      background = backgroundColor ?? colorScheme.error.withValues(alpha: 0.80);
      foreground = foregroundColor ?? Colors.white;
    } else if (isPrimary) {
      background =
          backgroundColor ?? colorScheme.primary.withValues(alpha: 0.85);
      foreground = foregroundColor ?? colorScheme.onPrimary;
    } else {
      background =
          backgroundColor ??
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
      foreground = foregroundColor ?? colorScheme.onSurface;
    }

    final decoration = M3EButtonDecoration(
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: WidgetStatePropertyAll(foreground),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    );
    final button = iconOnly && icon != null
        ? M3EIconButton(
            onPressed: onPressed,
            icon: icon!,
            width: iconButtonWidth,
            variant: iconButtonVariant,
          )
        : icon == null
        ? M3EButton(
            onPressed: onPressed,
            size: size,
            decoration: decoration,
            child: child,
          )
        : M3EButton.icon(
            onPressed: onPressed,
            size: size,
            icon: icon!,
            label: child,
            decoration: decoration,
          );

    return GlassSurface(
      borderRadius: BorderRadius.circular(borderRadius),
      blurSigma: blurSigma,
      border: borderColor == null ? null : Border.all(color: borderColor!),
      child: button,
    );
  }
}
