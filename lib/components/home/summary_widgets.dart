import 'package:material_ui/material_ui.dart';

/// Summary Widgets mirroring Sharva's SummaryWidgets:
/// 1. Active Tasks: Top green expressive card with large counter and today's scheduled count.
/// 2. Completion Rate: Warm terracotta card with percentage.
/// 3. Completed Tasks: Golden amber card with completed counter.
/// 4. Today Milestones: Bottom blue card with today's milestones.
class SummaryWidgets extends StatelessWidget {
  final int activeCount;
  final int todayActiveCount;
  final int completionRate;
  final int completedCount;

  const SummaryWidgets({
    super.key,
    required this.activeCount,
    required this.todayActiveCount,
    required this.completionRate,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Card 1: Active Tasks (Green)
    final greenBg = isDark ? const Color(0xFF1A3821) : const Color(0xFFD4F8D3);
    final greenText = isDark ? const Color(0xFFA6F0B0) : const Color(0xFF0F3D17);

    // Card 2: Completion Rate (Terracotta)
    final terraBg = isDark ? const Color(0xFF3D2017) : const Color(0xFFFFE3D6);
    final terraText = isDark ? const Color(0xFFFFB59F) : const Color(0xFF4D1F11);

    // Card 3: Completed Tasks (Amber)
    final amberBg = isDark ? const Color(0xFF393110) : const Color(0xFFFFF0C2);
    final amberText = isDark ? const Color(0xFFFFE082) : const Color(0xFF463B05);

    // Card 4: Milestones (Blue)
    final blueBg = isDark ? const Color(0xFF1B2B46) : const Color(0xFFD8E6FF);
    final blueText = isDark ? const Color(0xFFADC6FF) : const Color(0xFF0D2A58);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Widget 1: Active Tasks (Top Green Card) ─────────────────────────
        Container(
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
                  Icon(
                    Icons.check_circle_rounded,
                    size: 26,
                    color: greenText,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
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
        ),

        const SizedBox(height: 14),

        // ─── Widgets 2 & 3: Completion Rate & Completed Tasks ────────────────
        Row(
          children: [
            // Completion Rate
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: terraBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 24,
                      color: terraText,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$completionRate%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: terraText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Completion\nRate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: terraText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Completed Tasks
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: amberBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 24,
                      color: amberText,
                    ),
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
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ─── Widget 4: Today Milestones (Bottom Blue Card) ───────────────────
        Container(
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
        ),
      ],
    );
  }
}
