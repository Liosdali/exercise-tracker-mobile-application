import 'dart:math' as math;
import 'dart:ui';

import 'package:exercise_app/theme/atlas_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('dark scheme text', () {
    test('primary and muted text clear 4.5:1 on ink and surface', () {
      for (final bg in [AtlasTokens.darkInk, AtlasTokens.darkSurface]) {
        expect(contrastRatio(AtlasTokens.darkTextPrimary, bg),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(AtlasTokens.darkTextMuted, bg),
            greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('light scheme text', () {
    test('primary and muted text clear 4.5:1 on ink and surface', () {
      for (final bg in [AtlasTokens.lightInk, AtlasTokens.lightSurface]) {
        expect(contrastRatio(AtlasTokens.lightTextPrimary, bg),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(AtlasTokens.lightTextMuted, bg),
            greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('status hues', () {
    test('dark status hues clear 4.5:1 on ink and surface', () {
      final hues = <String, Color>{
        'success': AtlasTokens.darkSuccess,
        'warn': AtlasTokens.darkWarn,
        'danger': AtlasTokens.darkDanger,
        'info': AtlasTokens.darkInfo,
      };
      hues.forEach((name, hue) {
        for (final bg in [AtlasTokens.darkInk, AtlasTokens.darkSurface]) {
          expect(contrastRatio(hue, bg), greaterThanOrEqualTo(4.5),
              reason: '$name failed against $bg');
        }
      });
    });

    test('light status hues clear 4.5:1 on ink and surface', () {
      final hues = <String, Color>{
        'success': AtlasTokens.lightSuccess,
        'warn': AtlasTokens.lightWarn,
        'danger': AtlasTokens.lightDanger,
        'info': AtlasTokens.lightInfo,
      };
      hues.forEach((name, hue) {
        for (final bg in [AtlasTokens.lightInk, AtlasTokens.lightSurface]) {
          expect(contrastRatio(hue, bg), greaterThanOrEqualTo(4.5),
              reason: '$name failed against $bg');
        }
      });
    });
  });
}
