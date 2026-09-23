import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../components/segmented_column.dart';
import '../../../components/user_avatar.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/haptics.dart';

class ProfileSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const ProfileSection({super.key, this.onToast});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final SupabaseService _supabase = SupabaseService();

  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isSyncing = false;

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
    ZetaHaptics.light();
    themeProvider.setUserName(trimmed);
    setState(() => _isEditingName = false);
    widget.onToast?.call('Name updated and saved to database');
  }

  void _saveEmail(ThemeProvider themeProvider) {
    final trimmed = _emailController.text.trim();
    if (trimmed.isNotEmpty && !trimmed.contains('@')) {
      widget.onToast?.call('Please enter a valid email address');
      return;
    }
    ZetaHaptics.light();
    themeProvider.setUserEmail(trimmed);
    setState(() => _isEditingEmail = false);
    widget.onToast?.call(
      trimmed.isEmpty
          ? 'Email removed from database'
          : 'Email saved to database',
    );
  }

  Future<void> _handleDbSync(ThemeProvider themeProvider) async {
    ZetaHaptics.light();
    setState(() => _isSyncing = true);
    widget.onToast?.call('Syncing profile with database...');
    try {
      await themeProvider.syncProfileWithDb();
      if (!mounted) return;
      _nameController.text = themeProvider.userName;
      _emailController.text = themeProvider.userEmail;
      widget.onToast?.call('Profile synchronized with database successfully');
    } catch (e) {
      if (!mounted) return;
      widget.onToast?.call('Could not sync with database: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _pickImageFile(ThemeProvider themeProvider) async {
    ZetaHaptics.light();
    try {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.isNotEmpty) {
          final processedBytes = await _resizeImageBytes(bytes);
          final encoded = 'data:image/png;base64,${base64Encode(processedBytes)}';
          themeProvider.setAvatarPhoto(encoded);
          widget.onToast?.call('Profile photo updated and saved to database.');
        }
      }
    } catch (e) {
      widget.onToast?.call('Could not pick image: $e');
    }
  }

  Future<Uint8List> _resizeImageBytes(Uint8List bytes, {int maxDimension = 512}) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxDimension,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (_) {}
    return bytes;
  }

  void _showImageUrlDialog(BuildContext context, ThemeProvider themeProvider) {
    ZetaHaptics.light();
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
            'Photo Web URL',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter link to your avatar image:',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'https://...',
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
                  widget.onToast?.call('Profile photo saved to database.');
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasPhoto = themeProvider.hasAvatarPhoto;
    final isConnected = _supabase.isAuthenticated;

    final displayEmail = themeProvider.userEmail;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Hero Profile Card (M3 Expressive) ─────────────────────────
            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const UserAvatar(
                            radius: 36,
                            showRing: true,
                            ringWidth: 3.0,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        themeProvider.userName,
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.onSurface,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isConnected
                                            ? const Color(0xFF10B981)
                                                  .withValues(alpha: 0.15)
                                            : colorScheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isConnected
                                                ? Icons.cloud_done_rounded
                                                : Icons.shield_outlined,
                                            size: 11,
                                            color: isConnected
                                                ? const Color(0xFF10B981)
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isConnected ? 'SYNCED' : 'LOCAL',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                              color: isConnected
                                                  ? const Color(0xFF10B981)
                                                  : colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayEmail.isNotEmpty
                                      ? displayEmail
                                      : 'No email address configured',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Photo Action Button Group (M3 Expressive Connected)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: M3EButtonGroup(
                          type: M3EButtonGroupType.standard,
                          style: M3EButtonStyle.tonal,
                          // size: M3EButtonSize.custom(
                          //   height: 96,
                          //   hPadding: 48,
                          //   iconSize: 32,
                          //   iconGap: 10,
                          // ),
                          shape: M3EButtonShape.round,
                          selectedIndex: null,
                          onSelectedIndexChanged: (index) {
                            if (index == 0) {
                              _pickImageFile(themeProvider);
                            } else if (index == 1) {
                              _showImageUrlDialog(context, themeProvider);
                            } else if (index == 2 && hasPhoto) {
                              ZetaHaptics.light();
                              themeProvider.clearAvatarPhoto();
                              widget.onToast?.call(
                                'Photo removed from database. Using initial "${themeProvider.avatarInitial}".',
                              );
                            }
                          },
                          actions: [
                            M3EButtonGroupAction(
                              icon: const Icon(Icons.file_upload_outlined, size: 16),
                              label: const Text('Upload'),
                              tooltip: 'Upload image from local storage',
                              decoration: M3EToggleButtonDecoration.styleFrom(
                                backgroundColor: colorScheme.secondaryContainer,
                                foregroundColor:
                                    colorScheme.onSecondaryContainer,
                              ),
                            ),
                            M3EButtonGroupAction(
                              icon: const Icon(Icons.link_rounded, size: 16),
                              label: const Text('URL'),
                              tooltip: 'Set avatar image from URL',
                              decoration: M3EToggleButtonDecoration.styleFrom(
                                backgroundColor: colorScheme.secondaryContainer,
                                foregroundColor:
                                    colorScheme.onSecondaryContainer,
                              ),
                            ),
                            if (hasPhoto)
                              M3EButtonGroupAction(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                ),
                                label: const Text('Remove'),
                                tooltip: 'Remove custom photo',
                                decoration: M3EToggleButtonDecoration.styleFrom(
                                  backgroundColor: colorScheme.errorContainer,
                                  foregroundColor: colorScheme.onErrorContainer,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 2. PERSONAL DETAILS ──────────────────────────────────────────
            Text(
              'Personal Details',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Item 1: Display Name
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: 22,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Display Name',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (!_isEditingName) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    themeProvider.userName,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          M3EButton.icon(
                            icon: Icon(
                              _isEditingName
                                  ? Icons.close_rounded
                                  : Icons.edit_rounded,
                              size: 15,
                            ),
                            label: Text(_isEditingName ? 'Cancel' : 'Edit'),
                            style: _isEditingName
                                ? M3EButtonStyle.outlined
                                : M3EButtonStyle.tonal,
                            size: M3EButtonSize.sm,
                            onPressed: () {
                              ZetaHaptics.light();
                              _nameController.text = themeProvider.userName;
                              setState(() => _isEditingName = !_isEditingName);
                            },
                          ),
                        ],
                      ),
                      if (_isEditingName) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Enter display name',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
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
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Item 2: Email Address
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 22,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email Address',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (!_isEditingEmail) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    themeProvider.userEmail.isNotEmpty
                                        ? themeProvider.userEmail
                                        : 'Not configured (tap to add)',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          M3EButton.icon(
                            icon: Icon(
                              _isEditingEmail
                                  ? Icons.close_rounded
                                  : (themeProvider.userEmail.isNotEmpty
                                        ? Icons.edit_rounded
                                        : Icons.add_rounded),
                              size: 15,
                            ),
                            label: Text(
                              _isEditingEmail
                                  ? 'Cancel'
                                  : (themeProvider.userEmail.isNotEmpty
                                        ? 'Edit'
                                        : 'Add'),
                            ),
                            style: _isEditingEmail
                                ? M3EButtonStyle.outlined
                                : M3EButtonStyle.tonal,
                            size: M3EButtonSize.sm,
                            onPressed: () {
                              ZetaHaptics.light();
                              _emailController.text = themeProvider.userEmail;
                              setState(
                                () => _isEditingEmail = !_isEditingEmail,
                              );
                            },
                          ),
                        ],
                      ),
                      if (_isEditingEmail) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: Row(
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
                                      horizontal: 14,
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
                              if (themeProvider.userEmail.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                M3EButton(
                                  style: M3EButtonStyle.outlined,
                                  size: M3EButtonSize.sm,
                                  onPressed: () {
                                    _emailController.clear();
                                    _saveEmail(themeProvider);
                                  },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 3. DATABASE & CLOUD SYNC ─────────────────────────────────────
            Text(
              'Database & Cloud Sync',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: Color(0xFF4285F4),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supabase Profiles Storage',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Profile name, email, and avatar photo are saved in the database',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      M3EButton.icon(
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Sync'),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: _isSyncing
                            ? null
                            : () => _handleDbSync(themeProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 4. Explanatory Footer with Info Icon ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your profile details are stored in the database and synchronized across your sessions. Personal information is only accessible by you.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
