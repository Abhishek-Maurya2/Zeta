import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/attachment.dart';
import '../services/attachment_parser_service.dart';
import '../utils/haptics.dart';
import 'glass_alert_dialog.dart';

/// Expressive dialog for adding a link attachment (YouTube, Google Drive, or Web Link).
class AddAttachmentDialog extends StatefulWidget {
  const AddAttachmentDialog({super.key});

  static Future<AttachmentItem?> show(BuildContext context) {
    return showGlassDialog<AttachmentItem>(
      context: context,
      builder: (_) => const AddAttachmentDialog(),
    );
  }

  @override
  State<AddAttachmentDialog> createState() => _AddAttachmentDialogState();
}

class _AddAttachmentDialogState extends State<AddAttachmentDialog> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    ZetaHaptics.light();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
        _error = null;
      });
    }
  }

  Future<void> _handleAttach() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() => _error = 'Please enter a valid URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customTitle = _titleController.text.trim();
      final item = await AttachmentParserService.instance.parseUrl(
        rawUrl,
        customTitle: customTitle.isNotEmpty ? customTitle : null,
      );
      if (mounted) {
        Navigator.of(context).pop(item);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to parse URL';
        });
      }
    }
  }

  Widget _buildTypePreview() {
    final text = _urlController.text.toLowerCase();
    if (text.isEmpty) return const SizedBox.shrink();

    String typeLabel = 'Web Link';
    IconData iconData = Icons.language_rounded;
    Color iconColor = Colors.blue;

    if (text.contains('youtube.com') || text.contains('youtu.be')) {
      typeLabel = 'YouTube Video';
      iconData = Icons.play_arrow_rounded;
      iconColor = const Color(0xFFFF0000);
    } else if (text.contains('drive.google.com') || text.contains('docs.google.com')) {
      typeLabel = 'Google Drive';
      iconData = Icons.cloud_queue_rounded;
      iconColor = const Color(0xFF4285F4);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            'Detected: $typeLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      maxWidth: 420.0,
      title: const Row(
        children: [
          Icon(Icons.add_link_rounded, size: 22),
          SizedBox(width: 8),
          Text('Add Attachment'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _urlController,
            autofocus: true,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: 'URL (YouTube, Drive, or Web)',
              hintText: 'https://...',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                tooltip: 'Paste from clipboard',
                onPressed: _pasteFromClipboard,
              ),
            ),
          ),
          _buildTypePreview(),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title (Optional)',
              hintText: 'e.g. Reference Video / Study Docs',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
      actions: [
        GlassButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        GlassButton(
          isPrimary: true,
          onPressed: _isLoading ? null : _handleAttach,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Attach'),
        ),
      ],
    );
  }
}
