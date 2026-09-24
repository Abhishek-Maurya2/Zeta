import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';

/// Renders the user's avatar.
/// If a photo is set, displays the photo without blinking or refreshing.
/// If no photo is set, displays the first letter of the user's name.
///
/// [ringColor] can show the account sync state. Avatar appearance itself uses
/// the active Material theme and has no per-profile color customization.
class UserAvatar extends StatelessWidget {
  final double radius;
  final bool showRing;
  final double ringWidth;
  final double? fontSize;
  final VoidCallback? onTap;

  /// Optional sync-status ring color. Defaults to the active theme primary.
  final Color? ringColor;

  /// Optional tooltip message to display on hover/long-press.
  final String? tooltip;

  const UserAvatar({
    super.key,
    this.radius = 20,
    this.showRing = true,
    this.ringWidth = 2.0,
    this.fontSize,
    this.onTap,
    this.ringColor,
    this.tooltip,
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
    final accentColor = Theme.of(context).colorScheme.primary;
    final effectiveRingColor = ringColor ?? accentColor;
    final diameter = radius * 2;
    final initial = profileProvider.avatarInitial;
    final effectiveFontSize = fontSize ?? (radius * 0.85);
    final hasPhoto = profileProvider.hasAvatarPhoto;
    final photo = profileProvider.avatarPhoto;

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

    final Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: diameter + (showRing ? (ringWidth * 2 + 4) : 0),
      height: diameter + (showRing ? (ringWidth * 2 + 4) : 0),
      padding: showRing ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: showRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: effectiveRingColor, width: ringWidth),
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

    final Widget interactiveWidget = onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius * 2),
            child: content,
          )
        : content;

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: interactiveWidget);
    }

    return interactiveWidget;
  }
}
