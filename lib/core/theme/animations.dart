/// Sanbao animation configurations.
///
/// Derived from the styleguide:
/// - Spring: damping 25, stiffness 300 -- for layout transitions
/// - Ease: cubic-bezier(0.4, 0, 0.2, 1) -- for hover/fade
/// - Stagger: 60ms between list items
/// - Thinking indicator: scale wobble +/-8 degrees over 2s
library;

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Animation constants and curves for the Sanbao design system.
abstract final class SanbaoAnimations {
  // ---- Durations ----

  /// Fast transitions (hover, fade).
  static const Duration durationFast = Duration(milliseconds: 150);

  /// Normal transitions (most UI animations).
  static const Duration durationNormal = Duration(milliseconds: 250);

  /// Slow transitions (panel slides, complex layouts).
  static const Duration durationSlow = Duration(milliseconds: 400);

  /// Stagger delay between sequential list item animations.
  static const Duration staggerDelay = Duration(milliseconds: 60);

  /// Thinking indicator rotation period.
  static const Duration thinkingDuration = Duration(seconds: 2);

  // ---- Curves ----

  /// Spring-like curve for layout transitions.
  /// CSS: `cubic-bezier(0.34, 1.56, 0.64, 1)`
  static const Curve springCurve = Cubic(0.34, 1.56, 0.64, 1);

  /// Smooth ease for hover/fade transitions.
  /// CSS: `cubic-bezier(0.4, 0, 0.2, 1)`
  static const Curve smoothCurve = Cubic(0.4, 0, 0.2, 1);

  /// Deceleration curve for entering elements.
  static const Curve enterCurve = Curves.easeOut;

  /// Acceleration curve for exiting elements.
  static const Curve exitCurve = Curves.easeIn;

  /// Bounce curve for interactive feedback.
  static const Curve bounceCurve = Curves.elasticOut;

  // ---- Spring Simulation ----

  /// Spring description matching the web design system.
  /// damping: 25, stiffness: 300
  static final SpringDescription layoutSpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 25.0,
  );

  /// Gentle spring for subtle movements.
  static final SpringDescription gentleSpring = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 20.0,
  );

  /// Snappy spring for quick interactions.
  static final SpringDescription snappySpring = SpringDescription(
    mass: 1.0,
    stiffness: 400.0,
    damping: 30.0,
  );

  // ---- Scale ----

  /// Button press scale factor.
  /// CSS: `active:scale-[0.98]`
  static const double buttonPressScale = 0.98;

  /// Thinking indicator max rotation in degrees.
  static const double thinkingMaxRotation = 8.0;

  // ---- Message Animation ----

  /// Message appear translation offset.
  /// CSS: `translateY(8px)`
  static const double messageAppearOffset = 8.0;

  /// Slide-in offset for panels.
  /// CSS: `translateX(24px)`
  static const double panelSlideOffset = 24.0;
}
