import 'package:material_ui/material_ui.dart';

/// Expressive geometric logo mirroring Sharva's purple gradient lightning bolt.
class ZetaLogo extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ZetaLogo({
    super.key,
    this.size = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ZetaLogoPainter(),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: logoWidget,
        ),
      );
    }

    return logoWidget;
  }
}

class _ZetaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9333EA), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Stylized lightning bolt matching Sharva brand
    final path = Path()
      ..moveTo(w * 0.62, h * 0.04)
      ..lineTo(w * 0.22, h * 0.52)
      ..lineTo(w * 0.50, h * 0.52)
      ..lineTo(w * 0.38, h * 0.96)
      ..lineTo(w * 0.82, h * 0.44)
      ..lineTo(w * 0.54, h * 0.44)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
