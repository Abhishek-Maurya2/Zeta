import 'dart:async';
import 'dart:convert';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../components/attachment_chip.dart';
import '../../../models/attachment.dart';
import '../../../models/note_item.dart';
import '../../../models/revision.dart';
import '../../../providers/revision_provider.dart';
import '../../../services/url_metadata_service.dart';
import '../../../utils/haptics.dart';

/// Selection-aware rich text attribute.
enum DocStyleAttr {
  bold,
  italic,
  underline,
  strikethrough,
  title,
  heading1,
  heading2,
}

/// Represents an active style over an index range [start, end].
class DocStyleSpan {
  int start;
  int end;
  final Set<DocStyleAttr> attributes;
  final double? fontSize;

  DocStyleSpan({
    required this.start,
    required this.end,
    Set<DocStyleAttr>? attributes,
    this.fontSize,
  }) : attributes = attributes ?? <DocStyleAttr>{};

  DocStyleSpan copyWith({
    int? start,
    int? end,
    Set<DocStyleAttr>? attributes,
    double? fontSize,
  }) {
    return DocStyleSpan(
      start: start ?? this.start,
      end: end ?? this.end,
      attributes: attributes ?? Set.from(this.attributes),
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() => {
    's': start,
    'e': end,
    'a': attributes.map((a) => a.name).toList(),
    if (fontSize != null) 'fs': fontSize,
  };

  factory DocStyleSpan.fromJson(Map<String, dynamic> json) => DocStyleSpan(
    start: json['s'] as int? ?? 0,
    end: json['e'] as int? ?? 0,
    attributes:
        (json['a'] as List<dynamic>?)
            ?.map((e) => DocStyleAttr.values.firstWhere((val) => val.name == e))
            .toSet() ??
        <DocStyleAttr>{},
    fontSize: (json['fs'] as num?)?.toDouble(),
  );
}

/// Rich controller that builds non-markdown selection-based TextSpans.
class RichDocEditingController extends TextEditingController {
  List<DocStyleSpan> spans = [];

  RichDocEditingController({super.text});

  /// Loads raw content or formatted payload.
  void loadFormattedText(String raw) {
    if (raw.startsWith('{"zeta_doc_v1":')) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        text = decoded['body'] as String? ?? '';
        final rawSpans = decoded['spans'] as List<dynamic>? ?? [];
        spans = rawSpans
            .map((s) => DocStyleSpan.fromJson(s as Map<String, dynamic>))
            .toList();
        return;
      } catch (_) {}
    }
    text = raw;
    spans = [];
  }

  /// Exports text alongside its span format state.
  String exportFormattedText() {
    if (spans.isEmpty) return text;
    return jsonEncode({
      'zeta_doc_v1': true,
      'body': text,
      'spans': spans.map((s) => s.toJson()).toList(),
    });
  }

  /// Toggles a style for only the selected range.
  void toggleSelectionStyle(DocStyleAttr attr) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final start = sel.start < sel.end ? sel.start : sel.end;
    final end = sel.start < sel.end ? sel.end : sel.start;

    final existingIndex = spans.indexWhere(
      (s) => s.start == start && s.end == end,
    );

    if (existingIndex != -1) {
      final s = spans[existingIndex];
      if (s.attributes.contains(attr)) {
        s.attributes.remove(attr);
      } else {
        s.attributes.add(attr);
      }
      if (s.attributes.isEmpty && s.fontSize == null) {
        spans.removeAt(existingIndex);
      }
    } else {
      // Split overlapping spans and insert targeted span
      spans.add(DocStyleSpan(start: start, end: end, attributes: {attr}));
    }

    _normalizeSpans();
    notifyListeners();
  }

  /// Sets font size specifically for the selected text.
  void setSelectionFontSize(double size) {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return;

    final start = sel.start < sel.end ? sel.start : sel.end;
    final end = sel.start < sel.end ? sel.end : sel.start;

    final existingIndex = spans.indexWhere(
      (s) => s.start == start && s.end == end,
    );
    if (existingIndex != -1) {
      spans[existingIndex] = spans[existingIndex].copyWith(fontSize: size);
    } else {
      spans.add(DocStyleSpan(start: start, end: end, fontSize: size));
    }
    _normalizeSpans();
    notifyListeners();
  }

  void _normalizeSpans() {
    spans.removeWhere((s) => s.start >= s.end || s.start >= text.length);
    for (final s in spans) {
      if (s.end > text.length) s.end = text.length;
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle =
        style ?? TextStyle(color: colorScheme.onSurface, fontSize: 15.0);

    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    if (spans.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final children = <TextSpan>[];
    int cursor = 0;

    final sorted = List<DocStyleSpan>.from(spans)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final span in sorted) {
      if (span.start > cursor) {
        children.add(
          TextSpan(text: text.substring(cursor, span.start), style: baseStyle),
        );
      }

      final start = span.start.clamp(0, text.length);
      final end = span.end.clamp(0, text.length);

      if (start < end) {
        var styled = baseStyle;
        if (span.attributes.contains(DocStyleAttr.bold)) {
          styled = styled.copyWith(fontWeight: FontWeight.bold);
        }
        if (span.attributes.contains(DocStyleAttr.italic)) {
          styled = styled.copyWith(fontStyle: FontStyle.italic);
        }
        if (span.attributes.contains(DocStyleAttr.underline)) {
          styled = styled.copyWith(decoration: TextDecoration.underline);
        }
        if (span.attributes.contains(DocStyleAttr.strikethrough)) {
          styled = styled.copyWith(decoration: TextDecoration.lineThrough);
        }
        if (span.attributes.contains(DocStyleAttr.title)) {
          styled = styled.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          );
        }
        if (span.attributes.contains(DocStyleAttr.heading1)) {
          styled = styled.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          );
        }
        if (span.attributes.contains(DocStyleAttr.heading2)) {
          styled = styled.copyWith(fontSize: 17, fontWeight: FontWeight.w600);
        }
        if (span.fontSize != null) {
          styled = styled.copyWith(fontSize: span.fontSize);
        }

        children.add(TextSpan(text: text.substring(start, end), style: styled));
        cursor = end;
      }
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }

    return TextSpan(style: baseStyle, children: children);
  }
}

/// Document-style Notes Workspace with selection-only rich formatting.
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
  late final RichDocEditingController _docController;
  final TextEditingController _attachmentInputController =
      TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _attachmentFocusNode = FocusNode();

  late List<AttachmentItem> _currentAttachments;
  bool _showAttachmentInput = false;

  double _currentFontSize = 15.0;
  String _currentStyleType = 'Body';
  TextAlign _currentAlignment = TextAlign.left;

  Timer? _autoSaveDebounce;

  @override
  void initState() {
    super.initState();
    _selectedViewId = widget.initialTopic?.id;
    _titleController = TextEditingController();
    _docController = RichDocEditingController();
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
      _docController.loadFormattedText(note?.content ?? '');
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
      _docController.loadFormattedText(
        note?.content ?? topic.description ?? '',
      );
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
    final content = _docController.exportFormattedText();

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

  void _applyHeadingToSelection(String style) {
    setState(() => _currentStyleType = style);
    ZetaHaptics.selection();
    switch (style) {
      case 'Title':
        _docController.toggleSelectionStyle(DocStyleAttr.title);
        break;
      case 'Heading 1':
        _docController.toggleSelectionStyle(DocStyleAttr.heading1);
        break;
      case 'Heading 2':
        _docController.toggleSelectionStyle(DocStyleAttr.heading2);
        break;
      default:
        break;
    }
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

          // ─── 2. Google Docs Toolstrip ───────────────────────────────────
          if (_selectedViewId != '__all__')
            _buildFormatStrip(context, colorScheme),

          const Divider(height: 1),

          // ─── 3. Natural Document Canvas ──────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            PopupMenuButton<String>(
              tooltip: 'Text style',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              initialValue: _currentStyleType,
              onSelected: _applyHeadingToSelection,
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

            // Font Point Stepper for Selection
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
                      setState(
                        () => _currentFontSize = (_currentFontSize - 1).clamp(
                          11.0,
                          32.0,
                        ),
                      );
                      _docController.setSelectionFontSize(_currentFontSize);
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
                      setState(
                        () => _currentFontSize = (_currentFontSize + 1).clamp(
                          11.0,
                          32.0,
                        ),
                      );
                      _docController.setSelectionFontSize(_currentFontSize);
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

            // Selection-Only Formatting Buttons
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
                switch (index) {
                  case 0:
                    _docController.toggleSelectionStyle(DocStyleAttr.bold);
                    break;
                  case 1:
                    _docController.toggleSelectionStyle(DocStyleAttr.italic);
                    break;
                  case 2:
                    _docController.toggleSelectionStyle(DocStyleAttr.underline);
                    break;
                  case 3:
                    _docController.toggleSelectionStyle(
                      DocStyleAttr.strikethrough,
                    );
                    break;
                }
              },
              actions: const [
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'B',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  tooltip: 'Bold selection',
                ),
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'I',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tooltip: 'Italic selection',
                ),
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'U',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tooltip: 'Underline selection',
                ),
                M3EButtonGroupAction(
                  width: 32,
                  icon: Text(
                    'S',
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tooltip: 'Strikethrough selection',
                ),
              ],
            ),

            const VerticalDivider(width: 14, indent: 8, endIndent: 8),

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 4),

          // Inline Resource Link Drawer
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

          if (_currentAttachments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
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

          // Selection-styled Rich Text Area
          Expanded(
            child: TextField(
              controller: _docController,
              focusNode: _editorFocusNode,
              maxLines: null,
              expands: true,
              textAlign: _currentAlignment,
              style: TextStyle(
                fontSize: _currentFontSize,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const Divider(height: 20),
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
            const SizedBox(height: 4),
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
