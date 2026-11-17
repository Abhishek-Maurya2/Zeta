import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/preferences_service.dart';
import '../../../../theme/breakpoints.dart';

/// State representation for settings split pane resizing and collapsing.
@immutable
class SettingsSplitPaneState {
  static const double defaultPaneWidth = ZetaBreakpoints.paneFixedExpanded;
  static const double largePaneWidth = ZetaBreakpoints.paneFixedLarge;
  static const double minPaneWidth = ZetaBreakpoints.paneMinList;
  static const double minContentPaneWidth = ZetaBreakpoints.paneMinContent;
  static const double collapseThreshold = 180.0;

  final double paneWidth;
  final bool isPaneCollapsed;
  final bool hasCustomWidth;

  const SettingsSplitPaneState({
    this.paneWidth = defaultPaneWidth,
    this.isPaneCollapsed = false,
    this.hasCustomWidth = false,
  });

  SettingsSplitPaneState copyWith({
    double? paneWidth,
    bool? isPaneCollapsed,
    bool? hasCustomWidth,
  }) {
    return SettingsSplitPaneState(
      paneWidth: paneWidth ?? this.paneWidth,
      isPaneCollapsed: isPaneCollapsed ?? this.isPaneCollapsed,
      hasCustomWidth: hasCustomWidth ?? this.hasCustomWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsSplitPaneState &&
          runtimeType == other.runtimeType &&
          paneWidth == other.paneWidth &&
          isPaneCollapsed == other.isPaneCollapsed &&
          hasCustomWidth == other.hasCustomWidth;

  @override
  int get hashCode => Object.hash(
        paneWidth,
        isPaneCollapsed,
        hasCustomWidth,
      );
}

/// Riverpod StateNotifier managing the Settings two-pane split state with persistence.
class SettingsSplitPaneNotifier extends StateNotifier<SettingsSplitPaneState> {
  static const String _prefKeyPaneWidth = 'settings_pane_width';
  static const String _prefKeyPaneCollapsed = 'settings_pane_collapsed';

  final PreferencesService _prefs;

  SettingsSplitPaneNotifier([PreferencesService? prefs])
      : _prefs = prefs ?? PreferencesService.instance,
        super(const SettingsSplitPaneState()) {
    _loadSavedSettings();
  }

  void _loadSavedSettings() {
    try {
      final savedWidth = _prefs.getDouble(_prefKeyPaneWidth);
      final savedCollapsed = _prefs.getBool(_prefKeyPaneCollapsed);

      double initialWidth = state.paneWidth;
      bool hasCustom = false;
      bool isCollapsed = state.isPaneCollapsed;

      if (savedWidth != null &&
          savedWidth >= SettingsSplitPaneState.minPaneWidth) {
        initialWidth = savedWidth;
        hasCustom = true;
      }
      if (savedCollapsed != null) {
        isCollapsed = savedCollapsed;
      }

      state = state.copyWith(
        paneWidth: initialWidth,
        isPaneCollapsed: isCollapsed,
        hasCustomWidth: hasCustom,
      );
    } catch (_) {}
  }

  Future<void> _persistSettings() async {
    try {
      await _prefs.setDouble(_prefKeyPaneWidth, state.paneWidth);
      await _prefs.setBool(_prefKeyPaneCollapsed, state.isPaneCollapsed);
    } catch (_) {}
  }

  /// Sets the pane width during dragging or layout changes.
  void setWidth(double width) {
    if (state.paneWidth != width || state.isPaneCollapsed) {
      state = state.copyWith(
        paneWidth: width,
        hasCustomWidth: true,
        isPaneCollapsed: false,
      );
    }
  }

  /// Called when the drag ends to commit persistence and handle edge collapse.
  void onDragEnd(double finalWidth, double totalWidth) {
    if (finalWidth < SettingsSplitPaneState.collapseThreshold) {
      state = state.copyWith(
        isPaneCollapsed: true,
        hasCustomWidth: true,
      );
    } else {
      state = state.copyWith(
        paneWidth: finalWidth,
        hasCustomWidth: true,
        isPaneCollapsed: false,
      );
    }
    _persistSettings();
  }

  /// Toggles or sets pane collapse state.
  void setCollapsed(bool collapsed) {
    if (state.isPaneCollapsed != collapsed) {
      final width = state.paneWidth < SettingsSplitPaneState.minPaneWidth
          ? SettingsSplitPaneState.defaultPaneWidth
          : state.paneWidth;

      state = state.copyWith(
        isPaneCollapsed: collapsed,
        paneWidth: width,
      );
      _persistSettings();
    }
  }

  /// Double tap to toggle between standard width and expanded 50% split.
  void handleDoubleTap(double totalWidth) {
    final maxAllowed = (totalWidth -
            SettingsSplitPaneState.minContentPaneWidth -
            16.0)
        .clamp(
      SettingsSplitPaneState.minPaneWidth,
      totalWidth * 0.6,
    );
    final currentWidth = state.hasCustomWidth
        ? state.paneWidth
        : (totalWidth >= 1200
            ? SettingsSplitPaneState.largePaneWidth
            : SettingsSplitPaneState.defaultPaneWidth);
    final isNearStandard =
        (currentWidth - SettingsSplitPaneState.defaultPaneWidth).abs() < 10.0;

    final double newWidth = isNearStandard
        ? (totalWidth * 0.5).clamp(
            SettingsSplitPaneState.minPaneWidth,
            maxAllowed,
          )
        : SettingsSplitPaneState.defaultPaneWidth;

    state = state.copyWith(
      isPaneCollapsed: false,
      hasCustomWidth: true,
      paneWidth: newWidth,
    );
    _persistSettings();
  }
}

/// Global Riverpod provider for Settings split pane state and resizing actions.
final settingsSplitPaneProvider =
    StateNotifierProvider<SettingsSplitPaneNotifier, SettingsSplitPaneState>(
        (ref) {
  return SettingsSplitPaneNotifier();
});
