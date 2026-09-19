import 'package:flutter/material.dart';

/// App logo rendering the official Zeta icon from assets/logo/logo.png.
class ZetaLogo extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const ZetaLogo({super.key, this.size = 28, this.onTap, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Image.asset(
      'assets/logo/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
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
