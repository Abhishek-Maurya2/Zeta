import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/add_attachment_dialog.dart';
import '../../../components/attachment_chip.dart';
import '../../../components/glass_alert_dialog.dart';
import '../../../models/attachment.dart';
import '../../../models/note_item.dart';
import '../../../models/revision.dart';
import '../../../providers/revision_provider.dart';
import '../../../theme/breakpoints.dart';
import '../../../utils/haptics.dart';

/// Full-featured Notes & Attachments Sheet / Dialog for Subjects and Topics.
///
/// Features:
/// - Android: Read-only Notes View with clean Markdown and interactive attachment chips.
/// - Windows & Web: Read & Edit views with markdown toolbar, preview, and note-attachment management.
/// - Topic notes are accessible and visible within Subject notes.
/// - Supports attachments inside notes as well as direct subject/topic attachments.
class RevisionNotesSheet extends StatefulWidget {
  final Subject subject;
  final ChapterTopic? initialTopic;

  const RevisionNotesSheet({
    super.key,
    required this.subject,
    this.initialTopic,
  });

  static Future<void> show(
    BuildContext context, {
    required Subject subject,
    ChapterTopic? initialTopic,
  }) {
    final sizeClass = ZetaWindowSizeClass.of(context);
    final isCompact = sizeClass.isCompact;

    if (isCompact) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        builder: (ctx) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Theme.of(ctx).colorScheme.surface,
              child: RevisionNotesSheet(
                subject: subject,
                initialTopic: initialTopic,
              ),
            ),
          ),
        ),
      );
    } else {
      return showGlassDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 860,
                height: 720,
                color: Theme.of(ctx).colorScheme.surface.withValues(alpha: 0.95),
                child: RevisionNotesSheet(
                  subject: subject,
                  initialTopic: initialTopic,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  State<RevisionNotesSheet> createState() => _RevisionNotesSheetState();
}

class _RevisionNotesSheetState extends State<RevisionNotesSheet> {
  // Navigation / Selection State
  // null = Subject Overview Notes; non-null = Specific Topic's Notes; '__all__' = Aggregated Topics View
  String? _selectedViewId;

  // Edit Mode state (only available on Windows / Web)
  bool _isEditMode = false;

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<AttachmentItem> _currentNoteAttachments;
  late List<AttachmentItem> _currentDirectAttachments;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android && !kIsWeb;

  @override
  void initState() {
    super.initState();
    _selectedViewId = widget.initialTopic?.id;
    _initEditorState();
  }

  void _initEditorState() {
    final revProvider = context.read<RevisionProvider>();
    final currentSubject = revProvider.subjects.firstWhere(
      (s) => s.id == widget.subject.id,
      orElse: () => widget.subject,
    );

    if (_selectedViewId == null || _selectedViewId == '__all__') {
      // Subject notes
      final note = currentSubject.note;
      _titleController = TextEditingController(text: note?.title ?? currentSubject.name);
      _contentController = TextEditingController(text: note?.content ?? '');
      _currentNoteAttachments = note?.attachments.map((a) => a.copyWith()).toList() ?? [];
      _currentDirectAttachments = currentSubject.attachments.map((a) => a.copyWith()).toList();
    } else {
      // Topic notes
      final topic = revProvider.topics.firstWhere(
        (t) => t.id == _selectedViewId,
        orElse: () => widget.initialTopic!,
      );
      final note = topic.note;
      _titleController = TextEditingController(text: note?.title ?? topic.title);
      _contentController = TextEditingController(text: note?.content ?? topic.description ?? '');
      _currentNoteAttachments = note?.attachments.map((a) => a.copyWith()).toList() ?? [];
      _currentDirectAttachments = topic.attachments.map((a) => a.copyWith()).toList();
    }
  }

  void _switchView(String? viewId) {
    ZetaHaptics.selection();
    setState(() {
      _selectedViewId = viewId;
      _isEditMode = false;
      _initEditorState();
    });
  }

  void _insertMarkdown(String prefix, [String suffix = '']) {
    ZetaHaptics.light();
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final selectedText = text.substring(start, end);

    final replacement = '$prefix$selectedText$suffix';
    final newText = text.replaceRange(start, end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length),
    );
  }

  Future<void> _handleSave() async {
    ZetaHaptics.medium();
    final revProvider = context.read<RevisionProvider>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (_selectedViewId == null) {
      // Save subject note
      final currentSubject = revProvider.subjects.firstWhere(
        (s) => s.id == widget.subject.id,
        orElse: () => widget.subject,
      );
      final updatedNote = NoteItem(
        id: currentSubject.note?.id ?? currentSubject.id,
        title: title.isNotEmpty ? title : currentSubject.name,
        content: content,
        attachments: _currentNoteAttachments,
        createdAt: currentSubject.note?.createdAt,
      );
      final updatedSubject = currentSubject.copyWith(
        note: updatedNote,
        attachments: _currentDirectAttachments,
      );
      await revProvider.updateSubject(updatedSubject);
    } else if (_selectedViewId != '__all__') {
      // Save topic note
      final currentTopic = revProvider.topics.firstWhere((t) => t.id == _selectedViewId);
      final updatedNote = NoteItem(
        id: currentTopic.note?.id ?? currentTopic.id,
        title: title.isNotEmpty ? title : currentTopic.title,
        content: content,
        attachments: _currentNoteAttachments,
        createdAt: currentTopic.note?.createdAt,
      );
      final updatedTopic = currentTopic.copyWith(
        description: content,
        note: updatedNote,
        attachments: _currentDirectAttachments,
      );
      await revProvider.updateTopic(updatedTopic);
    }

    if (mounted) {
      setState(() {
        _isEditMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes & attachments saved!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revProvider = context.watch<RevisionProvider>();

    final subject = revProvider.subjects.firstWhere(
      (s) => s.id == widget.subject.id,
      orElse: () => widget.subject,
    );
    final subjectTopics = revProvider.topics
        .where((t) => t.subjectId == subject.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      children: [
        // ─── Header ─────────────────────────────────────────────────────────────
        _buildHeader(context, subject),

        // ─── View Switcher / Topic Selector Strip ────────────────────────────────
        _buildViewSelector(context, subject, subjectTopics),

        const Divider(height: 1),

        // ─── Content Area ───────────────────────────────────────────────────────
        Expanded(
          child: _selectedViewId == '__all__'
              ? _buildAllTopicsView(context, subjectTopics)
              : (_isEditMode && !_isAndroid)
                  ? _buildEditView(context)
                  : _buildReadView(context, subject, subjectTopics),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Subject subject) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: subject.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: subject.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subject.name,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedViewId == null
                      ? 'Subject Notes & Resources'
                      : _selectedViewId == '__all__'
                          ? 'All Topic Notes'
                          : 'Topic Notes',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Edit/Read Toggle (Hidden on Android)
          if (!_isAndroid && _selectedViewId != '__all__') ...[
            M3EButton.icon(
              onPressed: () {
                ZetaHaptics.light();
                if (_isEditMode) {
                  _handleSave();
                } else {
                  setState(() {
                    _isEditMode = true;
                  });
                }
              },
              label: Text(_isEditMode ? 'Save' : 'Edit'),
              icon: Icon(_isEditMode ? Icons.check_rounded : Icons.edit_outlined, size: 16),
              style: _isEditMode ? M3EButtonStyle.filled : M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
            ),
            const SizedBox(width: 8),
          ],

          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(
    BuildContext context,
    Subject subject,
    List<ChapterTopic> topics,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Subject Overview Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: const Icon(Icons.auto_stories_rounded, size: 16),
              label: const Text('Subject Overview'),
              selected: _selectedViewId == null,
              onSelected: (_) => _switchView(null),
            ),
          ),

          // All Topics Stream Button
          if (topics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: const Icon(Icons.view_agenda_rounded, size: 16),
                label: Text('All Topics Notes (${topics.length})'),
                selected: _selectedViewId == '__all__',
                onSelected: (_) => _switchView('__all__'),
              ),
            ),

          // Individual Topic Chips
          ...topics.map((t) {
            final hasNotes = t.note?.isNotEmpty == true || (t.description?.isNotEmpty ?? false);
            final hasAttachments = t.attachments.isNotEmpty || (t.note?.attachments.isNotEmpty ?? false);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: hasNotes || hasAttachments
                    ? const Icon(Icons.description_rounded, size: 15)
                    : null,
                label: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: _selectedViewId == t.id,
                onSelected: (_) => _switchView(t.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReadView(
    BuildContext context,
    Subject subject,
    List<ChapterTopic> topics,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final title = _titleController.text;
    final content = _contentController.text.trim();
    final noteAttachments = _currentNoteAttachments;
    final directAttachments = _currentDirectAttachments;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Direct Attachments Section (e.g. general links for subject/topic)
        if (directAttachments.isNotEmpty) ...[
          Text(
            'Resources & Links',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: directAttachments.map((a) => AttachmentChip(attachment: a)).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // Markdown Notes Content
        if (content.isNotEmpty)
          MarkdownBody(
            data: content,
            selectable: true,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
              }
            },
            styleSheet: MarkdownStyleSheet.fromTheme(m.Theme.of(context)).copyWith(
              p: textTheme.bodyLarge?.copyWith(height: 1.6),
              h1: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              h2: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              code: TextStyle(
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 48,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'No notes written yet.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (!_isAndroid) ...[
                  const SizedBox(height: 12),
                  M3EButton.icon(
                    onPressed: () => setState(() => _isEditMode = true),
                    label: const Text('Write Notes'),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                  ),
                ],
              ],
            ),
          ),

        // Attachments inside this note
        if (noteAttachments.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Attachments inside this Note',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: noteAttachments.map((a) => AttachmentChip(attachment: a)).toList(),
          ),
        ],
      ],
    );
  }

  /// Aggregated view showing all topic notes under the subject sequentially!
  Widget _buildAllTopicsView(BuildContext context, List<ChapterTopic> topics) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (topics.isEmpty) {
      return Center(
        child: Text(
          'No topics added yet under this subject.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: topics.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Divider(),
      ),
      itemBuilder: (context, index) {
        final topic = topics[index];
        final note = topic.note;
        final content = note?.content.isNotEmpty == true
            ? note!.content
            : (topic.description ?? '');
        final allAttachments = [
          ...topic.attachments,
          ...?note?.attachments,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!_isAndroid)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Topic Notes',
                    onPressed: () => _switchView(topic.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (content.isNotEmpty)
              MarkdownBody(
                data: content,
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
                  }
                },
                styleSheet: MarkdownStyleSheet.fromTheme(m.Theme.of(context)).copyWith(
                  p: textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              )
            else
              Text(
                'No notes for this topic.',
                style: textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

            if (allAttachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: allAttachments.map((a) => AttachmentChip(attachment: a)).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEditView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title Input
        TextField(
          controller: _titleController,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Note Title...',
            border: InputBorder.none,
          ),
        ),

        const SizedBox(height: 10),

        // Quick Markdown Formatting Toolbar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToolbarBtn('B', 'Bold', () => _insertMarkdown('**', '**')),
              _buildToolbarBtn('I', 'Italic', () => _insertMarkdown('*', '*')),
              _buildToolbarBtn('H1', 'Heading 1', () => _insertMarkdown('# ')),
              _buildToolbarBtn('H2', 'Heading 2', () => _insertMarkdown('## ')),
              _buildToolbarBtn('• List', 'Bullet list', () => _insertMarkdown('- ')),
              _buildToolbarBtn('1. List', 'Numbered list', () => _insertMarkdown('1. ')),
              _buildToolbarBtn('Task', 'Checklist', () => _insertMarkdown('- [ ] ')),
              _buildToolbarBtn('Code', 'Code block', () => _insertMarkdown('```\n', '\n```')),
              _buildToolbarBtn('Quote', 'Blockquote', () => _insertMarkdown('> ')),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Content Input
        Container(
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            minLines: 8,
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Write in markdown (headers, bullets, code, formulas)...',
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Section: Attachments inside this note
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attachments inside this Note',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            M3EButton.icon(
              onPressed: () async {
                ZetaHaptics.light();
                final item = await AddAttachmentDialog.show(context);
                if (item != null) {
                  setState(() {
                    _currentNoteAttachments.add(item);
                  });
                }
              },
              label: const Text('Add to Note'),
              icon: const Icon(Icons.add_link_rounded, size: 16),
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_currentNoteAttachments.isEmpty)
          Text(
            'No attachments inside this note yet.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _currentNoteAttachments.map((a) {
              return AttachmentChip(
                attachment: a,
                onDelete: () {
                  setState(() {
                    _currentNoteAttachments.removeWhere((item) => item.id == a.id);
                  });
                },
              );
            }).toList(),
          ),

        const SizedBox(height: 24),

        // Section: Direct Subject / Topic Attachments
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'General Resources & Links',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            M3EButton.icon(
              onPressed: () async {
                ZetaHaptics.light();
                final item = await AddAttachmentDialog.show(context);
                if (item != null) {
                  setState(() {
                    _currentDirectAttachments.add(item);
                  });
                }
              },
              label: const Text('Add Resource'),
              icon: const Icon(Icons.add_link_rounded, size: 16),
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_currentDirectAttachments.isEmpty)
          Text(
            'No general resources attached yet.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _currentDirectAttachments.map((a) {
              return AttachmentChip(
                attachment: a,
                onDelete: () {
                  setState(() {
                    _currentDirectAttachments.removeWhere((item) => item.id == a.id);
                  });
                },
              );
            }).toList(),
          ),

        const SizedBox(height: 32),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            M3EButton(
              onPressed: () => setState(() => _isEditMode = false),
              style: M3EButtonStyle.outlined,
              size: M3EButtonSize.md,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            M3EButton.icon(
              onPressed: _handleSave,
              label: const Text('Save Changes'),
              icon: const Icon(Icons.save_rounded, size: 16),
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.md,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbarBtn(String label, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
