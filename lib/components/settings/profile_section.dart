import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../widgets/user_avatar.dart';
import '../../providers/theme_provider.dart';
import '../../utils/haptics.dart';

class ProfileSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const ProfileSection({super.key, this.onToast});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  bool _isEditingName = false;
  bool _isEditingEmail = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _nameController = TextEditingController(text: themeProvider.userName);
    _emailController = TextEditingController(text: themeProvider.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
    widget.onToast?.call('Name updated to "$trimmed"');
  }

  void _saveEmail(ThemeProvider themeProvider) {
    final trimmed = _emailController.text.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      widget.onToast?.call('Please enter a valid email address');
      return;
    }
    themeProvider.setUserEmail(trimmed);
    setState(() => _isEditingEmail = false);
    widget.onToast?.call('Email address saved');
  }

  Future<void> _pickImageFile(ThemeProvider themeProvider) async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.isNotEmpty) {
          final ext = picked.extension?.toLowerCase() ?? 'png';
          final mime = (ext == 'jpg' || ext == 'jpeg')
              ? 'image/jpeg'
              : 'image/png';
          final encoded = 'data:$mime;base64,${base64Encode(bytes)}';
          themeProvider.setAvatarPhoto(encoded);
          widget.onToast?.call('Profile photo updated successfully.');
        }
      }
    } catch (e) {
      widget.onToast?.call('Could not pick image: $e');
    }
  }

  void _showImageUrlDialog(BuildContext context, ThemeProvider themeProvider) {
    final urlController = TextEditingController(
      text:
          (themeProvider.avatarPhoto != null &&
              themeProvider.avatarPhoto!.startsWith('http'))
          ? themeProvider.avatarPhoto!
          : '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          title: Text(
            'Enter Photo URL',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste any web image URL (e.g. Unsplash, GitHub, Gravatar):',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'https://example.com/photo.jpg',
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = urlController.text.trim();
                if (trimmed.isNotEmpty) {
                  themeProvider.setAvatarPhoto(trimmed);
                  widget.onToast?.call('Profile photo updated from URL.');
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save Photo'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoOptionsSheet(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;

        return Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Profile Photo',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Upload a photo or remove to use letter "${themeProvider.avatarInitial}"',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.file_upload_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text('Choose image file'),
                subtitle: const Text(
                  'Select a JPG or PNG file from your device',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImageFile(themeProvider);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                title: const Text('Enter image URL'),
                subtitle: const Text('Paste a link to any web image'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showImageUrlDialog(context, themeProvider);
                },
              ),
              if (themeProvider.hasAvatarPhoto) ...[
                const Divider(height: 20),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Remove photo',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Switch back to alphabet "${themeProvider.avatarInitial}" as avatar',
                  ),
                  onTap: () {
                    themeProvider.clearAvatarPhoto();
                    Navigator.of(sheetContext).pop();
                    widget.onToast?.call(
                      'Photo removed. Using letter "${themeProvider.avatarInitial}" as avatar.',
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasPhoto = themeProvider.hasAvatarPhoto;

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
          color: colorScheme.surfaceContainerLowest,
          children: [
            // ─── Item 1: Profile Photo & Alphabet Avatar ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;

                  const avatarWidget = UserAvatar(
                    radius: 24,
                    showRing: true,
                    ringWidth: 2.5,
                  );

                  final infoWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPhoto ? 'Profile Photo' : 'Profile Avatar',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPhoto
                            ? 'Custom photo active'
                            : 'Alphabet "${themeProvider.avatarInitial}" derived from ${themeProvider.userName}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );

                  final buttonsWidget = M3EButtonGroup(
                    type: M3EButtonGroupType.standard,
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    selectedIndex: null,
                    onSelectedIndexChanged: (index) {
                      if (index == 0) {
                        ZetaHaptics.light();
                        _showPhotoOptionsSheet(context, themeProvider);
                      } else if (index == 1 && hasPhoto) {
                        ZetaHaptics.light();
                        themeProvider.clearAvatarPhoto();
                        widget.onToast?.call(
                          'Photo removed. Using letter "${themeProvider.avatarInitial}" as avatar.',
                        );
                      }
                    },
                    actions: [
                      M3EButtonGroupAction(
                        icon: Icon(
                          hasPhoto
                              ? Icons.photo_camera_rounded
                              : Icons.add_a_photo_outlined,
                          size: 16,
                        ),
                        label: Text(hasPhoto ? 'Change' : 'Photo'),
                        decoration: M3EToggleButtonDecoration.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      if (hasPhoto)
                        M3EButtonGroupAction(
                          icon: Icon(Icons.close_rounded, size: 16),
                          tooltip: 'Remove photo',
                          decoration: M3EToggleButtonDecoration.styleFrom(
                            backgroundColor: colorScheme.secondaryContainer,
                            foregroundColor: colorScheme.onSecondaryContainer,
                          ),
                        ),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            avatarWidget,
                            const SizedBox(width: 14),
                            Expanded(child: infoWidget),
                          ],
                        ),
                        const SizedBox(height: 12),
                        buttonsWidget,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      avatarWidget,
                      const SizedBox(width: 16),
                      Expanded(child: infoWidget),
                      const SizedBox(width: 8),
                      buttonsWidget,
                    ],
                  );
                },
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
                                  fontWeight: FontWeight.w600,
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
                          label: const Text('Edit'),
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
                              hintText: 'Enter display name',
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

            // ─── Item 3: Email Address ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Address',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (!_isEditingEmail) ...[
                              const SizedBox(height: 2),
                              Text(
                                themeProvider.userEmail,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!_isEditingEmail)
                        M3EButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit'),
                          style: M3EButtonStyle.tonal,
                          size: M3EButtonSize.sm,
                          onPressed: () {
                            _emailController.text = themeProvider.userEmail;
                            setState(() => _isEditingEmail = true);
                          },
                        ),
                    ],
                  ),
                  if (_isEditingEmail) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _saveEmail(themeProvider),
                          ),
                        ),
                        const SizedBox(width: 8),
                        M3EButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Save'),
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.sm,
                          onPressed: () => _saveEmail(themeProvider),
                        ),
                        const SizedBox(width: 6),
                        M3EButton(
                          style: M3EButtonStyle.outlined,
                          size: M3EButtonSize.sm,
                          onPressed: () {
                            _emailController.text = themeProvider.userEmail;
                            setState(() => _isEditingEmail = false);
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
