import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../providers/pomodoro_provider.dart';
import '../components/pomodoro/pomodoro_timer_pane.dart';
import '../components/pomodoro/pomodoro_queue_pane.dart';
import '../components/pomodoro/pomodoro_analysis_pane.dart';
import '../components/pomodoro/pomodoro_settings_sheet.dart';

enum PomodoroTab {
  timer,
  queue,
  analysis;

  String get label {
    switch (this) {
      case PomodoroTab.timer:
        return 'Timer';
      case PomodoroTab.queue:
        return 'Up next';
      case PomodoroTab.analysis:
        return 'Analysis';
    }
  }
}

enum SecondaryPaneTab {
  queue,
  analysis;

  String get label {
    switch (this) {
      case SecondaryPaneTab.queue:
        return 'Up next';
      case SecondaryPaneTab.analysis:
        return 'Analysis';
    }
  }
}

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  PomodoroTab _activeTab = PomodoroTab.timer;
  SecondaryPaneTab _secondaryTab = SecondaryPaneTab.queue;
  bool _isAodMode = false;

  void _enterAodMode() {
    setState(() => _isAodMode = true);
    final provider = context.read<PomodoroProvider>();
    if (!provider.isRunning) {
      provider.startTimer();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitAodMode() {
    setState(() => _isAodMode = false);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTwoPane = width >= 840;
    final provider = context.watch<PomodoroProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        // ─── Main Content ───────────────────────────────────────────────────
        Scaffold(
          backgroundColor: Colors.transparent,
          body: isTwoPane
              ? _buildTwoPaneLayout(context, provider, colorScheme, textTheme)
              : _buildSinglePaneLayout(context, provider, colorScheme, textTheme),
        ),

        // ─── Always-On Display (AOD) Fullscreen Overlay ─────────────────────
        if (_isAodMode)
          _buildAodOverlay(context, provider, textTheme),
      ],
    );
  }

  // ─── Desktop / Wide (≥ 840px) Two-Pane Split Layout ─────────────────────
  Widget _buildTwoPaneLayout(
    BuildContext context,
    PomodoroProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // Left Pane: Timer Pane
        Expanded(
          flex: 55,
          child: PomodoroTimerPane(
            onToggleAod: _enterAodMode,
          ),
        ),

        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),

        // Right Pane: Secondary Pane (Up next or Analysis)
        Expanded(
          flex: 45,
          child: Container(
            color: colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Secondary Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        M3EButtonGroup(
                          type: M3EButtonGroupType.connected,
                          size: M3EButtonSize.sm,
                          style: M3EButtonStyle.tonal,
                          selectedIndex: _secondaryTab.index,
                          onSelectedIndexChanged: (idx) {
                            if (idx != null) {
                              setState(() {
                                _secondaryTab = SecondaryPaneTab.values[idx];
                              });
                            }
                          },
                          actions: [
                            M3EButtonGroupAction(
                              icon: const Icon(Icons.checklist_rounded, size: 16),
                              label: Text('Up next (${provider.queue.length})'),
                            ),
                            const M3EButtonGroupAction(
                              icon: Icon(Icons.insights_rounded, size: 16),
                              label: Text('Analysis'),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        if (_secondaryTab == SecondaryPaneTab.queue)
                          M3EButton.icon(
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: const Text('Configure'),
                            style: M3EButtonStyle.tonal,
                            size: M3EButtonSize.sm,
                            onPressed: () => PomodoroSettingsSheet.show(context),
                          )
                        else
                          Text(
                            'Session Stats',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Pane Body
                Expanded(
                  child: _secondaryTab == SecondaryPaneTab.queue
                      ? const PomodoroQueuePane(isSplitPane: true)
                      : const PomodoroAnalysisPane(isSplitPane: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Compact (< 840px) Tabbed Single-Pane Layout ─────────────────────────
  Widget _buildSinglePaneLayout(
    BuildContext context,
    PomodoroProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        // Top Connected Tab Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: M3EButtonGroup(
              type: M3EButtonGroupType.connected,
              size: M3EButtonSize.sm,
              style: M3EButtonStyle.tonal,
              selectedIndex: _activeTab.index,
              onSelectedIndexChanged: (idx) {
                if (idx != null) {
                  setState(() {
                    _activeTab = PomodoroTab.values[idx];
                  });
                }
              },
              actions: [
                const M3EButtonGroupAction(
                  label: Text('Timer'),
                ),
                M3EButtonGroupAction(
                  label: Text('Up next (${provider.queue.length})'),
                ),
                const M3EButtonGroupAction(
                  label: Text('Analysis'),
                ),
              ],
            ),
          ),
        ),

        // Active Tab View
        Expanded(
          child: IndexedStack(
            index: _activeTab.index,
            children: [
              PomodoroTimerPane(
                onToggleAod: _enterAodMode,
              ),
              const PomodoroQueuePane(),
              const PomodoroAnalysisPane(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Always-On Display (AOD) Fullscreen Mode ─────────────────────────────
  Widget _buildAodOverlay(
    BuildContext context,
    PomodoroProvider provider,
    TextTheme textTheme,
  ) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: InkWell(
          onTap: () => provider.toggleTimer(),
          child: Stack(
            children: [
              // Top Bar
              Positioned(
                top: 16,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      provider.mode.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.fullscreen_exit_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Exit full screen',
                      onPressed: _exitAodMode,
                    ),
                  ],
                ),
              ),

              // Giant Countdown Display
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        provider.formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 120,
                          fontWeight: FontWeight.w200,
                          letterSpacing: -3.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.isRunning ? 'RUNNING' : 'PAUSED',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
