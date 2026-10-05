import 'package:material_ui/material_ui.dart';


import 'glass_surface.dart';

Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightFactor = 0.85,
  double maxWidth = 600,
  double blurSigma = 6,
  Color? barrierColor,
  Color? surfaceColor,
  bool useSafeArea = false,
  bool avoidKeyboard = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.15),
    builder: (sheetContext) => GlassSheet(
      maxHeightFactor: maxHeightFactor,
      maxWidth: maxWidth,
      blurSigma: blurSigma,
      surfaceColor: surfaceColor,
      avoidKeyboard: avoidKeyboard,
      child: builder(sheetContext),
    ),
  );
}

/// Standard bottom-sheet frame with the app's translucent blurred surface.
class GlassSheet extends StatelessWidget {
  final Widget child;
  final double maxHeightFactor;
  final double maxWidth;
  final double blurSigma;
  final Color? surfaceColor;
  final BorderRadiusGeometry borderRadius;
  final bool avoidKeyboard;
  final bool material;
  final bool showBorder;

  const GlassSheet({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.85,
    this.maxWidth = 600,
    this.blurSigma = 6,
    this.surfaceColor,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(28)),
    this.avoidKeyboard = true,
    this.material = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius;
    final effectiveSurfaceColor =
        surfaceColor ??
        colorScheme.tertiaryContainer.withValues(alpha: 0.4);

    return Align(
      alignment: Alignment.bottomCenter,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
          maxWidth: maxWidth,
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: avoidKeyboard ? MediaQuery.viewInsetsOf(context).bottom : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.28 : 0.15,
                ),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GlassSurface(
            borderRadius: radius,
            blurSigma: blurSigma,
            color: effectiveSurfaceColor,
            border: showBorder
                ? Border.all(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.24 : 0.30,
                    ),
                  )
                : null,
            material: material,
            child: child,
          ),
        ),
      ),
    );
  }
}
