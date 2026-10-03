import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../models/attachment.dart';
import '../../theme/breakpoints.dart';

/// Attachment Chip styled consistently with M3E date/time filter chips,
/// displaying the page's favicon and truncated title to prevent RenderFlex overflow.
class AttachmentChip extends StatelessWidget {
  final AttachmentItem attachment;
  final VoidCallback onDelete;
  final int maxTitleLength;

  const AttachmentChip({
    super.key,
    required this.attachment,
    required this.onDelete,
    this.maxTitleLength = 18,
  });

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(
        url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url',
      );
      return uri.host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return '';
    }
  }

  String _getDisplayTitle() {
    String rawTitle = '';
    if (attachment.title.isNotEmpty && attachment.title != attachment.url) {
      rawTitle = attachment.title;
    } else {
      final domain = _getDomain(attachment.url);
      rawTitle = domain.isNotEmpty ? domain : attachment.url;
    }

    if (rawTitle.length > maxTitleLength) {
      return '${rawTitle.substring(0, maxTitleLength)}…';
    }
    return rawTitle;
  }

  Widget _buildFavicon(String domain, ColorScheme colorScheme) {
    if (domain.isEmpty) {
      return Icon(
        Icons.link_rounded,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      );
    }

    final faviconUrl =
        'https://www.google.com/s2/favicons?sz=32&domain_url=$domain';

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        faviconUrl,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.public_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = ZetaWindowSizeClass.of(context).isCompact;
    final domain = _getDomain(attachment.url);
    final displayTitle = _getDisplayTitle();

    final chipWidget = M3EChip(
      type: M3EChipType.filter,
      selected: true,
      label: displayTitle,
      leading: _buildFavicon(domain, colorScheme),
      onDeleted: onDelete,
      onPressed: () {},
    );

    if (!isCompact) return chipWidget;

    final radius = BorderRadius.circular(8.0);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: chipWidget,
        ),
      ),
    );
  }
}
