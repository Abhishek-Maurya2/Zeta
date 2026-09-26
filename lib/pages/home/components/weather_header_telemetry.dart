import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../components/segmented_column.dart';
import '../../../components/weather_icon.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../settings/components/settings_category.dart';
import '../../../utils/haptics.dart';

/// Weather telemetry widget in the Home page calendar header.
/// - Shows current weather condition, temperature, and SVG icon.
/// - On Windows: hovering for 2 seconds opens a rich weather flyout menu (matching profile_avatar_menu).
/// - On Android / mobile: no flyout; tapping opens Weather settings.
class WeatherHeaderTelemetry extends StatefulWidget {
  const WeatherHeaderTelemetry({super.key});

  @override
  State<WeatherHeaderTelemetry> createState() => _WeatherHeaderTelemetryState();
}

class _WeatherHeaderTelemetryState extends State<WeatherHeaderTelemetry>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  final Object _tapRegionGroupId = Object();

  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _hoverTimer;
  Timer? _closeTimer;
  bool _isHoveringText = false;
  bool _isHoveringIcon = false;
  bool _isHoveringFlyout = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _closeTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _openFlyout() {
    _closeTimer?.cancel();
    if (!_isOpen) {
      if (mounted) {
        setState(() {
          _isOpen = true;
        });
      }
      _overlayController.show();
    }
    _animController.forward();
  }

  void _closeFlyout() {
    if (!_isOpen) return;
    _hoverTimer?.cancel();
    _closeTimer?.cancel();
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
    _animController.reverse().then((_) {
      if (mounted && !_isOpen) {
        _overlayController.hide();
      }
    });
  }

  void _startCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (!_isHoveringText && !_isHoveringIcon && !_isHoveringFlyout) {
        _closeFlyout();
      }
    });
  }

  void _handleTextHoverEnter() {
    _isHoveringText = true;
    _closeTimer?.cancel();
    _hoverTimer?.cancel();

    // 3-second hover delay when hovered over text
    if (!_isOpen) {
      _hoverTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _isHoveringText && !_isOpen) {
          _openFlyout();
        }
      });
    }
  }

  void _handleTextHoverExit() {
    _isHoveringText = false;
    _hoverTimer?.cancel();
    _startCloseTimer();
  }

  void _handleIconHoverEnter() {
    _isHoveringIcon = true;
    _closeTimer?.cancel();
    _hoverTimer?.cancel();

    // Instant flyout when hovered over icon (no delay)
    if (!_isOpen) {
      _openFlyout();
    }
  }

  void _handleIconHoverExit() {
    _isHoveringIcon = false;
    _startCloseTimer();
  }

  void _handleFlyoutHoverEnter() {
    _isHoveringFlyout = true;
    _closeTimer?.cancel();
  }

  void _handleFlyoutHoverExit() {
    _isHoveringFlyout = false;
    _startCloseTimer();
  }

  void _navigateToWeatherSettings() {
    _closeFlyout();
    ZetaHaptics.light();
    final navProvider = context.read<NavigationProvider>();
    navProvider.setActivePage(PageId.settings);
    navProvider.setSettingsCategory(SettingsCategory.weather);
  }

  Widget _buildOverlayChild(BuildContext overlayContext) {
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8),
        child: TapRegion(
          groupId: _tapRegionGroupId,
          onTapOutside: (_) => _closeFlyout(),
          child: MouseRegion(
            onEnter: (_) => _handleFlyoutHoverEnter(),
            onExit: (_) => _handleFlyoutHoverExit(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.topLeft,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320,
                    maxWidth: 340,
                  ),
                  child: _WeatherFlyoutCard(
                    onDismiss: _closeFlyout,
                    onOpenSettings: _navigateToWeatherSettings,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    if (!weatherProvider.weatherEnabled ||
        !weatherProvider.showWeatherInHeader) {
      return const SizedBox.shrink();
    }

    final weather = weatherProvider.weatherData;
    final colorScheme = Theme.of(context).colorScheme;
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;

    final tempStr = weather != null
        ? '${weather.temperature.round()}°C'
        : '24°C';
    final conditionStr =
        weather?.displayCondition ??
        (DateTime.now().hour < 6 || DateTime.now().hour >= 19
            ? 'Clear Night'
            : 'Partly Cloudy');
    final effectiveCityName = weather?.cityName ?? weatherProvider.cityName;

    final chipContent = InkWell(
      hoverColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (isWindows && _isOpen) {
          _closeFlyout();
        } else {
          _navigateToWeatherSettings();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Separate Tooltip for Temperature & Condition Text
            Tooltip(
              message: _isOpen ? '' : '$conditionStr • $effectiveCityName',
              child: MouseRegion(
                hitTestBehavior: HitTestBehavior.translucent,
                onEnter: isWindows ? (_) => _handleTextHoverEnter() : null,
                onExit: isWindows ? (_) => _handleTextHoverExit() : null,
                child: Text(
                  tempStr,
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontSize: 26,
                    color: colorScheme.onSurfaceVariant,
                    fontVariations: const [
                      FontVariation('wght', 700),
                      FontVariation('wdth', 180),
                      FontVariation('GRAD', 180),
                      FontVariation('opsz', 220),
                      FontVariation('slnt', -10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // Separate Tooltip for Weather Icon
            Tooltip(
              message: _isOpen
                  ? ''
                  : (isWindows
                        ? 'Weather forecast'
                        : '$conditionStr • $effectiveCityName'),
              child: MouseRegion(
                hitTestBehavior: HitTestBehavior.translucent,
                onEnter: isWindows ? (_) => _handleIconHoverEnter() : null,
                onExit: isWindows ? (_) => _handleIconHoverExit() : null,
                child: WeatherIcon(
                  name:
                      weather?.iconName ??
                      (DateTime.now().hour < 6 || DateTime.now().hour >= 19
                          ? 'partly_cloudy_night'
                          : 'partly_cloudy_day'),
                  size: 28,
                  isDay: weather?.isEffectivelyDay,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // On Android / Mobile: direct chip with click action (no flyout)
    if (!isWindows) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: chipContent,
      );
    }

    // On Windows: wrap with OverlayPortal
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlayChild,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: TapRegion(groupId: _tapRegionGroupId, child: chipContent),
        ),
      ),
    );
  }
}

/// Rich Weather Flyout Card mirroring profile_avatar_menu styling
class _WeatherFlyoutCard extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onOpenSettings;

  const _WeatherFlyoutCard({
    required this.onDismiss,
    required this.onOpenSettings,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final isNow = DateTime.now().hour == hour && DateTime.now().day == time.day;
    if (isNow) return 'Now';

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weatherData;
    final isDark = theme.brightness == Brightness.dark;

    final temp = weather?.temperature.round() ?? 24;
    final condition = weather?.displayCondition ?? 'Clear Sky';
    final city = weather?.cityName ?? weatherProvider.cityName;
    final humidity = weather?.humidity ?? 50;
    final wind = weather?.windSpeed.round() ?? 10;
    final minTemp = weather?.minTempToday?.round();
    final maxTemp = weather?.maxTempToday?.round();
    final hourly = weather?.next24Hours ?? const [];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Card(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header: Weather Icon + Temp + City ──────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    WeatherIcon(
                      name: weather?.iconName ?? 'clear_day',
                      size: 50,
                      isDay: weather?.isEffectivelyDay,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  city,
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$temp°C',
                                style: TextStyle(
                                  fontFamily: 'GoogleSansFlex',
                                  fontSize: 30,
                                  color: colorScheme.onSurfaceVariant,
                                  fontVariations: const [
                                    FontVariation('wght', 900),
                                    FontVariation('wdth', 110),
                                    FontVariation('ROND', 100),
                                    FontVariation('opsz', 220),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  condition,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (minTemp != null && maxTemp != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'H: $maxTemp°  •  L: $minTemp°',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ─── Quick Stats Row (Humidity, Wind) ────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.tertiary.withValues(alpha: 0.1)
                        : colorScheme.tertiaryFixedDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBadge(
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.blue.shade400,
                        label: 'Humidity',
                        value: '$humidity%',
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: colorScheme.tertiary,
                      ),
                      _StatBadge(
                        icon: Icons.air_rounded,
                        iconColor: Colors.teal.shade300,
                        label: 'Wind',
                        value: '$wind km/h',
                      ),
                    ],
                  ),
                ),

                // ─── 24-Hour Forecast Horizontal Strip ───────────────────────
                if (hourly.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '24-Hour Forecast',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: hourly.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final item = hourly[index];
                        final isNow = index == 0;
                        return Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isNow
                                ? colorScheme.primaryContainer.withValues(
                                    alpha: 0.65,
                                  )
                                : isDark
                                ? colorScheme.tertiary.withValues(alpha: 0.1)
                                : colorScheme.tertiaryFixedDim.withValues(
                                    alpha: 0.3,
                                  ),
                            borderRadius: isNow
                                ? BorderRadius.circular(30)
                                : BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTime(item.time),
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: isNow
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isNow
                                      ? colorScheme.primary
                                      : colorScheme.tertiary,
                                ),
                              ),
                              WeatherIcon(
                                name: item.iconName,
                                size: 25,
                                isDay: item.isDay,
                              ),
                              Text(
                                '${item.temperature.round()}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isNow
                                      ? colorScheme.primary
                                      : colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 15),

                // ─── Actions: Refresh & Settings ─────────────────────────────
                M3ESegmentedColumn(
                  decoration: const M3ESegmentedListDecoration(
                    padding: EdgeInsets.all(2),
                    outerRadius: 14.0,
                    innerRadius: 6.0,
                    gap: 2.0,
                  ),
                  color: isDark
                      ? colorScheme.tertiary.withValues(alpha: 0.1)
                      : colorScheme.tertiaryFixedDim.withValues(alpha: 0.3),
                  children: [
                    // 1. Refresh Button
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        leading: weatherProvider.isWeatherLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        title: Text(
                          weatherProvider.isWeatherLoading
                              ? 'Refreshing…'
                              : 'Refresh Weather',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        onTap: weatherProvider.isWeatherLoading
                            ? null
                            : () async {
                                ZetaHaptics.light();
                                await weatherProvider.refreshWeather();
                              },
                      ),
                    ),

                    // 2. Settings Button
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        leading: Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Weather Settings',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        onTap: onOpenSettings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: colorScheme.outline,
              ),
            ),
            Text(
              value,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
