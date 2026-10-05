import 'package:material_ui/material_ui.dart';

import 'glass_surface.dart';

export 'glass_button.dart' show GlassButton;

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
          child: GlassSurface(
            borderRadius: radius,
            blurSigma: blurSigma,
            color: bg,
            border: borderDecoration,
            material: true,
            child: dialogBody,
          ),
        ),
      ),
    );
  }
}
