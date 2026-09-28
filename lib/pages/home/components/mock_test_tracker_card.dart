import 'package:flutter/material.dart';

import '../../../utils/haptics.dart';
import '../../../theme/motion_tokens.dart';

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

  const MockTestRadarCard({
    super.key,
    this.onSaveTest,
  });

  @override
  State<MockTestRadarCard> createState() => _MockTestRadarCardState();
}

class _MockTestRadarCardState extends State<MockTestRadarCard> {
  MockTestStage _selectedStage = MockTestStage.prelims;

  // ─── Prelims Default / Working State (GS1, CSAT) ─────────────
  final Map<String, double> _prelimsScores = {
    'GS-1': 108.5,
    'CSAT': 84.0,
  };
  final Map<String, double> _prelimsMax = {
    'GS-1': 200.0,
    'CSAT': 200.0,
  };

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

  static const Color _bgCard = Color(0xFF131416);
  static const Color _trackInactive = Color(0xFF1E2125);
  static const Color _accentOrange = Color(0xFFFF5722);
  static const Color _accentCyan = Color(0xFF38BDF8);

  bool get _isPrelims => _selectedStage == MockTestStage.prelims;
  Color get _themeColor => _isPrelims ? _accentOrange : _accentCyan;

  List<CategoryScore> get _activeCategories {
    if (_isPrelims) {
      return [
        CategoryScore(
          label: 'GS-1',
          score: _prelimsScores['GS-1'] ?? 0,
          maxScore: _prelimsMax['GS-1'] ?? 200,
          barColor: const Color(0xFFFF7043),
        ),
        CategoryScore(
          label: 'CSAT',
          score: _prelimsScores['CSAT'] ?? 0,
          maxScore: _prelimsMax['CSAT'] ?? 200,
          barColor: const Color(0xFFFFA726),
        ),
      ];
    } else {
      return [
        CategoryScore(
          label: 'GS 1',
          score: _mainsScores['GS 1'] ?? 0,
          maxScore: _mainsMax['GS 1'] ?? 250,
          barColor: const Color(0xFF38BDF8),
        ),
        CategoryScore(
          label: 'GS 2',
          score: _mainsScores['GS 2'] ?? 0,
          maxScore: _mainsMax['GS 2'] ?? 250,
          barColor: const Color(0xFF60A5FA),
        ),
        CategoryScore(
          label: 'GS 3',
          score: _mainsScores['GS 3'] ?? 0,
          maxScore: _mainsMax['GS 3'] ?? 250,
          barColor: const Color(0xFF818CF8),
        ),
        CategoryScore(
          label: 'GS 4',
          score: _mainsScores['GS 4'] ?? 0,
          maxScore: _mainsMax['GS 4'] ?? 250,
          barColor: const Color(0xFFA78BFA),
        ),
        CategoryScore(
          label: 'Essay',
          score: _mainsScores['Essay'] ?? 0,
          maxScore: _mainsMax['Essay'] ?? 250,
          barColor: const Color(0xFF34D399),
        ),
        CategoryScore(
          label: 'Optional',
          score: _mainsScores['Optional'] ?? 0,
          maxScore: _mainsMax['Optional'] ?? 500,
          barColor: const Color(0xFFF472B6),
        ),
      ];
    }
  }

  double get _totalObtained =>
      _activeCategories.fold(0.0, (acc, item) => acc + item.score);
  double get _totalMax =>
      _activeCategories.fold(0.0, (acc, item) => acc + item.maxScore);

  Future<void> _openAddTestDialog() async {
    ZetaHaptics.medium();

    MockTestStage dialogStage = _selectedStage;
    DateTime dialogDate = DateTime.now();

    final testNameCtrl = TextEditingController(text: 'Mock FLT #${DateTime.now().day}');
    final outOfCtrl = TextEditingController(
      text: dialogStage == MockTestStage.prelims ? '200' : '250',
    );

    // Initial controllers for all possible categories
    final Map<String, TextEditingController> scoreControllers = {
      'GS-1': TextEditingController(text: _prelimsScores['GS-1']?.toStringAsFixed(1) ?? '100'),
      'CSAT': TextEditingController(text: _prelimsScores['CSAT']?.toStringAsFixed(1) ?? '80'),
      'GS 1': TextEditingController(text: _mainsScores['GS 1']?.toStringAsFixed(1) ?? '100'),
      'GS 2': TextEditingController(text: _mainsScores['GS 2']?.toStringAsFixed(1) ?? '105'),
      'GS 3': TextEditingController(text: _mainsScores['GS 3']?.toStringAsFixed(1) ?? '95'),
      'GS 4': TextEditingController(text: _mainsScores['GS 4']?.toStringAsFixed(1) ?? '110'),
      'Essay': TextEditingController(text: _mainsScores['Essay']?.toStringAsFixed(1) ?? '125'),
      'Optional': TextEditingController(text: _mainsScores['Optional']?.toStringAsFixed(1) ?? '270'),
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
              backgroundColor: const Color(0xFF161618),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: const Text(
                'Log Mock Test',
                style: TextStyle(
                  color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: MockTestStage.values.map((stage) {
                          final isSel = dialogStage == stage;
                          final label = stage == MockTestStage.prelims ? 'Prelims' : 'Mains';
                          final color = stage == MockTestStage.prelims ? _accentOrange : _accentCyan;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                ZetaHaptics.selection();
                                setDialogState(() {
                                  dialogStage = stage;
                                  outOfCtrl.text = stage == MockTestStage.prelims ? '200' : '250';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? color : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? const Color(0xFF0C1014) : Colors.white70,
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Mock Test Series / Name',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date Picker Tile & Standard "Out Of" Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${dialogDate.day}/${dialogDate.month}/${dialogDate.year}',
                                      style: const TextStyle(
                                        color: Colors.white,
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Std Out Of',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'CATEGORY SCORES',
                      style: TextStyle(
                        fontFamily: 'nothingdot',
                        fontSize: 11,
                        color: Colors.white54,
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: key,
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isPrelimsModal ? _accentOrange : _accentCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final defaultMax = double.tryParse(outOfCtrl.text.trim()) ?? (isPrelimsModal ? 200.0 : 250.0);
                    final Map<String, double> parsedScores = {};

                    for (final key in activeKeys) {
                      final val = double.tryParse(scoreControllers[key]!.text.trim()) ?? 0.0;
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
                        for (final key in ['GS 1', 'GS 2', 'GS 3', 'GS 4', 'Essay']) {
                          _mainsMax[key] = defaultMax;
                        }
                        _mainsMax['Optional'] = defaultMax * 2; // Optional is 2 papers (500)
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
                  child: const Text('Log Test', style: TextStyle(color: Color(0xFF0F1216), fontWeight: FontWeight.w800)),
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
    const textMuted = Color(0xFF888F96);
    final themeColor = _themeColor;
    final categories = _activeCategories;

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ─── Ambient Glow ─────────────────────────────────────────
          Positioned.fill(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(begin: themeColor, end: themeColor),
              duration: const Duration(milliseconds: 300),
              builder: (context, col, _) {
                final c = col ?? themeColor;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 1.25),
                      radius: 1.15,
                      colors: [
                        c.withValues(alpha: 0.35),
                        c.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Main Content ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row with Title, Stage Switcher, and Add Button
                Row(
                  children: [
                    const Text(
                      'MOCK RADAR',
                      style: TextStyle(
                        fontFamily: 'nothingdot',
                        fontSize: 22,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),

                    // Stage Toggle Button (Prelims vs Mains)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: MockTestStage.values.map((stage) {
                          final isSelected = _selectedStage == stage;
                          final label = stage == MockTestStage.prelims ? 'Prelims' : 'Mains';

                          return GestureDetector(
                            onTap: () {
                              ZetaHaptics.selection();
                              setState(() => _selectedStage = stage);
                            },
                            child: AnimatedContainer(
                              duration: M3MotionDuration.short4,
                              curve: M3MotionEasing.standard,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? themeColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontFamily: 'GoogleSansFlex',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? const Color(0xFF0F1216) : Colors.white60,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Add Test Button
                    Material(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _openAddTestDialog,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.add_rounded, size: 18, color: themeColor),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Aggregated Score Readout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _totalObtained.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'headline',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      ' / ${_totalMax.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 14,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${((_totalObtained / _totalMax) * 100).toStringAsFixed(1)}% ACCURACY',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 11,
                        color: themeColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ─── Horizontal Bars with Labels and Progress Inside ──
                Column(
                  children: categories.map((cat) {
                    final percent = (cat.ratio * 100).round();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fullWidth = constraints.maxWidth;
                          final filledWidth = (fullWidth * cat.ratio).clamp(38.0, fullWidth);

                          return Container(
                            height: 34,
                            width: fullWidth,
                            decoration: BoxDecoration(
                              color: _trackInactive,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Animated Filled Bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  width: filledWidth,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: cat.barColor,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cat.barColor.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),

                                // Label & Progress Inside The Bar
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          cat.label,
                                          style: const TextStyle(
                                            fontFamily: 'GoogleSansFlex',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${cat.score.toStringAsFixed(1)} / ${cat.maxScore.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontFamily: 'RobotoMono',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withValues(alpha: 0.9),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$percent%',
                                              style: const TextStyle(
                                                fontFamily: 'headline',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}