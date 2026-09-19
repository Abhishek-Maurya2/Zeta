import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../utils/haptics.dart';

/// Display size variants for [ZetaEmptyState].
enum ZetaEmptyStateSize {
  /// Full-page or major section empty state.
  standard,

  /// Inline or nested card/drawer empty state.
  compact,
}

/// A highly polished, reusable empty state component crafted with
/// Material 3 Expressive shapes, typography, and buttons.
///
/// Features:
/// - Layered [M3EShapeContainer] illustration with expressive geometry
///   (e.g., cookie, sunny, flower, softBurst, ghostish).
/// - Gentle spring scale & fade-in entrance animation.
/// - Adaptive standard and compact sizing.
/// - Pre-configured presets for tasks, search, bin, focus, and pomodoro.
class ZetaEmptyState extends StatelessWidget {
  /// The icon displayed at the center of the expressive shape.
  final IconData icon;

  /// The Material 3 Expressive shape used for the illustration container.
  final M3EShapeKind shapeKind;

  /// Main heading text or custom widget.
  final String title;

  /// Descriptive subtitle text or explanation.
  final String? subtitle;

  /// Size variant: [ZetaEmptyStateSize.standard] or [ZetaEmptyStateSize.compact].
  final ZetaEmptyStateSize size;

  /// Optional primary action widget (e.g. an [M3EButton]).
  final Widget? primaryAction;

  /// Optional secondary action widget (e.g. an [M3EButton] or [M3EIconButton]).
  final Widget? secondaryAction;

  /// Optional custom background color for the shape.
  final Color? shapeColor;

  /// Optional custom foreground color for the icon.
  final Color? iconColor;

  /// Optional custom gradient for the shape container.
  final Gradient? shapeGradient;

  /// Maximum width for the subtitle text block to ensure optimal line length.
  final double maxContentWidth;

  /// Optional custom padding around the entire empty state.
  final EdgeInsetsGeometry? padding;

  /// Whether to animate the shape on entrance.
  final bool animated;

  const ZetaEmptyState({
    super.key,
    required this.icon,
    this.shapeKind = M3EShapeKind.cookie4Sided,
    required this.title,
    this.subtitle,
    this.size = ZetaEmptyStateSize.standard,
    this.primaryAction,
    this.secondaryAction,
    this.shapeColor,
    this.iconColor,
    this.shapeGradient,
    this.maxContentWidth = 400.0,
    this.padding,
    this.animated = true,
  });

  /// Preset for task-related empty states (all, pending, completed).
  factory ZetaEmptyState.tasks({
    Key? key,
    IconData icon = Icons.task_alt_rounded,
    M3EShapeKind shapeKind = M3EShapeKind.cookie4Sided,
    String title = 'No tasks yet',
    String? subtitle = 'Click "+ Add Task" to create your first task.',
    ZetaEmptyStateSize size = ZetaEmptyStateSize.standard,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onAction,
    Widget? customAction,
    Color? shapeColor,
    Color? iconColor,
  }) {
    Widget? action = customAction;
    if (action == null && actionLabel != null && onAction != null) {
      action = M3EButton.icon(
        icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
        label: Text(actionLabel),
        style: M3EButtonStyle.filled,
        size: size == ZetaEmptyStateSize.compact
            ? M3EButtonSize.sm
            : M3EButtonSize.md,
        onPressed: () {
          ZetaHaptics.light();
          onAction();
        },
      );
    }

    return ZetaEmptyState(
      key: key,
      icon: icon,
      shapeKind: shapeKind,
      title: title,
      subtitle: subtitle,
      size: size,
      primaryAction: action,
      shapeColor: shapeColor,
      iconColor: iconColor,
    );
  }

  /// Preset for search query empty states (when 0 matches found).
  factory ZetaEmptyState.search({
    Key? key,
    required String query,
    String? subtitle,
    VoidCallback? onClearSearch,
    String clearButtonLabel = 'Clear search filter',
    ZetaEmptyStateSize size = ZetaEmptyStateSize.standard,
    M3EShapeKind shapeKind = M3EShapeKind.ghostish,
  }) {
    return ZetaEmptyState(
      key: key,
      icon: Icons.search_off_rounded,
      shapeKind: shapeKind,
      title: 'No results for "$query"',
      subtitle: subtitle ?? 'No matching items found. Check your spelling or try different keywords.',
      size: size,
      primaryAction: onClearSearch != null
          ? M3EButton.icon(
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: Text(clearButtonLabel),
              style: M3EButtonStyle.outlined,
              size: M3EButtonSize.sm,
              onPressed: () {
                ZetaHaptics.light();
                onClearSearch();
              },
            )
          : null,
    );
  }

  /// Preset for recycle bin empty states.
  factory ZetaEmptyState.bin({
    Key? key,
    VoidCallback? onNavigateToTasks,
    String title = 'Bin is Empty',
    String subtitle = 'No deleted tasks. Items deleted from your task list will appear here and can be restored at any time.',
    ZetaEmptyStateSize size = ZetaEmptyStateSize.standard,
  }) {
    return ZetaEmptyState(
      key: key,
      icon: Icons.delete_outline_rounded,
      shapeKind: M3EShapeKind.flower,
      title: title,
      subtitle: subtitle,
      size: size,
      primaryAction: onNavigateToTasks != null
          ? M3EButton.icon(
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text('Go to Tasks'),
              style: M3EButtonStyle.filled,
              size: size == ZetaEmptyStateSize.compact
                  ? M3EButtonSize.sm
                  : M3EButtonSize.md,
              onPressed: () {
                ZetaHaptics.light();
                onNavigateToTasks();
              },
            )
          : null,
    );
  }

  /// Preset for Today's Focus card empty states.
  factory ZetaEmptyState.focus({
    Key? key,
    required bool isToday,
    required String formattedDate,
    VoidCallback? onCreateTask,
    ZetaEmptyStateSize size = ZetaEmptyStateSize.standard,
  }) {
    return ZetaEmptyState(
      key: key,
      icon: Icons.wb_sunny_rounded,
      shapeKind: M3EShapeKind.sunny,
      title: isToday ? 'Clear Focus for Today' : 'No Tasks Scheduled',
      subtitle: isToday
          ? 'All set! No pending tasks scheduled right now.'
          : 'No tasks scheduled for $formattedDate.',
      size: size,
      primaryAction: onCreateTask != null
          ? M3EButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Add new task',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
              ),
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.md,
              onPressed: () {
                ZetaHaptics.light();
                onCreateTask();
              },
            )
          : null,
    );
  }

  /// Preset for Pomodoro cycle or session history empty states.
  factory ZetaEmptyState.pomodoro({
    Key? key,
    required String title,
    String? subtitle,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onAction,
    ZetaEmptyStateSize size = ZetaEmptyStateSize.compact,
  }) {
    return ZetaEmptyState(
      key: key,
      icon: Icons.timer_outlined,
      shapeKind: M3EShapeKind.softBurst,
      title: title,
      subtitle: subtitle,
      size: size,
      primaryAction: (actionLabel != null && onAction != null)
          ? M3EButton.icon(
              icon: Icon(actionIcon ?? Icons.auto_awesome_rounded, size: 16),
              label: Text(actionLabel),
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              onPressed: () {
                ZetaHaptics.selection();
                onAction();
              },
            )
          : null,
    );
  }

  /// Preset for Revision / Study tracker empty states.
  factory ZetaEmptyState.revision({
    Key? key,
    IconData icon = Icons.auto_stories_rounded,
    M3EShapeKind shapeKind = M3EShapeKind.cookie4Sided,
    required String title,
    String? subtitle,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onAction,
    Widget? customAction,
    ZetaEmptyStateSize size = ZetaEmptyStateSize.standard,
    Color? shapeColor,
    Color? iconColor,
  }) {
    Widget? action = customAction;
    if (action == null && actionLabel != null && onAction != null) {
      action = M3EButton.icon(
        icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
        label: Text(actionLabel),
        style: M3EButtonStyle.filled,
        size: size == ZetaEmptyStateSize.compact
            ? M3EButtonSize.sm
            : M3EButtonSize.md,
        onPressed: () {
          ZetaHaptics.light();
          onAction();
        },
      );
    }

    return ZetaEmptyState(
      key: key,
      icon: icon,
      shapeKind: shapeKind,
      title: title,
      subtitle: subtitle,
      size: size,
      primaryAction: action,
      shapeColor: shapeColor,
      iconColor: iconColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isCompact = size == ZetaEmptyStateSize.compact;
    final double coreShapeSize = isCompact ? 65.0 : 95.0;
    final double haloSize = isCompact ? 80.0 : 120.0;
    final double iconSize = isCompact ? 26.0 : 38.0;

    final effectiveShapeColor = shapeColor ?? colorScheme.primaryContainer;
    final effectiveIconColor = iconColor ?? colorScheme.onPrimaryContainer;

    final Widget illustration = Stack(
      alignment: Alignment.center,
      children: [
        // Outer soft ambient halo
        M3EShapeContainer(
          kind: shapeKind,
          width: haloSize,
          height: haloSize,
          color: effectiveShapeColor.withValues(alpha: 0.22),
        ),
        // Core expressive shape container
        M3EShapeContainer(
          kind: shapeKind,
          width: coreShapeSize,
          height: coreShapeSize,
          color: effectiveShapeColor,
          gradient: shapeGradient,
          child: Center(
            child: Icon(icon, size: iconSize, color: effectiveIconColor),
          ),
        ),
      ],
    );

    final Widget animatedIllustration = animated
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.85 + (0.15 * value),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: illustration,
          )
        : illustration;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        animatedIllustration,
        SizedBox(height: isCompact ? 14 : 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isCompact ? 17 : 19),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: isCompact ? 6 : 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isCompact ? 13 : 15),
            ),
          ),
        ],
        if (primaryAction != null || secondaryAction != null) ...[
          SizedBox(height: isCompact ? 14 : 20),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [?primaryAction, ?secondaryAction],
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding:
            padding ??
            EdgeInsets.symmetric(
              vertical: isCompact ? 16 : 40,
              horizontal: isCompact ? 16 : 24,
            ),
        child: content,
      ),
    );
  }
}
