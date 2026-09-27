import 'package:flutter/material.dart';

class ActiveTasksCard extends StatelessWidget {
  final int activeCount;
  final int todayActiveCount;

  const ActiveTasksCard({
    super.key,
    required this.activeCount,
    required this.todayActiveCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenBg = isDark ? const Color(0xFF1A3821) : const Color(0xFFD4F8D3);
    final greenText = isDark ? const Color(0xFFA6F0B0) : const Color(0xFF0F3D17);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: greenBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.check_circle_rounded, size: 26, color: greenText),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: greenText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$activeCount',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: greenText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Active Tasks',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: greenText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$todayActiveCount task${todayActiveCount == 1 ? "" : "s"} scheduled for today',
            style: TextStyle(
              fontSize: 12,
              color: greenText.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}