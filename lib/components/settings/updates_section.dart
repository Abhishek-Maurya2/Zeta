import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../providers/update_provider.dart';
import '../../utils/haptics.dart';
import '../../widgets/zeta_logo.dart';

/// Clean, minimal About & Updates screen mirroring the standard Android design:
/// App Logo -> App Name -> Version -> Status ("You're up-to-date" / Update Button / Wavy Progress Bar).
class UpdatesSection extends StatelessWidget {
  final void Function(String message)? onToast;

  const UpdatesSection({super.key, this.onToast});

  static String formatDisplayVersion(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'v1.0.5';
    if (clean.contains('+')) {
      final parts = clean.split('+');
      final semver = parts[0].startsWith('v') ? parts[0] : 'v${parts[0]}';
      final build = parts.length > 1 ? parts[1].trim() : '';
      if (build.isNotEmpty && build != '0') {
        return '$semver (#$build)';
      }
      return semver;
    }
    return clean.startsWith('v') ? clean : 'v$clean';
  }

  @override
  Widget build(BuildContext context) {
    final updateProvider = context.watch<UpdateProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final info = updateProvider.updateInfo;
    final isAvailable = updateProvider.isUpdateAvailable;
    final isDownloading = updateProvider.isDownloading;
    final isDownloaded = updateProvider.isDownloaded;
    final isChecking = updateProvider.isChecking;
    final hasError = updateProvider.hasError;

    final displayVersion = formatDisplayVersion(updateProvider.currentVersion);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── App Logo ──────────────────────────────────────────────
            ZetaLogo(
              size: 88,
              borderRadius: BorderRadius.circular(44),
            ),
            const SizedBox(height: 18),

            // ─── App Name ──────────────────────────────────────────────
            Text(
              'Zeta',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            // ─── Version ───────────────────────────────────────────────
            Text(
              displayVersion,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // ─── Status / Actions ──────────────────────────────────────
            if (isDownloading) ...[
              // Linear wavy progress bar when downloading
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 8,
                        child: M3EProgressIndicator.linearWavy(
                          value: (updateProvider.downloadProgress?.progress ?? 0) > 0
                              ? updateProvider.downloadProgress!.progress
                              : null,
                          color: colorScheme.primary,
                          trackColor: colorScheme.surfaceContainerHigh,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          updateProvider.downloadProgress != null
                              ? '${(updateProvider.downloadProgress!.progress * 100).toStringAsFixed(0)}% • ${updateProvider.downloadProgress!.speedText}'
                              : 'Downloading...',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            ZetaHaptics.light();
                            updateProvider.cancelDownload();
                          },
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Cancel download',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (isDownloaded) ...[
              // Install button
              M3EButton.icon(
                icon: const Icon(Icons.system_update_alt_rounded, size: 18),
                label: const Text('Install Update'),
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.md,
                onPressed: () {
                  ZetaHaptics.medium();
                  updateProvider.install();
                },
              ),
            ] else if (isAvailable && info != null) ...[
              // Update button
              M3EButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('Update to v${info.latestVersion}'),
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.md,
                onPressed: () {
                  ZetaHaptics.medium();
                  updateProvider.startDownload();
                },
              ),
            ] else if (isChecking) ...[
              // Checking indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Checking for updates...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ] else if (hasError) ...[
              // Error state
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    updateProvider.errorMessage ?? 'Check failed',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  M3EButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    onPressed: () {
                      ZetaHaptics.light();
                      updateProvider.checkForUpdates();
                    },
                  ),
                ],
              ),
            ] else ...[
              // Clean "You're up-to-date" state matching the reference image
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  ZetaHaptics.light();
                  await updateProvider.checkForUpdates();
                  if (updateProvider.isUpToDate && onToast != null) {
                    onToast!('Zeta is up-to-date');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "You're up-to-date",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
