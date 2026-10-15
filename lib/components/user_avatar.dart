import 'package:zeta/core/core.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';

/// Available avatar shape geometries.
enum UserAvatarShape {
  circle,
  bun,
  cookie4Sided,
  cookie9Sided,
  clover4Leaf,
  sunny,
  softBoom,
  heart,
  gem;

  /// Returns the corresponding [M3EShapeKind], or `null` for circular geometry.
  M3EShapeKind? get m3eShapeKind {
    return switch (this) {
      UserAvatarShape.circle => null,
      UserAvatarShape.bun => M3EShapeKind.bun,
      UserAvatarShape.cookie4Sided => M3EShapeKind.cookie4Sided,
      UserAvatarShape.cookie9Sided => M3EShapeKind.cookie9Sided,
      UserAvatarShape.clover4Leaf => M3EShapeKind.clover4Leaf,
      UserAvatarShape.sunny => M3EShapeKind.sunny,
      UserAvatarShape.softBoom => M3EShapeKind.softBoom,
      UserAvatarShape.heart => M3EShapeKind.heart,
      UserAvatarShape.gem => M3EShapeKind.gem,
    };
  }
}

/// Renders the user's avatar.
/// If a photo is set, displays the photo without blinking or refreshing.
/// If no photo is set, displays the first letter of the user's name.
///
/// Features expressive ambient glow in the sync state color instead of a ring,
/// supporting multiple Material 3 Expressive shapes.
class UserAvatar extends StatelessWidget {
  final double radius;
  final bool showRing;
  final bool showGlow;
  final double ringWidth;
  final double? glowRadius;
  final double? fontSize;
  final VoidCallback? onTap;

  /// Optional sync-status ring color. Defaults to the active theme primary.
  final Color? ringColor;

  /// Optional custom glow color. Defaults to [ringColor] or active theme primary.
  final Color? glowColor;

  /// Optional tooltip message to display on hover/long-press.
  final String? tooltip;

  /// Optional flag indicating whether there is an active sync or data error.
  /// When true, renders an error badge indicator on the avatar.
  final bool hasError;

  /// Optional custom badge widget displayed over the avatar corner.
  final Widget? badge;

  /// Shape geometry of the avatar (circle, bun, cookie, clover, etc.).
  final UserAvatarShape shape;

  const UserAvatar({
    super.key,
    this.radius = 20,
    this.showRing = false,
    this.showGlow = true,
    this.ringWidth = 2.0,
    this.glowRadius,
    this.fontSize,
    this.onTap,
    this.ringColor,
    this.glowColor,
    this.tooltip,
    this.hasError = false,
    this.badge,
    this.shape = UserAvatarShape.circle,
  });

  // In-memory cache for decoded base64 avatar bytes to avoid re-allocating
  // and re-resolving MemoryImage on every rebuild (which causes photo blinking).
  static final Map<int, Uint8List> _base64Cache = {};

  static Uint8List? getOrDecodeBase64(String? str) {
    if (str == null || str.isEmpty) return null;
    final key = str.hashCode;
    final cached = _base64Cache[key];
    if (cached != null) return cached;
    try {
      if (_base64Cache.length > 20) _base64Cache.clear();
      final base64Str = str.contains(',') ? str.split(',').last : str;
      final decoded = base64Decode(base64Str.trim());
      _base64Cache[key] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final accentColor = context.colorScheme.primary;
    final effectiveRingColor = ringColor ?? accentColor;
    final effectiveGlowColor = glowColor ?? ringColor ?? accentColor;
    final effectiveGlowRadius = glowRadius ?? (radius * 0.3).clamp(5.0, 16.0);
    final diameter = radius * 2;
    final initial = profileProvider.avatarInitial;
    final effectiveFontSize = fontSize ?? (radius * 0.85);
    final hasPhoto = profileProvider.hasAvatarPhoto;
    final photo = profileProvider.avatarPhoto;
    final m3eKind = shape.m3eShapeKind;

    Widget fallbackInitial() {
      return Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
      );
    }

    Widget avatarContent() {
      if (hasPhoto && photo != null) {
        if (!kIsWeb &&
            (photo.startsWith('/') ||
                photo.contains(r':\') ||
                photo.contains(r':/') ||
                photo.startsWith('file:'))) {
          final filePath = photo.startsWith('file://')
              ? photo.replaceFirst('file://', '')
              : photo;
          final file = File(filePath);
          if (file.existsSync()) {
            return Image.file(
              file,
              key: ValueKey(
                '${file.path}_${file.lastModifiedSync().millisecondsSinceEpoch}',
              ),
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => fallbackInitial(),
            );
          }
        }
        if (photo.startsWith('http://') || photo.startsWith('https://')) {
          return Image.network(
            photo,
            key: ValueKey(photo),
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => fallbackInitial(),
          );
        } else {
          final bytes = getOrDecodeBase64(photo);
          if (bytes != null) {
            return Image.memory(
              bytes,
              key: ValueKey(bytes),
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => fallbackInitial(),
            );
          }
        }
      }
      return fallbackInitial();
    }

    final innerAvatar = Container(
      width: diameter,
      height: diameter,
      color: accentColor.withValues(alpha: 0.18),
      child: avatarContent(),
    );

    final Widget clippedAvatar = m3eKind != null
        ? ClipPath(
            clipper: M3EShapeClipper(m3eKind),
            child: innerAvatar,
          )
        : ClipOval(
            child: innerAvatar,
          );

    final Widget content = RepaintBoundary(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Ambient glow aura in the sync status color
            if (showGlow)
              Positioned.fill(
                child: CustomPaint(
                  painter: _M3EShapeGlowPainter(
                    kind: m3eKind,
                    color: effectiveGlowColor,
                    blurRadius: effectiveGlowRadius,
                  ),
                ),
              ),

            // 2. Avatar face (photo / initial) clipped to shape
            clippedAvatar,

            // 3. Optional stroked ring contour
            if (showRing)
              Positioned.fill(
                child: CustomPaint(
                  painter: _M3EShapeBorderPainter(
                    kind: m3eKind,
                    color: effectiveRingColor,
                    strokeWidth: ringWidth,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final borderRadius = switch (shape) {
      UserAvatarShape.circle => BorderRadius.circular(radius * 2),
      UserAvatarShape.bun => BorderRadius.circular(radius * 0.7),
      UserAvatarShape.gem => BorderRadius.circular(radius * 0.7),
      UserAvatarShape.clover4Leaf => BorderRadius.circular(radius * 0.8),
      UserAvatarShape.cookie4Sided => BorderRadius.circular(radius * 0.6),
      UserAvatarShape.cookie9Sided => BorderRadius.circular(radius * 0.8),
      UserAvatarShape.sunny => BorderRadius.circular(radius * 0.8),
      UserAvatarShape.softBoom => BorderRadius.circular(radius * 0.7),
      UserAvatarShape.heart => BorderRadius.circular(radius * 0.6),
    };

    final Widget interactiveWidget = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: content,
          )
        : content;

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: interactiveWidget);
    }

    return interactiveWidget;
  }
}

/// Paints a soft multi-tier ambient glow matching the avatar's shape contour.
class _M3EShapeGlowPainter extends CustomPainter {
  final M3EShapeKind? kind;
  final Color color;
  final double blurRadius;

  const _M3EShapeGlowPainter({
    required this.kind,
    required this.color,
    required this.blurRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0.0 || blurRadius <= 0) return;

    final path = kind == null || kind == M3EShapeKind.circle
        ? (Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height)))
        : M3EShapeClipper(kind!).getClip(size);

    // Multi-tier ambient bloom:
    // 1. Soft atmospheric halo
    final atmosphericPaint = Paint()
      ..color = color.withValues(alpha: 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius * 1.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, atmosphericPaint);

    // 2. Focused mid glow
    final midPaint = Paint()
      ..color = color.withValues(alpha: 0.50)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius * 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, midPaint);

    // 3. Vibrant edge aura
    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius * 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _M3EShapeGlowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.blurRadius != blurRadius ||
        oldDelegate.kind != kind;
  }
}

/// Paints the stroked outline of an [M3EShapeKind] contour fitted to the widget.
class _M3EShapeBorderPainter extends CustomPainter {
  final M3EShapeKind? kind;
  final Color color;
  final double strokeWidth;

  const _M3EShapeBorderPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeWidth <= 0 || color.a == 0.0) return;
    final halfStroke = strokeWidth / 2;
    final drawRect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      math.max(0.0, size.width - strokeWidth),
      math.max(0.0, size.height - strokeWidth),
    );
    if (kind == null || kind == M3EShapeKind.circle) {
      final path = Path()..addOval(drawRect);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
    } else {
      canvas.save();
      canvas.translate(halfStroke, halfStroke);
      final drawSize = Size(drawRect.width, drawRect.height);
      final path = M3EShapeClipper(kind!).getClip(drawSize);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _M3EShapeBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.kind != kind;
  }
}
