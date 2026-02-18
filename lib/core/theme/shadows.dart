/// Sanbao shadow definitions.
///
/// Blue-tinted shadows matching the web design system.
/// Shadow base: rgba(26, 33, 56, alpha) for general elements,
/// rgba(79, 110, 247, alpha) for accent/input focus.
library;

import 'package:flutter/material.dart';

/// Shadow presets for the Sanbao design system.
abstract final class SanbaoShadows {
  /// Barely visible shadow for subtle depth on normal elements.
  /// CSS: `0 1px 2px rgba(26, 33, 56, 0.04)`
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A1A2138),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Card-level shadow for moderate elevation.
  /// CSS: `0 4px 12px rgba(26, 33, 56, 0.06)`
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F1A2138),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Modal/popup shadow for high elevation.
  /// CSS: `0 8px 32px rgba(26, 33, 56, 0.08)`
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x141A2138),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  /// Extra large shadow for floating elements.
  /// CSS: `0 16px 48px rgba(26, 33, 56, 0.10)`
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1A1A2138),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  /// Input field shadow (unfocused).
  /// CSS: `0 4px 24px rgba(79, 110, 247, 0.08)`
  static const List<BoxShadow> input = [
    BoxShadow(
      color: Color(0x144F6EF7),
      blurRadius: 24,
      offset: Offset(0, 4),
    ),
  ];

  /// Input field shadow (focused) -- blue glow.
  /// CSS: `0 4px 32px rgba(79, 110, 247, 0.15)`
  static const List<BoxShadow> inputFocus = [
    BoxShadow(
      color: Color(0x264F6EF7),
      blurRadius: 32,
      offset: Offset(0, 4),
    ),
  ];

  /// No shadow.
  static const List<BoxShadow> none = [];
}
