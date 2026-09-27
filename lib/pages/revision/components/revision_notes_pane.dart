import 'dart:async';
import 'dart:ui';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../components/attachment_chip.dart';
import '../../../models/attachment.dart';
import '../../../models/note_item.dart';
import '../../../models/revision.dart';
import '../../../providers/revision_provider.dart';
import '../../../services/url_metadata_service.dart';
import '../../../theme/breakpoints.dart';
import '../../../utils/haptics.dart';

/// Clean Document-style Note Workspace without Markdown syntax or bloated margins.
class RevisionNotesPane extends StatefulWidget {
  final Subject subject;
  final ChapterTopic? initialTopic;
  final VoidCallback? onBack;

  const RevisionNotesPane({
    super.key,
    required this.subject,
    this.initialTopic,
    this.onBack,
  });

  @override
  State<RevisionNotesPane> createState() => _RevisionNotesPaneState();
}

class _RevisionNotesPaneState extends State<RevisionNotesPane> {
  String? _selectedViewId;

  late final TextEditingController _titleController;
  late final TextEditingController _docController;
  final TextEditingController _attachmentInputController =
      TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _attachmentFocusNode = FocusNode();

  late List<AttachmentItem> _currentAttachments;
  bool _showAttachmentInput = false;

  // Active formatting state
  double _currentFontSize = 15.0;
  String _currentStyleType = 'Body';
  TextAlign _currentAlignment = TextAlign.left;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrike = false;

  Timer? _autoSaveDebounce;

  @override
  void initState() {
    super.initState();
    _selectedViewId = widget.initialTopic?.id;
    _titleController = TextEditingController();
    _docController = TextEditingController();
    _initEditorState();

    _titleController.addListener(_onTextChanged);
    _docController.addListener(_onTextChanged);
  }

  void _initEditorState() {
    final revProvider = context.read<RevisionProvider>();
    final currentSubject = revProvider.subjects.firstWhere(
      (s) => s.id == widget.subject.id,
      orElse: () => widget.subject,
    );

    if (_selectedViewId == null || _selectedViewId == '__all__') {
      final note = currentSubject.note;
      _titleController.text = note?.title ?? currentSubject.name;
      _docController.text = note?.content ?? '';
      _currentAttachments = [
        ...currentSubject.attachments,
        ...?note?.attachments,
      ];
    } else {
      final topic = revProvider.topics.firstWhere(
        (t) => t.id == _selectedViewId,
        orElse: () => widget.initialTopic!,
      );
      final note = topic.note;
      _titleController.text = note?.title ?? topic.title;
      _docController.text = note?.content ?? topic.description ?? '';
      _currentAttachments = [...topic.attachments, ...?note?.attachments];
    }
  }

  void _switchView(String? viewId) {
    _triggerImmediateSave();
    ZetaHaptics.selection();
    setState(() {
      _selectedViewId = viewId;
      _showAttachmentInput = false;
      _initEditorState();
    });
  }

  void _onTextChanged() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 600), () {
      _triggerImmediateSave();
    });
  }

  Future<void> _triggerImmediateSave() async {
    if (!mounted) return;
    final revProvider = context.read<RevisionProvider>();
    final title = _titleController.text.trim();
    final content = _docController.text;

    if (_selectedViewId == null) {
      final currentSubject = revProvider.subjects.firstWhere(
        (s) => s.id == widget.subject.id,
        orElse: () => widget.subject,
      );
      final updatedNote = NoteItem(
        id: currentSubject.note?.id ?? currentSubject.id,
        title: title.isNotEmpty ? title : currentSubject.name,
        content: content,
        attachments: _currentAttachments,
        createdAt: currentSubject.note?.createdAt,
      );
      final updatedSubject = currentSubject.copyWith(
        note: updatedNote,
        attachments: _currentAttachments,
      );
      await revProvider.updateSubject(updatedSubject);
    } else if (_selectedViewId != '__all__') {
      final currentTopic = revProvider.topics
          .where((t) => t.id == _selectedViewId)
          .firstOrNull;
      if (currentTopic == null) return;

      final updatedNote = NoteItem(
        id: currentTopic.note?.id ?? currentTopic.id,
        title: title.isNotEmpty ? title : currentTopic.title,
        content: content,
        attachments: _currentAttachments,
        createdAt: currentTopic.note?.createdAt,
      );
      final updatedTopic = currentTopic.copyWith(
        description: content,
        note: updatedNote,
        attachments: _currentAttachments,
      );
      await revProvider.updateTopic(updatedTopic);
    }
  }

  void _applyHeadingStyle(String style) {
    setState(() {
      _currentStyleType = style;
      switch (style) {
        case 'Title':
          _currentFontSize = 24.0;
          _isBold = true;
          break;
        case 'Heading 1':
          _currentFontSize = 20.0;
          _isBold = true;
          break;
        case 'Heading 2':
          _currentFontSize = 17.0;
          _isBold = true;
          break;
        default:
          _currentFontSize = 15.0;
          _isBold = false;
          break;
      }
    });
    ZetaHaptics.selection();
  }

  void _insertListPrefix(String prefix) {
    ZetaHaptics.light();
    final text = _docController.text;
    final selection = _docController.selection;
    final cursor = selection.start >= 0 ? selection.start : text.length;

    int lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _docController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
    _editorFocusNode.requestFocus();
  }

  Future<void> _addAttachmentInline() async {
    final text = _attachmentInputController.text.trim();
    if (text.isEmpty) return;

    final isUrl = RegExp(
      r'^(https?:\/\/)?([\w\-]+(\.[\w\-]+)+.*)$',
      caseSensitive: false,
    ).hasMatch(text);

    final formattedUrl =
        isUrl && !text.startsWith('http://') && !text.startsWith('https://')
        ? 'https://$text'
        : text;

    final attachmentId = 'att-${DateTime.now().millisecondsSinceEpoch}';

    final tempItem = AttachmentItem(
      id: attachmentId,
      title: isUrl ? Uri.tryParse(formattedUrl)?.host ?? text : text,
      url: formattedUrl,
      type: AttachmentType.link,
    );

    setState(() {
      _currentAttachments.add(tempItem);
      _attachmentInputController.clear();
      _showAttachmentInput = false;
    });
    ZetaHaptics.light();
    _triggerImmediateSave();

    if (isUrl) {
      final meta = await UrlMetadataService.instance.fetchMetadata(
        formattedUrl,
      );
      if (mounted && meta.title.isNotEmpty) {
        setState(() {
          final idx = _currentAttachments.indexWhere(
            (a) => a.id == attachmentId,
          );
          if (idx != -1) {
            _currentAttachments[idx] = _currentAttachments[idx].copyWith(
              title: meta.title,
            );
          }
        });
        _triggerImmediateSave();
      }
    }
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    _titleController.dispose();
    _docController.dispose();
    _attachmentInputController.dispose();
    _editorFocusNode.dispose();
    _attachmentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final revProvider = context.watch<RevisionProvider>();

    final subject = revProvider.subjects.firstWhere(
      (s) => s.id == widget.subject.id,
      orElse: () => widget.subject,
    );
    final subjectTopics =
        revProvider.topics.where((t) => t.subjectId == subject.id).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. Header Dropdown ──────────────────────────────────────────
          _buildHeaderDropdown(context, subject, subjectTopics),

          // ─── 2. Google Docs-style Toolstrip ──────────────────────────────
          if (_selectedViewId != '__all__')
            _buildFormatStrip(context, colorScheme),

          const Divider(height: 1),

          // ─── 3. Clean Document Canvas ────────────────────────────────────
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: _selectedViewId == '__all__'
                  ? _buildCombinedTopicsDoc(context, subjectTopics)
                  : _buildEditorCanvas(context, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDropdown(
    BuildContext context,
    Subject subject,
    List<ChapterTopic> topics,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<M3EDropdownItem<String>> dropdownItems = [
      const M3EDropdownItem(label: 'Subject Overview', value: '__overview__'),
      if (topics.isNotEmpty)
        M3EDropdownItem(
          label: 'Combined View (${topics.length} Chapters)',
          value: '__all__',
        ),
      for (int i = 0; i < topics.length; i++)
        M3EDropdownItem(
          label: '${i + 1}. ${topics[i].title}',
          value: topics[i].id,
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            M3EIconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              size: M3EIconButtonSize.sm,
              variant: M3EIconButtonVariant.standard,
              tooltip: 'Back to topics',
              onPressed: () {
                _triggerImmediateSave();
                widget.onBack!();
              },
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: M3EDropdownMenu<String>(
              singleSelect: true,
              searchEnabled: true,
              enabled: true,
              items: dropdownItems,
              fieldStyle: M3EDropdownFieldStyle(
                hintText: _selectedViewId == null
                    ? 'Subject Overview'
                    : _selectedViewId == '__all__'
                    ? 'Combined View'
                    : topics
                              .where((t) => t.id == _selectedViewId)
                              .firstOrNull
                              ?.title ??
                          'Select topic',
                showClearIcon: false,
              ),
              dropdownStyle: const M3EDropdownPanelStyle(
                expandDirection: M3EDropdownExpandDirection.auto,
              ),
              onSelectionChanged: (List<M3EDropdownItem<String>> items) {
                if (items.isEmpty) return;
                final val = items.first.value;
                if (val == '__overview__') {
                  _switchView(null);
                } else {
                  _switchView(val);
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.sm,
            icon: const Icon(Icons.add_link_rounded, size: 20),
            tooltip: 'Add resource link',
            onPressed: () {
              setState(() => _showAttachmentInput = !_showAttachmentInput);
              if (_showAttachmentInput) {
                Future.delayed(
                  const Duration(milliseconds: 60),
                  () => _attachmentFocusNode.requestFocus(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormatStrip(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Style Selector Popup
            PopupMenuButton<String>(
              tooltip: 'Text style',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              initialValue: _currentStyleType,
              onSelected: _applyHeadingStyle,
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'Body', child: Text('Body text')),
                const PopupMenuItem(
                  value: 'Title',
                  child: Text(
                    'Title',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                const PopupMenuItem(
                  value: 'Heading 1',
                  child: Text(
                    'Heading 1',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const PopupMenuItem(
                  value: 'Heading 2',
                  child: Text(
                    'Heading 2',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _currentStyleType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Font Point Stepper
            Container(
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      ZetaHaptics.light();
                      setState(() {
                        _currentFontSize = (_currentFontSize - 1).clamp(
                          11.0,
                          32.0,
                        );
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.remove, size: 12),
                    ),
                  ),
                  Text(
                    '${_currentFontSize.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ZetaHaptics.light();
                      setState(() {
                        _currentFontSize = (_currentFontSize + 1).clamp(
                          11.0,
                          32.0,
                        );
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.add, size: 12),
                    ),
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 14, indent: 8, endIndent: 8),

            // Bold, Italic, Underline, Strikethrough Group
            M3EButtonGroup(
              type: M3EButtonGroupType.standard,
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.xs,
              shape: M3EButtonShape.round,
              neighborSquish: true,
              selectedIndex: null,
              onSelectedIndexChanged: (int? index) {
                if (index == null) return;
                ZetaHaptics.light();
                setState(() {
                  switch (index) {
                    case 0:
                      _isBold = !_isBold;
                      break;
                    case 1:
                      _isItalic = !_isItalic;
                      break;
                    case 2:
                      _isUnderline = !_isUnderline;
                      break;
                    case 3:
                      _isStrike = !_isStrike;
                      break;
                  }
                });
              },
              actions: [
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'B',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _isBold ? colorScheme.primary : null,
                    ),
                  ),
                  tooltip: 'Bold',
                ),
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'I',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: _isItalic ? colorScheme.primary : null,
                    ),
                  ),
                  tooltip: 'Italic',
                ),
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'U',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      color: _isUnderline ? colorScheme.primary : null,
                    ),
                  ),
                  tooltip: 'Underline',
                ),
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'S',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.bold,
                      color: _isStrike ? colorScheme.primary : null,
                    ),
                  ),
                  tooltip: 'Strikethrough',
                ),
              ],
            ),

            const VerticalDivider(width: 14, indent: 8, endIndent: 8),

            // Alignment & Lists
            IconButton(
              icon: Icon(
                _currentAlignment == TextAlign.center
                    ? Icons.format_align_center_rounded
                    : _currentAlignment == TextAlign.right
                    ? Icons.format_align_right_rounded
                    : Icons.format_align_left_rounded,
                size: 17,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28),
              tooltip: 'Alignment',
              onPressed: () {
                setState(() {
                  if (_currentAlignment == TextAlign.left) {
                    _currentAlignment = TextAlign.center;
                  } else if (_currentAlignment == TextAlign.center) {
                    _currentAlignment = TextAlign.right;
                  } else {
                    _currentAlignment = TextAlign.left;
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_rounded, size: 17),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28),
              tooltip: 'Bullet list',
              onPressed: () => _insertListPrefix('• '),
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered_rounded, size: 17),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28),
              tooltip: 'Numbered list',
              onPressed: () => _insertListPrefix('1. '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorCanvas(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Document Title
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              hintText: 'Document Title',
              hintStyle: TextStyle(fontWeight: FontWeight.w600),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),

          const SizedBox(height: 6),

          // Inline Link Drawer
          if (_showAttachmentInput) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _attachmentInputController,
                      focusNode: _attachmentFocusNode,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Paste link or resource URL...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addAttachmentInline(),
                    ),
                  ),
                  M3EIconButton(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.tonal,
                    tooltip: 'Attach',
                    onPressed: _addAttachmentInline,
                  ),
                  M3EIconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    size: M3EIconButtonSize.xs,
                    variant: M3EIconButtonVariant.standard,
                    tooltip: 'Cancel',
                    onPressed: () =>
                        setState(() => _showAttachmentInput = false),
                  ),
                ],
              ),
            ),
          ],

          // Attachments Group
          if (_currentAttachments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _currentAttachments.map((a) {
                  return AttachmentChip(
                    attachment: a,
                    onDelete: () {
                      setState(() {
                        _currentAttachments.removeWhere(
                          (item) => item.id == a.id,
                        );
                      });
                      _triggerImmediateSave();
                    },
                  );
                }).toList(),
              ),
            ),
          ],

          const Divider(height: 1),

          // Natural Text Editor Body
          Expanded(
            child: TextField(
              controller: _docController,
              focusNode: _editorFocusNode,
              maxLines: null,
              expands: true,
              textAlign: _currentAlignment,
              style: TextStyle(
                fontSize: _currentFontSize,
                fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: TextDecoration.combine([
                  if (_isUnderline) TextDecoration.underline,
                  if (_isStrike) TextDecoration.lineThrough,
                ]),
                height: 1.5,
                color: colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'Type your notes here...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedTopicsDoc(
    BuildContext context,
    List<ChapterTopic> topics,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (topics.isEmpty) {
      return Center(
        child: Text(
          'No chapters recorded under this subject.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final topic = topics[index];
        final content = topic.note?.content.isNotEmpty == true
            ? topic.note!.content
            : (topic.description ?? '');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. ${topic.title}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  tooltip: 'Jump to this chapter',
                  onPressed: () => _switchView(topic.id),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              content.isNotEmpty
                  ? content
                  : 'No notes written for this chapter.',
              style: textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: content.isNotEmpty
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
