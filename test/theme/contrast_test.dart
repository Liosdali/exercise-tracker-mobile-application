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

  group('status hues used as a fill', () {
    // Spec §2 rule 1: status colour only ever appears on small marks — a
    // dot, an icon, a line of text. It must never become a large opaque
    // fill (a full-bleed SnackBar background, a 48dp destructive button).
    // Unlike kit hues — which the spec pairs with an explicit, measured
    // `onFill` foreground (white or `ink`) — status hues carry no such
    // pairing. This group measures the two foregrounds a fill would
    // realistically carry, `textPrimary` and white, against every status
    // hue in both schemes.
    //
    // Every combination below fails to clear 4.5:1 against *both*
    // foregrounds at once — this is a real measurement, not a guess: dark
    // `success` as a SnackBar fill measures 2.06 against textPrimary, dark
    // `danger` 3.08, and the destructive button's white-on-danger measures
    // 3.48 — all below the floor. Where one foreground happens to clear
    // (light hues are dark enough that white text on them clears easily),
    // the other foreground fails outright, so there is still no foreground
    // choice that makes the hue a safe, general-purpose fill.
    //
    // This is a regression guard, not a live production check — after the
    // fix wave nothing pairs a status hue with a fill; SnackBars use
    // StatusMark on the themed surface and destructive buttons take the
    // theme's default filled style. If a future palette change ever made a
    // status hue clear 4.5:1 against BOTH foregrounds, this test would
    // fail, which is deliberate: a status hue passing this check is not
    // permission to use it as a fill. The app must not use a status hue as
    // a fill regardless of what this test finds; a pairing that fails it is
    // proof the ban is load-bearing, not just stylistic.
    const white = Color(0xFFFFFFFF);

    void expectNoSafeFillPairing(String scheme, Map<String, Color> hues,
        Color textPrimary) {
      hues.forEach((name, hue) {
        final onTextPrimary = contrastRatio(hue, textPrimary);
        final onWhite = contrastRatio(hue, white);
        final clearsBoth = onTextPrimary >= 4.5 && onWhite >= 4.5;
        expect(clearsBoth, isFalse,
            reason: '$scheme $name would be safe as a fill against both '
                'textPrimary ($onTextPrimary) and white ($onWhite) — a '
                'status hue must never be used as a fill regardless');
      });
    }

    test('dark status hues have no safe fill pairing', () {
      expectNoSafeFillPairing(
        'dark',
        <String, Color>{
          'success': AtlasTokens.darkSuccess,
          'warn': AtlasTokens.darkWarn,
          'danger': AtlasTokens.darkDanger,
          'info': AtlasTokens.darkInfo,
        },
        AtlasTokens.darkTextPrimary,
      );
    });

    test('light status hues have no safe fill pairing', () {
      expectNoSafeFillPairing(
        'light',
        <String, Color>{
          'success': AtlasTokens.lightSuccess,
          'warn': AtlasTokens.lightWarn,
          'danger': AtlasTokens.lightDanger,
          'info': AtlasTokens.lightInfo,
        },
        AtlasTokens.lightTextPrimary,
      );
    });
  });
}
