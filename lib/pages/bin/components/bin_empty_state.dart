import 'package:flutter/material.dart';

import '../../../components/zeta_empty_state.dart';

class BinEmptyState extends StatelessWidget {
  final VoidCallback onNavigateToTasks;

  const BinEmptyState({super.key, required this.onNavigateToTasks});

  @override
  Widget build(BuildContext context) {
    return ZetaEmptyState.bin(
      onNavigateToTasks: onNavigateToTasks,
    );
  }
}
