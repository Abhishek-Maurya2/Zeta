import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart'; // Adjust path if needed

import '../../../providers/theme_provider.dart'; // Adjust path as needed

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../utils/haptics.dart';

enum MockTestStage { prelims, mains }

class CategoryScore {
  final String label;
  final double score;
  final double maxScore;
  final Color barColor;

  const CategoryScore({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.barColor,
  });

  double get ratio => maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
}

class MockEntryRecord {
  final MockTestStage stage;
  final String testName;
  final DateTime date;
  final Map<String, double> categoryScores;
  final double totalOutOf;

  const MockEntryRecord({
    required this.stage,
    required this.testName,
    required this.date,
    required this.categoryScores,
    required this.totalOutOf,
  });
}

class MockTestRadarCard extends StatefulWidget {
  final void Function(MockEntryRecord record)? onSaveTest;

  const MockTestRadarCard({super.key, this.onSaveTest});

  @override
  State<MockTestRadarCard> createState() => _MockTestRadarCardState();
}

class _MockTestRadarCardState extends State<MockTestRadarCard> {
  MockTestStage _selectedStage = MockTestStage.prelims;

  // ─── Prelims Default / Working State (GS1, CSAT) ─────────────
  final Map<String, double> _prelimsScores = {'GS-1': 108.5, 'CSAT': 84.0};
  final Map<String, double> _prelimsMax = {'GS-1': 200.0, 'CSAT': 200.0};

  // ─── Mains Default / Working State (GS1, GS2, GS3, GS4, Essay, Optional)
  final Map<String, double> _mainsScores = {
    'GS 1': 102.0,
    'GS 2': 114.0,
    'GS 3': 96.5,
    'GS 4': 118.0,
    'Essay': 132.0,
    'Optional': 282.0,
  };
  final Map<String, double> _mainsMax = {
    'GS 1': 250.0,
    'GS 2': 250.0,
    'GS 3': 250.0,
    'GS 4': 250.0,
    'Essay': 250.0,
    'Optional': 500.0,
  };

  bool get _isPrelims => _selectedStage == MockTestStage.prelims;

  List<CategoryScore> _activeCategories() {
    // Palette matching the reference image: Lilac, Coral, Orchid, Deep Plum, Periwinkle, Mint
    final barPalette = [
      const Color(0xFFBA84FA), // Lilac / Lavender
      const Color(0xFFFF8B88), // Coral / Salmon Pink
      const Color(0xFFE28BFA), // Orchid / Bright Lilac
      const Color(0xFF3B1846), // Deep Plum / Eggplant (white text)
      const Color(0xFFBAC6FB), // Periwinkle / Powder Blue
      const Color(0xFF86EFAC), // Soft Mint Sage
    ];

    if (_isPrelims) {
      return [
        CategoryScore(
          label: 'GS-1',
          score: _prelimsScores['GS-1'] ?? 0,
          maxScore: _prelimsMax['GS-1'] ?? 200,
          barColor: barPalette[0],
        ),
        CategoryScore(
          label: 'CSAT',
          score: _prelimsScores['CSAT'] ?? 0,
          maxScore: _prelimsMax['CSAT'] ?? 200,
          barColor: barPalette[1],
        ),
      ];
    } else {
      return [
        CategoryScore(
          label: 'GS 1',
          score: _mainsScores['GS 1'] ?? 0,
          maxScore: _mainsMax['GS 1'] ?? 250,
          barColor: barPalette[0],
        ),
        CategoryScore(
          label: 'GS 2',
          score: _mainsScores['GS 2'] ?? 0,
          maxScore: _mainsMax['GS 2'] ?? 250,
          barColor: barPalette[1],
        ),
        CategoryScore(
          label: 'GS 3',
          score: _mainsScores['GS 3'] ?? 0,
          maxScore: _mainsMax['GS 3'] ?? 250,
          barColor: barPalette[2],
        ),
        CategoryScore(
          label: 'GS 4',
          score: _mainsScores['GS 4'] ?? 0,
          maxScore: _mainsMax['GS 4'] ?? 250,
          barColor: barPalette[3],
        ),
        CategoryScore(
          label: 'Essay',
          score: _mainsScores['Essay'] ?? 0,
          maxScore: _mainsMax['Essay'] ?? 250,
          barColor: barPalette[4],
        ),
        CategoryScore(
          label: 'Optional',
          score: _mainsScores['Optional'] ?? 0,
          maxScore: _mainsMax['Optional'] ?? 500,
          barColor: barPalette[5],
        ),
      ];
    }
  }

  double _totalObtained(List<CategoryScore> cats) =>
      cats.fold(0.0, (acc, item) => acc + item.score);
  double _totalMax(List<CategoryScore> cats) =>
      cats.fold(0.0, (acc, item) => acc + item.maxScore);

  Future<void> _openAddTestDialog() async {
    ZetaHaptics.medium();
    final cs = Theme.of(context).colorScheme;

    MockTestStage dialogStage = _selectedStage;
    DateTime dialogDate = DateTime.now();

    final testNameCtrl = TextEditingController(
      text: 'Mock FLT #${DateTime.now().day}',
    );
    final outOfCtrl = TextEditingController(
      text: dialogStage == MockTestStage.prelims ? '200' : '250',
    );

    // Initial controllers for all possible categories
    final Map<String, TextEditingController> scoreControllers = {
      'GS-1': TextEditingController(
        text: _prelimsScores['GS-1']?.toStringAsFixed(1) ?? '100',
      ),
      'CSAT': TextEditingController(
        text: _prelimsScores['CSAT']?.toStringAsFixed(1) ?? '80',
      ),
      'GS 1': TextEditingController(
        text: _mainsScores['GS 1']?.toStringAsFixed(1) ?? '100',
      ),
      'GS 2': TextEditingController(
        text: _mainsScores['GS 2']?.toStringAsFixed(1) ?? '105',
      ),
      'GS 3': TextEditingController(
        text: _mainsScores['GS 3']?.toStringAsFixed(1) ?? '95',
      ),
      'GS 4': TextEditingController(
        text: _mainsScores['GS 4']?.toStringAsFixed(1) ?? '110',
      ),
      'Essay': TextEditingController(
        text: _mainsScores['Essay']?.toStringAsFixed(1) ?? '125',
      ),
      'Optional': TextEditingController(
        text: _mainsScores['Optional']?.toStringAsFixed(1) ?? '270',
      ),
    };

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isPrelimsModal = dialogStage == MockTestStage.prelims;
            final activeKeys = isPrelimsModal
                ? ['GS-1', 'CSAT']
                : ['GS 1', 'GS 2', 'GS 3', 'GS 4', 'Essay', 'Optional'];

            return AlertDialog(
              backgroundColor: cs.surfaceContainerHigh,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              title: Text(
                'Log Mock Test',
                style: TextStyle(
                  color: cs.onSurface,
                  fontFamily: 'GoogleSansFlex',
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stage Selector Pill
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: MockTestStage.values.map((stage) {
                          final isSel = dialogStage == stage;
                          final label = stage == MockTestStage.prelims
                              ? 'Prelims'
                              : 'Mains';
                          final accentColor = stage == MockTestStage.prelims
                              ? cs.tertiary
                              : cs.primary;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ZetaHaptics.selection();
                                setDialogState(() {
                                  dialogStage = stage;
                                  outOfCtrl.text =
                                      stage == MockTestStage.prelims
                                      ? '200'
                                      : '250';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? accentColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.zero,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSel
                                        ? cs.onTertiary
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Test Name Input
                    TextField(
                      controller: testNameCtrl,
                      style: TextStyle(color: cs.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Mock Test Series / Name',
                        labelStyle: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date Picker Tile & Standard "Out Of" Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dialogDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => dialogDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainer,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${dialogDate.day}/${dialogDate.month}/${dialogDate.year}',
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontFamily: 'RobotoMono',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: outOfCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(color: cs.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Std Out Of',
                              labelStyle: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainer,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'CATEGORY SCORES',
                      style: TextStyle(
                        fontFamily: 'nothingdot',
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dynamic category input grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeKeys.map((key) {
                        return SizedBox(
                          width: 125,
                          child: TextField(
                            controller: scoreControllers[key],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(color: cs.onSurface, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: key,
                              labelStyle: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainer,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isPrelimsModal ? cs.tertiary : cs.primary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {
                    final defaultMax =
                        double.tryParse(outOfCtrl.text.trim()) ??
                        (isPrelimsModal ? 200.0 : 250.0);
                    final Map<String, double> parsedScores = {};

                    for (final key in activeKeys) {
                      final val =
                          double.tryParse(scoreControllers[key]!.text.trim()) ??
                          0.0;
                      parsedScores[key] = val;
                    }

                    setState(() {
                      _selectedStage = dialogStage;
                      if (isPrelimsModal) {
                        _prelimsScores.addAll(parsedScores);
                        _prelimsMax['GS-1'] = defaultMax;
                        _prelimsMax['CSAT'] = defaultMax;
                      } else {
                        _mainsScores.addAll(parsedScores);
                        for (final key in [
                          'GS 1',
                          'GS 2',
                          'GS 3',
                          'GS 4',
                          'Essay',
                        ]) {
                          _mainsMax[key] = defaultMax;
                        }
                        _mainsMax['Optional'] =
                            defaultMax * 2; // Optional is 2 papers (500)
                      }
                    });

                    widget.onSaveTest?.call(
                      MockEntryRecord(
                        stage: dialogStage,
                        testName: testNameCtrl.text.trim(),
                        date: dialogDate,
                        categoryScores: parsedScores,
                        totalOutOf: defaultMax,
                      ),
                    );

                    Navigator.of(dialogCtx).pop();
                  },
                  child: Text(
                    'Log Test',
                    style: TextStyle(
                      color: isPrelimsModal ? cs.onTertiary : cs.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    testNameCtrl.dispose();
    outOfCtrl.dispose();
    for (final c in scoreControllers.values) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);

    // Resolve colorScheme dynamically based on the active dark/light mode
    final themeData = isDark
        ? AppTheme.dark(
            themeProvider.seedColor,
            themeProvider.variant,
            themeProvider.cornerStyle,
            themeProvider.highContrast,
            themeProvider.compactDensity,
            themeProvider.animations,
          )
        : AppTheme.light(
            themeProvider.seedColor,
            themeProvider.variant,
            themeProvider.cornerStyle,
            themeProvider.highContrast,
            themeProvider.compactDensity,
            themeProvider.animations,
          );

    final colorScheme = themeData.colorScheme;

    final themeColor = _isPrelims ? colorScheme.tertiary : colorScheme.primary;
    final categories = _activeCategories();
    final totalObt = _totalObtained(categories);
    final totalMx = _totalMax(categories);
    final isCompact = MediaQuery.sizeOf(context).width < 400;

    final rowHeight = _isPrelims ? 52.0 : 44.0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header: Title + Stage Switcher + Add Button ───
            Row(
              children: [
                Text(
                  'TEST',
                  style: TextStyle(
                    fontFamily: 'Nothingdot',
                    fontSize: 27,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),

                // Stage Toggle: M3EButtonGroup for Prelims / Mains
                M3EButtonGroup(
                  type: M3EButtonGroupType.connected,
                  size: M3EButtonSize.xs,
                  style: M3EButtonStyle.filled,
                  selectedIndex: _isPrelims ? 0 : 1,
                  onSelectedIndexChanged: (index) {
                    if (index == null) return;
                    ZetaHaptics.selection();
                    setState(() {
                      _selectedStage = index == 0
                          ? MockTestStage.prelims
                          : MockTestStage.mains;
                    });
                  },
                  actions: const [
                    M3EButtonGroupAction(label: Text('Prelims')),
                    M3EButtonGroupAction(label: Text('Mains')),
                  ],
                ),

                // Add Test Button: Wide variant M3EIconButton filled
                M3EIconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  variant: M3EIconButtonVariant.filled,
                  width: M3EIconButtonWidth.wide,
                  size: M3EIconButtonSize.xs,
                  tooltip: 'Add Test',
                  onPressed: _openAddTestDialog,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ─── Score Readout ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totalObt.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'headline',
                    letterSpacing: 2,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    height: 1.0,
                  ),
                ),
                Text(
                  ' / ${totalMx.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${((totalObt / totalMx) * 100).toStringAsFixed(1)}% OVERALL',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      color: themeColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ─── Expressive Segmented Arrow Chart ───
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Chart Stack with Dotted Boundary Lines
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Right vertical dotted line (100% mark)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: SizedBox(
                            width: 2,
                            child: CustomPaint(
                              painter: _DottedVerticalLinePainter(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // The 3-segment Arrow Bars
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: categories.map((cat) {
                            return _buildBarRow(
                              context: context,
                              cat: cat,
                              totalWidth: totalWidth,
                              isCompact: isCompact,
                              rowHeight: rowHeight,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single segmented arrow row consisting of:
  /// [ Main Bar (with label) ] + [ Percentage Pill ] + [ Arrow Tip > ]
  Widget _buildBarRow({
    required BuildContext context,
    required CategoryScore cat,
    required double totalWidth,
    required bool isCompact,
    required double rowHeight,
  }) {
    final percent = (cat.ratio * 100).round();

    const gap = 4.0;
    final arrowW = isCompact ? 16.0 : 20.0;
    final pillW = isCompact ? 66.0 : 78.0;
    final minBarW = isCompact ? 46.0 : 56.0;
    final minComboW = minBarW + gap + pillW + gap + arrowW;

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode(context);

    // Resolve colorScheme dynamically based on the active dark/light mode
    final themeData = isDark
        ? AppTheme.dark(
            themeProvider.seedColor,
            themeProvider.variant,
            themeProvider.cornerStyle,
            themeProvider.highContrast,
            themeProvider.compactDensity,
            themeProvider.animations,
          )
        : AppTheme.light(
            themeProvider.seedColor,
            themeProvider.variant,
            themeProvider.cornerStyle,
            themeProvider.highContrast,
            themeProvider.compactDensity,
            themeProvider.animations,
          );

    final colorScheme = themeData.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: cat.ratio),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, animatedRatio, _) {
          final targetX = (animatedRatio * totalWidth).clamp(0.0, totalWidth);

          final double barW;
          if (targetX >= minComboW) {
            barW = targetX - gap - pillW - gap - arrowW;
          } else {
            barW = minBarW;
          }

          return SizedBox(
            height: rowHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Main Bar (Category label inside on the left) ──
                Container(
                  width: barW + 15,
                  height: rowHeight,
                  decoration: BoxDecoration(
                    color: cat.barColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(rowHeight / 2),
                      bottomRight: Radius.circular(rowHeight / 2),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 14.0, right: 8.0),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    cat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontVariations: const [
                        FontVariation('ROND', 200),
                        FontVariation('wght', 700.0),
                      ],
                      fontSize: 20,
                      color: colorScheme.surfaceContainerLowest.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: gap),

                // ── 2. Percentage Stadium Pill ──
                Container(
                  width: pillW,
                  height: rowHeight,
                  decoration: BoxDecoration(
                    color: cat.barColor,
                    borderRadius: BorderRadius.circular(rowHeight / 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$percent%',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontVariations: const [
                        FontVariation('rond', 100),
                        FontVariation('wght', 900.0),
                      ],
                      fontSize: 24,
                      color: colorScheme.surfaceContainerLowest.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Returns black or white depending on the luminance of the bar color.
  /// Threshold 0.15 ensures that only deep dark colors like Deep Plum (#3B1846)
  /// get white text, while all pastel colors (Lilac, Coral, Orchid, Periwinkle, Mint)
  /// get crisp dark charcoal text, matching the reference image.
}

// ─── Custom Painter for vertical dotted boundary lines (0% & 100%) ───────────

class _DottedVerticalLinePainter extends CustomPainter {
  final Color color;
  static const double dotRadius = 1.1;
  static const double spacing = 3.5;

  const _DottedVerticalLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double y = dotRadius;
    while (y < size.height) {
      y += dotRadius * 2 + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedVerticalLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
