import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/update_provider.dart';
import '../../utils/haptics.dart';
import '../../widgets/zeta_logo.dart';
import '../../widgets/segmented_column.dart';

/// Clean, minimal About & Updates screen mirroring Lawnchair / Android style:
/// App Logo -> App Name -> Version -> Status button -> Changelog (when available) -> Developer list.
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── App Logo ──────────────────────────────────────────────
              ZetaLogo(size: 88, borderRadius: BorderRadius.circular(44)),
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
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 15,
                          child: M3EProgressIndicator.linearWavy(
                            value:
                                (updateProvider.downloadProgress?.progress ??
                                        0) >
                                    0
                                ? updateProvider.downloadProgress!.progress
                                : null,
                            color: colorScheme.primary,
                            trackColor: colorScheme.surfaceContainerHigh,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          M3EIconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              ZetaHaptics.light();
                              updateProvider.cancelDownload();
                            },
                            variant: M3EIconButtonVariant.standard,
                            width: M3EIconButtonWidth.narrow,
                            decoration: M3EIconButtonDecoration(
                              backgroundColor: WidgetStateProperty.all(
                                colorScheme.onSurface.withValues(alpha: 0.1),
                              ),
                            ),
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
                Material(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Checking for updates',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                // "You're up-to-date" state styled as a button with primaryContainer background and trailing icon
                Material(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      ZetaHaptics.light();
                      await updateProvider.checkForUpdates();
                      if (updateProvider.isUpToDate && onToast != null) {
                        onToast!('Zeta is up-to-date');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "You're up-to-date",
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // ─── Changelog (when update available) ──────────────────────
              if (isAvailable && info != null) ...[
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "What's New in v${info.latestVersion}",
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                M3ESegmentedColumn(
                  decoration: const M3ESegmentedListDecoration(
                    padding: EdgeInsets.zero,
                    outerRadius: 20,
                    innerRadius: 6,
                  ),
                  color: colorScheme.surfaceContainerLow,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Release Notes',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (info.tagName.isNotEmpty) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    info.tagName,
                                    style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            info.releaseNotes.trim().isNotEmpty
                                ? info.releaseNotes.trim()
                                : 'Performance improvements, bug fixes, and stability updates.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // ─── Developer / Product Section (Segmented List) ───────────
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Developer',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              M3ESegmentedColumn(
                decoration: const M3ESegmentedListDecoration(
                  padding: EdgeInsets.zero,
                ),
                color: colorScheme.surfaceContainerLow,
                children: [
                  // Developer profile tile
                  InkWell(
                    onTap: () {
                      ZetaHaptics.light();
                      _launchUrl('https://github.com/Abhishek-Maurya2');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primaryContainer,
                            child: ClipOval(
                              child: Image.network(
                                'https://github.com/Abhishek-Maurya2.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Text(
                                      'AM',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
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
                                  'Abhishek Maurya',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Development',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // GitHub repository tile
                  InkWell(
                    onTap: () {
                      ZetaHaptics.light();
                      _launchUrl('https://github.com/Abhishek-Maurya2/Zeta');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.code_rounded,
                              size: 22,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Zeta',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Abhishek-Maurya2/Zeta',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
