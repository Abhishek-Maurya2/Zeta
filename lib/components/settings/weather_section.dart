import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/weather_icon.dart';

class WeatherSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const WeatherSection({super.key, this.onToast});

  @override
  State<WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<WeatherSection> {
  bool _isEditing = false;
  late TextEditingController _cityController;

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

  Future<void> _handleSetCity(ThemeProvider themeProvider) async {
    final nextCity = _cityController.text.trim();
    if (nextCity.isEmpty) return;

    themeProvider.setCityName(nextCity);
    setState(() => _isEditing = false);
    widget.onToast?.call('Fetching live weather for $nextCity...');
  }

  Future<void> _handleRefresh(ThemeProvider themeProvider) async {
    await themeProvider.refreshWeather();
    widget.onToast?.call(
      'Weather telemetry refreshed for ${themeProvider.cityName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final weather = themeProvider.weatherData;
    final isLoading = themeProvider.isWeatherLoading;

    final tempDisplay = weather != null
        ? '${weather.temperature.round()}°C'
        : '24°C';
    final conditionDisplay = weather?.displayCondition ??
        (DateTime.now().hour < 6 || DateTime.now().hour >= 19
            ? 'Clear Night'
            : 'Partly Cloudy');
    final humidityDisplay = weather != null ? '${weather.humidity}%' : '65%';
    final windDisplay = weather != null
        ? '${weather.windSpeed.round()} km/h'
        : '12 km/h';

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
                    'Live open-source telemetry via Open-Meteo in Celsius (°C).',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            M3EButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              onPressed: isLoading ? null : () => _handleRefresh(themeProvider),
            ),
          ],
        ),
        const SizedBox(height: 14),

        M3ESegmentedColumn(
          decoration: const M3ESegmentedListDecoration(
            padding: EdgeInsets.all(1.0),
          ),
          color: colorScheme.surfaceContainerLowest,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Center(
                                child: WeatherIcon(
                                  name: weather?.iconName ??
                                      (DateTime.now().hour < 6 ||
                                              DateTime.now().hour >= 19
                                          ? 'clear_night'
                                          : 'clear_day'),
                                  isDay: weather?.isEffectivelyDay,
                                  size: 32,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    weather?.cityName ?? themeProvider.cityName,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  tempDisplay,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  conditionDisplay,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '•  Humidity $humidityDisplay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '•  Wind $windDisplay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
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
                        icon: const Icon(
                          Icons.my_location_rounded,
                          size: 16,
                        ),
                        label: const Text('Use my location'),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: isLoading
                            ? null
                            : () async {
                                widget.onToast
                                    ?.call('Detecting device location...');
                                final success =
                                    await themeProvider.detectUserLocation();
                                if (success) {
                                  _cityController.text = themeProvider.cityName;
                                  widget.onToast?.call(
                                    'Location updated to ${themeProvider.cityName}',
                                  );
                                } else {
                                  widget.onToast?.call(
                                    'Could not detect location. Please search manually.',
                                  );
                                }
                              },
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
                              hintText:
                                  'Enter any city (e.g. London, Tokyo, Mumbai)',
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
                        M3EButton(
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.sm,
                          onPressed: () => _handleSetCity(themeProvider),
                          child: const Text('Update'),
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
