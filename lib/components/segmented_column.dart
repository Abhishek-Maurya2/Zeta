import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:material_3_expressive/material_3_expressive.dart';

export 'zeta_empty_state.dart';

/// Segmented list decoration matching M3 Expressive card style.
class M3ESegmentedListDecoration {
  final EdgeInsetsGeometry? padding;
  final double outerRadius;
  final double innerRadius;
  final double selectedRadius;
  final double gap;
  final Color? color;
  final BorderSide? border;

  const M3ESegmentedListDecoration({
    this.padding,
    this.outerRadius = 24.0,
    this.innerRadius = 4.0,
    this.selectedRadius = 50.0,
    this.gap = 3.0,
    this.color,
    this.border,
  });
}

/// A Material 3 Expressive segmented column that dynamically rounds corners
/// using [M3ECardList] from `material_3_expressive`.
class M3ESegmentedColumn extends StatelessWidget {
  final List<Widget> children;
  final M3ESegmentedListDecoration? decoration;
  final Color? color;
  final double outerRadius;
  final double innerRadius;
  final double selectedRadius;
  final double gap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Widget? emptyBuilder;
  final int? selectedIndex;
  final M3ESelectionController? selectionController;
  final void Function(int index)? onTap;
  final Color? Function(int index)? colorBuilder;
  final BorderRadius? Function(int index, M3ECardPosition position)?
  borderRadiusBuilder;

  const M3ESegmentedColumn({
    super.key,
    required this.children,
    this.decoration,
    this.color,
    this.outerRadius = 24.0,
    this.innerRadius = 4.0,
    this.selectedRadius = 50.0,
    this.gap = 3.0,
    this.padding,
    this.margin,
    this.emptyBuilder,
    this.selectedIndex,
    this.selectionController,
    this.onTap,
    this.colorBuilder,
    this.borderRadiusBuilder,
  });

  BorderRadius _getTileBorderRadius({
    required int index,
    required int totalCount,
    required double outerRadius,
    required double innerRadius,
    required double selectedRadius,
    bool isSelected = false,
  }) {
    if (isSelected) {
      return BorderRadius.circular(selectedRadius);
    }
    if (totalCount == 1) {
      return BorderRadius.circular(outerRadius);
    }
    if (index == 0) {
      return BorderRadius.vertical(
        top: Radius.circular(outerRadius),
        bottom: Radius.circular(innerRadius),
      );
    }
    if (index == totalCount - 1) {
      return BorderRadius.vertical(
        top: Radius.circular(innerRadius),
        bottom: Radius.circular(outerRadius),
      );
    }
    return BorderRadius.circular(innerRadius);
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return emptyBuilder ?? const SizedBox.shrink();
    }

    final effectiveOuterRadius = decoration?.outerRadius ?? outerRadius;
    final effectiveInnerRadius = decoration?.innerRadius ?? innerRadius;
    final effectiveSelectedRadius =
        decoration?.selectedRadius ?? selectedRadius;
    final effectiveGap = decoration?.gap ?? gap;
    final effectiveColor = decoration?.color ?? color;
    final effectivePadding = decoration?.padding ?? padding;
    final effectiveBorder = decoration?.border;

    BorderRadius? Function(int index, M3ECardPosition position)?
    effectiveRadiusBuilder = borderRadiusBuilder;
    if (effectiveRadiusBuilder == null &&
        (selectedIndex != null || selectionController != null)) {
      effectiveRadiusBuilder = (index, position) {
        final isSelected =
            (selectionController?.isSelected(index) ?? false) ||
            (selectedIndex != null && index == selectedIndex);
        if (isSelected) {
          return BorderRadius.circular(effectiveSelectedRadius);
        }
        return null;
      };
    }

    Widget list = ClipRRect(
      borderRadius: BorderRadius.circular(effectiveOuterRadius),
      child: M3ECardList(
        itemCount: children.length,
        itemBuilder: (context, index) {
          final position = children.length == 1
              ? M3ECardPosition.single
              : (index == 0
                  ? M3ECardPosition.first
                  : (index == children.length - 1
                      ? M3ECardPosition.last
                      : M3ECardPosition.middle));

          final isSelected =
              (selectionController?.isSelected(index) ?? false) ||
              (selectedIndex != null && index == selectedIndex);

          final cellRadius = borderRadiusBuilder?.call(index, position) ??
              _getTileBorderRadius(
                index: index,
                totalCount: children.length,
                outerRadius: effectiveOuterRadius,
                innerRadius: effectiveInnerRadius,
                selectedRadius: effectiveSelectedRadius,
                isSelected: isSelected,
              );

          return ListTileTheme(
            shape: RoundedRectangleBorder(borderRadius: cellRadius),
            child: ClipRRect(
              borderRadius: cellRadius,
              child: Material(
                color: Colors.transparent,
                borderRadius: cellRadius,
                clipBehavior: Clip.antiAlias,
                child: children[index],
              ),
            ),
          );
        },
        outerRadius: effectiveOuterRadius,
        innerRadius: effectiveInnerRadius,
        gap: effectiveGap,
        color: effectiveColor,
        colorBuilder: colorBuilder,
        borderRadiusBuilder: effectiveRadiusBuilder,
        padding: effectivePadding,
        margin: margin,
        border: effectiveBorder,
        emptyBuilder: emptyBuilder,
        onTap: onTap,
      ),
    );

    if (selectionController != null) {
      list = M3ESelectionScope(
        controller: selectionController!,
        itemCount: children.length,
        child: list,
      );
    } else if (selectedIndex != null) {
      list = M3ESelectionScope(
        controller: M3ESelectionController(initialSelected: {selectedIndex!}),
        itemCount: children.length,
        child: list,
      );
    }

    return list;
  }
}
