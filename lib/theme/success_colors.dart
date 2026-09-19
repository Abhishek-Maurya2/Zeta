import 'package:material_ui/material_ui.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Material 3 Custom Success Color Roles according to official Material 3 specification:
/// https://m3.material.io/styles/color/advanced/define-new-colors
///
/// Defines the complete semantic success color family:
/// - [success] (Tonal 40 light / Tonal 80 dark)
/// - [onSuccess] (Tonal 100 light / Tonal 20 dark)
/// - [successContainer] (Tonal 90 light / Tonal 30 dark)
/// - [onSuccessContainer] (Tonal 10 light / Tonal 90 dark)
/// - [successFixed] (Tonal 90)
/// - [onSuccessFixed] (Tonal 10)
/// - [successFixedDim] (Tonal 80)
/// - [onSuccessFixedVariant] (Tonal 30)
@immutable
class SuccessColors extends ThemeExtension<SuccessColors> {
  const SuccessColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.successFixed,
    required this.onSuccessFixed,
    required this.successFixedDim,
    required this.onSuccessFixedVariant,
  });

  /// Primary color role for success elements (e.g. key actions, active success badges).
  final Color success;

  /// Content/text/icon color on top of [success].
  final Color onSuccess;

  /// Container/background color role for success elements (e.g. cards, hit goal bars).
  final Color successContainer;

  /// Content/text/icon color on top of [successContainer].
  final Color onSuccessContainer;

  /// Fixed tone success color role for elements that maintain contrast across themes.
  final Color successFixed;

  /// Content color on top of [successFixed].
  final Color onSuccessFixed;

  /// Dim fixed tone success color role.
  final Color successFixedDim;

  /// Variant content color on top of fixed success roles.
  final Color onSuccessFixedVariant;

  /// Default M3 Success seed color (Material 3 Forest/Emerald Key Green: #3B693A).
  static const Color defaultSeedColor = Color(0xFF3B693A);

  /// Generates light mode M3 Success colors from [seedColor].
  /// Optional [harmonizeWith] harmonizes the success seed with the app's primary seed color.
  factory SuccessColors.light({
    Color seedColor = defaultSeedColor,
    Color? harmonizeWith,
  }) {
    return _fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      harmonizeWith: harmonizeWith,
    );
  }

  /// Generates dark mode M3 Success colors from [seedColor].
  /// Optional [harmonizeWith] harmonizes the success seed with the app's primary seed color.
  factory SuccessColors.dark({
    Color seedColor = defaultSeedColor,
    Color? harmonizeWith,
  }) {
    return _fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      harmonizeWith: harmonizeWith,
    );
  }

  /// Generates M3 Success colors dynamically from a [ColorScheme].
  factory SuccessColors.fromColorScheme(
    ColorScheme colorScheme, {
    Color seedColor = defaultSeedColor,
    Color? harmonizeWith,
  }) {
    return _fromSeed(
      seedColor: seedColor,
      brightness: colorScheme.brightness,
      harmonizeWith: harmonizeWith,
    );
  }

  static SuccessColors _fromSeed({
    required Color seedColor,
    required Brightness brightness,
    Color? harmonizeWith,
  }) {
    final effectiveSeed = harmonizeWith != null
        ? Color(Blend.harmonize(seedColor.toARGB32(), harmonizeWith.toARGB32()))
        : seedColor;

    final hct = Hct.fromInt(effectiveSeed.toARGB32());
    final palette = TonalPalette.of(hct.hue, hct.chroma);

    final isLight = brightness == Brightness.light;

    return SuccessColors(
      success: Color(palette.get(isLight ? 40 : 80)),
      onSuccess: Color(palette.get(isLight ? 90 : 20)),
      successContainer: Color(palette.get(isLight ? 90 : 30)),
      onSuccessContainer: Color(palette.get(isLight ? 10 : 90)),
      successFixed: Color(palette.get(90)),
      onSuccessFixed: Color(palette.get(10)),
      successFixedDim: Color(palette.get(80)),
      onSuccessFixedVariant: Color(palette.get(30)),
    );
  }

  @override
  SuccessColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? successFixed,
    Color? onSuccessFixed,
    Color? successFixedDim,
    Color? onSuccessFixedVariant,
  }) {
    return SuccessColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      successFixed: successFixed ?? this.successFixed,
      onSuccessFixed: onSuccessFixed ?? this.onSuccessFixed,
      successFixedDim: successFixedDim ?? this.successFixedDim,
      onSuccessFixedVariant: onSuccessFixedVariant ?? this.onSuccessFixedVariant,
    );
  }

  @override
  SuccessColors lerp(ThemeExtension<SuccessColors>? other, double t) {
    if (other is! SuccessColors) return this;
    return SuccessColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      successFixed: Color.lerp(successFixed, other.successFixed, t)!,
      onSuccessFixed: Color.lerp(onSuccessFixed, other.onSuccessFixed, t)!,
      successFixedDim: Color.lerp(successFixedDim, other.successFixedDim, t)!,
      onSuccessFixedVariant: Color.lerp(onSuccessFixedVariant, other.onSuccessFixedVariant, t)!,
    );
  }
}

/// Extensions for direct access to M3 Success color roles on [ColorScheme], [ThemeData], and [BuildContext].
extension SuccessColorsColorSchemeX on ColorScheme {
  /// Resolves M3 [SuccessColors] dynamically for this [ColorScheme].
  SuccessColors get successColors => SuccessColors.fromColorScheme(this);

  /// M3 Success Color Role (Tonal 40 light / Tonal 80 dark)
  Color get success => successColors.success;

  /// M3 On-Success Color Role (Tonal 100 light / Tonal 20 dark)
  Color get onSuccess => successColors.onSuccess;

  /// M3 Success Container Color Role (Tonal 90 light / Tonal 30 dark)
  Color get successContainer => successColors.successContainer;

  /// M3 On-Success Container Color Role (Tonal 10 light / Tonal 90 dark)
  Color get onSuccessContainer => successColors.onSuccessContainer;

  /// M3 Success Fixed Role (Tonal 90)
  Color get successFixed => successColors.successFixed;

  /// M3 On-Success Fixed Role (Tonal 10)
  Color get onSuccessFixed => successColors.onSuccessFixed;

  /// M3 Success Fixed Dim Role (Tonal 80)
  Color get successFixedDim => successColors.successFixedDim;

  /// M3 On-Success Fixed Variant Role (Tonal 30)
  Color get onSuccessFixedVariant => successColors.onSuccessFixedVariant;
}

extension SuccessColorsThemeDataX on ThemeData {
  SuccessColors get successColors =>
      extension<SuccessColors>() ??
      (brightness == Brightness.light ? SuccessColors.light() : SuccessColors.dark());
}

extension SuccessColorsBuildContextX on BuildContext {
  SuccessColors get successColors => Theme.of(this).successColors;
}
