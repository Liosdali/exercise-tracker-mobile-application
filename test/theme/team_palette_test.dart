import 'dart:math' as math;
import 'dart:ui';

import 'package:exercise_app/theme/atlas_tokens.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('every KitColor has a swatch', () {
    for (final kit in KitColor.values) {
      expect(kitSwatches[kit], isNotNull, reason: '$kit has no swatch');
    }
  });

  test('slugs are unique and match the enum names', () {
    final slugs = kitSwatches.values.map((s) => s.slug).toList();
    expect(slugs.toSet().length, slugs.length);
    for (final entry in kitSwatches.entries) {
      expect(entry.value.slug, entry.key.name);
    }
  });

  test('every fill clears 4.5:1 against its own foreground', () {
    for (final swatch in kitSwatches.values) {
      expect(contrastRatio(swatch.fill, swatch.onFill),
          greaterThanOrEqualTo(4.5),
          reason: '${swatch.slug} fill/onFill failed');
    }
  });

  test('every dark mark clears 4.5:1 on dark ink and dark surface', () {
    for (final swatch in kitSwatches.values) {
      for (final bg in [AtlasTokens.darkInk, AtlasTokens.darkSurface]) {
        expect(contrastRatio(swatch.darkMark, bg), greaterThanOrEqualTo(4.5),
            reason: '${swatch.slug} darkMark failed against $bg');
      }
    }
  });

  test('every light mark clears 4.5:1 on light ink and light surface', () {
    for (final swatch in kitSwatches.values) {
      for (final bg in [AtlasTokens.lightInk, AtlasTokens.lightSurface]) {
        expect(contrastRatio(swatch.lightMark, bg), greaterThanOrEqualTo(4.5),
            reason: '${swatch.slug} lightMark failed against $bg');
      }
    }
  });

  test('markFor picks the mark matching the brightness', () {
    final teal = swatchOf(KitColor.teal);
    expect(teal.markFor(Brightness.dark), teal.darkMark);
    expect(teal.markFor(Brightness.light), teal.lightMark);
  });

  test('kitFromSlug round-trips and falls back to steel', () {
    expect(kitFromSlug('crimson'), KitColor.crimson);
    expect(kitFromSlug('gold'), KitColor.gold);
    expect(kitFromSlug(null), kDefaultKit);
    expect(kitFromSlug('chartreuse'), kDefaultKit);
    expect(kDefaultKit, KitColor.steel);
  });
}
