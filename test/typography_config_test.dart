import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeta/theme/typography_config.dart';
import 'package:zeta/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TypographyConfig & RoleTypographyConfig Tests', () {
    test('Default role configurations have expected defaults', () {
      expect(RoleTypographyConfig.defaultHeadings.fontId, equals('google-sans-flex'));
      expect(RoleTypographyConfig.defaultHeadings.weight, equals(700));
      expect(RoleTypographyConfig.defaultHeadings.width, equals(100));

      expect(RoleTypographyConfig.defaultTitles.fontId, equals('google-sans-flex'));
      expect(RoleTypographyConfig.defaultTitles.weight, equals(600));

      expect(RoleTypographyConfig.defaultBody.fontId, equals('roboto-flex'));
      expect(RoleTypographyConfig.defaultBody.weight, equals(400));

      expect(RoleTypographyConfig.defaultLabels.fontId, equals('roboto-flex'));
      expect(RoleTypographyConfig.defaultLabels.weight, equals(500));
    });

    test('SupportedFont provides Google Sans Flex with fallback chain', () {
      final font = kSupportedFonts.firstWhere((f) => f.id == 'google-sans-flex');
      expect(font.name, equals('Google Sans Flex'));
      expect(font.fontFallbacks, contains('Google Sans'));
      expect(font.fontFallbacks, contains('Roboto'));
    });

    test('toTextStyle constructs correct FontVariation list', () {
      const config = RoleTypographyConfig(
        fontId: 'google-sans-flex',
        weight: 820,
        width: 125,
        slant: -8.0,
        roundness: 75,
        grade: 110,
      );

      const base = TextStyle(fontSize: 20);
      final style = config.toTextStyle(base);

      expect(style.fontVariations, isNotNull);
      final variations = style.fontVariations!;

      expect(variations.any((v) => v.axis == 'wght' && v.value == 820), isTrue);
      expect(variations.any((v) => v.axis == 'wdth' && v.value == 125), isTrue);
      expect(variations.any((v) => v.axis == 'slnt' && v.value == -8.0), isTrue);
      expect(variations.any((v) => v.axis == 'ROND' && v.value == 75), isTrue);
      expect(variations.any((v) => v.axis == 'GRAD' && v.value == 110), isTrue);
      expect(variations.any((v) => v.axis == 'opsz' && v.value == 20), isTrue);
    });

    test('RoleTypographyConfig serialization round-trip', () {
      const original = RoleTypographyConfig(
        fontId: 'shantell-sans',
        weight: 650,
        width: 110,
        slant: -5.0,
        roundness: 90,
        grade: -50,
      );

      final json = original.toJson();
      final restored = RoleTypographyConfig.fromJson(
        json,
        fallback: RoleTypographyConfig.defaultHeadings,
      );

      expect(restored.fontId, equals('shantell-sans'));
      expect(restored.weight, equals(650));
      expect(restored.width, equals(110));
      expect(restored.slant, equals(-5.0));
      expect(restored.roundness, equals(90));
      expect(restored.grade, equals(-50));
    });

    test('ThemeProvider updates and resets role typography', () {
      final themeProvider = ThemeProvider();

      const custom = RoleTypographyConfig(
        fontId: 'roboto-mono',
        weight: 700,
        width: 100,
        slant: 0,
        roundness: 0,
        grade: 0,
      );

      themeProvider.updateRoleTypography(TypographyRole.headings, custom);
      expect(themeProvider.headingsTypography.fontId, equals('roboto-mono'));

      themeProvider.resetRoleTypography(TypographyRole.headings);
      expect(
        themeProvider.headingsTypography.fontId,
        equals(RoleTypographyConfig.defaultHeadings.fontId),
      );
    });

    test('ThemeProvider applies curated TypographyPreset', () {
      final themeProvider = ThemeProvider();
      final editorialPreset = kTypographyPresets.firstWhere((p) => p.id == 'editorial');

      themeProvider.applyTypographyPreset(editorialPreset);

      expect(themeProvider.headingsTypography.fontId, equals('roboto-serif'));
      expect(themeProvider.labelsTypography.fontId, equals('roboto-mono'));
    });

    test('Bundled fonts resolve to registered asset families with variable axes metadata', () {
      final googleSans = kSupportedFonts.firstWhere((f) => f.id == 'google-sans-flex');
      expect(googleSans.fontFamily, equals('GoogleSansFlex'));
      expect(googleSans.supportsAxis('ROND'), isTrue);
      expect(googleSans.supportsAxis('slnt'), isTrue);
      expect(googleSans.supportsAxis('wdth'), isTrue);
      expect(googleSans.supportsAxis('wght'), isTrue);
      expect(googleSans.supportsAxis('GRAD'), isTrue);

      final robotoFlex = kSupportedFonts.firstWhere((f) => f.id == 'roboto-flex');
      expect(robotoFlex.fontFamily, equals('RobotoFlex'));
      expect(robotoFlex.supportsAxis('ROND'), isFalse);
      expect(robotoFlex.supportsAxis('slnt'), isTrue);
      expect(robotoFlex.supportsAxis('wdth'), isTrue);

      final robotoMono = kSupportedFonts.firstWhere((f) => f.id == 'roboto-mono');
      expect(robotoMono.fontFamily, equals('RobotoMono'));
    });

    test('Roundness variation is applied for Google Sans Flex', () {
      const config = RoleTypographyConfig(
        fontId: 'google-sans-flex',
        weight: 600,
        width: 100,
        slant: -4.0,
        roundness: 80,
        grade: 50,
      );

      final style = config.toTextStyle(const TextStyle(fontSize: 16));
      expect(style.fontFamily, equals('GoogleSansFlex'));
      expect(style.fontVariations, isNotNull);
      final rondVariation = style.fontVariations!.firstWhere((v) => v.axis == 'ROND');
      expect(rondVariation.value, equals(80));

      final slntVariation = style.fontVariations!.firstWhere((v) => v.axis == 'slnt');
      expect(slntVariation.value, equals(-4.0));
    });
  });
}
