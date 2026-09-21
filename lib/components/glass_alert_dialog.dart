import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shows a dialog with a frosted glassmorphic surface and dimmed barrier.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.15),
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: builder,
  );
}

/// An expressive dialog with container-bounded backdrop blur,
/// translucent background, zero elevation, subtle glass borders,
/// and properly constrained intrinsic height and width.
class GlassAlertDialog extends StatelessWidget {
  final Widget? icon;
  final EdgeInsetsGeometry? iconPadding;
  final Color? iconColor;
  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;
  final Widget? content;
  final EdgeInsetsGeometry? contentPadding;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Border? border;
  final EdgeInsets insetPadding;
  final bool scrollable;
  final double? width;
  final double? minWidth;
  final double? maxWidth;
  final double? maxHeight;

  const GlassAlertDialog({
    super.key,
    this.icon,
    this.iconPadding,
    this.iconColor,
    this.title,
    this.titlePadding,
    this.content,
    this.contentPadding,
    this.actions,
    this.actionsPadding,
    this.actionsAlignment,
    this.borderRadius,
    this.blurSigma = 6.0,
    this.backgroundColor,
    this.border,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 24.0,
    ),
    this.scrollable = false,
    this.width,
    this.minWidth,
    this.maxWidth = 480.0,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = borderRadius ?? BorderRadius.circular(28);
    final bg =
        backgroundColor ??
        colorScheme.surfaceContainerHigh.withValues(alpha: 0.55);
    final borderDecoration =
        border ??
        Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1.0,
        );

    final resolvedTitlePadding =
        titlePadding ??
        EdgeInsets.fromLTRB(
          24.0,
          icon == null ? 24.0 : 16.0,
          24.0,
          content == null ? 20.0 : 16.0,
        );

    final resolvedContentPadding =
        contentPadding ??
        EdgeInsets.fromLTRB(
          24.0,
          (title == null && icon == null) ? 24.0 : 0.0,
          24.0,
          actions == null ? 24.0 : 20.0,
        );

    final resolvedActionsPadding =
        actionsPadding ?? const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 20.0);

    Widget? contentWidget = content;
    if (contentWidget != null && scrollable) {
      contentWidget = SingleChildScrollView(child: contentWidget);
    }

    final dialogBody = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null)
          Padding(
            padding:
                iconPadding ?? const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
            child: IconTheme(
              data: IconThemeData(
                color: iconColor ?? colorScheme.secondary,
                size: 28.0,
              ),
              child: icon!,
            ),
          ),
        if (title != null)
          Padding(
            padding: resolvedTitlePadding,
            child: DefaultTextStyle(
              style: textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              child: title!,
            ),
          ),
        if (contentWidget != null)
          Flexible(
            child: Padding(
              padding: resolvedContentPadding,
              child: DefaultTextStyle(
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                child: contentWidget,
              ),
            ),
          ),
        if (actions != null && actions!.isNotEmpty)
          Padding(
            padding: resolvedActionsPadding,
            child: OverflowBar(
              alignment: actionsAlignment ?? MainAxisAlignment.end,
              spacing: 8.0,
              overflowSpacing: 8.0,
              children: actions!,
            ),
          ),
      ],
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: insetPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: width ?? minWidth ?? 280.0,
            maxWidth: width ?? maxWidth ?? 480.0,
            maxHeight: maxHeight ?? double.infinity,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: radius,
                  border: borderDecoration,
                ),
                child: Material(color: Colors.transparent, child: dialogBody),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glassmorphic button with container-bounded backdrop blur,
/// translucent background, crisp glass border, zero elevation,
/// and M3 expressive interactive states.
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

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius = 20.0,
    this.blurSigma = 6.0,
    this.size = M3EButtonSize.sm,
    this.isDestructive = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;

    if (isDestructive) {
      bg = backgroundColor ?? colorScheme.error.withValues(alpha: 0.80);
      fg = foregroundColor ?? Colors.white;
    } else if (isPrimary) {
      bg = backgroundColor ?? colorScheme.primary.withValues(alpha: 0.85);
      fg = foregroundColor ?? colorScheme.onPrimary;
    } else {
      bg =
          backgroundColor ??
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
      fg = foregroundColor ?? colorScheme.onSurface;
    }

    final buttonDecoration = M3EButtonDecoration(
      backgroundColor: WidgetStatePropertyAll(bg),
      foregroundColor: WidgetStatePropertyAll(fg),
      elevation: const WidgetStatePropertyAll(0.0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    );

    final button = icon != null
        ? M3EButton.icon(
            onPressed: onPressed,
            size: size,
            icon: icon!,
            label: child,
            decoration: buttonDecoration,
          )
        : M3EButton(
            onPressed: onPressed,
            size: size,
            decoration: buttonDecoration,
            child: child,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            // border: Border.all(color: border, width: 1.0),
          ),
          child: button,
        ),
      ),
    );
  }
}
