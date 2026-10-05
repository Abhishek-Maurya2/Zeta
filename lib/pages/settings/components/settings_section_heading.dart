import 'package:material_ui/material_ui.dart';

class SettingsSectionHeading extends StatelessWidget {
  final String title;

  const SettingsSectionHeading(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.labelMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: colorScheme.primary,
      ),
    );
  }
}
