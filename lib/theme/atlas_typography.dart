import 'package:flutter/material.dart';

/// The Atlas type scale.
///
/// Archivo Expanded Bold carries display text and rank numerals for its
/// squared-off jersey character; normal-width Archivo handles everything
/// else. Two widths of one family read as two voices without a second
/// typeface.
///
/// Nothing here is ever set in capitals. See the spec's prohibitions: in
/// Turkish `i` uppercases to `İ`, and Dart's locale-less `toUpperCase()`
/// gets that wrong.
abstract final class AtlasTypography {
  static const String sans = 'Archivo';
  static const String expanded = 'ArchivoExpanded';

  /// Digits that line up in a column rather than jittering.
  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const TextStyle display = TextStyle(
    fontFamily: expanded,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.6,
    fontFeatures: _tabular,
  );

  static const TextStyle title = TextStyle(
    fontFamily: expanded,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    fontFeatures: _tabular,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: sans,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: sans,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// Applies tabular figures to any style that will hold a number.
  static TextStyle numeric(TextStyle base) =>
      base.copyWith(fontFeatures: _tabular);

  /// Maps the scale onto Material's slots so themed widgets inherit it.
  static TextTheme textTheme(Color primary, Color muted) {
    return TextTheme(
      displayLarge: display.copyWith(color: primary),
      displayMedium: display.copyWith(color: primary, fontSize: 32),
      headlineLarge: title.copyWith(color: primary),
      headlineMedium: title.copyWith(color: primary, fontSize: 21),
      titleLarge: title.copyWith(color: primary),
      titleMedium: heading.copyWith(color: primary),
      titleSmall: label.copyWith(color: primary),
      bodyLarge: body.copyWith(color: primary, fontSize: 16),
      bodyMedium: body.copyWith(color: primary),
      bodySmall: body.copyWith(color: muted, fontSize: 13),
      labelLarge: label.copyWith(color: primary),
      labelMedium: label.copyWith(color: muted),
      labelSmall: micro.copyWith(color: muted),
    );
  }
}
