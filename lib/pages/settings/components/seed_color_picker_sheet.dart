import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../components/glass_button.dart';
import '../../../components/glass_sheet.dart';
import '../../../providers/theme_provider.dart';

class SeedColorPickerSheet extends StatefulWidget {
  final ThemeProvider themeProvider;
  final void Function(String message)? onToast;

  const SeedColorPickerSheet({
    super.key,
    required this.themeProvider,
    this.onToast,
  });

  static Future<void> show(
    BuildContext context, {
    required ThemeProvider themeProvider,
    void Function(String message)? onToast,
  }) async {
    await showGlassSheet<void>(
      context: context,
      maxHeightFactor: 0.82,
      maxWidth: 580,
      builder: (_) => SeedColorPickerSheet(
        themeProvider: themeProvider,
        onToast: onToast,
      ),
    );
  }

  @override
  State<SeedColorPickerSheet> createState() => _SeedColorPickerSheetState();
}

class _SeedColorPickerSheetState extends State<SeedColorPickerSheet> {
  late HSVColor _mixerColor;
  bool _showMixer = false;

  @override
  void initState() {
    super.initState();
    _mixerColor = HSVColor.fromColor(widget.themeProvider.seedColor);
  }

  Color get _mixedColor => _mixerColor.toColor();

  String _hex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  bool get _currentColorIsPreset => kSeedPresets.any(
    (preset) =>
        preset.color.toARGB32() == widget.themeProvider.seedColor.toARGB32(),
  );

  void _selectPreset(SeedPreset preset) {
    widget.themeProvider.setSeedColor(preset.color);
    Navigator.of(context).pop();
    widget.onToast?.call('Applied ${preset.name} (${preset.hex})');
  }

  void _applyMixedColor() {
    final color = _mixedColor;
    final hex = _hex(color);
    widget.themeProvider.setSeedColor(color);
    Navigator.of(context).pop();
    widget.onToast?.call('Applied Custom Palette ($hex)');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _showMixer ? Icons.tune_rounded : Icons.color_lens_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showMixer ? 'Color Mixer' : 'Palette Seed Presets',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _showMixer
                          ? 'Mix hue, saturation, and brightness'
                          : 'Choose a seed for your app palette',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              GlassButton.icon(
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurface,
                ),
                iconButtonWidth: M3EIconButtonWidth.wide,
                iconButtonVariant: M3EIconButtonVariant.standard,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        Flexible(
          child: _showMixer
              ? _buildMixer(context)
              : _buildPresetGrid(context),
        ),
      ],
    );
  }

  Widget _buildPresetGrid(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: kSeedPresets.length + 1,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 142,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildColorMixerTile(
            textTheme: textTheme,
            selected: !_currentColorIsPreset,
          );
        }

        final preset = kSeedPresets[index - 1];
        final isSelected = widget.themeProvider.seedColor.toARGB32() ==
            preset.color.toARGB32();
        final radius = BorderRadius.circular(22);

        return Material(
          color: preset.color,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () => _selectPreset(preset),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : const SizedBox(height: 22),
                  ),
                  const Spacer(),
                  Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.hex,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorMixerTile({
    required TextTheme textTheme,
    required bool selected,
  }) {
    const radius = BorderRadius.all(Radius.circular(22));
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          setState(() {
            _mixerColor = HSVColor.fromColor(widget.themeProvider.seedColor);
            _showMixer = true;
          });
        },
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
                Color(0xFF14B8A6),
                Color(0xFFF59E0B),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: Colors.white),
                    const Spacer(),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Color Mixer',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Create a custom seed',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMixer(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _mixedColor;
    final foreground = color.computeLuminance() > 0.45
        ? Colors.black
        : Colors.white;

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 96,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                  'Custom seed',
                  style: textTheme.titleSmall?.copyWith(
                    color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                  _hex(color),
                  style: textTheme.labelSmall?.copyWith(
                    color: foreground,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMixerSlider(
              context,
              title: 'Hue',
              valueLabel: '${_mixerColor.hue.round()}°',
              value: _mixerColor.hue,
              min: 0,
              max: 360,
              divisions: 360,
              onChanged: (value) => setState(
                () => _mixerColor = _mixerColor.withHue(value),
              ),
            ),
            _buildMixerSlider(
              context,
              title: 'Saturation',
              valueLabel: '${(_mixerColor.saturation * 100).round()}%',
              value: _mixerColor.saturation,
              min: 0,
              max: 1,
              divisions: 100,
              onChanged: (value) => setState(
                () => _mixerColor = _mixerColor.withSaturation(value),
              ),
            ),
            _buildMixerSlider(
              context,
              title: 'Brightness',
              valueLabel: '${(_mixerColor.value * 100).round()}%',
              value: _mixerColor.value,
              min: 0,
              max: 1,
              divisions: 100,
              onChanged: (value) => setState(
                () => _mixerColor = _mixerColor.withValue(value),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    onPressed: () => setState(() => _showMixer = false),
                    child: const Text('Presets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    isPrimary: true,
                    onPressed: _applyMixedColor,
                    child: const Text('Apply Color'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixerSlider(
    BuildContext context, {
    required String title,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final color = _mixedColor;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: colorScheme.onSurface.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.28 : 0.18,
            ),
            overlayColor: color.withValues(alpha: 0.14),
          ),
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
