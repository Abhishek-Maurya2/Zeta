import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/update_provider.dart';
import '../../utils/haptics.dart';
import '../../widgets/segmented_column.dart';

/// Settings section allowing users to inspect application versions,
/// check for releases, download updates with a linear wavy progress bar,
/// and trigger installation.
///
/// Seamlessly uses compile-time build authentication (Option A via GitHub Actions)
/// without requiring manual repository or token configuration from the user.
class UpdatesSection extends StatelessWidget {
  final void Function(String message)? onToast;

  const UpdatesSection({super.key, this.onToast});

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
    final isUpToDate = updateProvider.isUpToDate;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Section Title & Refresh Action ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APPLICATION UPDATES',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inspect current version, check for new releases, and install updates.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              M3EButton.icon(
                icon: isChecking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Check Now'),
                style: M3EButtonStyle.tonal,
                size: M3EButtonSize.sm,
                onPressed: isChecking || isDownloading
                    ? null
                    : () {
                        ZetaHaptics.light();
                        updateProvider.checkForUpdates();
                      },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Main Status Segmented Card ──────────────────────────────────
          M3ESegmentedColumn(
            decoration: const M3ESegmentedListDecoration(
              padding: EdgeInsets.all(1.0),
            ),
            color: colorScheme.surfaceContainerLowest,
            children: [
              // Row 1: Status Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Status Icon Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isAvailable || isDownloaded
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : hasError
                                ? colorScheme.error.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isAvailable
                            ? Icons.system_update_rounded
                            : isDownloaded
                                ? Icons.download_done_rounded
                                : hasError
                                    ? Icons.cloud_off_rounded
                                    : isDownloading
                                        ? Icons.downloading_rounded
                                        : Icons.check_circle_outline_rounded,
                        color: isAvailable || isDownloaded
                            ? colorScheme.primary
                            : hasError
                                ? colorScheme.error
                                : isUpToDate
                                    ? const Color(0xFF10B981)
                                    : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Version Title, Badge & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isChecking
                                      ? 'Checking for updates...'
                                      : isDownloading
                                          ? 'Downloading Update'
                                          : isDownloaded
                                              ? 'Update Ready'
                                              : isAvailable
                                                  ? 'Update Available'
                                                  : hasError
                                                      ? 'Check Failed'
                                                      : 'Up to Date',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Status Pill Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? colorScheme.primary.withValues(alpha: 0.15)
                                      : isDownloaded
                                          ? colorScheme.primary.withValues(alpha: 0.15)
                                          : isUpToDate
                                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                              : hasError
                                                  ? colorScheme.errorContainer
                                                  : colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAvailable && info != null
                                      ? 'v${info.latestVersion}'
                                      : isUpToDate
                                          ? 'v${info?.currentVersion ?? '1.0.0+1'}'
                                          : isDownloading && updateProvider.downloadProgress != null
                                              ? '${(updateProvider.downloadProgress!.progress * 100).toStringAsFixed(0)}%'
                                              : hasError
                                                  ? 'Offline'
                                                  : 'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isAvailable || isDownloaded
                                        ? colorScheme.primary
                                        : isUpToDate
                                            ? const Color(0xFF10B981)
                                            : hasError
                                                ? colorScheme.onErrorContainer
                                                : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isChecking
                                ? 'Connecting to GitHub repository...'
                                : hasError
                                    ? updateProvider.errorMessage ?? 'Failed to query GitHub repository.'
                                    : isDownloading && updateProvider.downloadProgress != null
                                        ? '${updateProvider.downloadProgress!.transferredText} • ${updateProvider.downloadProgress!.speedText}'
                                        : isDownloaded
                                            ? (defaultTargetPlatform == TargetPlatform.windows
                                                ? 'Installer opened automatically. Run setup to finish updating, or tap Install to relaunch.'
                                                : 'Installer downloaded. Tap install to finish updating.')
                                            : isAvailable && info != null
                                                ? 'Version ${info.latestVersion} available${info.platformAsset?.formattedSize.isNotEmpty == true ? ' • ${info.platformAsset!.formattedSize}' : ''}'
                                                : 'Current version v${info?.currentVersion ?? '1.0.0+1'} is the newest build',
                            style: textTheme.bodySmall?.copyWith(
                              color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Primary Action Button
                    if (isAvailable)
                      M3EButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download'),
                        style: M3EButtonStyle.filled,
                        size: M3EButtonSize.sm,
                        onPressed: () {
                          ZetaHaptics.medium();
                          updateProvider.startDownload();
                        },
                      )
                    else if (isDownloaded)
                      M3EButton.icon(
                        icon: const Icon(Icons.system_update_alt_rounded, size: 16),
                        label: const Text('Install'),
                        style: M3EButtonStyle.filled,
                        size: M3EButtonSize.sm,
                        onPressed: () {
                          ZetaHaptics.medium();
                          updateProvider.install();
                        },
                      )
                    else if (isDownloading)
                      M3EButton(
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: () {
                          ZetaHaptics.selection();
                          updateProvider.cancelDownload();
                        },
                        child: const Icon(Icons.close_rounded, size: 16),
                      )
                    else if (hasError)
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
              ),

              // Row 2 (Active Download): Material 3 Expressive Linear Wavy Progress Bar
              if (isDownloading && updateProvider.downloadProgress != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: M3EProgressIndicator.linearWavy(
                            value: updateProvider.downloadProgress!.progress > 0
                                ? updateProvider.downloadProgress!.progress
                                : null,
                            color: colorScheme.primary,
                            trackColor: colorScheme.surfaceContainerHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Release Notes (if available) ─────────────────────────────────
          if (info != null && info.releaseNotes.isNotEmpty && !isChecking) ...[
            Text(
              'RELEASE NOTES (${info.tagName})',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        info.releaseNotes,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ─── Preferences Segmented Section ────────────────────────────────
          Text(
            'UPDATE SETTINGS',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          M3ESegmentedColumn(
            decoration: const M3ESegmentedListDecoration(
              padding: EdgeInsets.all(1.0),
            ),
            color: colorScheme.surfaceContainerLowest,
            children: [
              // Auto-check on startup
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.autorenew_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check Automatically',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Silently verify new releases when Zeta starts',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    M3ESwitch(
                      value: updateProvider.autoCheck,
                      onChanged: (val) {
                        updateProvider.saveSettings(autoCheck: val);
                        ZetaHaptics.selection();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
