import 'package:flutter/material.dart';

class TodayMilestonesCard extends StatelessWidget {
  final int todayActiveCount;

  const TodayMilestonesCard({
    super.key,
    required this.todayActiveCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blueBg = isDark ? const Color(0xFF1B2B46) : const Color(0xFFD8E6FF);
    final blueText = isDark ? const Color(0xFFADC6FF) : const Color(0xFF0D2A58);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: blueBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 22,
              color: blueText,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$todayActiveCount Today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: blueText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Milestones due before end of day.',
                  style: TextStyle(
                    fontSize: 12,
                    color: blueText.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}