import 'package:material_ui/material_ui.dart';

import '../../../models/task.dart';
import '../../../components/task_card_item.dart';

/// Legacy/convenience wrapper for [TaskCardItem] configured for deleted bin tasks.
/// Shared across the app to ensure maximum modularity and reusability.
class BinItem extends StatelessWidget {
  final Task task;
  final bool isExpanded;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;
  final VoidCallback? onToggleExpand;
  final void Function(Offset globalPosition)? onContextMenu;

  const BinItem({
    super.key,
    required this.task,
    required this.onRestore,
    required this.onPermanentDelete,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return TaskCardItem(
      task: task,
      isDeleted: true,
      isExpanded: isExpanded,
      onToggleExpand: onToggleExpand,
      onRestore: onRestore,
      onPermanentDelete: onPermanentDelete,
      onContextMenu: onContextMenu,
    );
  }
}

/// Expressive alias for [BinItem] clearly indicating it renders a deleted task card.
typedef BinTaskCard = BinItem;
