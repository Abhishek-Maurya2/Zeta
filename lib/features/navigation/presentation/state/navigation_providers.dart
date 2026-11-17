import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../pages/settings/components/settings_category.dart';
import '../../../../providers/navigation_provider.dart';

/// Immutable state representation for the application's navigation stack and destination state.
@immutable
class NavigationState {
  final List<PageId> pageStack;
  final SettingsCategory? selectedSettingsCategory;
  final bool isRailExpanded;
  final bool isNavigatingBack;
  final String? resumeItemId;

  const NavigationState({
    this.pageStack = const [PageId.home],
    this.selectedSettingsCategory,
    this.isRailExpanded = true,
    this.isNavigatingBack = false,
    this.resumeItemId,
  });

  PageId get activePage =>
      pageStack.isNotEmpty ? pageStack.last : PageId.home;

  bool get canPop =>
      (activePage == PageId.settings && selectedSettingsCategory != null) ||
      pageStack.length > 1;

  NavigationState copyWith({
    List<PageId>? pageStack,
    SettingsCategory? Function()? selectedSettingsCategory,
    bool? isRailExpanded,
    bool? isNavigatingBack,
    String? Function()? resumeItemId,
  }) {
    return NavigationState(
      pageStack: pageStack ?? this.pageStack,
      selectedSettingsCategory: selectedSettingsCategory != null
          ? selectedSettingsCategory()
          : this.selectedSettingsCategory,
      isRailExpanded: isRailExpanded ?? this.isRailExpanded,
      isNavigatingBack: isNavigatingBack ?? this.isNavigatingBack,
      resumeItemId: resumeItemId != null ? resumeItemId() : this.resumeItemId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState &&
          runtimeType == other.runtimeType &&
          listEquals(pageStack, other.pageStack) &&
          selectedSettingsCategory == other.selectedSettingsCategory &&
          isRailExpanded == other.isRailExpanded &&
          isNavigatingBack == other.isNavigatingBack &&
          resumeItemId == other.resumeItemId;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(pageStack),
        selectedSettingsCategory,
        isRailExpanded,
        isNavigatingBack,
        resumeItemId,
      );
}

/// Riverpod StateNotifier managing the declarative navigation stack and settings category state.
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier([NavigationState? initialState])
      : super(initialState ?? const NavigationState());

  void setActivePage(PageId page) {
    if (state.activePage == page) return;

    final newStack = List<PageId>.from(state.pageStack);
    if (page == PageId.home) {
      newStack.clear();
      newStack.add(PageId.home);
    } else {
      newStack.remove(page);
      newStack.add(page);
    }

    state = state.copyWith(
      pageStack: newStack,
      isNavigatingBack: false,
      selectedSettingsCategory: page != PageId.settings ? () => null : null,
    );
  }

  void pushPage(PageId page, {SettingsCategory? category}) {
    if (state.activePage == page) {
      if (category != null && category != state.selectedSettingsCategory) {
        state = state.copyWith(
          selectedSettingsCategory: () => category,
        );
      }
      return;
    }

    final newStack = List<PageId>.from(state.pageStack);
    newStack.remove(page);
    newStack.add(page);

    state = state.copyWith(
      pageStack: newStack,
      isNavigatingBack: false,
      selectedSettingsCategory: () =>
          category ?? (page != PageId.settings ? null : state.selectedSettingsCategory),
    );
  }

  bool pop() {
    // 1. Pop settings category first
    if (state.activePage == PageId.settings &&
        state.selectedSettingsCategory != null) {
      state = state.copyWith(
        selectedSettingsCategory: () => null,
      );
      return true;
    }

    // 2. Pop page stack
    if (state.pageStack.length > 1) {
      final newStack = List<PageId>.from(state.pageStack);
      newStack.removeLast();
      final newActive = newStack.isNotEmpty ? newStack.last : PageId.home;

      state = state.copyWith(
        pageStack: newStack,
        isNavigatingBack: true,
        selectedSettingsCategory:
            newActive != PageId.settings ? () => null : null,
      );
      return true;
    }

    return false;
  }

  void setSettingsCategory(SettingsCategory? category) {
    if (state.selectedSettingsCategory != category) {
      state = state.copyWith(
        selectedSettingsCategory: () => category,
      );
    }
  }

  void clearSettingsCategory() {
    if (state.selectedSettingsCategory != null) {
      state = state.copyWith(
        selectedSettingsCategory: () => null,
      );
    }
  }

  void toggleRailExpanded() {
    state = state.copyWith(
      isRailExpanded: !state.isRailExpanded,
    );
  }

  void setRailExpanded(bool expanded) {
    if (state.isRailExpanded != expanded) {
      state = state.copyWith(
        isRailExpanded: expanded,
      );
    }
  }

  void resumeTo({
    required PageId page,
    String? itemId,
    SettingsCategory? category,
  }) {
    final newStack = List<PageId>.from(state.pageStack);
    if (page == PageId.home) {
      newStack.clear();
      newStack.add(PageId.home);
    } else {
      newStack.remove(page);
      newStack.add(page);
    }

    state = state.copyWith(
      pageStack: newStack,
      selectedSettingsCategory: () => category,
      resumeItemId: () => itemId,
    );
  }

  void clearResumeItemId() {
    if (state.resumeItemId != null) {
      state = state.copyWith(
        resumeItemId: () => null,
      );
    }
  }
}

/// Global Riverpod provider for navigation state and operations.
final navigationNotifierProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

/// Selector provider for the active PageId.
final activePageProvider = Provider<PageId>((ref) {
  return ref.watch(navigationNotifierProvider.select((s) => s.activePage));
});

/// Selector provider for the current settings category.
final selectedSettingsCategoryProvider = Provider<SettingsCategory?>((ref) {
  return ref.watch(
    navigationNotifierProvider.select((s) => s.selectedSettingsCategory),
  );
});

/// Selector provider for the page stack.
final pageStackProvider = Provider<List<PageId>>((ref) {
  return ref.watch(navigationNotifierProvider.select((s) => s.pageStack));
});

/// Selector provider for navigation rail expansion state.
final isRailExpandedProvider = Provider<bool>((ref) {
  return ref.watch(navigationNotifierProvider.select((s) => s.isRailExpanded));
});

/// Selector provider for canPop.
final canPopNavigationProvider = Provider<bool>((ref) {
  return ref.watch(navigationNotifierProvider.select((s) => s.canPop));
});
