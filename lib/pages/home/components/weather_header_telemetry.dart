import 'package:zeta/core/core.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../components/weather_icon.dart';
import '../../../components/glass_surface.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../settings/components/settings_category.dart';
import '../../../theme/motion_tokens.dart';
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

  AnimationController? _animController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  Animation<double>? _slideAnimation;
  Animation<double>? _radiusAnimation;

  Timer? _hoverTimer;
  Timer? _closeTimer;
  bool _isHoveringText = false;
  bool _isHoveringIcon = false;
  bool _isHoveringFlyout = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: M3MotionDuration.medium3, // 350ms expressive container transform
      reverseDuration: M3MotionDuration.short4, // 200ms clean exit
    );
    _animController = controller;

    // Emphasized Decelerate for entry, Emphasized Accelerate for reverse
    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: M3MotionEasing.emphasizedDecelerate,
      reverseCurve: M3MotionEasing.emphasizedAccelerate,
    );

    // Scale from pill dimensions into full card
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(curvedAnimation);

    // Container transform vertical slide down into place
    _slideAnimation = Tween<double>(begin: -14.0, end: 0.0).animate(curvedAnimation);

    // Shape morph: transforms from a compact pill (radius 40) into the card (radius 24)
    _radiusAnimation = Tween<double>(begin: 40.0, end: 24.0).animate(curvedAnimation);

    // Fade-in with expressive ease
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
        reverseCurve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );
  }


  @override
  void dispose() {
    _hoverTimer?.cancel();
    _closeTimer?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  void _openFlyout() {
    _closeTimer?.cancel();
    if (_animController == null) {
      _initAnimations();
    }
    if (!_isOpen) {
      if (mounted) {
        setState(() {
          _isOpen = true;
        });
      }
      _overlayController.show();
    }
    _animController?.forward();
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
    _animController?.reverse().then((_) {
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
    final controller = _animController;
    if (controller == null) {
      return const SizedBox.shrink();
    }

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
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final slide = _slideAnimation?.value ?? 0.0;
                final scale = _scaleAnimation?.value ?? 1.0;
                final fade = _fadeAnimation?.value ?? 1.0;
                final radius = _radiusAnimation?.value ?? 24.0;

                return Transform.translate(
                  offset: Offset(0, slide),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: fade.clamp(0.0, 1.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 340,
                  maxWidth: 370,
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
    final colorScheme = context.colorScheme;
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

    return GlassSurface(
      borderRadius: BorderRadius.circular(24),
      blurSigma: 12,
      child: Card(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header: [Temp] ──── [Location, H/L, Wind, Humidity] ──── [Icon + Status] ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Pointed & Stretched Large Temperature
                    Transform.scale(
                      scaleY: 1.25,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        '$temp°',
                        style: TextStyle(
                          fontFamily: 'GoogleSansFlex',
                          fontSize: 94,
                          height: 1.0,
                          color: colorScheme.onSurfaceVariant,
                          fontVariations: const [
                            FontVariation('wght', 600),
                            FontVariation('wdth', 80),
                            FontVariation('ROND', 10),
                            FontVariation('opsz', 144),
                            FontVariation('slnt', 0),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // 2. Middle Column: Location at top, H/L, Humidity, Wind Speed
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Location at top
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  city,
                                  style: textTheme.labelMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (minTemp != null && maxTemp != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 15,
                                  color: Color(0xFFFF7043), // warm coral/orange
                                ),
                                Text(
                                  '$maxTemp°',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 15,
                                  color: Color(0xFF42A5F5), // cool sky blue
                                ),
                                Text(
                                  '$minTemp°',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),

                          // Humidity
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop_rounded,
                                size: 16,
                                color: Colors.blue.shade400,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$humidity%',
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Wind Speed
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.air_rounded,
                                size: 16,
                                color: Colors.teal.shade300,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$wind km/h',
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 3. Right Side: Weather Icon + Status below icon
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WeatherIcon(
                          name: weather?.iconName ?? 'clear_day',
                          size: 56,
                          isDay: weather?.isEffectivelyDay,
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 105),
                          child: Text(
                            condition,
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                                ? colorScheme.primaryContainer
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
                M3EList(
                  color: isDark
                      ? colorScheme.tertiary.withValues(alpha: 0.1)
                      : colorScheme.tertiaryFixedDim.withValues(alpha: 0.3),
                  itemCount: 2,
                  onTap: (index) async {
                    if (index == 0) {
                      if (!weatherProvider.isWeatherLoading) {
                        ZetaHaptics.light();
                        await weatherProvider.refreshWeather();
                      }
                    } else if (index == 1) {
                      onOpenSettings();
                    }
                  },
                  itemBuilder: (context, index) => index == 0
                      ? M3EListItem(
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
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          headline: weatherProvider.isWeatherLoading
                              ? 'Refreshing…'
                              : 'Refresh Weather',
                        )
                      : M3EListItem(
                          leading: Icon(
                            Icons.settings_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          headline: 'Weather Settings',
                        ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

