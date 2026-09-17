import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../widgets/segmented_column.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/weather_icon.dart';
import '../../utils/haptics.dart';

class WeatherSection extends StatefulWidget {
  final void Function(String message)? onToast;

  const WeatherSection({super.key, this.onToast});

  @override
  State<WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<WeatherSection> {
  bool _isEditing = false;
  late TextEditingController _cityController;

  static const List<String> _popularCities = [
    'London, UK',
    'Tokyo, JP',
    'New York, US',
    'Paris, FR',
    'Mumbai, IN',
    'San Francisco, US',
    'Sydney, AU',
  ];

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

    ZetaHaptics.light();
    themeProvider.setCityName(nextCity);
    setState(() => _isEditing = false);
    widget.onToast?.call('Fetching live weather for $nextCity...');
  }

  void _selectCity(ThemeProvider themeProvider, String city) {
    ZetaHaptics.light();
    _cityController.text = city;
    themeProvider.setCityName(city);
    widget.onToast?.call('Fetching live weather for $city...');
  }

  Future<void> _handleRefresh(ThemeProvider themeProvider) async {
    ZetaHaptics.light();
    await themeProvider.refreshWeather();
    if (!mounted) return;
    widget.onToast?.call(
      'Weather telemetry refreshed for ${themeProvider.cityName}',
    );
  }

  Future<void> _handleDetectLocation(ThemeProvider themeProvider) async {
    ZetaHaptics.light();
    widget.onToast?.call('Detecting device location...');
    final success = await themeProvider.detectUserLocation();
    if (!mounted) return;
    if (success) {
      _cityController.text = themeProvider.cityName;
      widget.onToast?.call('Location updated to ${themeProvider.cityName}');
    } else {
      widget.onToast?.call(
        'Could not detect location. Please search manually.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isMasterOn = themeProvider.weatherEnabled;
    final weather = themeProvider.weatherData;
    final isLoading = themeProvider.isWeatherLoading;

    final tempDisplay = weather != null
        ? '${weather.temperature.round()}°C'
        : '24°C';
    final conditionDisplay =
        weather?.displayCondition ??
        (DateTime.now().hour < 6 || DateTime.now().hour >= 19
            ? 'Clear Night'
            : 'Partly Cloudy');
    final humidityDisplay = weather != null ? '${weather.humidity}%' : '65%';
    final windDisplay = weather != null
        ? '${weather.windSpeed.round()} km/h'
        : '12 km/h';

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. Master Toggle Card (Android M3 Expressive pill) ───────────
            M3ESegmentedColumn(
              decoration: M3ESegmentedListDecoration(
                outerRadius: 50,
                innerRadius: 50,
                color: isMasterOn
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainer,
              ),
              onTap: (_) {
                ZetaHaptics.light();
                final newVal = !isMasterOn;
                themeProvider.setWeatherEnabled(newVal);
                widget.onToast?.call(
                  newVal
                      ? 'Weather telemetry turned on'
                      : 'Weather telemetry turned off',
                );
              },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Use weather',
                          style: textTheme.displaySmall?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isMasterOn
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      M3ESwitch(
                        value: isMasterOn,
                        selectedIcon: const Icon(
                          Icons.wb_sunny_rounded,
                          size: 16,
                        ),
                        unselectedIcon: const Icon(
                          Icons.cloud_off_rounded,
                          size: 16,
                        ),
                        onChanged: (val) {
                          ZetaHaptics.light();
                          themeProvider.setWeatherEnabled(val);
                          widget.onToast?.call(
                            val
                                ? 'Weather telemetry turned on'
                                : 'Weather telemetry turned off',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 2. CURRENT FORECAST & TELEMETRY ─────────────────────────────
            Text(
              'Current Forecast',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Hero Telemetry Showcase
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weather Icon Container (M3 Expressive softBoom / softBloom shape)
                          M3EShapeContainer.bun(
                            width: 73,
                            height: 73,
                            color: isMasterOn
                                ? colorScheme.surfaceContainerHigh
                                : colorScheme.surfaceContainer,
                            child: isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Opacity(
                                      opacity: isMasterOn ? 1.0 : 0.38,
                                      child: WeatherIcon(
                                        name:
                                            weather?.iconName ??
                                            (DateTime.now().hour < 6 ||
                                                    DateTime.now().hour >= 19
                                                ? 'clear_night'
                                                : 'clear_day'),
                                        isDay: weather?.isEffectivelyDay,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),

                          // City Name, Live Badge, and Conditions
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 16,
                                      color: isMasterOn
                                          ? colorScheme.primary
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.38,
                                            ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        weather?.cityName ??
                                            themeProvider.cityName,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isMasterOn
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurface
                                                    .withValues(alpha: 0.38),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !isMasterOn
                                            ? colorScheme
                                                  .surfaceContainerHighest
                                            : (isLoading
                                                  ? colorScheme
                                                        .secondaryContainer
                                                  : colorScheme
                                                        .primaryContainer),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        !isMasterOn
                                            ? 'PAUSED'
                                            : (isLoading
                                                  ? 'UPDATING...'
                                                  : 'LIVE'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                          color: !isMasterOn
                                              ? colorScheme.onSurfaceVariant
                                                    .withValues(alpha: 0.6)
                                              : (isLoading
                                                    ? colorScheme
                                                          .onSecondaryContainer
                                                    : colorScheme
                                                          .onPrimaryContainer),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Large Temperature & Condition
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      tempDisplay,
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: isMasterOn
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurface.withValues(
                                                alpha: 0.38,
                                              ),
                                        fontVariations: const [
                                          FontVariation('wght', 800),
                                          FontVariation('wdth', 110),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              conditionDisplay,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isMasterOn
                                                        ? colorScheme
                                                              .onSurfaceVariant
                                                        : colorScheme
                                                              .onSurfaceVariant
                                                              .withValues(
                                                                alpha: 0.38,
                                                              ),
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
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

                      // Stat Chips Row: Humidity, Wind, Daylight
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildStatChip(
                            context,
                            icon: Icons.water_drop_rounded,
                            label: 'Humidity $humidityDisplay',
                            enabled: isMasterOn,
                          ),
                          _buildStatChip(
                            context,
                            icon: Icons.air_rounded,
                            label: 'Wind $windDisplay',
                            enabled: isMasterOn,
                          ),
                          _buildStatChip(
                            context,
                            icon: (weather?.isEffectivelyDay ?? true)
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_round,
                            label: (weather?.isEffectivelyDay ?? true)
                                ? 'Daytime'
                                : 'Nighttime',
                            enabled: isMasterOn,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions: Use location & Refresh
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      M3EButton.icon(
                        icon: const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('Use device location'),
                        style: M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        onPressed: isMasterOn && !isLoading
                            ? () => _handleDetectLocation(themeProvider)
                            : null,
                      ),
                      M3EButton.icon(
                        icon: isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh forecast'),
                        style: M3EButtonStyle.outlined,
                        size: M3EButtonSize.sm,
                        onPressed: isMasterOn && !isLoading
                            ? () => _handleRefresh(themeProvider)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 3. LOCATION & SEARCH ────────────────────────────────────────
            Text(
              'Location & Search',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Selected Location Tile + Change Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pin_drop_rounded,
                        size: 22,
                        color: isMasterOn
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected location',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isMasterOn
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.38,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              weather?.cityName ?? themeProvider.cityName,
                              style: textTheme.bodySmall?.copyWith(
                                color: isMasterOn
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.38,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      M3EButton.icon(
                        icon: Icon(
                          _isEditing
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          size: 15,
                        ),
                        label: Text(_isEditing ? 'Close' : 'Search'),
                        style: _isEditing
                            ? M3EButtonStyle.tonal
                            : M3EButtonStyle.outlined,
                        size: M3EButtonSize.xs,
                        onPressed: isMasterOn
                            ? () {
                                ZetaHaptics.light();
                                setState(() => _isEditing = !_isEditing);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),

                // Expandable Search Field & Quick Picks
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cityController,
                                  enabled: isMasterOn,
                                  autofocus: true,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isMasterOn
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.38,
                                          ),
                                  ),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                    ),
                                    hintText: 'Enter city (e.g. London, Tokyo, Mumbai)',
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                    suffixIcon: _cityController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              _cityController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    isDense: true,
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHigh
                                        .withValues(alpha: 0.5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) =>
                                      _handleSetCity(themeProvider),
                                ),
                              ),
                              const SizedBox(width: 8),
                              M3EButton(
                                style: M3EButtonStyle.filled,
                                size: M3EButtonSize.sm,
                                onPressed: isMasterOn
                                    ? () => _handleSetCity(themeProvider)
                                    : null,
                                child: const Text('Update'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Quick Pick Chips
                          Text(
                            'Popular cities',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularCities.map((city) {
                              final currentCity =
                                  weather?.cityName ?? themeProvider.cityName;
                              final isCurrent = currentCity
                                  .toLowerCase()
                                  .contains(
                                    city.split(',').first.trim().toLowerCase(),
                                  );

                              return InkWell(
                                onTap: isMasterOn
                                    ? () => _selectCity(themeProvider, city)
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surfaceContainerHigh
                                              .withValues(
                                                alpha: isMasterOn ? 0.8 : 0.3,
                                              ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCurrent
                                          ? colorScheme.primary.withValues(
                                              alpha: 0.4,
                                            )
                                          : colorScheme.outlineVariant
                                                .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isCurrent
                                            ? Icons.check_circle_rounded
                                            : Icons.location_city_rounded,
                                        size: 14,
                                        color: isCurrent
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant
                                                  .withValues(
                                                    alpha: isMasterOn
                                                        ? 1.0
                                                        : 0.38,
                                                  ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isCurrent
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurface
                                                    .withValues(
                                                      alpha: isMasterOn
                                                          ? 1.0
                                                          : 0.38,
                                                    ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 4. DISPLAY & ATMOSPHERE ─────────────────────────────────────
            Text(
              'Display & Atmosphere',
              style: textTheme.labelMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            M3ESegmentedColumn(
              decoration: const M3ESegmentedListDecoration(
                padding: EdgeInsets.all(1.0),
                outerRadius: 28.0,
                innerRadius: 6.0,
                gap: 3.0,
              ),
              color: colorScheme.surfaceContainerLowest,
              children: [
                // Show weather on Home screen
                _buildSwitchTile(
                  context,
                  title: 'Show weather on Home screen',
                  subtitle: 'Display live temperature and weather badge on the weekly calendar strip',
                  value: themeProvider.showWeatherInHeader,
                  enabled: isMasterOn,
                  selectedIcon: const Icon(Icons.home_rounded, size: 16),
                  unselectedIcon: const Icon(Icons.home_outlined, size: 16),
                  onChanged: (val) {
                    ZetaHaptics.light();
                    themeProvider.setShowWeatherInHeader(val);
                    widget.onToast?.call(
                      val
                          ? 'Weather header enabled on Home screen'
                          : 'Weather header hidden on Home screen',
                    );
                  },
                ),

                // Temperature measurement scale info tile
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Measurement units',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isMasterOn
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.38,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Celsius (°C) temperature and metric wind speed (km/h)',
                              style: textTheme.bodySmall?.copyWith(
                                color: isMasterOn
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.38,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: isMasterOn ? 1.0 : 0.38,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '°C Metric',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isMasterOn
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSecondaryContainer.withValues(
                                    alpha: 0.38,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 5. Explanatory Footer with Info Icon ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'When weather is active, Zeta uses real-time meteorological forecasts from Open-Meteo to inform your dashboard, adaptive daytime/nighttime ambient lighting, and schedule planning. No GPS tracking data is ever stored on external servers.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(
          alpha: enabled ? 0.7 : 0.25,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: enabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    Widget? selectedIcon,
    Widget? unselectedIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: enabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          M3ESwitch(
            value: value,
            selectedIcon: selectedIcon,
            unselectedIcon: unselectedIcon,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
