import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Renders the user's avatar.
/// If a photo is set, displays the photo.
/// If no photo is set, displays the first letter of the user's name.
///
/// [ringColor] overrides the ring and glow color — e.g. pass a sync-status
/// color from [TaskProvider] to reflect sync state in the ring.
/// When null the avatar accent color from [ThemeProvider] is used.
class UserAvatar extends StatelessWidget {
  final double radius;
  final bool showRing;
  final double ringWidth;
  final double? fontSize;
  final VoidCallback? onTap;

  /// Optional ring + glow color override. Null = use accent color from ThemeProvider.
  final Color? ringColor;

  const UserAvatar({
    super.key,
    this.radius = 20,
    this.showRing = true,
    this.ringWidth = 2.0,
    this.fontSize,
    this.onTap,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final accentColor = themeProvider.currentAvatarColor;
    final effectiveRingColor = ringColor ?? accentColor;
    final diameter = radius * 2;
    final initial = themeProvider.avatarInitial;
    final effectiveFontSize = fontSize ?? (radius * 0.85);

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
      if (themeProvider.hasAvatarPhoto) {
        final photo = themeProvider.avatarPhoto!;
        try {
          if (photo.startsWith('http://') || photo.startsWith('https://')) {
            return Image.network(
              photo,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallbackInitial(),
            );
          } else if (photo.startsWith('data:image')) {
            final base64Str = photo.contains(',')
                ? photo.split(',').last
                : photo;
            final bytes = base64Decode(base64Str.trim());
            return Image.memory(
              bytes,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallbackInitial(),
            );
          } else {
            // Raw base64 string or URI
            final bytes = base64Decode(photo.trim());
            return Image.memory(
              bytes,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallbackInitial(),
            );
          }
        } catch (_) {
          return fallbackInitial();
        }
      }
      return fallbackInitial();
    }

    Widget content = Container(
      width: diameter + (showRing ? (ringWidth * 2 + 4) : 0),
      height: diameter + (showRing ? (ringWidth * 2 + 4) : 0),
      padding: showRing ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: showRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: effectiveRingColor, width: ringWidth),
              boxShadow: [
                BoxShadow(
                  color: effectiveRingColor.withValues(alpha: 0.30),
                  blurRadius: 8,
                ),
              ],
            )
          : null,
      child: ClipOval(
        child: Container(
          width: diameter,
          height: diameter,
          color: accentColor.withValues(alpha: 0.18),
          child: avatarContent(),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius * 2),
        child: content,
      );
    }

    return content;
  }
}
