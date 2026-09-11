import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../widgets/segmented_column.dart';

import '../../providers/theme_provider.dart';

class WeatherSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const WeatherSection({super.key, this.onToast});

  @override
  State<WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<WeatherSection> {
  bool _isEditing = false;
  late TextEditingController _cityController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _cityController = TextEditingController(text: themeProvider.cityName);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _handleSetCity(ThemeProvider themeProvider) {
    final nextCity = _cityController.text.trim();
    if (nextCity.isEmpty) return;

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      themeProvider.setCityName(nextCity);
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
      widget.onToast?.call('Location updated to $nextCity');
    });
  }

  void _handleDetectLocation(ThemeProvider themeProvider) {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      themeProvider.setCityName('Bengaluru, IN');
      _cityController.text = 'Bengaluru, IN';
      setState(() => _isLoading = false);
      widget.onToast?.call('Detected location from device GPS: Bengaluru, IN');
    });
  }

  void _handleRefresh() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onToast?.call('Weather telemetry refreshed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEATHER & LOCATION',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Configure local city for live open-source weather telemetry in Celsius (°C).',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            M3EButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              onPressed: _isLoading ? null : _handleRefresh,
            ),
          ],
        ),
        const SizedBox(height: 14),

        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainer,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.amber.shade700,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              themeProvider.cityName,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '24°C',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Partly Cloudy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '•  Humidity 65%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '•  Wind 12 km/h',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      M3EButton.icon(
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('Use my location'),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: _isLoading
                            ? null
                            : () => _handleDetectLocation(themeProvider),
                      ),
                      M3EButton.icon(
                        icon: Icon(
                          _isEditing
                              ? Icons.close_rounded
                              : Icons.edit_location_rounded,
                          size: 16,
                        ),
                        label: Text(_isEditing ? 'Close' : 'Change city'),
                        style: M3EButtonStyle.outlined,
                        size: M3EButtonSize.sm,
                        onPressed: () {
                          setState(() => _isEditing = !_isEditing);
                        },
                      ),
                    ],
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Enter a city name (e.g. London, UK)',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onSubmitted: (_) => _handleSetCity(themeProvider),
                          ),
                        ),
                        const SizedBox(width: 8),
                        M3EButton.icon(
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Search & Set'),
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.sm,
                          onPressed: _isLoading
                              ? null
                              : () => _handleSetCity(themeProvider),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
