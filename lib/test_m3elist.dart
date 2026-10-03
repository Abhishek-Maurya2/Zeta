import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:flutter/material.dart';

Widget test() {
  return M3EList(
    itemCount: 2,
    itemBuilder: (context, index) => M3EListItem(headline: 'Test'),
    physics: const NeverScrollableScrollPhysics(),
  );
}
