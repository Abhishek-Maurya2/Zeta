import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// A custom wrapper that tricks [M3EList] into applying its native 
/// swipe/expand physics to any arbitrary custom widget.
class M3ECustomListItem extends M3EListItem {
  final Widget customChild;

  const M3ECustomListItem({
    super.key,
    required this.customChild,
    super.swipe,
    super.expanded,
    super.transform,
  }) : super(
          // We must provide dummy values for required fields 
          // because we are extending M3EListItem.
          headline: '', 
        );

  @override
  Widget build(BuildContext context) {
    // 1. By extending M3EListItem, the parent M3EList extracts our `swipe` property.
    // 2. By overriding build(), we throw away M3EListItem's rigid text layout 
    //    and just render our totally custom UI!
    return customChild;
  }
}
