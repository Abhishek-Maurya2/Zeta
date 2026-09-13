import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Renders the user's avatar.
/// If a photo is set, displays the photo without blinking or refreshing.
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

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: diameter + (showRing ? (ringWidth * 2 + 4) : 0),
      height: diameter + (showRing ? (ringWidth * 2 + 4) : 0),
      padding: showRing ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: showRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: effectiveRingColor, width: ringWidth),
              boxShadow: [
                BoxShadow(
                  color: effectiveRingColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            )
          : null,
      child: RepaintBoundary(
        child: ClipOval(
          child: Container(
            width: diameter,
            height: diameter,
            color: accentColor.withValues(alpha: 0.18),
            child: avatarContent(),
          ),
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
