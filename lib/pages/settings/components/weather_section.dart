import 'package:geolocator/geolocator.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../providers/weather_provider.dart';
import '../../../components/weather_icon.dart';
import '../../../utils/app_snackbar.dart';
import '../../../utils/haptics.dart';

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
    final weatherProvider = context.read<WeatherProvider>();
    _cityController = TextEditingController(text: weatherProvider.cityName);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _showSnackbar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    if (actionLabel != null && onAction != null) {
      AppSnackbar.show(
        context,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    } else if (widget.onToast != null) {
      widget.onToast!(message);
    } else {
      AppSnackbar.show(context, message: message);
    }
  }

  Future<void> _handleSetCity(WeatherProvider weatherProvider) async {
    final nextCity = _cityController.text.trim();
    if (nextCity.isEmpty) return;

    ZetaHaptics.light();
    weatherProvider.setCityName(nextCity);
    setState(() => _isEditing = false);
    _showSnackbar('Fetching live weather for $nextCity...');
  }

  void _selectCity(WeatherProvider weatherProvider, String city) {
    ZetaHaptics.light();
    _cityController.text = city;
    weatherProvider.setCityName(city);
    _showSnackbar('Fetching live weather for $city...');
  }

  Future<void> _handleRefresh(WeatherProvider weatherProvider) async {
    ZetaHaptics.light();
    await weatherProvider.refreshWeather();
    if (!mounted) return;
    _showSnackbar(
      'Weather telemetry refreshed for ${weatherProvider.cityName}',
    );
  }

  Future<void> _handleDetectLocation(WeatherProvider weatherProvider) async {
    ZetaHaptics.light();

    // 1. Check if GPS / Location Service is enabled on device
    bool serviceEnabled = false;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = false;
    }

    if (!serviceEnabled) {
      if (!mounted) return;
      final shouldTurnOn = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.location_off_rounded, size: 28),
          title: const Text('Turn on GPS'),
          content: const Text(
            'Location services (GPS) are currently turned off. Please turn on GPS to detect your device location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Turn on GPS'),
            ),
          ],
        ),
      );

      if (shouldTurnOn == true) {
        await Geolocator.openLocationSettings();
      }

      // If user declined or opened settings, do not proceed and show snackbar
      if (!mounted) return;
      _showSnackbar(
        'Please turn on GPS or give permission for GPS.',
        actionLabel: 'Settings',
        onAction: () => Geolocator.openLocationSettings(),
      );
      return;
    }

    // 2. Check and request Location Permission
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {
      permission = LocationPermission.denied;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.location_disabled_rounded, size: 28),
          title: const Text('Permission Required'),
          content: const Text(
            'Location permission is permanently denied. Please grant location permission in app settings to use your device location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await Geolocator.openAppSettings();
      }

      if (!mounted) return;
      _showSnackbar(
        'Please turn on GPS or give permission for GPS.',
        actionLabel: 'Settings',
        onAction: () => Geolocator.openAppSettings(),
      );
      return;
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      if (!mounted) return;
      _showSnackbar(
        'Please turn on GPS or give permission for GPS.',
        actionLabel: 'Settings',
        onAction: () => Geolocator.openAppSettings(),
      );
      return;
    }

    // 3. GPS is turned on AND permission is granted -> strictly use GPS
    _showSnackbar('Detecting device location via GPS...');
    try {
      final success = await weatherProvider.detectDeviceLocationFromGps();
      if (!mounted) return;
      if (success) {
        _cityController.text = weatherProvider.cityName;
        _showSnackbar('Location updated to ${weatherProvider.cityName}');
      } else {
        _showSnackbar('Could not detect GPS location. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      if (e is LocationServiceDisabledException) {
        _showSnackbar(
          'Please turn on GPS or give permission for GPS.',
          actionLabel: 'Settings',
          onAction: () => Geolocator.openLocationSettings(),
        );
      } else if (e is PermissionDeniedException) {
        _showSnackbar(
          'Please turn on GPS or give permission for GPS.',
          actionLabel: 'Settings',
          onAction: () => Geolocator.openAppSettings(),
        );
      } else {
        _showSnackbar('Could not detect GPS location. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isMasterOn = weatherProvider.weatherEnabled;
    final weather = weatherProvider.weatherData;
    final isLoading = weatherProvider.isWeatherLoading;

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
            M3EList(
              outerRadius: 50,
              innerRadius: 50,
              color: isMasterOn
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              itemCount: 1,
              itemBuilder: (context, index) => M3EListItem(
                headline: 'Use weather',
                trailing: M3ESwitch(
                  value: isMasterOn,
                  selectedIcon: const Icon(Icons.wb_sunny_rounded, size: 16),
                  unselectedIcon: const Icon(Icons.cloud_off_rounded, size: 16),
                  onChanged: (val) {
                    ZetaHaptics.light();
                    weatherProvider.setWeatherEnabled(val);
                    widget.onToast?.call(
                      val
                          ? 'Weather telemetry turned on'
                          : 'Weather telemetry turned off',
                    );
                  },
                ),
                onTap: () {
                  ZetaHaptics.light();
                  final newVal = !isMasterOn;
                  weatherProvider.setWeatherEnabled(newVal);
                  widget.onToast?.call(
                    newVal
                        ? 'Weather telemetry turned on'
                        : 'Weather telemetry turned off',
                  );
                },
              ),
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

            M3EList(
              color: colorScheme.surfaceContainerLowest,

              itemCount: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
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
                                          size: 40,
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
                                              weatherProvider.cityName,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isMasterOn
                                                    ? colorScheme.onSurface
                                                    : colorScheme.onSurface
                                                          .withValues(
                                                            alpha: 0.38,
                                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        tempDisplay,
                                        style: TextStyle(
                                          fontFamily: 'GoogleSansFlex',
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: isMasterOn
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurface
                                                    .withValues(alpha: 0.38),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                  );
                }
                return Padding(
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
                            ? () => _handleDetectLocation(weatherProvider)
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
                            ? () => _handleRefresh(weatherProvider)
                            : null,
                      ),
                    ],
                  ),
                );
              },
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

            M3EList(
              color: colorScheme.surfaceContainerLowest,

              itemCount: _isEditing ? 2 : 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
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
                                weather?.cityName ?? weatherProvider.cityName,
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
                  );
                }
                return Padding(
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
                                  hintText:
                                      'Enter city (e.g. London, Tokyo, Mumbai)',
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
                                    _handleSetCity(weatherProvider),
                              ),
                            ),
                            const SizedBox(width: 8),
                            M3EButton(
                              style: M3EButtonStyle.filled,
                              size: M3EButtonSize.sm,
                              onPressed: isMasterOn
                                  ? () => _handleSetCity(weatherProvider)
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
                                weather?.cityName ?? weatherProvider.cityName;
                            final isCurrent = currentCity
                                .toLowerCase()
                                .contains(
                                  city.split(',').first.trim().toLowerCase(),
                                );

                            return InkWell(
                              onTap: isMasterOn
                                  ? () => _selectCity(weatherProvider, city)
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
                                        : colorScheme.outlineVariant.withValues(
                                            alpha: 0.3,
                                          ),
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
                                            : colorScheme.onSurface.withValues(
                                                alpha: isMasterOn ? 1.0 : 0.38,
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
                );
              },
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

            M3EList(
              color: colorScheme.surfaceContainerLowest,

              itemCount: 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSwitchTile(
                    context,
                    title: 'Show weather on Home screen',
                    subtitle: 'Display live temperature and weather badge on the weekly calendar strip',
                    value: weatherProvider.showWeatherInHeader,
                    enabled: isMasterOn,
                    selectedIcon: const Icon(Icons.home_rounded, size: 16),
                    unselectedIcon: const Icon(Icons.home_outlined, size: 16),
                    onChanged: (val) {
                      ZetaHaptics.light();
                      weatherProvider.setShowWeatherInHeader(val);
                      widget.onToast?.call(
                        val
                            ? 'Weather header enabled on Home screen'
                            : 'Weather header hidden on Home screen',
                      );
                    },
                  );
                }
                return Padding(
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
                              'Celsius and (km/h) metric for wind speed ',
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
                );
              },
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
