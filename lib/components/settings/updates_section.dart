import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/update_model.dart';
import '../../providers/update_provider.dart';
import '../../utils/haptics.dart';
import '../../widgets/segmented_column.dart';
import '../../widgets/zeta_button.dart';

/// Settings section allowing users to inspect application versions,
/// check for releases against public or private GitHub repositories,
/// download updates with a linear wavy progress bar, and trigger installation.
class UpdatesSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const UpdatesSection({super.key, this.onToast});

  @override
  State<UpdatesSection> createState() => _UpdatesSectionState();
}

class _UpdatesSectionState extends State<UpdatesSection> {
  late final TextEditingController _ownerController;
  late final TextEditingController _repoController;
  late final TextEditingController _tokenController;

  bool _isAdvancedExpanded = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<UpdateProvider>();
    _ownerController = TextEditingController(text: provider.owner);
    _repoController = TextEditingController(text: provider.repo);
    _tokenController = TextEditingController(text: provider.token ?? '');
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _saveRepoSettings(UpdateProvider provider) {
    provider.saveSettings(
      owner: _ownerController.text.trim(),
      repo: _repoController.text.trim(),
      token: _tokenController.text.trim(),
    );
    ZetaHaptics.light();
    widget.onToast?.call('Repository settings updated.');
  }

  @override
  Widget build(BuildContext context) {
    final updateProvider = context.watch<UpdateProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
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
            'Check for the latest features, view release notes, and install updates.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Main Hero Status Card
          _buildHeroStatusCard(context, updateProvider, colorScheme, textTheme),
          const SizedBox(height: 20),

          // Release Notes Section (if available)
          if (updateProvider.updateInfo?.releaseNotes.isNotEmpty == true &&
              !updateProvider.isChecking) ...[
            _buildReleaseNotesCard(context, updateProvider, colorScheme, textTheme),
            const SizedBox(height: 20),
          ],

          // Preferences & Automation
          Text(
            'UPDATE PREFERENCES',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildPreferencesSection(context, updateProvider, colorScheme, textTheme),
          const SizedBox(height: 20),

          // Advanced Private Repository Configuration
          _buildAdvancedSection(context, updateProvider, colorScheme, textTheme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroStatusCard(
    BuildContext context,
    UpdateProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isAvailable = provider.isUpdateAvailable;
    final isDownloading = provider.isDownloading;
    final isDownloaded = provider.isDownloaded;
    final isChecking = provider.isChecking;
    final hasError = provider.hasError;

    // Card background tint
    Color cardBg;
    if (isDownloading) {
      cardBg = colorScheme.surfaceContainerHigh;
    } else if (isDownloaded) {
      cardBg = colorScheme.primaryContainer.withValues(alpha: 0.6);
    } else if (isAvailable) {
      cardBg = colorScheme.primaryContainer;
    } else if (hasError) {
      cardBg = colorScheme.errorContainer.withValues(alpha: 0.4);
    } else {
      cardBg = colorScheme.surfaceContainerHigh;
    }

    return M3ECard(
      variant: M3ECardVariant.filled,
      color: cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // Icon or Morphing Loading Indicator
          if (isChecking)
            const SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: M3ELoadingIndicator(
                  variant: M3ELoadingIndicatorVariant.contained,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isAvailable
                    ? colorScheme.primary
                    : isDownloaded
                        ? colorScheme.primary
                        : hasError
                            ? colorScheme.error
                            : colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAvailable
                    ? Icons.system_update_rounded
                    : isDownloaded
                        ? Icons.check_circle_outline_rounded
                        : hasError
                            ? Icons.cloud_off_rounded
                            : isDownloading
                                ? Icons.downloading_rounded
                                : Icons.check_circle_rounded,
                size: 38,
                color: isAvailable || isDownloaded
                    ? colorScheme.onPrimary
                    : hasError
                        ? colorScheme.onError
                        : colorScheme.onSecondaryContainer,
              ),
            ),
          const SizedBox(height: 18),

          // Status title
          Text(
            isChecking
                ? 'Checking for updates...'
                : isDownloading
                    ? 'Downloading Update'
                    : isDownloaded
                        ? 'Update Ready to Install!'
                        : isAvailable
                            ? 'New Version Available!'
                            : hasError
                                ? 'Update Check Failed'
                                : "You're up to date",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isAvailable
                  ? colorScheme.onPrimaryContainer
                  : hasError
                      ? colorScheme.error
                      : colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Status subtitle
          if (isChecking)
            Text(
              'Connecting to ${provider.owner}/${provider.repo}...',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else if (hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                provider.errorMessage ?? 'An error occurred while connecting to GitHub.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (isDownloading && provider.downloadProgress != null)
            _buildDownloadProgressContent(provider.downloadProgress!, colorScheme, textTheme)
          else if (isDownloaded)
            Text(
              'Version ${provider.updateInfo?.latestVersion} has finished downloading.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            )
          else
            _buildVersionBadges(provider, colorScheme, textTheme),

          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(context, provider, colorScheme),
        ],
      ),
    );
  }

  Widget _buildVersionBadges(
    UpdateProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final info = provider.updateInfo;
    final current = info?.currentVersion ?? '1.0.0+1';
    final latest = info?.latestVersion;
    final isAvailable = provider.isUpdateAvailable;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Current Version Badge
        Column(
          children: [
            Text(
              'Current',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'v$current',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),

        // If update is available, show transition arrow and latest badge
        if (isAvailable && latest != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          Column(
            children: [
              Text(
                'Latest',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'v$latest',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Linear Wavy Progress Bar during active download.
  Widget _buildDownloadProgressContent(
    DownloadProgress progress,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final pctText = '${(progress.progress * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.transferredText,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$pctText (${progress.speedText})',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Material 3 Expressive Linear Wavy Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: M3EProgressIndicator.linearWavy(
                value: progress.progress > 0 ? progress.progress : null,
                color: colorScheme.primary,
                trackColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    UpdateProvider provider,
    ColorScheme colorScheme,
  ) {
    if (provider.isChecking) {
      return const SizedBox.shrink();
    }

    if (provider.isDownloading) {
      return ZetaButton.icon(
        label: const Text('Cancel Download'),
        icon: const Icon(Icons.close_rounded, size: 18),
        style: M3EButtonStyle.outlined,
        size: M3EButtonSize.sm,
        onPressed: () {
          provider.cancelDownload();
          ZetaHaptics.selection();
        },
      );
    }

    if (provider.isDownloaded) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZetaButton.icon(
            label: const Text('Install Now'),
            icon: const Icon(Icons.system_update_alt_rounded, size: 18),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.md,
            onPressed: () {
              ZetaHaptics.medium();
              provider.install();
            },
          ),
        ],
      );
    }

    if (provider.isUpdateAvailable) {
      final asset = provider.updateInfo?.platformAsset;
      final sizeText = asset != null && asset.formattedSize.isNotEmpty
          ? ' (${asset.formattedSize})'
          : '';

      return Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          ZetaButton.icon(
            label: Text('Download Update$sizeText'),
            icon: const Icon(Icons.download_rounded, size: 18),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.md,
            onPressed: () {
              ZetaHaptics.medium();
              provider.startDownload();
            },
          ),
          ZetaButton.icon(
            label: const Text('Refresh'),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.md,
            onPressed: () {
              ZetaHaptics.light();
              provider.checkForUpdates();
            },
          ),
        ],
      );
    }

    if (provider.hasError) {
      return ZetaButton.icon(
        label: const Text('Retry Check'),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        style: M3EButtonStyle.filled,
        size: M3EButtonSize.sm,
        onPressed: () {
          ZetaHaptics.light();
          provider.checkForUpdates();
        },
      );
    }

    // Default up to date state
    return ZetaButton.icon(
      label: const Text('Check for updates'),
      icon: const Icon(Icons.refresh_rounded, size: 18),
      style: M3EButtonStyle.filled,
      size: M3EButtonSize.sm,
      onPressed: () {
        ZetaHaptics.light();
        provider.checkForUpdates();
      },
    );
  }

  Widget _buildReleaseNotesCard(
    BuildContext context,
    UpdateProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final info = provider.updateInfo;
    if (info == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes_rounded, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'RELEASE NOTES (${info.tagName})',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        M3ECard(
          variant: M3ECardVariant.outlined,
          color: colorScheme.surfaceContainerLowest,
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            width: double.infinity,
            child: SelectableText(
              info.releaseNotes,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    UpdateProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return M3ESegmentedColumn(
      decoration: const M3ESegmentedListDecoration(padding: EdgeInsets.all(1.0)),
      color: colorScheme.surfaceContainerLowest,
      children: [
        // Auto-check toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.autorenew_rounded, size: 22, color: colorScheme.onSurfaceVariant),
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
                    const SizedBox(height: 2),
                    Text(
                      'Silently verify new releases when Zeta starts',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.autoCheck,
                onChanged: (val) {
                  provider.saveSettings(autoCheck: val);
                  ZetaHaptics.selection();
                },
              ),
            ],
          ),
        ),

        // Supabase Edge Function Proxy Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 22, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure Supabase Proxy',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Use edge function backend to keep private tokens off client devices',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.useSupabaseProxy,
                onChanged: (val) {
                  provider.saveSettings(useSupabaseProxy: val);
                  ZetaHaptics.selection();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(
    BuildContext context,
    UpdateProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _isAdvancedExpanded = !_isAdvancedExpanded;
            });
            ZetaHaptics.selection();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _isAdvancedExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'PRIVATE REPOSITORY & ACCESS CONFIGURATION',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isAdvancedExpanded) ...[
          const SizedBox(height: 8),
          M3ECard(
            variant: M3ECardVariant.outlined,
            color: colorScheme.surfaceContainerLowest,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure your GitHub repository coordinates and access token for private repository releases.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Owner Field
                TextField(
                  controller: _ownerController,
                  decoration: const InputDecoration(
                    labelText: 'GitHub Owner / Organization',
                    hintText: 'e.g. Abhishek-Maurya2',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Repo Field
                TextField(
                  controller: _repoController,
                  decoration: const InputDecoration(
                    labelText: 'Repository Name',
                    hintText: 'e.g. antimatter or Zeta',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Personal Access Token Field
                TextField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  decoration: InputDecoration(
                    labelText: 'GitHub Personal Access Token (PAT)',
                    hintText: 'ghp_... or github_pat_...',
                    helperText:
                        'Required for private repos if not using Supabase proxy. Needs contents:read permission.',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureToken = !_obscureToken;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ZetaButton(
                      label: const Text('Save Configuration'),
                      style: M3EButtonStyle.filled,
                      size: M3EButtonSize.sm,
                      onPressed: () => _saveRepoSettings(provider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
