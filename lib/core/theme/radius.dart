/// Sanbao border radius constants.
///
/// Derived from the styleguide:
/// - Small elements: 8px
/// - Buttons, badges: 12px
/// - Cards, modals: 16px
/// - Extra large: 24px
/// - Chat input: 32px
/// - Avatars: full circle
library;

import 'package:flutter/material.dart';

/// Border radius constants matching the Sanbao design system.
abstract final class SanbaoRadius {
  // ---- Raw Values ----

  /// Small elements (code badges, small chips).
  static const double smValue = 8.0;

  /// Buttons, badges, medium elements.
  static const double mdValue = 12.0;

  /// Cards, modals, large containers.
  static const double lgValue = 16.0;

  /// Extra large containers.
  static const double xlValue = 24.0;

  /// Chat input field.
  static const double inputValue = 32.0;

  /// Full circle (avatars).
  static const double fullValue = 9999.0;

  // ---- BorderRadius ----

  /// Small: 8px all corners.
  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));

  /// Medium: 12px all corners.
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));

  /// Large: 16px all corners.
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));

  /// Extra large: 24px all corners.
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));

  /// Chat input: 32px all corners.
  static const BorderRadius input =
      BorderRadius.all(Radius.circular(inputValue));

  /// Full circle.
  static const BorderRadius full =
      BorderRadius.all(Radius.circular(fullValue));

  /// No rounding.
  static const BorderRadius none = BorderRadius.all(Radius.zero);

  // ---- Message Bubble Radii ----

  /// User message bubble: rounded top-right is reduced.
  static const BorderRadius userMessage = BorderRadius.only(
    topLeft: Radius.circular(lgValue),
    topRight: Radius.circular(smValue),
    bottomLeft: Radius.circular(lgValue),
    bottomRight: Radius.circular(lgValue),
  );

  /// Assistant message bubble: rounded top-left is reduced.
  static const BorderRadius assistantMessage = BorderRadius.only(
    topLeft: Radius.circular(smValue),
    topRight: Radius.circular(lgValue),
    bottomLeft: Radius.circular(lgValue),
    bottomRight: Radius.circular(lgValue),
  );

  // ---- Circular Radius ----

  /// Circular radius for small elements.
  static const Radius circularSm = Radius.circular(smValue);

  /// Circular radius for medium elements.
  static const Radius circularMd = Radius.circular(mdValue);

  /// Circular radius for large elements.
  static const Radius circularLg = Radius.circular(lgValue);
}
