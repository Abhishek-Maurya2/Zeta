import 'package:zeta/core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/task.dart';
import '../../models/revision.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/revision_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/haptics.dart';
import '../../utils/task_date_formatter.dart';
import '../../components/zeta_empty_state.dart';
import '../../components/task_edit_pane.dart';
import '../../theme/breakpoints.dart';

class TopBarSearch extends StatelessWidget {
  final M3ESearchController searchController;

  const TopBarSearch({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final revisionProvider = context.watch<RevisionProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final isCompact = ZetaWindowSizeClass.of(context).isCompact;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSearchOpen = searchController.isAttached && searchController.isOpen;
    if (!isSearchOpen && searchController.text != taskProvider.searchQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentlyOpen =
            searchController.isAttached && searchController.isOpen;
        if (!currentlyOpen &&
            searchController.text != taskProvider.searchQuery) {
          searchController.text = taskProvider.searchQuery;
        }
      });
    }

    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: M3ESearchAnchor(
            searchController: searchController,
            builder: (BuildContext context, M3ESearchController controller) {
              return M3ESearchBar(
                controller: controller,
                margin: isCompact ? 6 : null,
                focusedMargin: isCompact ? 0 : null,
                backgroundColor: WidgetStatePropertyAll(
                  colorScheme.surfaceContainerLowest,
                ),
                leading: isCompact
                    ? const SizedBox(width: 1)
                    : const Icon(M3EIcons.search_rounded),
                readOnly: true,
                alignment: AlignmentDirectional.center,
                wrapActions: false,
                hintText: isCompact
                    ? 'Search'
                    : 'Search Tasks, Notes, Subjects',
                onTap: () {
                  if (!controller.isOpen) {
                    controller.openView();
                  }
                },
                onSubmitted: (query) {
                  final trimmed = query.trim();
                  if (trimmed.isNotEmpty) {
                    taskProvider.setSearchQuery(trimmed);
                    navProvider.setActivePage(PageId.tasks);
                    if (controller.isAttached && controller.isOpen) {
                      controller.closeView(trimmed);
                    }
                  }
                },
                trailing: [
                  if (taskProvider.searchQuery.isNotEmpty ||
                      searchController.text.isNotEmpty)
                    M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        ZetaHaptics.light();
                        searchController.clear();
                        taskProvider.clearSearchQuery();
                      },
                    ),
                  // Keyboard shortcut badge [/] — non-compact only, hidden when searching
                  if (!isCompact &&
                      taskProvider.searchQuery.isEmpty &&
                      searchController.text.isEmpty)
                    Tooltip(
                      message: 'Press / to search',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          '/',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'RobotoMono',
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  // Theme Switch Icon Button Standard inside SearchBar
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                    onPressed: () {
                      ZetaHaptics.light();
                      themeProvider.toggleTheme(isDark);
                    },
                  ),
                ],
              );
            },
            suggestionsBuilder: (context, controller) {
              return _buildSearchSuggestions(
                context,
                controller,
                navProvider,
                taskProvider,
                revisionProvider,
                textTheme,
                colorScheme,
              );
            },
          ),
        ),
      ),
    );
  }

  Iterable<Widget> _buildSearchSuggestions(
    BuildContext context,
    M3ESearchController controller,
    NavigationProvider navProvider,
    TaskProvider taskProvider,
    RevisionProvider revisionProvider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final query = controller.text.trim();

    void safeCloseView([String? result]) {
      if (controller.isAttached && controller.isOpen) {
        controller.closeView(result);
      }
    }

    final isCompact = ZetaWindowSizeClass.of(context).isCompact;

    if (query.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: isCompact ? 4 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Links',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              M3EList(
                gap: 3,
                color: colorScheme.surfaceContainerLowest,
                itemCount: 3,
                haptic: M3EHapticFeedback.heavy,
                onTap: (index) {
                  safeCloseView(null);
                  switch (index) {
                    case 0:
                      TaskEditPane.show(context);
                    case 1:
                      navProvider.setActivePage(PageId.bin);
                    case 2:
                      navProvider.setActivePage(PageId.settings);
                  }
                },
                itemBuilder: (context, index) => switch (index) {
                  0 => M3EListItem(
                    leading: Icon(
                      Symbols.add_circle_rounded,
                      fill: 1,
                      weight: 700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'New Task',
                  ),
                  1 => M3EListItem(
                    leading: Icon(
                      Symbols.delete_rounded,
                      fill: 1,
                      weight: 700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Bin',
                  ),
                  _ => M3EListItem(
                    leading: Icon(
                      Symbols.settings_rounded,
                      fill: 1,
                      weight: 700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    headline: 'Settings',
                  ),
                },
              ),
              if (!ZetaWindowSizeClass.of(context).isCompact) ...[
                const SizedBox(height: 12),
                Text(
                  'Keyboard Shortcuts',
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _shortcutTag('Search', '/', colorScheme),
                    _shortcutTag('New Task', 'N', colorScheme),
                    _shortcutTag('Refresh', 'R', colorScheme),
                    _shortcutTag('Dismiss', 'Esc', colorScheme),
                  ],
                ),
              ],
            ],
          ),
        ),
      ];
    }

    final matchingTasks = taskProvider.searchTasks(query);
    final matchingBinTasks = taskProvider.searchBinTasks(query);
    final activeTasks = matchingTasks.where((t) => !t.completed).toList();
    final completedTasks = matchingTasks.where((t) => t.completed).toList();

    final qLower = query.toLowerCase();

    bool matchesSubject(Subject subject) {
      if (subject.name.toLowerCase().contains(qLower)) return true;
      if (subject.note?.content.toLowerCase().contains(qLower) == true) {
        return true;
      }
      return false;
    }

    int scoreSubject(Subject subject) {
      final name = subject.name.toLowerCase();
      int score = 0;
      if (name == qLower) {
        score += 1000;
      } else if (name.startsWith(qLower)) {
        score += 800;
      } else {
        final words = name.split(RegExp(r'\s+'));
        if (words.any((w) => w.startsWith(qLower))) {
          score += 600;
        } else if (name.contains(qLower)) {
          score += 400;
        }
      }
      if (subject.note?.content.isNotEmpty == true) {
        final content = subject.note!.content.toLowerCase();
        if (content.startsWith(qLower)) {
          score += 150;
        } else if (content.contains(qLower)) {
          score += 100;
        }
      }
      return score;
    }

    bool matchesTopic(ChapterTopic topic) {
      if (topic.title.toLowerCase().contains(qLower)) return true;
      if (topic.description?.toLowerCase().contains(qLower) == true) {
        return true;
      }
      if (topic.note?.content.toLowerCase().contains(qLower) == true) {
        return true;
      }
      return false;
    }

    int scoreTopic(ChapterTopic topic) {
      final title = topic.title.toLowerCase();
      int score = 0;
      if (title == qLower) {
        score += 1000;
      } else if (title.startsWith(qLower)) {
        score += 800;
      } else {
        final words = title.split(RegExp(r'\s+'));
        if (words.any((w) => w.startsWith(qLower))) {
          score += 600;
        } else if (title.contains(qLower)) {
          score += 400;
        }
      }
      final desc = topic.description?.isNotEmpty == true
          ? topic.description!
          : (topic.note?.content ?? '');
      if (desc.isNotEmpty) {
        final descLower = desc.toLowerCase();
        if (descLower.startsWith(qLower)) {
          score += 150;
        } else if (descLower.contains(qLower)) {
          score += 100;
        }
      }
      return score;
    }

    int scoreTask(Task task) {
      final title = task.title.toLowerCase();
      int score = 0;
      if (title == qLower) {
        score += 1000;
      } else if (title.startsWith(qLower)) {
        score += 800;
      } else {
        final words = title.split(RegExp(r'\s+'));
        if (words.any((w) => w.startsWith(qLower))) {
          score += 600;
        } else if (title.contains(qLower)) {
          score += 400;
        }
      }
      for (final subtask in task.subtasks) {
        final subTitle = subtask.title.toLowerCase();
        if (subTitle == qLower) {
          score += 300;
        } else if (subTitle.startsWith(qLower)) {
          score += 250;
        } else if (subTitle.contains(qLower)) {
          score += 200;
        }
      }
      if (task.description != null) {
        final desc = task.description!.toLowerCase();
        if (desc.startsWith(qLower)) {
          score += 150;
        } else if (desc.contains(qLower)) {
          score += 100;
        }
      }
      if (task.dueDate != null && task.dueDate!.toLowerCase().contains(qLower)) {
        score += 50;
      }
      return score;
    }

    int compareTasks(Task a, Task b) {
      final sA = scoreTask(a);
      final sB = scoreTask(b);
      if (sA != sB) return sB.compareTo(sA);
      return b.updatedAt.compareTo(a.updatedAt);
    }

    final activeList = (activeTasks..sort(compareTasks)).take(5).toList();
    final completedList = (completedTasks..sort(compareTasks)).take(5).toList();
    final binList = (matchingBinTasks..sort(compareTasks)).take(5).toList();

    final matchingSubjects = revisionProvider.subjects
        .where(matchesSubject)
        .toList();
    matchingSubjects.sort((a, b) => scoreSubject(b).compareTo(scoreSubject(a)));
    final subjectList = matchingSubjects.take(5).toList();

    final matchingTopics = revisionProvider.topics
        .where(matchesTopic)
        .toList();
    matchingTopics.sort((a, b) => scoreTopic(b).compareTo(scoreTopic(a)));
    final topicList = matchingTopics.take(5).toList();

    final totalCount = matchingTasks.length +
        matchingBinTasks.length +
        matchingSubjects.length +
        matchingTopics.length;

    final widgets = <Widget>[];

    widgets.add(
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4 : 12,
          vertical: isCompact ? 4 : 12,
        ),
        child: M3EList(
          gap: 3,
          color: colorScheme.surfaceContainerLowest,
          itemCount: 2,
          onTap: (index) {
            if (index == 0) {
              safeCloseView(query);
              taskProvider.setSearchQuery(query);
              navProvider.setActivePage(PageId.tasks);
            } else {
              safeCloseView(null);
              TaskEditPane.show(context, initialTitle: query);
            }
          },
          itemBuilder: (context, index) => index == 0
              ? M3EListItem(
                  leading: Icon(
                    Symbols.search_rounded,
                    fill: 1,
                    weight: 700,
                    color: colorScheme.primary,
                  ),
                  headline:
                      '$totalCount results found for \'$query\'',
                )
              : M3EListItem(
                  leading: Icon(
                    Symbols.add_task_rounded,
                    fill: 1,
                    weight: 700,
                    color: colorScheme.primary,
                  ),
                  headline: 'Create task \'$query\'',
                ),
        ),
      ),
    );

    M3EListItem buildTaskTile(Task task) {
      String? snippet;
      if (task.description != null &&
          task.description!.toLowerCase().contains(qLower)) {
        final desc = task.description!;
        final idx = desc.toLowerCase().indexOf(qLower);
        final start = (idx - 15).clamp(0, desc.length);
        final end = (idx + query.length + 25).clamp(0, desc.length);
        final prefix = start > 0 ? '…' : '';
        final suffix = end < desc.length ? '…' : '';
        snippet =
            'Note: $prefix${desc.substring(start, end).replaceAll('\n', ' ')}$suffix';
      }

      return M3EListItem(
        leading: Icon(
          task.completed
              ? Symbols.check_rounded
              : Symbols.radio_button_unchecked_rounded,
          fill: task.completed ? 1 : 0,
          weight: 700,
          color: task.completed
              ? const Color(0xFF10B981)
              : colorScheme.onSurfaceVariant,
        ),
        headline: task.title,
        supportingText: snippet,
        trailing: task.dueDate != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.dueDate!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              )
            : null,
      );
    }

    IconData resolveSubjectSymbol(String name) {
      return switch (name) {
        'account_balance_rounded' => Symbols.account_balance_rounded,
        'history_edu_rounded' => Symbols.history_edu_rounded,
        'trending_up_rounded' => Symbols.trending_up_rounded,
        'terminal_rounded' => Symbols.terminal_rounded,
        'calculate_rounded' => Symbols.calculate_rounded,
        'biotech_rounded' => Symbols.biotech_rounded,
        'science_rounded' => Symbols.science_rounded,
        'palette_rounded' => Symbols.palette_rounded,
        'language_rounded' => Symbols.language_rounded,
        'psychology_rounded' => Symbols.psychology_rounded,
        _ => Symbols.menu_book_rounded,
      };
    }

    M3EListItem buildSubjectTile(Subject subject) {
      String? snippet;
      final noteContent = subject.note?.content;
      if (noteContent != null && noteContent.toLowerCase().contains(qLower)) {
        final idx = noteContent.toLowerCase().indexOf(qLower);
        final start = (idx - 15).clamp(0, noteContent.length);
        final end = (idx + query.length + 25).clamp(0, noteContent.length);
        final prefix = start > 0 ? '…' : '';
        final suffix = end < noteContent.length ? '…' : '';
        snippet =
            'Note: $prefix${noteContent.substring(start, end).replaceAll('\n', ' ')}$suffix';
      }

      final topicCount = revisionProvider.topics
          .where((t) => t.subjectId == subject.id)
          .length;
      final topicLabel =
          '$topicCount ${topicCount == 1 ? 'topic' : 'topics'}';
      final supporting = snippet != null
          ? '$topicLabel · $snippet'
          : 'Subject · $topicLabel';

      return M3EListItem(
        leading: Icon(
          resolveSubjectSymbol(subject.iconName),
          fill: 1,
          weight: 700,
          color: subject.color,
        ),
        headline: subject.name,
        supportingText: supporting,
      );
    }

    M3EListItem buildTopicTile(ChapterTopic topic) {
      final subject = revisionProvider.subjects
          .where((s) => s.id == topic.subjectId)
          .firstOrNull;
      final isDone = topic.isCompleted || topic.isMastered;

      String? snippet;
      final text = topic.description?.isNotEmpty == true
          ? topic.description!
          : (topic.note?.content ?? '');
      if (text.isNotEmpty && text.toLowerCase().contains(qLower)) {
        final idx = text.toLowerCase().indexOf(qLower);
        final start = (idx - 15).clamp(0, text.length);
        final end = (idx + query.length + 25).clamp(0, text.length);
        final prefix = start > 0 ? '…' : '';
        final suffix = end < text.length ? '…' : '';
        snippet =
            'Note: $prefix${text.substring(start, end).replaceAll('\n', ' ')}$suffix';
      }

      final subjectName = subject?.name ?? 'Revision';
      final supporting =
          snippet != null ? '$subjectName · $snippet' : 'Topic · $subjectName';

      Widget? trailing;
      if (topic.isMastered) {
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Mastered 🏆',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        );
      } else if (topic.status == RevisionStatus.overdue) {
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Overdue',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onErrorContainer,
            ),
          ),
        );
      } else if (topic.nextRevisionDate != null) {
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            TaskDateFormatter.format(topic.nextRevisionDate!),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        );
      }

      return M3EListItem(
        leading: Icon(
          isDone ? Symbols.check_rounded : Symbols.description_rounded,
          fill: 1,
          weight: 700,
          color: isDone
              ? const Color(0xFF10B981)
              : colorScheme.onSurfaceVariant,
        ),
        headline: topic.title,
        supportingText: supporting,
        trailing: trailing,
      );
    }

    if (activeList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: Text(
            'Tasks (${activeTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final taskTiles = activeList.map(buildTaskTile).toList();
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: taskTiles.length,
            onTap: (index) {
              safeCloseView(null);
              TaskEditPane.show(context, task: activeList[index]);
            },
            itemBuilder: (context, index) => taskTiles[index],
          ),
        ),
      );
    }

    if (subjectList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: Text(
            'Subjects (${matchingSubjects.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final subjectTiles = subjectList.map(buildSubjectTile).toList();
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: subjectTiles.length,
            onTap: (index) {
              safeCloseView(null);
              final subject = subjectList[index];
              revisionProvider.selectSubject(subject.id);
              revisionProvider.closeNotes();
              navProvider.setActivePage(PageId.revision);
            },
            itemBuilder: (context, index) => subjectTiles[index],
          ),
        ),
      );
    }

    if (topicList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: Text(
            'Topics (${matchingTopics.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final topicTiles = topicList.map(buildTopicTile).toList();
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: topicTiles.length,
            onTap: (index) {
              safeCloseView(null);
              final topic = topicList[index];
              revisionProvider.selectSubject(topic.subjectId);
              revisionProvider.openNotes(topic: topic);
              navProvider.setActivePage(PageId.revision);
            },
            itemBuilder: (context, index) => topicTiles[index],
          ),
        ),
      );
    }

    if (completedList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: Text(
            'Completed (${completedTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final completedTiles = completedList.map(buildTaskTile).toList();
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: completedTiles.length,
            onTap: (index) {
              safeCloseView(null);
              TaskEditPane.show(context, task: completedList[index]);
            },
            itemBuilder: (context, index) => completedTiles[index],
          ),
        ),
      );
    }

    if (binList.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: Text(
            'Bin (${matchingBinTasks.length})',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
      );

      final binTiles = <Widget>[];
      for (final binTask in binList) {
        binTiles.add(
          M3EListItem(
            leading: Icon(
              Symbols.delete_rounded,
              fill: 1,
              weight: 700,
              color: colorScheme.error,
            ),
            headline: binTask.title,
          ),
        );
      }

      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 12,
            vertical: 6,
          ),
          child: M3EList(
            gap: 3,
            color: colorScheme.surfaceContainerLowest,
            itemCount: binTiles.length,
            onTap: (index) {
              safeCloseView(null);
              navProvider.setActivePage(PageId.bin);
            },
            itemBuilder: (context, index) => binTiles[index],
          ),
        ),
      );
    }

    if (activeTasks.isEmpty &&
        matchingSubjects.isEmpty &&
        matchingTopics.isEmpty &&
        completedTasks.isEmpty &&
        matchingBinTasks.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: ZetaEmptyState.search(
            query: query,
            subtitle: 'Tap "Create task" above to add it to your list.',
            size: ZetaEmptyStateSize.compact,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _shortcutTag(String label, String keyChar, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              keyChar,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
