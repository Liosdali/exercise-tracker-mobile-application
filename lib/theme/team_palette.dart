import 'dart:ui';

import 'package:flutter/foundation.dart';

/// The eight colours a team can adopt.
///
/// `steel` is the default so a user who has joined no team sees neutral
/// chrome rather than a borrowed identity.
enum KitColor { crimson, claret, violet, royal, teal, forest, gold, steel }

/// A kit colour in its two roles.
///
/// A [fill] sits behind its own [onFill] foreground, so it needs no scheme
/// transform and is identical in light and dark — a team's header is the same
/// colour in both. A mark sits on the scheme's own background, as a
/// leaderboard rail, a crest border or team-coloured text, so it must clear
/// that background instead and differs per scheme.
@immutable
class KitSwatch {
  const KitSwatch({
    required this.slug,
    required this.fill,
    required this.onFill,
    required this.darkMark,
    required this.lightMark,
  });

  final String slug;
  final Color fill;
  final Color onFill;
  final Color darkMark;
  final Color lightMark;

  Color markFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkMark : lightMark;
}

const Color _white = Color(0xFFFFFFFF);
const Color _ink = Color(0xFF161A21);

/// Steel's four values, hoisted so [AtlasColors]'s const constructors can
/// reference them directly — a const constructor cannot call [swatchOf], but
/// a const variable reference is still a valid const expression.
const Color kSteelFill = Color(0xFF5A6472);
const Color kSteelOnFill = _white;
const Color kSteelDarkMark = Color(0xFF7F8A9A);
const Color kSteelLightMark = Color(0xFF5A6472);

/// Ratios are measured in `test/theme/team_palette_test.dart`.
const Map<KitColor, KitSwatch> kitSwatches = <KitColor, KitSwatch>{
  KitColor.crimson: KitSwatch(
    slug: 'crimson',
    fill: Color(0xFFCE3B34),
    onFill: _white,
    darkMark: Color(0xFFD96660),
    lightMark: Color(0xFFCE3B34),
  ),
  KitColor.claret: KitSwatch(
    slug: 'claret',
    fill: Color(0xFFA6276B),
    onFill: _white,
    darkMark: Color(0xFFD95D9F),
    lightMark: Color(0xFFA6276B),
  ),
  KitColor.violet: KitSwatch(
    slug: 'violet',
    fill: Color(0xFF7A4DD4),
    onFill: _white,
    darkMark: Color(0xFF9976DE),
    lightMark: Color(0xFF7A4DD4),
  ),
  KitColor.royal: KitSwatch(
    slug: 'royal',
    fill: Color(0xFF2F5FD0),
    onFill: _white,
    darkMark: Color(0xFF6387DC),
    lightMark: Color(0xFF2F5FD0),
  ),
  KitColor.teal: KitSwatch(
    slug: 'teal',
    fill: Color(0xFF17727D),
    onFill: _white,
    darkMark: Color(0xFF1E97A5),
    lightMark: Color(0xFF17727D),
  ),
  KitColor.forest: KitSwatch(
    slug: 'forest',
    fill: Color(0xFF2C7A46),
    onFill: _white,
    darkMark: Color(0xFF389B59),
    lightMark: Color(0xFF2C7A46),
  ),
  // gold is the one hue whose fill takes ink rather than white, which is
  // also why its fill already passes as a dark mark unchanged.
  KitColor.gold: KitSwatch(
    slug: 'gold',
    fill: Color(0xFFB8891B),
    onFill: _ink,
    darkMark: Color(0xFFB8891B),
    lightMark: Color(0xFF906B15),
  ),
  KitColor.steel: KitSwatch(
    slug: 'steel',
    fill: kSteelFill,
    onFill: kSteelOnFill,
    darkMark: kSteelDarkMark,
    lightMark: kSteelLightMark,
  ),
};

/// The colour a team has when it has chosen none.
const KitColor kDefaultKit = KitColor.steel;

KitSwatch swatchOf(KitColor kit) => kitSwatches[kit]!;

/// Resolves a stored slug, falling back to [kDefaultKit] for null, empty or
/// unrecognised values so a bad row can never crash a screen.
KitColor kitFromSlug(String? slug) {
  if (slug == null || slug.isEmpty) return kDefaultKit;
  for (final entry in kitSwatches.entries) {
    if (entry.value.slug == slug) return entry.key;
  }
  return kDefaultKit;
}
