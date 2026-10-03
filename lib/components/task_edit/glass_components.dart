import 'dart:ui';
import 'package:material_ui/material_ui.dart';

class GlassButton extends StatelessWidget {
  final Widget child;
  final bool isCompact;
  final Color borderColor;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.child,
    required this.isCompact,
    required this.borderColor,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCompact) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  final Widget child;
  final bool isCompact;
  final ColorScheme colorScheme;
  final bool selected;
  final double borderRadius;

  const GlassChip({
    super.key,
    required this.child,
    required this.isCompact,
    required this.colorScheme,
    this.selected = false,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCompact) return child;
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.20,
                      ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
