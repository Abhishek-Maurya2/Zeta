import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment.dart';
import '../services/url_metadata_service.dart';
import '../utils/haptics.dart';
import 'segmented_column.dart';

/// Reusable attachment chip matching the TaskDueDateChip design token language:
/// - Secondary container background, 8px rounded corners, 8x4 padding.
/// - 16px favicon or platform icon.
/// - Auto-resolves page title with truncation (ellipsis) and optional delete button.
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.only(
            left: 8,
            right: onDelete != null ? 4 : 8,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AttachmentFavicon(
                url: attachment.url,
                type: attachment.type,
                driveType: attachment.driveType,
                overrideFaviconUrl: attachment.faviconUrl,
                size: 16,
              ),
              const SizedBox(width: 8),
              AttachmentResolvedTitle(
                rawTitle: attachment.title,
                url: attachment.url,
                maxLength: maxTitleLength,
                textStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSecondaryContainer,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    ZetaHaptics.light();
                    onDelete!();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
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

/// Expressive attachment group chip matching the TaskDueDateChip design token language.
/// - 1 attachment: leading favicon + fetched page title + tap opens URL directly.
/// - > 1 attachments: attachment icon + up to 3 stacked favicons + count label + tap opens flyout.
class TaskAttachmentsChipGroup extends StatefulWidget {
  final List<AttachmentItem> attachments;
  final int maxTitleLength;

  const TaskAttachmentsChipGroup({
    super.key,
    required this.attachments,
    this.maxTitleLength = 18,
  });

  @override
  State<TaskAttachmentsChipGroup> createState() =>
      _TaskAttachmentsChipGroupState();
}

class _TaskAttachmentsChipGroupState extends State<TaskAttachmentsChipGroup>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final Object _tapRegionGroupId = Object();

  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openFlyout() {
    if (!_isOpen) {
      setState(() => _isOpen = true);
      _overlayController.show();
    }
    _animController.forward();
  }

  void _closeFlyout() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _animController.reverse().then((_) {
      if (mounted && !_isOpen) {
        _overlayController.hide();
      }
    });
  }

  Future<void> _launchUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Builds a stacked row of up to 3 overlapping favicons
  Widget _buildStackedFavicons(BuildContext context) {
    final displayedItems = widget.attachments.take(3).toList();
    const double iconSize = 16.0;
    const double overlapOffset = 11.0;
    final totalWidth = iconSize + (displayedItems.length - 1) * overlapOffset;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: totalWidth,
      height: iconSize,
      child: Stack(
        children: [
          for (int i = 0; i < displayedItems.length; i++)
            Positioned(
              left: i * overlapOffset,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.secondaryContainer,
                    width: 1.5,
                  ),
                ),
                child: AttachmentFavicon(
                  url: displayedItems[i].url,
                  type: displayedItems[i].type,
                  driveType: displayedItems[i].driveType,
                  overrideFaviconUrl: displayedItems[i].faviconUrl,
                  size: iconSize - 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachments.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isMultiple = widget.attachments.length > 1;
    final firstAttachment = widget.attachments.first;

    final chipButton = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        ZetaHaptics.selection();
        if (isMultiple) {
          _isOpen ? _closeFlyout() : _openFlyout();
        } else {
          _launchUrl(firstAttachment.url);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isMultiple
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 6),
                  // Stacked favicons (max 3)
                  _buildStackedFavicons(context),
                  const SizedBox(width: 8),
                  // Count Label
                  Text(
                    '${widget.attachments.length} Attachments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _isOpen
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AttachmentFavicon(
                    url: firstAttachment.url,
                    type: firstAttachment.type,
                    driveType: firstAttachment.driveType,
                    overrideFaviconUrl: firstAttachment.faviconUrl,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  AttachmentResolvedTitle(
                    rawTitle: firstAttachment.title,
                    url: firstAttachment.url,
                    maxLength: widget.maxTitleLength,
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (!isMultiple) {
      return chipButton;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (overlayContext) =>
            _buildOverlayChild(overlayContext),
        child: TapRegion(groupId: _tapRegionGroupId, child: chipButton),
      ),
    );
  }

  Widget _buildOverlayChild(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8),
        child: TapRegion(
          groupId: _tapRegionGroupId,
          onTapOutside: (_) => _closeFlyout(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.topLeft,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Card(
                      color: colorScheme.tertiaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                'Attachments (${widget.attachments.length})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.outline,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            M3ESegmentedColumn(
                              decoration: const M3ESegmentedListDecoration(
                                padding: EdgeInsets.all(2),
                                outerRadius: 14.0,
                                innerRadius: 6.0,
                                gap: 2.0,
                              ),
                              color: isDark
                                  ? colorScheme.tertiary.withValues(alpha: 0.1)
                                  : colorScheme.tertiaryFixedDim.withValues(
                                      alpha: 0.3,
                                    ),
                              children: [
                                for (final item in widget.attachments)
                                  Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 2,
                                          ),
                                      leading: AttachmentFavicon(
                                        url: item.url,
                                        type: item.type,
                                        driveType: item.driveType,
                                        overrideFaviconUrl: item.faviconUrl,
                                        size: 18,
                                      ),
                                      title: AttachmentResolvedTitle(
                                        rawTitle: item.title,
                                        url: item.url,
                                        maxLength: 32,
                                        textStyle: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                      onTap: () {
                                        _closeFlyout();
                                        ZetaHaptics.selection();
                                        _launchUrl(item.url);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget to asynchronously load and resolve URL page titles.
class AttachmentResolvedTitle extends StatelessWidget {
  final String rawTitle;
  final String url;
  final int maxLength;
  final TextStyle? textStyle;

  const AttachmentResolvedTitle({
    super.key,
    required this.rawTitle,
    required this.url,
    required this.maxLength,
    this.textStyle,
  });

  String _truncate(String text) {
    final clean = text.trim();
    if (clean.length <= maxLength) return clean;
    return '${clean.substring(0, maxLength - 1)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (rawTitle.trim().isNotEmpty) {
      return Text(
        _truncate(rawTitle),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    return FutureBuilder<UrlMetadata>(
      future: UrlMetadataService.instance.fetchMetadata(url),
      builder: (context, snapshot) {
        final title = snapshot.data?.title ?? Uri.tryParse(url)?.host ?? url;
        return Text(
          _truncate(title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
      },
    );
  }
}

/// Helper widget resolving favicons with fallbacks to Google Favicon API or native icons.
class AttachmentFavicon extends StatelessWidget {
  final String url;
  final AttachmentType type;
  final String? driveType;
  final String? overrideFaviconUrl;
  final double size;

  const AttachmentFavicon({
    super.key,
    required this.url,
    this.type = AttachmentType.link,
    this.driveType,
    this.overrideFaviconUrl,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (type == AttachmentType.youtube) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.play_arrow_rounded,
          size: size * 0.8,
          color: Colors.white,
        ),
      );
    }

    if (type == AttachmentType.googleDrive) {
      final dt = GoogleDriveType.fromString(driveType);
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
      return Icon(iconData, size: size, color: color);
    }

    final effectiveFaviconUrl = overrideFaviconUrl?.isNotEmpty == true
        ? overrideFaviconUrl!
        : 'https://www.google.com/s2/favicons?domain=${Uri.tryParse(url)?.host ?? ""}&sz=64';

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.network(
        effectiveFaviconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.link_rounded,
          size: size,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
