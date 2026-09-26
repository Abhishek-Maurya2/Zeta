import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment.dart';
import '../utils/haptics.dart';

/// An expressive chip for displaying an [AttachmentItem] with website/service logo
/// and truncated title. Tapping opens the link via [url_launcher].
class AttachmentChip extends StatelessWidget {
  final AttachmentItem attachment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int maxTitleLength;
  final bool isSelected;

  const AttachmentChip({
    super.key,
    required this.attachment,
    this.onTap,
    this.onDelete,
    this.maxTitleLength = 20,
    this.isSelected = false,
  });

  static String truncateTitle(String title, int maxLength) {
    final clean = title.trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength - 1)}…';
  }

  Future<void> _handleTap() async {
    ZetaHaptics.selection();
    if (onTap != null) {
      onTap!();
      return;
    }
    final uri = Uri.tryParse(attachment.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildLeadingIcon(BuildContext context) {
    switch (attachment.type) {
      case AttachmentType.youtube:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 14,
            color: Colors.white,
          ),
        );

      case AttachmentType.googleDrive:
        final dt = GoogleDriveType.fromString(attachment.driveType);
        final (iconData, color) = switch (dt) {
          GoogleDriveType.document => (
            Icons.description_rounded,
            const Color(0xFF4285F4),
          ),
          GoogleDriveType.spreadsheets => (
            Icons.table_chart_rounded,
            const Color(0xFF0F9D58),
          ),
          GoogleDriveType.presentation => (
            Icons.slideshow_rounded,
            const Color(0xFFF4B400),
          ),
          GoogleDriveType.folder => (
            Icons.folder_rounded,
            const Color(0xFF5F6368),
          ),
          GoogleDriveType.genericFile => (
            Icons.cloud_queue_rounded,
            const Color(0xFF4285F4),
          ),
        };
        return Icon(iconData, size: 16, color: color);

      case AttachmentType.link:
        if (attachment.faviconUrl != null && attachment.faviconUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.network(
              attachment.faviconUrl!,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.link_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        return Icon(
          Icons.link_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayTitle = truncateTitle(
      attachment.title.isNotEmpty ? attachment.title : attachment.url,
      maxTitleLength,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            left: 8,
            right: onDelete != null ? 4 : 10,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeadingIcon(context),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                InkResponse(
                  onTap: () {
                    ZetaHaptics.light();
                    onDelete!();
                  },
                  radius: 12,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
