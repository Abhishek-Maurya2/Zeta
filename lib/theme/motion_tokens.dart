import 'package:flutter/material.dart';

/// Official Material Design 3 Motion Tokens.
/// Reference: https://m3.material.io/styles/motion/overview
abstract final class M3MotionEasing {
  /// Emphasized easing curve (0.2, 0.0, 0.0, 1.0).
  /// Used for expressive transitions between UI states starting and ending on screen.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Emphasized decelerate curve (0.05, 0.7, 0.1, 1.0).
  /// Used for elements entering the screen with expressive energy.
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized accelerate curve (0.3, 0.0, 0.8, 0.15).
  /// Used for elements exiting the screen cleanly.
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Standard baseline easing curve (0.2, 0.0, 0.0, 1.0).
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Standard decelerate curve (0.0, 0.0, 0.2, 1.0).
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Standard accelerate curve (0.4, 0.0, 1.0, 1.0).
  static const Curve standardAccelerate = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Linear curve for opacity dissolves.
  static const Curve linear = Curves.linear;
}

/// Official Material Design 3 Duration Tokens.
abstract final class M3MotionDuration {
  // Short family: micro-interactions, ripples, state changes
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);

  // Medium family: page transitions, dialogs, expanding elements
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);

  // Long family: large transforms, full-screen transitions
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);

  // Extra long family: ambient transitions, splash sequences
  static const Duration extraLong1 = Duration(milliseconds: 700);
  static const Duration extraLong2 = Duration(milliseconds: 800);
  static const Duration extraLong3 = Duration(milliseconds: 900);
  static const Duration extraLong4 = Duration(milliseconds: 1000);
}

/// Official Material Design 3 Expressive Spring Physics parameters.
abstract final class M3MotionSpring {
  /// Expressive spatial motion (pages, sheets, containers).
  static const double spatialStiffness = 380.0;
  static const double spatialDamping = 0.85;

  /// Expressive effects motion (FABs, chips, micro-bounce).
  static const double effectsStiffness = 700.0;
  static const double effectsDamping = 0.70;
}
