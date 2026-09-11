import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../widgets/segmented_column.dart';

import '../../providers/theme_provider.dart';

class ProfileSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const ProfileSection({super.key, this.onToast});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _nameController = TextEditingController(text: themeProvider.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName(ThemeProvider themeProvider) {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      widget.onToast?.call('Display name cannot be empty');
      return;
    }
    themeProvider.setUserName(trimmed);
    setState(() => _isEditingName = false);
    widget.onToast?.call('Display name updated to "$trimmed"');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFILE',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainer,
          children: [
            // ─── Item 1: Profile Photo ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x3310B981), blurRadius: 8),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        themeProvider.userInitials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Photo',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Account avatar and visual representation',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      M3EButton.icon(
                        icon: const Icon(Icons.photo_camera_rounded, size: 16),
                        label: const Text('Change'),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: () {
                          widget.onToast?.call('Avatar presets updated');
                        },
                      ),
                      M3EButton.icon(
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reset'),
                        style: M3EButtonStyle.outlined,
                        size: M3EButtonSize.sm,
                        onPressed: () {
                          themeProvider.setUserName('Abhishek');
                          _nameController.text = 'Abhishek';
                          widget.onToast?.call('Avatar reset to default image.');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Item 2: Display Name ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Name',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (!_isEditingName) ...[
                              const SizedBox(height: 2),
                              Text(
                                themeProvider.userName,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!_isEditingName)
                        M3EButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit name'),
                          style: M3EButtonStyle.tonal,
                          size: M3EButtonSize.sm,
                          onPressed: () {
                            _nameController.text = themeProvider.userName;
                            setState(() => _isEditingName = true);
                          },
                        ),
                    ],
                  ),
                  if (_isEditingName) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Enter your display name',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _saveName(themeProvider),
                          ),
                        ),
                        const SizedBox(width: 8),
                        M3EButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Save'),
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.sm,
                          onPressed: () => _saveName(themeProvider),
                        ),
                        const SizedBox(width: 6),
                        M3EButton(
                          style: M3EButtonStyle.outlined,
                          size: M3EButtonSize.sm,
                          onPressed: () {
                            _nameController.text = themeProvider.userName;
                            setState(() => _isEditingName = false);
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
