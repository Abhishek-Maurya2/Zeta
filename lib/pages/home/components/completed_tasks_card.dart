import 'package:flutter/material.dart';

class CompletedTasksCard extends StatelessWidget {
  final int completedCount;

  const CompletedTasksCard({
    super.key,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberBg = isDark ? const Color(0xFF393110) : const Color(0xFFFFF0C2);
    final amberText = isDark ? const Color(0xFFFFE082) : const Color(0xFF463B05);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: amberBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.task_alt_rounded, size: 24, color: amberText),
          const SizedBox(height: 14),
          Text(
            '$completedCount',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: amberText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Completed\nTasks',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: amberText,
            ),
          ),
        ],
      ),
    );
  }
}