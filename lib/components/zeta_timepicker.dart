import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/haptics.dart';

/// AM/PM period selector using connected buttongroup outline variant.
class ZetaDayPeriodControl extends StatelessWidget {
  const ZetaDayPeriodControl({
    super.key,
    required this.isPm,
    required this.onChanged,
    this.orientation = Orientation.portrait,
    this.forInput = false,
  });

  final bool isPm;
  final ValueChanged<bool> onChanged;
  final Orientation orientation;
  final bool forInput;

  @override
  Widget build(BuildContext context) {
    final bool landscape = !forInput && orientation == Orientation.landscape;
    final colorScheme = Theme.of(context).colorScheme;

    return M3EButtonGroup(
      type: M3EButtonGroupType.standard,
      style: M3EButtonStyle.tonal,
      density: M3EButtonGroupDensity.compact,
      // size: M3EButtonSize.custom(
      //   height: landscape ? 38 : 40,
      //   width: landscape ? 52 : 52,
      // ),
      direction: landscape ? Axis.horizontal : Axis.vertical,
      selectedIndex: isPm ? 1 : 0,
      onSelectedIndexChanged: (index) {
        if (index == null) return;
        ZetaHaptics.selection();
        onChanged(index == 1);
      },
      actions: [
        M3EButtonGroupAction(
          label: const Text('AM'),
          decoration: M3EButtonDecoration(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.primaryContainer;
              }
              return colorScheme.surfaceContainerLowest;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.onPrimaryContainer;
              }
              return colorScheme.onSurface;
            }),
          ),
        ),
        M3EButtonGroupAction(
          label: const Text('PM'),
          decoration: M3EButtonDecoration(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.primaryContainer;
              }
              return colorScheme.surfaceContainerLowest;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.onPrimaryContainer;
              }
              return colorScheme.onSurface;
            }),
          ),
        ),
      ],
    );
  }
}

/// Paints the clock dial face, hour/minute labels, selector hand, and center knob.
class ZetaTimeDialPainter extends CustomPainter {
  const ZetaTimeDialPainter({
    required this.labels,
    required this.handAngle,
    required this.highlightedLabelIndex,
    required this.showSelectorDot,
    required this.dialColor,
    required this.accentColor,
    required this.onAccentColor,
    required this.labelColor,
    required this.labelStyle,
    required this.textDirection,
    this.dialKnobRadius = 20,
    this.dialCenterRadius = 4,
    this.dialRingInset = 4,
    this.dialHandWidth = 2,
    this.dialLabelFontSize = 15,
  });

  final List<String> labels;
  final double handAngle;
  final int? highlightedLabelIndex;
  final bool showSelectorDot;
  final Color dialColor;
  final Color accentColor;
  final Color onAccentColor;
  final Color labelColor;
  final TextStyle labelStyle;
  final TextDirection textDirection;
  final double dialKnobRadius;
  final double dialCenterRadius;
  final double dialRingInset;
  final double dialHandWidth;
  final double dialLabelFontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;
    final double ringRadius = radius - dialKnobRadius - dialRingInset;

    // Draw dial background circle
    canvas.drawCircle(center, radius, Paint()..color = dialColor);

    final knob = center + Offset.fromDirection(handAngle, ringRadius);
    final accentPaint = Paint()..color = accentColor;

    // Draw selector hand
    canvas.drawLine(
      center,
      knob,
      Paint()
        ..color = accentColor
        ..strokeWidth = dialHandWidth,
    );

    // Draw center dot and selector knob
    canvas.drawCircle(center, dialCenterRadius, accentPaint);
    canvas.drawCircle(knob, dialKnobRadius, accentPaint);

    if (showSelectorDot) {
      canvas.drawCircle(knob, 2.5, Paint()..color = onAccentColor);
    }

    // Paint numbers
    for (var i = 0; i < labels.length; i++) {
      _paintLabel(canvas, center, ringRadius, i);
    }
  }

  void _paintLabel(Canvas canvas, Offset center, double ringRadius, int i) {
    final double step = 2 * math.pi / labels.length;
    final double angle = -math.pi / 2 + (i * step);
    final position = center + Offset.fromDirection(angle, ringRadius);
    final selected = highlightedLabelIndex == i;

    final painter = TextPainter(
      text: TextSpan(
        text: labels[i],
        style: labelStyle.copyWith(
          color: selected ? onAccentColor : labelColor,
          fontSize: dialLabelFontSize,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(ZetaTimeDialPainter oldDelegate) {
    return oldDelegate.handAngle != handAngle ||
        oldDelegate.highlightedLabelIndex != highlightedLabelIndex ||
        oldDelegate.showSelectorDot != showSelectorDot ||
        oldDelegate.labels != labels ||
        oldDelegate.dialColor != dialColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.labelStyle != labelStyle;
  }
}

/// Fully customizable Time Picker Dialog for Zeta.
class ZetaTimePickerDialog extends StatefulWidget {
  const ZetaTimePickerDialog({
    super.key,
    required this.initialTime,
    this.initialEntryMode = M3ETimePickerEntryMode.dial,
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.orientation,
    this.alwaysUse24HourFormat,
  });

  final M3ETime initialTime;
  final M3ETimePickerEntryMode initialEntryMode;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;
  final Orientation? orientation;
  final bool? alwaysUse24HourFormat;

  @override
  State<ZetaTimePickerDialog> createState() => _ZetaTimePickerDialogState();
}

class _ZetaTimePickerDialogState extends State<ZetaTimePickerDialog> {
  late M3ETime _selectedTime;
  late M3ETimePickerEntryMode _entryMode;
  M3ETimePickerMode _activeMode = M3ETimePickerMode.hour;

  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  final FocusNode _hourFocusNode = FocusNode();
  final FocusNode _minuteFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _entryMode = widget.initialEntryMode;
    _hourController = TextEditingController(text: _formatHourText());
    _minuteController = TextEditingController(text: _formatMinuteText());
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  bool _is24Hour(BuildContext context) {
    return widget.alwaysUse24HourFormat ??
        MediaQuery.alwaysUse24HourFormatOf(context);
  }

  String _formatHourText() {
    if (widget.alwaysUse24HourFormat ?? false) {
      return _selectedTime.hour.toString().padLeft(2, '0');
    }
    final h = _selectedTime.hourOf12 == 0 ? 12 : _selectedTime.hourOf12;
    return h.toString().padLeft(2, '0');
  }

  String _formatMinuteText() {
    return _selectedTime.minute.toString().padLeft(2, '0');
  }

  void _syncTextControllers() {
    _hourController.text = _formatHourText();
    _minuteController.text = _formatMinuteText();
  }

  void _handleConfirm() {
    if (_entryMode == M3ETimePickerEntryMode.input) {
      final form = _formKey.currentState;
      if (form == null || !form.validate()) return;
      form.save();
    }
    Navigator.of(context).pop(_selectedTime);
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _toggleEntryMode() {
    setState(() {
      _entryMode = _entryMode == M3ETimePickerEntryMode.dial
          ? M3ETimePickerEntryMode.input
          : M3ETimePickerEntryMode.dial;
      if (_entryMode == M3ETimePickerEntryMode.input) {
        _syncTextControllers();
      }
    });
  }

  void _setPeriod(bool isPm) {
    final use24 = _is24Hour(context);
    if (use24) return;
    final int hour12 = _selectedTime.hourOf12 == 0
        ? 12
        : _selectedTime.hourOf12;
    final int hour24 = isPm
        ? (hour12 == 12 ? 12 : hour12 + 12)
        : (hour12 == 12 ? 0 : hour12);
    setState(() {
      _selectedTime = _selectedTime.copyWith(hour: hour24);
      _syncTextControllers();
    });
  }

  void _setHour(int hour, {bool autoAdvance = false}) {
    final use24 = _is24Hour(context);
    final int hour24;
    if (use24) {
      hour24 = hour % 24;
    } else {
      final h12 = hour == 0 ? 12 : hour;
      hour24 = _selectedTime.isPm
          ? (h12 == 12 ? 12 : h12 + 12)
          : (h12 == 12 ? 0 : h12);
    }
    setState(() {
      _selectedTime = _selectedTime.copyWith(hour: hour24);
      _syncTextControllers();
      if (autoAdvance) {
        _activeMode = M3ETimePickerMode.minute;
      }
    });
  }

  void _setMinute(int minute) {
    setState(() {
      _selectedTime = _selectedTime.copyWith(minute: minute % 60);
      _syncTextControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final isDial = _entryMode == M3ETimePickerEntryMode.dial;
    final use24Hour = _is24Hour(context);
    final help = widget.helpText ?? (isDial ? 'Select time' : 'Enter time');

    // Auto-detect orientation from screen dimensions if not explicitly set
    final size = MediaQuery.sizeOf(context);
    final orientation =
        widget.orientation ??
        (size.width > size.height
            ? Orientation.landscape
            : Orientation.portrait);
    final isLandscape = orientation == Orientation.landscape;

    // Action row is shared between portrait and landscape
    final actionRow = Row(
      children: [
        IconButton(
          icon: Icon(
            isDial ? Icons.keyboard_outlined : Icons.access_time_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 22,
          ),
          tooltip: isDial
              ? localizations.inputTimeModeButtonLabel
              : localizations.dialModeButtonLabel,
          onPressed: _toggleEntryMode,
        ),
        const Spacer(),
        TextButton(
          onPressed: _handleCancel,
          child: Text(
            widget.cancelText ?? localizations.cancelButtonLabel,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _handleConfirm,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            widget.confirmText ?? localizations.okButtonLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    final Widget dialogBody;

    if (isLandscape && isDial) {
      // Landscape dial: side-by-side layout
      dialogBody = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            help,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: time header + AM/PM
              Expanded(
                child: _buildDialTimeHeader(
                  colorScheme,
                  use24Hour,
                  orientation: orientation,
                ),
              ),
              const SizedBox(width: 24),
              // Right side: dial
              _buildDialCanvas(colorScheme, use24Hour),
            ],
          ),
          const SizedBox(height: 20),
          actionRow,
        ],
      );
    } else {
      // Portrait layout (or input mode in any orientation)
      dialogBody = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Help Text
          Text(
            help,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // 2. Time Display / Text Fields + AM/PM Outline ButtonGroup
          if (isDial)
            _buildDialTimeHeader(
              colorScheme,
              use24Hour,
              orientation: orientation,
            )
          else
            _buildInputTimeHeader(colorScheme, use24Hour),

          const SizedBox(height: 24),

          // 3. Main Picker View (Dial or Keypad Inputs)
          if (isDial)
            Center(child: _buildDialCanvas(colorScheme, use24Hour))
          else
            const SizedBox.shrink(),

          if (isDial) const SizedBox(height: 20),

          // 4. Action Row
          actionRow,
        ],
      );
    }

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isLandscape ? 560 : 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: dialogBody,
        ),
      ),
    );
  }

  /// Builds the hour and minute selector boxes with the connected AM/PM button group.
  Widget _buildDialTimeHeader(
    ColorScheme colorScheme,
    bool use24Hour, {
    Orientation orientation = Orientation.portrait,
  }) {
    final hourActive = _activeMode == M3ETimePickerMode.hour;
    final minuteActive = _activeMode == M3ETimePickerMode.minute;
    final isLandscape = orientation == Orientation.landscape;

    final timeRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hour Display Box
        Expanded(
          child: _TimeNumberBox(
            text: _formatHourText(),
            isActive: hourActive,
            onTap: () {
              ZetaHaptics.selection();
              setState(() => _activeMode = M3ETimePickerMode.hour);
            },
          ),
        ),

        // Colon Separator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            ':',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        // Minute Display Box
        Expanded(
          child: _TimeNumberBox(
            text: _formatMinuteText(),
            isActive: minuteActive,
            onTap: () {
              ZetaHaptics.selection();
              setState(() => _activeMode = M3ETimePickerMode.minute);
            },
          ),
        ),

        // AM/PM inline for portrait
        if (!use24Hour && !isLandscape) ...[
          const SizedBox(width: 12),
          ZetaDayPeriodControl(
            isPm: _selectedTime.isPm,
            onChanged: _setPeriod,
            orientation: orientation,
          ),
        ],
      ],
    );

    if (isLandscape && !use24Hour) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          timeRow,
          const SizedBox(height: 12),
          ZetaDayPeriodControl(
            isPm: _selectedTime.isPm,
            onChanged: _setPeriod,
            orientation: orientation,
          ),
        ],
      );
    }

    return timeRow;
  }

  /// Builds the numeric text fields for manual input mode with AM/PM button group.
  Widget _buildInputTimeHeader(ColorScheme colorScheme, bool use24Hour) {
    return Form(
      key: _formKey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hour Input Field
          Expanded(
            child: SizedBox(
              height: 76,
              child: ListenableBuilder(
                listenable: _hourFocusNode,
                builder: (context, _) {
                  final focused = _hourFocusNode.hasFocus;
                  return TextFormField(
                    controller: _hourController,
                    focusNode: _hourFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: focused
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: focused
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) {
                        final advance = val.length == 2;
                        if (use24Hour && parsed >= 0 && parsed <= 23) {
                          _setHour(parsed, autoAdvance: advance);
                        } else if (!use24Hour && parsed >= 1 && parsed <= 12) {
                          _setHour(parsed, autoAdvance: advance);
                        }
                        if (advance) {
                          _minuteFocusNode.requestFocus();
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ':',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Minute Input Field
          Expanded(
            child: SizedBox(
              height: 76,
              child: ListenableBuilder(
                listenable: _minuteFocusNode,
                builder: (context, _) {
                  final focused = _minuteFocusNode.hasFocus;
                  return TextFormField(
                    controller: _minuteController,
                    focusNode: _minuteFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: focused
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: focused
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 0 && parsed <= 59) {
                        _setMinute(parsed);
                      }
                    },
                  );
                },
              ),
            ),
          ),

          if (!use24Hour) ...[
            const SizedBox(width: 12),
            ZetaDayPeriodControl(
              isPm: _selectedTime.isPm,
              forInput: true,
              onChanged: _setPeriod,
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the interactive circular dial.
  Widget _buildDialCanvas(ColorScheme colorScheme, bool use24Hour) {
    const double dialSize = 252;

    return SizedBox.square(
      dimension: dialSize,
      child: GestureDetector(
        onTapDown: (details) {
          ZetaHaptics.selection();
          _handleDialTouch(
            details.localPosition,
            dialSize,
            use24Hour,
            isTap: true,
          );
        },
        onPanStart: (details) {
          _handleDialTouch(
            details.localPosition,
            dialSize,
            use24Hour,
            isTap: false,
          );
        },
        onPanUpdate: (details) {
          _handleDialTouch(
            details.localPosition,
            dialSize,
            use24Hour,
            isTap: false,
          );
        },
        onPanEnd: (_) {
          // Auto-advance to minute after dragging to select an hour
          if (_activeMode == M3ETimePickerMode.hour) {
            setState(() => _activeMode = M3ETimePickerMode.minute);
          }
        },
        child: CustomPaint(
          size: const Size.square(dialSize),
          painter: ZetaTimeDialPainter(
            labels: _getDialLabels(use24Hour),
            handAngle: _getHandAngle(use24Hour),
            highlightedLabelIndex: _getHighlightedLabelIndex(use24Hour),
            showSelectorDot: _shouldShowSelectorDot(),
            dialColor: colorScheme.surfaceContainerLowest,
            accentColor: colorScheme.primary,
            onAccentColor: colorScheme.onPrimary,
            labelColor: colorScheme.onSurface,
            labelStyle:
                Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }

  List<String> _getDialLabels(bool use24Hour) {
    if (_activeMode == M3ETimePickerMode.hour) {
      if (use24Hour) {
        return [
          for (int i = 0; i < 12; i++) (i * 2).toString().padLeft(2, '0'),
        ];
      }
      return ['12', for (int i = 1; i <= 11; i++) '$i'];
    }
    return [for (int i = 0; i < 12; i++) (i * 5).toString().padLeft(2, '0')];
  }

  double _getHandAngle(bool use24Hour) {
    final double fraction;
    if (_activeMode == M3ETimePickerMode.hour) {
      if (use24Hour) {
        fraction = (_selectedTime.hour / 24) % 1;
      } else {
        fraction = (_selectedTime.hourOf12 % 12) / 12;
      }
    } else {
      fraction = (_selectedTime.minute / 60) % 1;
    }
    return -math.pi / 2 + (fraction * 2 * math.pi);
  }

  int? _getHighlightedLabelIndex(bool use24Hour) {
    if (_activeMode == M3ETimePickerMode.hour) {
      if (use24Hour) {
        return (_selectedTime.hour / 2).round() % 12;
      }
      return _selectedTime.hourOf12 % 12;
    }
    final int min = _selectedTime.minute;
    if (min % 5 != 0) return null;
    return (min ~/ 5) % 12;
  }

  bool _shouldShowSelectorDot() {
    return _activeMode == M3ETimePickerMode.minute &&
        _selectedTime.minute % 5 != 0;
  }

  void _handleDialTouch(
    Offset localPos,
    double dialSize,
    bool use24Hour, {
    required bool isTap,
  }) {
    final center = Offset(dialSize / 2, dialSize / 2);
    final delta = localPos - center;
    final angle = math.atan2(delta.dy, delta.dx);
    final fraction = ((angle + math.pi / 2) / (2 * math.pi)) % 1;

    if (_activeMode == M3ETimePickerMode.hour) {
      if (use24Hour) {
        final hour = (fraction * 24).round() % 24;
        _setHour(hour);
      } else {
        final slot = (fraction * 12).round() % 12;
        _setHour(slot == 0 ? 12 : slot);
      }
      if (isTap) {
        // Auto-advance to minute mode after picking an hour
        setState(() => _activeMode = M3ETimePickerMode.minute);
      }
    } else {
      var minute = (fraction * 60).round() % 60;
      if (isTap) {
        minute = ((minute + 2) ~/ 5) * 5 % 60;
      }
      _setMinute(minute);
    }
  }
}

/// Tappable rounded card displaying hour or minute with expressive selection state.
class _TimeNumberBox extends StatelessWidget {
  const _TimeNumberBox({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  final String text;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Static entry point for presenting the Zeta Time Picker.
abstract final class ZetaTimePicker {
  const ZetaTimePicker._();

  /// Shows the Zeta Time Picker dialog.
  ///
  /// Returns a [Future] that resolves to the selected [M3ETime], or null if dismissed.
  static Future<M3ETime?> show(
    BuildContext context, {
    required M3ETime initialTime,
    M3ETimePickerEntryMode initialEntryMode = M3ETimePickerEntryMode.dial,
    String? helpText,
    String? cancelText,
    String? confirmText,
    bool barrierDismissible = true,
    Orientation? orientation,
    bool? alwaysUse24HourFormat,
  }) {
    return showGeneralDialog<M3ETime>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ZetaTimePickerDialog(
          initialTime: initialTime,
          initialEntryMode: initialEntryMode,
          helpText: helpText,
          cancelText: cancelText,
          confirmText: confirmText,
          orientation: orientation,
          alwaysUse24HourFormat: alwaysUse24HourFormat,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}