import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:flutter/material.dart';

void testSubjectsListPattern() {
  M3ECardList(
    variant: M3ECardVariant.filled,
    selection: true,
    itemCount: 3,
    itemBuilder: (BuildContext context, int index) {
      return M3EListItem(
        headline: 'Mathematics',
        supportingText: '3/5 completed (60%) · 1 due',
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(M3EIcons.inbox, color: Colors.blue, size: 20),
        ),
        trailing: const Icon(M3EIcons.chevron_right),
        selected: index == 0,
        onTap: () {},
      );
    },
  );
}
