import 'package:flutter/painting.dart';

/// Text styles for the design's fonts.
///
/// The bundled fonts are variable fonts, so each style sets the `wght` axis as
/// well as [FontWeight]; otherwise some platforms render every weight as Regular.
abstract final class AppText {
  static TextStyle nunito(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
  }) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    color: color,
    height: height,
  );

  /// The FridgeFriend wordmark.
  static TextStyle brand(Color color) => TextStyle(
    fontFamily: 'Bricolage Grotesque',
    fontSize: 18.333,
    fontWeight: FontWeight.w800,
    fontVariations: const [
      FontVariation.weight(800),
      FontVariation('opsz', 14),
      FontVariation('wdth', 100),
    ],
    letterSpacing: -0.55,
    color: color,
  );

  /// Figma's `Label/Large`: filter chips.
  static TextStyle labelLarge(Color color) => TextStyle(
    fontFamily: 'Figtree',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation.weight(600)],
    height: 20 / 14,
    letterSpacing: 0.1,
    color: color,
  );
}
