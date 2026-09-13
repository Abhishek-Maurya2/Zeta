import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// The four Material 3 typographic roles in Zeta.
enum TypographyRole {
  headings('Headings & Display', 'Hero displays, section banners, & major headers'),
  titles('Titles & Subheaders', 'Card titles, dialog headers, & app bar brand'),
  body('Body & Content', 'Tasks, notes, paragraphs, & descriptions'),
  labels('Labels & Controls', 'Buttons, chips, badges, & navigation tabs');

  final String label;
  final String description;

  const TypographyRole(this.label, this.description);
}

/// Metadata and font loader helper for supported flex variable fonts.
class SupportedFont {
  final String id;
  final String name;
  final String category;
  final String? sampleText;
  final Set<String> supportedAxes;

  const SupportedFont({
    required this.id,
    required this.name,
    required this.category,
    this.sampleText,
    this.supportedAxes = const {'wght'},
  });

  bool supportsAxis(String axis) => supportedAxes.contains(axis);

  /// Resolves the primary font family string corresponding to the bundled variable fonts.
  String? get fontFamily {
    switch (id) {
      case 'google-sans-flex':
        return 'GoogleSansFlex';
      case 'roboto-flex':
        return 'RobotoFlex';
      case 'roboto-mono':
        return 'RobotoMono';
      case 'roboto-serif':
        return 'RobotoSerif';
      case 'noto-sans':
        return 'NotoSans';
      case 'shantell-sans':
        try {
          return GoogleFonts.shantellSans().fontFamily;
        } catch (_) {
          return 'Shantell Sans';
        }
      case 'system':
      default:
        return null;
    }
  }

  /// Resolves the font family fallback chain.
  List<String>? get fontFallbacks {
    switch (id) {
      case 'google-sans-flex':
        return const ['RobotoFlex', 'Google Sans', 'Roboto', 'sans-serif'];
      case 'roboto-flex':
        return const ['GoogleSansFlex', 'Roboto', 'sans-serif'];
      case 'roboto-mono':
        return const ['monospace'];
      case 'roboto-serif':
        return const ['serif'];
      case 'noto-sans':
        return const ['RobotoFlex', 'sans-serif'];
      case 'shantell-sans':
        return const ['sans-serif'];
      case 'system':
      default:
        return null;
    }
  }
}

/// Supported flex variable fonts in Zeta.
const List<SupportedFont> kSupportedFonts = [
  SupportedFont(
    id: 'google-sans-flex',
    name: 'Google Sans Flex',
    category: 'Material 3 Expressive',
    sampleText: 'Expressive geometry with full variable axes (Roundness, Width, Slant, Weight)',
    supportedAxes: {'wght', 'wdth', 'slnt', 'ROND', 'GRAD', 'opsz'},
  ),
  SupportedFont(
    id: 'roboto-flex',
    name: 'Roboto Flex',
    category: 'Full-Axis Variable',
    sampleText: 'Extensive variable axes from ultra-condensed thin to wide bold',
    supportedAxes: {'wght', 'wdth', 'slnt', 'GRAD', 'opsz'},
  ),
  SupportedFont(
    id: 'roboto-mono',
    name: 'Roboto Mono',
    category: 'Variable Monospace',
    sampleText: '12:45:00 • 85% Tabular & Code Metrics',
    supportedAxes: {'wght'},
  ),
  SupportedFont(
    id: 'roboto-serif',
    name: 'Roboto Serif',
    category: 'Editorial Variable',
    sampleText: 'Refined editorial styling with variable weight, width & grade',
    supportedAxes: {'wght', 'wdth', 'GRAD', 'opsz'},
  ),
  SupportedFont(
    id: 'noto-sans',
    name: 'Noto Sans',
    category: 'Global High-Legibility',
    sampleText: 'Clear humanist curves across languages with variable width & weight',
    supportedAxes: {'wght', 'wdth'},
  ),
  SupportedFont(
    id: 'shantell-sans',
    name: 'Shantell Sans',
    category: 'Soft & Rounded Variable',
    sampleText: 'Organic handwriting curves for playful, warm UI',
    supportedAxes: {'wght'},
  ),
  SupportedFont(
    id: 'system',
    name: 'System Default',
    category: 'Platform Baseline',
    sampleText: 'Clean native system typography',
    supportedAxes: {'wght'},
  ),
];

/// Configuration for a single typography role with fine-tuned variable axes.
class RoleTypographyConfig {
  final String fontId;
  final double weight; // 100..1000
  final double width; // 50..151
  final double slant; // -10..0
  final double roundness; // 0..100
  final double grade; // -200..150
  final double? opticalSize;

  const RoleTypographyConfig({
    required this.fontId,
    required this.weight,
    required this.width,
    required this.slant,
    required this.roundness,
    required this.grade,
    this.opticalSize,
  });

  SupportedFont get supportedFont => kSupportedFonts.firstWhere(
        (f) => f.id == fontId,
        orElse: () => kSupportedFonts.first,
      );

  /// Builds a [TextStyle] applying the font family, weight, and variable font axes.
  TextStyle toTextStyle(TextStyle baseStyle) {
    final font = supportedFont;
    final family = font.fontFamily;
    final fallbacks = font.fontFallbacks;

    // Map weight to standard FontWeight for layout fallbacks
    final clampedWeight = weight.clamp(100.0, 900.0);
    final weightIndex = (clampedWeight / 100).round().clamp(1, 9) - 1;
    final effectiveFontWeight = FontWeight.values[weightIndex];

    // Assemble variable font variations strictly supported by the font
    final variations = <FontVariation>[];
    if (font.id != 'system') {
      if (font.supportsAxis('wght')) {
        variations.add(FontVariation('wght', weight.clamp(1.0, 1000.0)));
      }
      if (font.supportsAxis('wdth')) {
        variations.add(FontVariation('wdth', width.clamp(25.0, 151.0)));
      }
      if (slant != 0) {
        if (font.supportsAxis('slnt')) {
          variations.add(FontVariation('slnt', slant.clamp(-10.0, 0.0)));
        }
      } else if (font.supportsAxis('slnt')) {
        variations.add(const FontVariation('slnt', 0.0));
      }
      if (roundness > 0) {
        if (font.supportsAxis('ROND')) {
          variations.add(FontVariation('ROND', roundness.clamp(0.0, 100.0)));
        }
      } else if (font.supportsAxis('ROND')) {
        variations.add(const FontVariation('ROND', 0.0));
      }
      if (grade != 0) {
        if (font.supportsAxis('GRAD')) {
          variations.add(FontVariation('GRAD', grade.clamp(-200.0, 150.0)));
        }
      } else if (font.supportsAxis('GRAD')) {
        variations.add(const FontVariation('GRAD', 0.0));
      }
      if (font.supportsAxis('opsz')) {
        if (opticalSize != null) {
          variations.add(FontVariation('opsz', opticalSize!));
        } else if (baseStyle.fontSize != null) {
          variations.add(FontVariation('opsz', baseStyle.fontSize!.clamp(6.0, 144.0)));
        }
      }
    }

    return baseStyle.copyWith(
      fontFamily: family,
      fontFamilyFallback: fallbacks,
      fontWeight: effectiveFontWeight,
      fontVariations: variations.isNotEmpty ? variations : null,
    );
  }

  RoleTypographyConfig copyWith({
    String? fontId,
    double? weight,
    double? width,
    double? slant,
    double? roundness,
    double? grade,
    double? opticalSize,
  }) {
    return RoleTypographyConfig(
      fontId: fontId ?? this.fontId,
      weight: weight ?? this.weight,
      width: width ?? this.width,
      slant: slant ?? this.slant,
      roundness: roundness ?? this.roundness,
      grade: grade ?? this.grade,
      opticalSize: opticalSize ?? this.opticalSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontId': fontId,
        'weight': weight,
        'width': width,
        'slant': slant,
        'roundness': roundness,
        'grade': grade,
        if (opticalSize != null) 'opticalSize': opticalSize,
      };

  factory RoleTypographyConfig.fromJson(
    Map<String, dynamic>? json, {
    required RoleTypographyConfig fallback,
  }) {
    if (json == null) return fallback;
    return RoleTypographyConfig(
      fontId: json['fontId'] as String? ?? fallback.fontId,
      weight: (json['weight'] as num?)?.toDouble() ?? fallback.weight,
      width: (json['width'] as num?)?.toDouble() ?? fallback.width,
      slant: (json['slant'] as num?)?.toDouble() ?? fallback.slant,
      roundness: (json['roundness'] as num?)?.toDouble() ?? fallback.roundness,
      grade: (json['grade'] as num?)?.toDouble() ?? fallback.grade,
      opticalSize: (json['opticalSize'] as num?)?.toDouble() ?? fallback.opticalSize,
    );
  }

  static const RoleTypographyConfig defaultHeadings = RoleTypographyConfig(
    fontId: 'google-sans-flex',
    weight: 700,
    width: 100,
    slant: 0,
    roundness: 0,
    grade: 0,
  );

  static const RoleTypographyConfig defaultTitles = RoleTypographyConfig(
    fontId: 'google-sans-flex',
    weight: 600,
    width: 100,
    slant: 0,
    roundness: 0,
    grade: 0,
  );

  static const RoleTypographyConfig defaultBody = RoleTypographyConfig(
    fontId: 'roboto-flex',
    weight: 400,
    width: 100,
    slant: 0,
    roundness: 0,
    grade: 0,
  );

  static const RoleTypographyConfig defaultLabels = RoleTypographyConfig(
    fontId: 'roboto-flex',
    weight: 500,
    width: 100,
    slant: 0,
    roundness: 0,
    grade: 0,
  );
}

/// Curated typography presets for one-tap harmonized styles.
class TypographyPreset {
  final String id;
  final String name;
  final String description;
  final RoleTypographyConfig headings;
  final RoleTypographyConfig titles;
  final RoleTypographyConfig body;
  final RoleTypographyConfig labels;

  const TypographyPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.headings,
    required this.titles,
    required this.body,
    required this.labels,
  });
}

const List<TypographyPreset> kTypographyPresets = [
  TypographyPreset(
    id: 'm3-expressive',
    name: 'Material Expressive',
    description: 'Google Sans Flex headings with balanced Roboto Flex body',
    headings: RoleTypographyConfig(
      fontId: 'google-sans-flex',
      weight: 700,
      width: 105,
      slant: 0,
      roundness: 20,
      grade: 0,
    ),
    titles: RoleTypographyConfig(
      fontId: 'google-sans-flex',
      weight: 600,
      width: 100,
      slant: 0,
      roundness: 10,
      grade: 0,
    ),
    body: RoleTypographyConfig(
      fontId: 'roboto-flex',
      weight: 400,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
    labels: RoleTypographyConfig(
      fontId: 'roboto-flex',
      weight: 500,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
  ),
  TypographyPreset(
    id: 'editorial',
    name: 'Editorial Serif',
    description: 'Refined Roboto Serif headings with clean Roboto Flex content',
    headings: RoleTypographyConfig(
      fontId: 'roboto-serif',
      weight: 700,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 25,
    ),
    titles: RoleTypographyConfig(
      fontId: 'roboto-serif',
      weight: 600,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
    body: RoleTypographyConfig(
      fontId: 'roboto-flex',
      weight: 400,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
    labels: RoleTypographyConfig(
      fontId: 'roboto-mono',
      weight: 500,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
  ),
  TypographyPreset(
    id: 'modern-tech',
    name: 'Modern Tech Mono',
    description: 'Condensed Google Sans with Roboto Mono for code & data precision',
    headings: RoleTypographyConfig(
      fontId: 'google-sans-flex',
      weight: 800,
      width: 95,
      slant: 0,
      roundness: 0,
      grade: 50,
    ),
    titles: RoleTypographyConfig(
      fontId: 'roboto-mono',
      weight: 600,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
    body: RoleTypographyConfig(
      fontId: 'roboto-flex',
      weight: 400,
      width: 98,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
    labels: RoleTypographyConfig(
      fontId: 'roboto-mono',
      weight: 500,
      width: 100,
      slant: 0,
      roundness: 0,
      grade: 0,
    ),
  ),
  TypographyPreset(
    id: 'soft-rounded',
    name: 'Soft & Friendly',
    description: 'Enhanced roundness axis with Shantell Sans & gentle curves',
    headings: RoleTypographyConfig(
      fontId: 'google-sans-flex',
      weight: 700,
      width: 100,
      slant: 0,
      roundness: 80,
      grade: 0,
    ),
    titles: RoleTypographyConfig(
      fontId: 'shantell-sans',
      weight: 600,
      width: 100,
      slant: 0,
      roundness: 100,
      grade: 0,
    ),
    body: RoleTypographyConfig(
      fontId: 'roboto-flex',
      weight: 400,
      width: 100,
      slant: 0,
      roundness: 50,
      grade: 0,
    ),
    labels: RoleTypographyConfig(
      fontId: 'shantell-sans',
      weight: 600,
      width: 100,
      slant: 0,
      roundness: 80,
      grade: 0,
    ),
  ),
];
