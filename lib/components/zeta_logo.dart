import 'package:flutter/material.dart';

/// App logo rendering the official Zeta icon from assets/logo/logo.png.
class ZetaLogo extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const ZetaLogo({super.key, this.size = 28, this.onTap, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.22);

    Widget logoWidget = Image.asset(
      'assets/logo/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        final theme = Theme.of(context);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: effectiveRadius,
          ),
          child: Center(
            child: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: size * 0.55,
            ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      logoWidget = ClipRRect(borderRadius: borderRadius!, child: logoWidget);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: logoWidget),
      );
    }

    return logoWidget;
  }
}
