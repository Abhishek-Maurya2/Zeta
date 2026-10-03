import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../components/user_avatar.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/haptics.dart';
import '../../../features/auth/presentation/auth_provider.dart';

class ProfileSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const ProfileSection({super.key, this.onToast});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final SupabaseService _supabase = SupabaseService();

  bool _isEditingName = false;
  bool _isSyncing = false;

  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    _nameController = TextEditingController(text: profileProvider.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(ProfileProvider profileProvider) async {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      widget.onToast?.call('Display name cannot be empty');
      return;
    }
    ZetaHaptics.light();
    try {
      await profileProvider.setUserName(trimmed);
      if (!mounted) return;
      setState(() => _isEditingName = false);
      widget.onToast?.call('Name saved');
    } catch (error) {
      if (mounted) widget.onToast?.call('Could not save name: $error');
    }
  }

  Future<void> _handleDbSync(ProfileProvider profileProvider) async {
    ZetaHaptics.light();
    setState(() => _isSyncing = true);
    widget.onToast?.call('Syncing profile with database...');
    try {
      await profileProvider.syncProfileWithDb();
      if (!mounted) return;
      _nameController.text = profileProvider.userName;
      widget.onToast?.call(
        profileProvider.syncError == null
            ? 'Profile synchronized successfully'
            : 'Profile saved locally; sync will retry when connected',
      );
    } catch (e) {
      if (!mounted) return;
      widget.onToast?.call('Could not sync with database: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _pickImageFile(ProfileProvider profileProvider) async {
    ZetaHaptics.light();
    try {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.isNotEmpty) {
          final processedBytes = await _resizeImageBytes(bytes);
          await profileProvider.uploadAvatar(processedBytes, extension: 'png');
          if (mounted) {
            widget.onToast?.call(
              profileProvider.syncError == null ? 'Profile photo saved' : 'Profile photo saved locally; sync will retry when connected',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) widget.onToast?.call('Could not save profile photo: $e');
    }
  }

  Future<void> _clearAvatar(ProfileProvider profileProvider) async {
    try {
      await profileProvider.clearAvatarPhoto();
      if (mounted) {
        widget.onToast?.call(
          profileProvider.syncError == null
              ? 'Photo removed. Using initial "${profileProvider.avatarInitial}".'
              : 'Photo removed locally; sync will retry when connected',
        );
      }
    } catch (error) {
      if (mounted) {
        widget.onToast?.call('Could not remove profile photo: $error');
      }
    }
  }

  Future<Uint8List> _resizeImageBytes(
    Uint8List bytes, {
    int maxDimension = 512,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxDimension,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (_) {}
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasPhoto = profileProvider.hasAvatarPhoto;
    final isConnected = _supabase.isAuthenticated;
    final profileSyncColor = profileProvider.syncError != null
        ? colorScheme.error
        : profileProvider.isSyncing
        ? const Color(0xFFF59E0B)
        : profileProvider.lastSyncedAt != null
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    final profileSyncLabel = profileProvider.syncError != null
        ? 'ERROR'
        : profileProvider.isSyncing
        ? 'SYNCING'
        : profileProvider.lastSyncedAt != null
        ? 'SYNCED'
        : 'LOCAL';

    final displayEmail = profileProvider.userEmail;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Hero Profile Card (M3 Expressive) ─────────────────────────
            M3EList(
              itemCount: 1,
              itemBuilder: (context, index) => Padding(
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
                          UserAvatar(
                            radius: 36,
                            showRing: true,
                            ringWidth: 3.0,
                            ringColor: profileSyncColor,
                            tooltip: profileProvider.syncError != null
                                ? 'Sync Error: ${profileProvider.syncError}'
                                : 'Sync Status: $profileSyncLabel',
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
                                        profileProvider.userName,
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
                                    Tooltip(
                                      message: profileProvider.syncError != null
                                          ? 'Sync Error: ${profileProvider.syncError}'
                                          : 'Sync Status: $profileSyncLabel',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: profileSyncColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              profileSyncLabel == 'ERROR'
                                                  ? Icons.cloud_off_rounded
                                                  : profileProvider.isSyncing
                                                  ? Icons.sync_rounded
                                                  : isConnected
                                                  ? Icons.cloud_done_rounded
                                                  : Icons.shield_outlined,
                                              size: 11,
                                              color: profileSyncColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              profileSyncLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                                color: profileSyncColor,
                                              ),
                                            ),
                                          ],
                                        ),
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
                              _pickImageFile(profileProvider);
                            } else if (index == 1 && hasPhoto) {
                              ZetaHaptics.light();
                              unawaited(_clearAvatar(profileProvider));
                            }
                          },
                          actions: [
                            M3EButtonGroupAction(
                              icon: const Icon(
                                Icons.file_upload_outlined,
                                size: 16,
                              ),
                              label: const Text('Upload'),
                              tooltip: 'Upload image from local storage',
                              decoration: M3EButtonDecoration.styleFrom(
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
                                decoration: M3EButtonDecoration.styleFrom(
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

            M3EList(
              color: colorScheme.surfaceContainerLowest,
              itemCount: 2,
              itemBuilder: (context, index) => index == 0
                  ? Padding(
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
                                        profileProvider.userName,
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
                                  _nameController.text = profileProvider.userName;
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
                                      onSubmitted: (_) =>
                                          _saveName(profileProvider),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  M3EButton.icon(
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Save'),
                                    style: M3EButtonStyle.filled,
                                    size: M3EButtonSize.sm,
                                    onPressed: () => _saveName(profileProvider),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
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
                                  'Account email',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profileProvider.userEmail.isNotEmpty
                                      ? profileProvider.userEmail
                                      : 'Unavailable',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Managed by account',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
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

            M3EList(
              itemCount: 1,
              itemBuilder: (context, index) => M3EListItem(
                leading: Container(
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
                headline: 'Supabase Profiles Storage',
                supportingText:
                    'Profile name, email, and avatar photo are saved in the database',
                trailing: M3EButton.icon(
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
                      : () => _handleDbSync(profileProvider),
                ),
              ),
            ),

            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: context.watch<AuthProvider>().isBusy
                  ? null
                  : () => context.read<AuthProvider>().signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
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
