# Atlas Workout Visual Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Atlas Workout a Club Kit visual identity — quiet graphite chrome with each team's colour as a real theming axis — replacing the stock `ColorScheme.fromSeed(Colors.deepPurple)` theme.

**Architecture:** Three tiers. A token layer under `lib/theme/` supplies colour, typography, shape and motion constants and feeds two `ThemeData` factories, which restyle the existing Material widgets with no screen edits. A `ThemeExtension<AtlasColors>` carries the values Material has no slot for (status hues, team accent), and a `TeamTheme` widget overrides the team accent for any team-scoped subtree so components never import `TeamProvider`. A six-widget component layer under `lib/widgets/atlas/` carries the identity, and a Postgres column on `public.groups` stores each team's kit slug.

**Tech Stack:** Flutter (Dart SDK ^3.12.2), Material 3, `provider` 6.1.5, Supabase (`supabase_flutter` 2.17.2), `flutter_test` with golden tests, Archivo (SIL OFL) bundled as static TTFs.

**Spec:** `docs/superpowers/specs/2026-09-20-atlas-visual-identity-design.md`

## Global Constraints

- **Dark is the primary scheme.** Light must be authored, but dark is what gets screenshotted.
- **Contrast floor is 4.5:1 everywhere**, measured against both the scheme background and the scheme surface. No exceptions; a hue that cannot clear it gets changed, not waived.
- **No all-caps text anywhere.** Turkish `i` uppercases to `İ`, so `toUpperCase()` without a Turkish locale corrupts the second language. Sentence case throughout.
- **No tracked-out label above a heading, no arrow glyph appended to button or link text, no meta strings joined with middle dots.**
- **Radius carries role:** fields and chips 8, cards and feed items 14, bottom sheets 24 top corners only, kit rails 2, crests fully round. Never one radius everywhere.
- **Motion is spent once** — the leaderboard reorder. No section entrance animations, no press lift on cards. Every animation respects `MediaQuery.disableAnimations`.
- **Elevation is a surface step plus a hairline in dark, a real shadow in light.**
- **Kit colour fills large fields only; status colour appears on small marks only.** They never share a pixel.
- **Team identity always ships with the team name or initial beside the colour.** Colour is never the sole carrier of meaning.
- **All numeric columns use `FontFeature.tabularFigures()`.**
- **Every user-facing string goes through `AppLocalizations`** and must be added to both `lib/l10n/app_en.arb` and `lib/l10n/app_tr.arb`.
- **Exact token values** are in spec sections 2 and 3 and are reproduced in Tasks 1, 2 and 4. Copy them verbatim; do not re-derive.

## File Structure

**Created:**

| Path | Responsibility |
|---|---|
| `lib/theme/atlas_tokens.dart` | Chrome and status colour constants for both schemes, plus space, radius and duration scales |
| `lib/theme/team_palette.dart` | The `KitColor` enum and the eight swatches: fill, foreground, dark mark, light mark |
| `lib/theme/atlas_colors.dart` | `ThemeExtension<AtlasColors>` and the `context.atlas` accessor |
| `lib/theme/atlas_typography.dart` | The type scale as `TextStyle` constants and the `TextTheme` builder |
| `lib/theme/atlas_theme.dart` | `buildDarkTheme()` / `buildLightTheme()` including all component themes |
| `lib/widgets/atlas/team_theme.dart` | `TeamTheme`, which overrides the team accent for a subtree |
| `lib/widgets/atlas/team_crest.dart` | `TeamCrest` |
| `lib/widgets/atlas/team_header.dart` | `TeamHeader` |
| `lib/widgets/atlas/stat_tile.dart` | `StatTile` |
| `lib/widgets/atlas/leaderboard_row.dart` | `LeaderboardRow` and `AnimatedLeaderboard` |
| `lib/widgets/atlas/feed_item.dart` | `FeedItem` |
| `lib/widgets/atlas/status_mark.dart` | `StatusMark` |
| `assets/fonts/` | Five Archivo static TTFs plus `OFL.txt` |
| `supabase/migrations/202609200001_team_kit_colour.sql` | Adds `groups.color` |
| `test/flutter_test_config.dart` | Loads the bundled fonts for every test in the tree |
| `test/theme/font_coverage_test.dart` | Parses the TTF cmap tables to prove Turkish glyph coverage |
| `test/theme/contrast_test.dart` | Enforces the 4.5:1 floor on every token pairing |
| `test/theme/atlas_colors_test.dart` | `copyWith` and `lerp` behaviour of the extension |
| `test/widgets/atlas/*_test.dart` | One golden and behaviour test file per component |

**Modified:**

| Path | Change |
|---|---|
| `pubspec.yaml` | `assets/fonts/` asset entry and the `fonts:` declaration |
| `lib/main.dart:141-152` | Replaced by the two theme factory calls |
| 14 screen files plus `lib/services/deep_link_service.dart` | 44 hardcoded `Colors.*` call sites become tokens |
| `lib/models/team.dart` | Gains the `color` field |
| `lib/providers/team_provider.dart:105,141` | Column list and insert gain `color`; new `setTeamColor` method |
| `lib/screens/create_team_screen.dart` | Kit colour picker |
| `lib/screens/team_detail_screen.dart` | Admin-only colour edit, `TeamTheme` wrapper |
| `lib/screens/team_list_screen.dart`, `team_leaderboard_screen.dart`, `social_feed_screen.dart` | `TeamTheme` wrappers and component adoption |
| `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb` | Eight colour names plus picker strings |
| `supabase/setup_fresh_project.sql` | `groups` table definition gains `color` so fresh installs match |

**Already verified, no work needed:** `join_team_by_invite_token` is declared `RETURNS public.groups` and selects `*`, so the new column flows through the join path unchanged. The `"Admins can update their group"` policy uses `is_team_admin(id) OR owner_id = auth.uid()` in both `USING` and `WITH CHECK`, so admin colour writes are already permitted.

---
### Task 1: Chrome and status tokens, with the contrast floor as a test

**Files:**
- Create: `lib/theme/atlas_tokens.dart`
- Create: `test/theme/contrast_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `AtlasTokens` with static `Color` fields `darkInk`, `darkSurface`, `darkSurfaceRaised`, `darkLine`, `darkTextPrimary`, `darkTextMuted`, `darkSuccess`, `darkWarn`, `darkDanger`, `darkInfo` and the matching `light*` names; `AtlasSpace` with `xs`=4, `sm`=8, `md`=12, `lg`=16, `xl`=24, `xxl`=32, `xxxl`=48 as `double`; `AtlasRadius` with `field`=8, `card`=14, `sheet`=24, `rail`=2 as `double`; `AtlasMotion.reorder` as `Duration`. Also `double contrastRatio(Color a, Color b)` exported from `test/theme/contrast_test.dart` is **not** shared — Task 2 redeclares its own copy deliberately, since test helpers do not belong in `lib/`.

- [ ] **Step 1: Write the failing test**

Create `test/theme/contrast_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/contrast_test.dart`
Expected: FAIL at compile time — `Target of URI doesn't exist: 'package:exercise_app/theme/atlas_tokens.dart'`.

- [ ] **Step 3: Write the tokens**

Create `lib/theme/atlas_tokens.dart`:

```dart
import 'package:flutter/painting.dart';

/// Raw colour tokens for both schemes.
///
/// Every value here is measured against the 4.5:1 contrast floor in
/// `test/theme/contrast_test.dart`. Change a value and the test decides
/// whether the change ships.
abstract final class AtlasTokens {
  // Dark scheme chrome. Blue-leaning graphite, not a tinted black.
  static const Color darkInk = Color(0xFF161A21);
  static const Color darkSurface = Color(0xFF1E232C);
  static const Color darkSurfaceRaised = Color(0xFF262C37);
  static const Color darkLine = Color(0xFF333A47);
  static const Color darkTextPrimary = Color(0xFFEEF1F6);
  static const Color darkTextMuted = Color(0xFF98A1B0);

  // Light scheme chrome.
  static const Color lightInk = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightLine = Color(0xFFDDE2EA);
  static const Color lightTextPrimary = Color(0xFF171B22);
  static const Color lightTextMuted = Color(0xFF5D6675);

  // Status hues. Small marks only: a dot, an icon, a line of text.
  static const Color darkSuccess = Color(0xFF3FBF87);
  static const Color darkWarn = Color(0xFFE0A62E);
  static const Color darkDanger = Color(0xFFE16151);
  static const Color darkInfo = Color(0xFF4C8DF0);

  static const Color lightSuccess = Color(0xFF1E7A52);
  static const Color lightWarn = Color(0xFF8A6410);
  static const Color lightDanger = Color(0xFFB33A2E);
  static const Color lightInfo = Color(0xFF2B5FB8);
}

/// The 4pt spacing scale. `xl` is the rhythm between sections.
abstract final class AtlasSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Radius carries role rather than being one value everywhere.
abstract final class AtlasRadius {
  static const double field = 8;
  static const double card = 14;
  static const double sheet = 24;
  static const double rail = 2;
}

/// The app spends its ambient motion once, on the leaderboard reorder.
abstract final class AtlasMotion {
  static const Duration reorder = Duration(milliseconds: 240);
  static const Curve reorderCurve = Curves.easeOutCubic;
}
```

Note: `Curves` lives in `package:flutter/animation.dart`, which `painting.dart` does not export. Add `import 'package:flutter/animation.dart';` alongside the painting import.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/theme/contrast_test.dart`
Expected: PASS, 4 tests. If `darkDanger` fails on surface you have used `#E05B4B`, the value the spec rejected; use `#E16151`.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/atlas_tokens.dart test/theme/contrast_test.dart
git commit -m "Add Atlas chrome and status tokens with a contrast floor test"
```

---

### Task 2: The eight kit swatches

**Files:**
- Create: `lib/theme/team_palette.dart`
- Create: `test/theme/team_palette_test.dart`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `enum KitColor { crimson, claret, violet, royal, teal, forest, gold, steel }`; `class KitSwatch` with `final String slug`, `final Color fill`, `final Color onFill`, `final Color darkMark`, `final Color lightMark` and `Color markFor(Brightness brightness)`; `const Map<KitColor, KitSwatch> kitSwatches`; `const KitColor kDefaultKit = KitColor.steel`; `KitColor kitFromSlug(String? slug)` which falls back to `kDefaultKit` for null or unknown input; `KitSwatch swatchOf(KitColor kit)`.

- [ ] **Step 1: Write the failing test**

Create `test/theme/team_palette_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/team_palette_test.dart`
Expected: FAIL at compile time — `team_palette.dart` does not exist.

- [ ] **Step 3: Write the palette**

Create `lib/theme/team_palette.dart`:

```dart
import 'package:flutter/painting.dart';

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
    fill: Color(0xFF5A6472),
    onFill: _white,
    darkMark: Color(0xFF7F8A9A),
    lightMark: Color(0xFF5A6472),
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/theme/team_palette_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/team_palette.dart test/theme/team_palette_test.dart
git commit -m "Add the eight Atlas kit swatches with fill and mark roles"
```

---
### Task 3: The AtlasColors theme extension

Material's `ColorScheme` has no slot for "unsynced" or "personal best", and no slot for a team accent. This extension is what lets a screen write `context.atlas.warn` instead of `Colors.orange`.

**Files:**
- Create: `lib/theme/atlas_colors.dart`
- Create: `test/theme/atlas_colors_test.dart`

**Interfaces:**
- Consumes: `AtlasTokens` (Task 1), `KitSwatch` and `kDefaultKit` and `swatchOf` (Task 2).
- Produces: `class AtlasColors extends ThemeExtension<AtlasColors>` with `final Color` fields `ink`, `surface`, `surfaceRaised`, `line`, `textPrimary`, `textMuted`, `success`, `warn`, `danger`, `info`, `teamFill`, `teamOnFill`, `teamMark`; named constructors `AtlasColors.dark()` and `AtlasColors.light()`; `copyWith` accepting every field as an optional named `Color?`; `lerp`. Also `extension AtlasColorsContext on BuildContext { AtlasColors get atlas; }`.

- [ ] **Step 1: Write the failing test**

Create `test/theme/atlas_colors_test.dart`:

```dart
import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/theme/atlas_tokens.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark defaults come from the dark tokens and the default kit', () {
    const colors = AtlasColors.dark();
    expect(colors.ink, AtlasTokens.darkInk);
    expect(colors.textMuted, AtlasTokens.darkTextMuted);
    expect(colors.danger, AtlasTokens.darkDanger);
    expect(colors.teamFill, swatchOf(kDefaultKit).fill);
    expect(colors.teamMark, swatchOf(kDefaultKit).darkMark);
  });

  test('light defaults come from the light tokens and the default kit', () {
    const colors = AtlasColors.light();
    expect(colors.ink, AtlasTokens.lightInk);
    expect(colors.danger, AtlasTokens.lightDanger);
    expect(colors.teamMark, swatchOf(kDefaultKit).lightMark);
  });

  test('copyWith replaces only the named fields', () {
    const base = AtlasColors.dark();
    final swatch = swatchOf(KitColor.claret);
    final copy = base.copyWith(
      teamFill: swatch.fill,
      teamOnFill: swatch.onFill,
      teamMark: swatch.darkMark,
    );
    expect(copy.teamFill, swatch.fill);
    expect(copy.teamMark, swatch.darkMark);
    expect(copy.ink, base.ink);
    expect(copy.success, base.success);
  });

  test('lerp at t=0 and t=1 returns the endpoints', () {
    const a = AtlasColors.dark();
    const b = AtlasColors.light();
    expect(a.lerp(b, 0).ink, a.ink);
    expect(a.lerp(b, 1).ink, b.ink);
  });

  test('lerp against a null or foreign extension returns this', () {
    const a = AtlasColors.dark();
    expect(a.lerp(null, 0.5), same(a));
  });

  testWidgets('context.atlas reads the extension off the theme',
      (tester) async {
    late AtlasColors seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[AtlasColors.dark()],
        ),
        home: Builder(
          builder: (context) {
            seen = context.atlas;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen.ink, AtlasTokens.darkInk);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/atlas_colors_test.dart`
Expected: FAIL at compile time — `atlas_colors.dart` does not exist.

- [ ] **Step 3: Write the extension**

Create `lib/theme/atlas_colors.dart`:

```dart
import 'package:flutter/material.dart';

import 'atlas_tokens.dart';
import 'team_palette.dart';

/// The colours Material's [ColorScheme] has no slot for.
///
/// Status hues describe sync and progress state; the team fields describe
/// whichever team's subtree the widget is in. Outside a team, the team fields
/// hold the default kit so nothing has to null-check them.
@immutable
class AtlasColors extends ThemeExtension<AtlasColors> {
  const AtlasColors({
    required this.ink,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.textPrimary,
    required this.textMuted,
    required this.success,
    required this.warn,
    required this.danger,
    required this.info,
    required this.teamFill,
    required this.teamOnFill,
    required this.teamMark,
  });

  const AtlasColors.dark()
      : ink = AtlasTokens.darkInk,
        surface = AtlasTokens.darkSurface,
        surfaceRaised = AtlasTokens.darkSurfaceRaised,
        line = AtlasTokens.darkLine,
        textPrimary = AtlasTokens.darkTextPrimary,
        textMuted = AtlasTokens.darkTextMuted,
        success = AtlasTokens.darkSuccess,
        warn = AtlasTokens.darkWarn,
        danger = AtlasTokens.darkDanger,
        info = AtlasTokens.darkInfo,
        teamFill = const Color(0xFF5A6472),
        teamOnFill = const Color(0xFFFFFFFF),
        teamMark = const Color(0xFF7F8A9A);

  const AtlasColors.light()
      : ink = AtlasTokens.lightInk,
        surface = AtlasTokens.lightSurface,
        surfaceRaised = AtlasTokens.lightSurfaceRaised,
        line = AtlasTokens.lightLine,
        textPrimary = AtlasTokens.lightTextPrimary,
        textMuted = AtlasTokens.lightTextMuted,
        success = AtlasTokens.lightSuccess,
        warn = AtlasTokens.lightWarn,
        danger = AtlasTokens.lightDanger,
        info = AtlasTokens.lightInfo,
        teamFill = const Color(0xFF5A6472),
        teamOnFill = const Color(0xFFFFFFFF),
        teamMark = const Color(0xFF5A6472);

  final Color ink;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color textPrimary;
  final Color textMuted;

  final Color success;
  final Color warn;
  final Color danger;
  final Color info;

  final Color teamFill;
  final Color teamOnFill;
  final Color teamMark;

  @override
  AtlasColors copyWith({
    Color? ink,
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? textPrimary,
    Color? textMuted,
    Color? success,
    Color? warn,
    Color? danger,
    Color? info,
    Color? teamFill,
    Color? teamOnFill,
    Color? teamMark,
  }) {
    return AtlasColors(
      ink: ink ?? this.ink,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      teamFill: teamFill ?? this.teamFill,
      teamOnFill: teamOnFill ?? this.teamOnFill,
      teamMark: teamMark ?? this.teamMark,
    );
  }

  @override
  AtlasColors lerp(ThemeExtension<AtlasColors>? other, double t) {
    if (other is! AtlasColors) return this;
    return AtlasColors(
      ink: Color.lerp(ink, other.ink, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      line: Color.lerp(line, other.line, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      teamFill: Color.lerp(teamFill, other.teamFill, t)!,
      teamOnFill: Color.lerp(teamOnFill, other.teamOnFill, t)!,
      teamMark: Color.lerp(teamMark, other.teamMark, t)!,
    );
  }
}

/// Reads the Atlas colours off the ambient theme.
///
/// Both theme factories install the extension, so the bang is safe in app
/// code. A widget test that builds a bare [ThemeData] must add it too.
extension AtlasColorsContext on BuildContext {
  AtlasColors get atlas => Theme.of(this).extension<AtlasColors>()!;
}
```

The const constructors repeat the default kit's hex values rather than calling `swatchOf(kDefaultKit)`, because a `const` constructor cannot call a function. The test asserts the two stay in agreement, so a change to `steel` that forgets this file fails the build.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/theme/atlas_colors_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/theme/atlas_colors.dart test/theme/atlas_colors_test.dart
git commit -m "Add the AtlasColors theme extension for status and team hues"
```

---

### Task 4: Bundle Archivo and build the type scale

**Files:**
- Create: `assets/fonts/Archivo-Regular.ttf`, `Archivo-Medium.ttf`, `Archivo-SemiBold.ttf`, `Archivo_Expanded-SemiBold.ttf`, `Archivo_Expanded-Bold.ttf`, `OFL.txt`
- Create: `lib/theme/atlas_typography.dart`
- Create: `test/flutter_test_config.dart`
- Create: `test/theme/font_coverage_test.dart`
- Modify: `pubspec.yaml` (the `flutter:` section, after the existing `assets:` list)

**Interfaces:**
- Consumes: nothing.
- Produces: `abstract final class AtlasTypography` with static `TextStyle` fields `display`, `title`, `heading`, `body`, `label`, `micro`, plus `static TextTheme textTheme(Color primary, Color muted)`. The families are `'Archivo'` and `'ArchivoExpanded'`. Numeric styles (`display`, `title`) carry `FontFeature.tabularFigures()`; `TextStyle numeric(TextStyle base)` applies it to any other style.

- [ ] **Step 1: Fetch the fonts**

Download the Archivo family from Google Fonts (`https://fonts.google.com/specimen/Archivo`, "Get font" then "Download all"). From the zip's `static/` directory copy exactly these five files into `assets/fonts/`:

```
Archivo-Regular.ttf
Archivo-Medium.ttf
Archivo-SemiBold.ttf
Archivo_Expanded-SemiBold.ttf
Archivo_Expanded-Bold.ttf
```

Copy the zip's `OFL.txt` to `assets/fonts/OFL.txt`. The licence requires it to ship with the fonts.

- [ ] **Step 2: Declare the fonts in pubspec.yaml**

In the `flutter:` section, add `- assets/fonts/` to the existing `assets:` list so it reads:

```yaml
  assets:
    - storage/data/exercises.json
    - storage/images/
    - storage/videos/
    - .env
    - assets/fonts/
```

Then replace the commented-out `# fonts:` example block near the end of the file with:

```yaml
  fonts:
    - family: Archivo
      fonts:
        - asset: assets/fonts/Archivo-Regular.ttf
          weight: 400
        - asset: assets/fonts/Archivo-Medium.ttf
          weight: 500
        - asset: assets/fonts/Archivo-SemiBold.ttf
          weight: 600
    - family: ArchivoExpanded
      fonts:
        - asset: assets/fonts/Archivo_Expanded-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Archivo_Expanded-Bold.ttf
          weight: 700
```

Run `flutter pub get`.

- [ ] **Step 3: Write the failing font coverage test**

This parses the TTF `cmap` table directly rather than rendering text, so it cannot be fooled by system font fallback quietly substituting a glyph.

Create `test/theme/font_coverage_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Returns the set of Unicode code points a TrueType font maps to a real
/// glyph, reading the format 4 and format 12 `cmap` subtables.
Set<int> _coveredCodePoints(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final numTables = data.getUint16(4);

  int? cmapOffset;
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
    if (tag == 'cmap') {
      cmapOffset = data.getUint32(record + 8);
      break;
    }
  }
  if (cmapOffset == null) return <int>{};

  final numSubtables = data.getUint16(cmapOffset + 2);
  final covered = <int>{};

  for (var i = 0; i < numSubtables; i++) {
    final record = cmapOffset + 4 + i * 8;
    final platformId = data.getUint16(record);
    final encodingId = data.getUint16(record + 2);
    final isUnicode = platformId == 0 ||
        (platformId == 3 && (encodingId == 1 || encodingId == 10));
    if (!isUnicode) continue;

    final subtable = cmapOffset + data.getUint32(record + 4);
    final format = data.getUint16(subtable);

    if (format == 4) {
      final segCount = data.getUint16(subtable + 6) ~/ 2;
      final endCodes = subtable + 14;
      final startCodes = endCodes + segCount * 2 + 2;
      final idDeltas = startCodes + segCount * 2;
      final idRangeOffsets = idDeltas + segCount * 2;

      for (var s = 0; s < segCount; s++) {
        final end = data.getUint16(endCodes + s * 2);
        final start = data.getUint16(startCodes + s * 2);
        if (start > end || start == 0xFFFF) continue;
        final delta = data.getInt16(idDeltas + s * 2);
        final rangeOffset = data.getUint16(idRangeOffsets + s * 2);

        for (var c = start; c <= end; c++) {
          int glyph;
          if (rangeOffset == 0) {
            glyph = (c + delta) & 0xFFFF;
          } else {
            final glyphIndexAddress =
                idRangeOffsets + s * 2 + rangeOffset + (c - start) * 2;
            if (glyphIndexAddress + 1 >= bytes.length) continue;
            glyph = data.getUint16(glyphIndexAddress);
            if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
          }
          if (glyph != 0) covered.add(c);
        }
      }
    } else if (format == 12) {
      final numGroups = data.getUint32(subtable + 12);
      for (var g = 0; g < numGroups; g++) {
        final group = subtable + 16 + g * 12;
        final start = data.getUint32(group);
        final end = data.getUint32(group + 4);
        final startGlyph = data.getUint32(group + 8);
        if (startGlyph == 0 && start == 0) continue;
        for (var c = start; c <= end; c++) {
          covered.add(c);
        }
      }
    }
  }
  return covered;
}

void main() {
  // The Turkish set, including the dotted/dotless I pair that cheap fonts
  // omit. Section 3 of the spec commits to these.
  const turkish = 'ğĞşŞİıçÇöÖüÜ';

  const fonts = <String>[
    'assets/fonts/Archivo-Regular.ttf',
    'assets/fonts/Archivo-Medium.ttf',
    'assets/fonts/Archivo-SemiBold.ttf',
    'assets/fonts/Archivo_Expanded-SemiBold.ttf',
    'assets/fonts/Archivo_Expanded-Bold.ttf',
  ];

  for (final path in fonts) {
    test('$path covers the Turkish glyph set', () {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      final covered = _coveredCodePoints(file.readAsBytesSync());
      expect(covered, isNotEmpty, reason: '$path has no readable cmap');

      final missing = <String>[];
      for (final rune in turkish.runes) {
        if (!covered.contains(rune)) {
          missing.add(String.fromCharCode(rune));
        }
      }
      expect(missing, isEmpty,
          reason: '$path is missing ${missing.join(", ")}');
    });
  }
}
```

- [ ] **Step 4: Run the coverage test**

Run: `flutter test test/theme/font_coverage_test.dart`
Expected: PASS, 5 tests. A failure naming `İ` or `ğ` means the wrong Archivo subset was downloaded — fetch the full family rather than a Latin-only subset.

- [ ] **Step 5: Add the test font loader**

Widget and golden tests do not pick up pubspec fonts automatically; without this they render in the fallback face and every golden is wrong. `flutter_test_config.dart` runs once for every test under `test/`.

Create `test/flutter_test_config.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      File(path).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _load('Archivo', <String>[
    'assets/fonts/Archivo-Regular.ttf',
    'assets/fonts/Archivo-Medium.ttf',
    'assets/fonts/Archivo-SemiBold.ttf',
  ]);
  await _load('ArchivoExpanded', <String>[
    'assets/fonts/Archivo_Expanded-SemiBold.ttf',
    'assets/fonts/Archivo_Expanded-Bold.ttf',
  ]);
  return testMain();
}
```

- [ ] **Step 6: Write the type scale**

Create `lib/theme/atlas_typography.dart`:

```dart
import 'dart:ui' show FontFeature;

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
```

- [ ] **Step 7: Verify the scale compiles and the analyzer is clean**

Run: `flutter analyze lib/theme/`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add assets/fonts pubspec.yaml lib/theme/atlas_typography.dart \
        test/flutter_test_config.dart test/theme/font_coverage_test.dart
git commit -m "Bundle Archivo and add the Atlas type scale"
```

---
### Task 5: The theme factories, wired into the app

This is the task where the whole app changes appearance. The 34 `Scaffold`s, 31 `AppBar`s, 31 `SnackBar`s, 27 `Card`s, 27 `ListTile`s, 22 `TextField`s, 22 buttons and 8 `Chip`s restyle from here with no screen edits.

**Files:**
- Create: `lib/theme/atlas_theme.dart`
- Create: `test/theme/atlas_theme_test.dart`
- Modify: `lib/main.dart:141-152`

**Interfaces:**
- Consumes: `AtlasTokens`, `AtlasSpace`, `AtlasRadius` (Task 1); `AtlasColors` (Task 3); `AtlasTypography` (Task 4).
- Produces: `ThemeData buildDarkTheme()` and `ThemeData buildLightTheme()`, both installing `AtlasColors` in `extensions`.

- [ ] **Step 1: Write the failing test**

Create `test/theme/atlas_theme_test.dart`:

```dart
import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:exercise_app/theme/atlas_tokens.dart';
import 'package:exercise_app/theme/atlas_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark theme carries the Atlas extension and chrome', () {
    final theme = buildDarkTheme();
    expect(theme.brightness, Brightness.dark);
    expect(theme.extension<AtlasColors>()!.ink, AtlasTokens.darkInk);
    expect(theme.scaffoldBackgroundColor, AtlasTokens.darkInk);
    expect(theme.useMaterial3, isTrue);
  });

  test('light theme carries the Atlas extension and chrome', () {
    final theme = buildLightTheme();
    expect(theme.brightness, Brightness.light);
    expect(theme.extension<AtlasColors>()!.ink, AtlasTokens.lightInk);
    expect(theme.scaffoldBackgroundColor, AtlasTokens.lightInk);
  });

  test('body text uses Archivo in both schemes', () {
    for (final theme in [buildDarkTheme(), buildLightTheme()]) {
      expect(theme.textTheme.bodyMedium!.fontFamily, AtlasTypography.sans);
      expect(theme.textTheme.titleLarge!.fontFamily, AtlasTypography.expanded);
    }
  });

  test('radius carries role rather than one value everywhere', () {
    final theme = buildDarkTheme();
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect((cardShape.borderRadius as BorderRadius).topLeft.x, 14);

    final sheetShape =
        theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
    expect((sheetShape.borderRadius as BorderRadius).topLeft.x, 24);
    expect((sheetShape.borderRadius as BorderRadius).bottomLeft.x, 0);
  });

  test('dark cards separate by surface step and hairline, not shadow', () {
    final theme = buildDarkTheme();
    expect(theme.cardTheme.color, AtlasTokens.darkSurface);
    expect(theme.cardTheme.elevation, 0);
    final side = (theme.cardTheme.shape! as RoundedRectangleBorder).side;
    expect(side.color, AtlasTokens.darkLine);
  });

  test('light cards use a real shadow and no hairline', () {
    final theme = buildLightTheme();
    expect(theme.cardTheme.elevation, greaterThan(0));
    final side = (theme.cardTheme.shape! as RoundedRectangleBorder).side;
    expect(side.style, BorderStyle.none);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/atlas_theme_test.dart`
Expected: FAIL at compile time — `atlas_theme.dart` does not exist.

- [ ] **Step 3: Write the factories**

Create `lib/theme/atlas_theme.dart`:

```dart
import 'package:flutter/material.dart';

import 'atlas_colors.dart';
import 'atlas_tokens.dart';
import 'atlas_typography.dart';

ThemeData buildDarkTheme() => _build(
      brightness: Brightness.dark,
      atlas: const AtlasColors.dark(),
    );

ThemeData buildLightTheme() => _build(
      brightness: Brightness.light,
      atlas: const AtlasColors.light(),
    );

/// Both schemes share one construction; they differ only in their tokens and
/// in how they separate layers. Dark steps the surface and draws a hairline,
/// because a shadow on `#161A21` reads as grey smudge. Light uses a real
/// shadow.
ThemeData _build({
  required Brightness brightness,
  required AtlasColors atlas,
}) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: atlas.teamFill,
    onPrimary: atlas.teamOnFill,
    secondary: atlas.info,
    onSecondary: const Color(0xFFFFFFFF),
    error: atlas.danger,
    onError: const Color(0xFFFFFFFF),
    surface: atlas.surface,
    onSurface: atlas.textPrimary,
    surfaceContainerHighest: atlas.surfaceRaised,
    onSurfaceVariant: atlas.textMuted,
    outline: atlas.line,
  );

  final textTheme =
      AtlasTypography.textTheme(atlas.textPrimary, atlas.textMuted);

  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AtlasRadius.card),
    side: isDark
        ? BorderSide(color: atlas.line)
        : const BorderSide(style: BorderStyle.none),
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AtlasRadius.field),
    borderSide: BorderSide(color: atlas.line),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: <ThemeExtension<dynamic>>[atlas],
    scaffoldBackgroundColor: atlas.ink,
    canvasColor: atlas.ink,
    dividerColor: atlas.line,
    textTheme: textTheme,
    dividerTheme: DividerThemeData(color: atlas.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: atlas.ink,
      foregroundColor: atlas.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: isDark ? 0 : 2,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: atlas.surface,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 0 : 2,
      shadowColor: isDark ? Colors.transparent : const Color(0x1A171B22),
      margin: const EdgeInsets.symmetric(vertical: AtlasSpace.sm),
      shape: cardShape,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: atlas.textMuted,
      textColor: atlas.textPrimary,
      titleTextStyle: textTheme.bodyLarge,
      subtitleTextStyle: textTheme.bodySmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.card),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? atlas.surface : atlas.ink,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: atlas.teamMark, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: atlas.danger),
      ),
      labelStyle: textTheme.labelMedium,
      hintStyle: textTheme.bodyMedium!.copyWith(color: atlas.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AtlasSpace.lg,
        vertical: AtlasSpace.md,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: atlas.teamFill,
        foregroundColor: atlas.teamOnFill,
        textStyle: textTheme.labelLarge,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: AtlasSpace.xl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.field),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: atlas.textPrimary,
        side: BorderSide(color: atlas.line),
        textStyle: textTheme.labelLarge,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasRadius.field),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: atlas.teamMark,
        textStyle: textTheme.labelLarge,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? atlas.surfaceRaised : atlas.ink,
      side: BorderSide(color: atlas.line),
      labelStyle: textTheme.labelMedium!.copyWith(color: atlas.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.field),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: atlas.surfaceRaised,
      contentTextStyle: textTheme.bodyMedium!.copyWith(
        color: atlas.textPrimary,
      ),
      actionTextColor: atlas.teamMark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.field),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: atlas.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AtlasRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: atlas.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtlasRadius.card),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? atlas.surface : atlas.surface,
      indicatorColor: atlas.teamFill.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: atlas.teamMark,
      linearTrackColor: atlas.line,
    ),
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/theme/atlas_theme_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Wire the factories into the app**

In `lib/main.dart`, add to the import block:

```dart
import 'theme/atlas_theme.dart';
```

Then replace lines 141-152 — the `theme:`, `darkTheme:` and `themeMode:` arguments — with:

```dart
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: settings.themeMode,
```

- [ ] **Step 6: Verify the app still builds and the suite still passes**

Run: `flutter analyze lib/`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS. If `test/account_ui_test.dart` or `test/widget_test.dart` fail on a colour or font expectation, update those expectations to the new tokens — do not revert the theme.

- [ ] **Step 7: Commit**

```bash
git add lib/theme/atlas_theme.dart test/theme/atlas_theme_test.dart lib/main.dart
git commit -m "Replace the seeded Material theme with the Atlas theme factories"
```

---

### Task 6: Replace hardcoded colours in snackbars and destructive controls

Twelve of the 44 hardcoded sites are `SnackBar` backgrounds and destructive `FilledButton` fills. They are grouped here because they share a fix: a snackbar's tone comes from its content colour, not from repainting the whole bar.

**Files:**
- Modify: `lib/screens/create_team_screen.dart:40,63,75`
- Modify: `lib/screens/join_team_screen.dart:42,62,82`
- Modify: `lib/screens/team_detail_screen.dart:98,144`
- Modify: `lib/screens/settings_screen.dart:73,171,245,464`
- Modify: `lib/services/deep_link_service.dart:147`
- Create: `test/theme/no_hardcoded_colors_test.dart`

**Interfaces:**
- Consumes: `context.atlas` (Task 3).
- Produces: nothing other tasks depend on.

- [ ] **Step 1: Write the failing guard test**

This is the test that keeps the cleanup from silently regressing. It scans source rather than behaviour, which is the only way to assert a negative across 30 screens.

Create `test/theme/no_hardcoded_colors_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens and services must take colour from the theme, never from the
/// Material palette constants. `lib/theme/` is exempt: it is where colour is
/// allowed to be literal.
void main() {
  test('no Colors.<name> constants outside lib/theme', () {
    final offenders = <String>[];
    final pattern = RegExp(
      r'Colors\.(red|green|orange|amber|deepOrange|deepPurple|grey|blue|yellow|pink|purple|teal|indigo|lime|cyan|brown)\b',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalised = entity.path.replaceAll(r'\', '/');
      if (normalised.startsWith('lib/theme/')) continue;
      if (normalised.startsWith('lib/l10n/')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('$normalised:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'Hardcoded palette colours found:\n${offenders.join("\n")}');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/no_hardcoded_colors_test.dart`
Expected: FAIL listing 42 offending lines across `lib/screens/` and `lib/services/`. (`lib/main.dart`'s two `Colors.deepPurple` lines are already gone after Task 5.)

- [ ] **Step 3: Fix the snackbar sites**

Every one of these follows the same shape. In `lib/screens/create_team_screen.dart`, `join_team_screen.dart`, `team_detail_screen.dart` and `lib/services/deep_link_service.dart`, replace `backgroundColor: Colors.red` with the danger token and `backgroundColor: Colors.green` with the success token.

Add to each file's imports:

```dart
import '../theme/atlas_colors.dart';
```

For `lib/services/deep_link_service.dart` the relative path is the same (`../theme/atlas_colors.dart`).

Then, at each site, change:

```dart
        SnackBar(content: Text(text), backgroundColor: Colors.red),
```

to:

```dart
        SnackBar(
          content: Text(text),
          backgroundColor: context.atlas.danger,
        ),
```

and the `Colors.green` sites to `context.atlas.success`.

In `deep_link_service.dart:147` the surrounding method must already hold a `BuildContext` to show a snackbar; use that context. If the context there is named something other than `context`, substitute the local name.

- [ ] **Step 4: Fix the destructive button sites**

In `lib/screens/settings_screen.dart` at lines 73, 171, 245 and 464, replace:

```dart
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
```

with:

```dart
            style: FilledButton.styleFrom(
              backgroundColor: context.atlas.danger,
              foregroundColor: const Color(0xFFFFFFFF),
            ),
```

The explicit foreground is needed because the theme's `filledButtonTheme` sets the team foreground, which is not guaranteed to read on the danger fill.

Add the import to `settings_screen.dart`:

```dart
import '../theme/atlas_colors.dart';
```

- [ ] **Step 5: Run the guard test**

Run: `flutter test test/theme/no_hardcoded_colors_test.dart`
Expected: FAIL still, but the offender list is now down to the icon and text sites handled in Task 7. Confirm no `create_team_screen.dart`, `join_team_screen.dart`, `deep_link_service.dart` or `settings_screen.dart` button lines remain in the list. `settings_screen.dart:446` and `:449` are icon and text sites and stay for Task 7.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/create_team_screen.dart lib/screens/join_team_screen.dart \
        lib/screens/team_detail_screen.dart lib/screens/settings_screen.dart \
        lib/services/deep_link_service.dart test/theme/no_hardcoded_colors_test.dart
git commit -m "Take snackbar and destructive button colour from the theme"
```

---

### Task 7: Replace the remaining hardcoded colours

The other 30 sites are icon tints and text colours carrying sync, completion and warning meaning.

**Files:**
- Modify: `lib/screens/active_workout_screen.dart:362`
- Modify: `lib/screens/calendar_screen.dart:192,214,224`
- Modify: `lib/screens/dashboard_screen.dart:137,173,175`
- Modify: `lib/screens/pending_suggestions_screen.dart:125,127,128,156,324`
- Modify: `lib/screens/profile_stats_screen.dart:290`
- Modify: `lib/screens/program_detail_screen.dart:232,234`
- Modify: `lib/screens/social_feed_screen.dart:191,203,204`
- Modify: `lib/screens/team_detail_screen.dart:74,120,180,244`
- Modify: `lib/screens/team_leaderboard_screen.dart:216,312,319`
- Modify: `lib/screens/workouts_screen.dart:263`
- Modify: `lib/screens/onboarding_name_screen.dart:58`
- Modify: `lib/screens/settings_screen.dart:446,449`

**Interfaces:**
- Consumes: `context.atlas` (Task 3).
- Produces: nothing other tasks depend on.

- [ ] **Step 1: Apply the mapping**

Add `import '../theme/atlas_colors.dart';` to each file above that does not already have it, then substitute by meaning, not by hue:

| Was | Becomes | Why |
|---|---|---|
| `Colors.green` (completed, done, trending up) | `context.atlas.success` | Completion |
| `Colors.orange` (pending, scheduled, warning) | `context.atlas.warn` | Unfinished state |
| `Colors.red` (blocked, rejected, destructive text) | `context.atlas.danger` | Destructive or failed |
| `Colors.amber` (achievement, trophy) | `context.atlas.warn` | Achievement is a highlight, not an error |
| `Colors.deepOrange` (streak flame, `dashboard_screen.dart:137`) | `context.atlas.warn` | Same highlight role |
| `Colors.grey` (muted caption text) | `context.atlas.textMuted` | Not a status at all |
| `Colors.deepPurple` (`onboarding_name_screen.dart:58`) | `context.atlas.teamMark` | The old seed colour; becomes the accent |
| `Colors.grey` as `selectionColor` (`team_detail_screen.dart:244`) | `context.atlas.line` | A surface mark |

Two sites need more than a swap:

`lib/screens/pending_suggestions_screen.dart:125-128` is a conditional chain. Rewrite it as:

```dart
    final statusColor = suggestion.isApproved
        ? context.atlas.success
        : suggestion.isRejected
            ? context.atlas.danger
            : context.atlas.warn;
```

Keep the existing condition expressions exactly as they are in the file; only the three colour values change.

`lib/screens/dashboard_screen.dart:175` and `lib/screens/program_detail_screen.dart:234` use `const TextStyle(color: Colors.green)`. The `const` must go, since `context.atlas` is not a constant:

```dart
                Text(
                  l10n.dashboardCompletedLabel,
                  style: TextStyle(color: context.atlas.success),
                ),
```

Likewise `lib/screens/social_feed_screen.dart:204` and `settings_screen.dart:449` drop `const` for the danger colour. `social_feed_screen.dart:204` also carries a hardcoded English string `'Block $userName'`; leave it as-is here so this task stays a colour change, and note it as pre-existing l10n debt.

- [ ] **Step 2: Run the guard test**

Run: `flutter test test/theme/no_hardcoded_colors_test.dart`
Expected: PASS, 1 test, empty offender list.

- [ ] **Step 3: Run the analyzer and the whole suite**

Run: `flutter analyze lib/`
Expected: `No issues found!` A `prefer_const_constructors` warning on a widget you just de-consted means a parent still marked `const`; remove that too.

Run: `flutter test`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/screens lib/services
git commit -m "Take every status colour from the Atlas tokens"
```

---
### Task 8: TeamTheme and TeamCrest

`TeamTheme` is the interface that keeps the component layer independent: it overrides the team fields of `AtlasColors` for a subtree, so no component ever imports `TeamProvider`.

**Files:**
- Create: `lib/widgets/atlas/team_theme.dart`
- Create: `lib/widgets/atlas/team_crest.dart`
- Create: `test/widgets/atlas/harness.dart`
- Create: `test/widgets/atlas/team_theme_test.dart`
- Create: `test/widgets/atlas/team_crest_test.dart`

**Interfaces:**
- Consumes: `AtlasColors`, `context.atlas` (Task 3); `KitColor`, `swatchOf` (Task 2); `buildDarkTheme`, `buildLightTheme` (Task 5).
- Produces: `class TeamTheme extends StatelessWidget` with `const TeamTheme({super.key, required KitColor kit, required Widget child})`; `enum CrestSize { small, medium, large }`; `class TeamCrest extends StatelessWidget` with `const TeamCrest({super.key, required String teamName, CrestSize size = CrestSize.medium})` and `static double diameterOf(CrestSize size)`; test helper `Future<void> pumpAtlas(WidgetTester tester, Widget child, {Brightness brightness = Brightness.dark})`.

- [ ] **Step 1: Write the test harness**

Create `test/widgets/atlas/harness.dart`:

```dart
import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget inside a real Atlas theme, centred on the scheme
/// background, so goldens show the component as it actually ships.
Future<void> pumpAtlas(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  Size surfaceSize = const Size(390, 300),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark
          ? buildDarkTheme()
          : buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

- [ ] **Step 2: Write the failing tests**

Create `test/widgets/atlas/team_theme_test.dart`:

```dart
import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('overrides the team fields for its subtree', (tester) async {
    late AtlasColors inside;
    await pumpAtlas(
      tester,
      TeamTheme(
        kit: KitColor.claret,
        child: Builder(
          builder: (context) {
            inside = context.atlas;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final claret = swatchOf(KitColor.claret);
    expect(inside.teamFill, claret.fill);
    expect(inside.teamOnFill, claret.onFill);
    expect(inside.teamMark, claret.darkMark);
  });

  testWidgets('picks the light mark under a light theme', (tester) async {
    late AtlasColors inside;
    await pumpAtlas(
      tester,
      TeamTheme(
        kit: KitColor.royal,
        child: Builder(
          builder: (context) {
            inside = context.atlas;
            return const SizedBox.shrink();
          },
        ),
      ),
      brightness: Brightness.light,
    );
    expect(inside.teamMark, swatchOf(KitColor.royal).lightMark);
  });

  testWidgets('leaves the status hues untouched', (tester) async {
    late AtlasColors inside;
    await pumpAtlas(
      tester,
      TeamTheme(
        kit: KitColor.gold,
        child: Builder(
          builder: (context) {
            inside = context.atlas;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(inside.success, const AtlasColors.dark().success);
    expect(inside.ink, const AtlasColors.dark().ink);
  });
}
```

Create `test/widgets/atlas/team_crest_test.dart`:

```dart
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/team_crest.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('shows the first letter of the team name', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.forest,
        child: TeamCrest(teamName: 'Kadıköy Barbell'),
      ),
    );
    expect(find.text('K'), findsOneWidget);
  });

  testWidgets('uses the kit fill and its paired foreground', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.gold,
        child: TeamCrest(teamName: 'Atlas'),
      ),
    );
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(TeamCrest),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, swatchOf(KitColor.gold).fill);
    expect(decoration.shape, BoxShape.circle);

    final text = tester.widget<Text>(find.text('A'));
    expect(text.style!.color, swatchOf(KitColor.gold).onFill);
  });

  testWidgets('falls back to a neutral mark for an empty name',
      (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.steel,
        child: TeamCrest(teamName: '   '),
      ),
    );
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('sizes follow the declared diameters', (tester) async {
    for (final size in CrestSize.values) {
      await pumpAtlas(
        tester,
        TeamTheme(
          kit: KitColor.teal,
          child: TeamCrest(teamName: 'Atlas', size: size),
        ),
      );
      final box = tester.getSize(find.byType(TeamCrest));
      expect(box.width, TeamCrest.diameterOf(size));
      expect(box.height, TeamCrest.diameterOf(size));
    }
  });

  testWidgets('golden: crest in dark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.claret,
        child: TeamCrest(teamName: 'Atlas', size: CrestSize.large),
      ),
      surfaceSize: const Size(200, 200),
    );
    await expectLater(
      find.byType(TeamCrest),
      matchesGoldenFile('goldens/team_crest_dark.png'),
    );
  });

  testWidgets('golden: crest in light', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.claret,
        child: TeamCrest(teamName: 'Atlas', size: CrestSize.large),
      ),
      brightness: Brightness.light,
      surfaceSize: const Size(200, 200),
    );
    await expectLater(
      find.byType(TeamCrest),
      matchesGoldenFile('goldens/team_crest_light.png'),
    );
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/widgets/atlas/`
Expected: FAIL at compile time — neither widget exists.

- [ ] **Step 4: Write TeamTheme**

Create `lib/widgets/atlas/team_theme.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/team_palette.dart';

/// Scopes a team's kit colour to a subtree.
///
/// This is the whole interface between team data and the component layer.
/// Wrap a team screen in it and every Atlas component inside picks up the
/// right colour; components read `context.atlas.teamFill` and never learn
/// where the team came from.
class TeamTheme extends StatelessWidget {
  const TeamTheme({super.key, required this.kit, required this.child});

  final KitColor kit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = swatchOf(kit);
    final atlas = theme.extension<AtlasColors>()!.copyWith(
          teamFill: swatch.fill,
          teamOnFill: swatch.onFill,
          teamMark: swatch.markFor(theme.brightness),
        );
    return Theme(
      data: theme.copyWith(
        extensions: <ThemeExtension<dynamic>>[atlas],
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 5: Write TeamCrest**

Create `lib/widgets/atlas/team_crest.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_typography.dart';

enum CrestSize { small, medium, large }

/// A team's initial on its kit colour.
///
/// The letter is not decoration: the spec forbids colour from being the only
/// carrier of team identity, so the crest always states the initial and
/// callers place the full name beside it.
class TeamCrest extends StatelessWidget {
  const TeamCrest({
    super.key,
    required this.teamName,
    this.size = CrestSize.medium,
  });

  final String teamName;
  final CrestSize size;

  static double diameterOf(CrestSize size) => switch (size) {
        CrestSize.small => 28,
        CrestSize.medium => 40,
        CrestSize.large => 64,
      };

  static double _fontSizeOf(CrestSize size) => switch (size) {
        CrestSize.small => 13,
        CrestSize.medium => 18,
        CrestSize.large => 28,
      };

  /// The first character of the trimmed name, or `?` when there is none.
  /// Deliberately not upper-cased: `toUpperCase()` turns Turkish `i` into
  /// `I` rather than `İ`.
  String get _initial {
    final trimmed = teamName.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final diameter = diameterOf(size);
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: atlas.teamFill,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initial,
        style: AtlasTypography.title.copyWith(
          color: atlas.teamOnFill,
          fontSize: _fontSizeOf(size),
          height: 1,
        ),
      ),
    );
  }
}
```

`characters.first` needs `import 'package:flutter/material.dart';` only — `characters` is re-exported by the Flutter SDK. If the analyzer disagrees, add `import 'package:characters/characters.dart';`.

- [ ] **Step 6: Generate the goldens and run the tests**

Run: `flutter test test/widgets/atlas/ --update-goldens`
Then run: `flutter test test/widgets/atlas/`
Expected: PASS, 9 tests. Inspect `test/widgets/atlas/goldens/team_crest_dark.png` by eye before committing — a golden nobody looked at is a rubber stamp. The letter must be Archivo Expanded, not the fallback face.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/atlas/team_theme.dart lib/widgets/atlas/team_crest.dart \
        test/widgets/atlas/
git commit -m "Add TeamTheme and TeamCrest"
```

---

### Task 9: StatusMark

**Files:**
- Create: `lib/widgets/atlas/status_mark.dart`
- Create: `test/widgets/atlas/status_mark_test.dart`

**Interfaces:**
- Consumes: `context.atlas` (Task 3); `AtlasSpace` (Task 1); `pumpAtlas` (Task 8).
- Produces: `enum AtlasStatus { success, warn, danger, info }`; `class StatusMark extends StatelessWidget` with `const StatusMark({super.key, required AtlasStatus status, required String label, IconData? icon})` and `static Color colorOf(BuildContext context, AtlasStatus status)`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/atlas/status_mark_test.dart`:

```dart
import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/widgets/atlas/status_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('each status resolves to its token', (tester) async {
    late BuildContext ctx;
    await pumpAtlas(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        },
      ),
    );
    final atlas = ctx.atlas;
    expect(StatusMark.colorOf(ctx, AtlasStatus.success), atlas.success);
    expect(StatusMark.colorOf(ctx, AtlasStatus.warn), atlas.warn);
    expect(StatusMark.colorOf(ctx, AtlasStatus.danger), atlas.danger);
    expect(StatusMark.colorOf(ctx, AtlasStatus.info), atlas.info);
  });

  testWidgets('shows a dot when no icon is given', (tester) async {
    await pumpAtlas(
      tester,
      const StatusMark(status: AtlasStatus.warn, label: 'Not synced'),
    );
    expect(find.text('Not synced'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('shows the icon when one is given', (tester) async {
    await pumpAtlas(
      tester,
      const StatusMark(
        status: AtlasStatus.success,
        label: 'Synced',
        icon: Icons.check_circle,
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
    expect(icon.size, 16);
  });

  testWidgets('label is never upper-cased', (tester) async {
    await pumpAtlas(
      tester,
      const StatusMark(status: AtlasStatus.info, label: 'İstanbul kaydı'),
    );
    expect(find.text('İstanbul kaydı'), findsOneWidget);
  });

  testWidgets('golden: all four statuses in dark', (tester) async {
    await pumpAtlas(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusMark(
              status: AtlasStatus.success,
              label: 'Synced',
              icon: Icons.check_circle),
          SizedBox(height: 8),
          StatusMark(status: AtlasStatus.warn, label: 'Not synced'),
          SizedBox(height: 8),
          StatusMark(status: AtlasStatus.danger, label: 'Sync failed'),
          SizedBox(height: 8),
          StatusMark(status: AtlasStatus.info, label: '3 conflicts'),
        ],
      ),
      surfaceSize: const Size(300, 220),
    );
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/status_mark_dark.png'),
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/atlas/status_mark_test.dart`
Expected: FAIL at compile time — `status_mark.dart` does not exist.

- [ ] **Step 3: Write StatusMark**

Create `lib/widgets/atlas/status_mark.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';

enum AtlasStatus { success, warn, danger, info }

/// A small coloured mark with its meaning spelled out beside it.
///
/// Status colour only ever appears at this scale — a dot or a 16dp icon and a
/// line of text — so it never competes with a team's kit colour, which only
/// fills large fields.
class StatusMark extends StatelessWidget {
  const StatusMark({
    super.key,
    required this.status,
    required this.label,
    this.icon,
  });

  final AtlasStatus status;
  final String label;
  final IconData? icon;

  static Color colorOf(BuildContext context, AtlasStatus status) {
    final atlas = context.atlas;
    return switch (status) {
      AtlasStatus.success => atlas.success,
      AtlasStatus.warn => atlas.warn,
      AtlasStatus.danger => atlas.danger,
      AtlasStatus.info => atlas.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorOf(context, status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 16, color: color)
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: AtlasSpace.sm),
        Flexible(
          child: Text(
            label,
            style: AtlasTypography.label.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Generate the golden and run the tests**

Run: `flutter test test/widgets/atlas/status_mark_test.dart --update-goldens`
Then run: `flutter test test/widgets/atlas/status_mark_test.dart`
Expected: PASS, 5 tests. Check the golden shows four distinguishable hues against `#161A21`.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/atlas/status_mark.dart test/widgets/atlas/status_mark_test.dart \
        test/widgets/atlas/goldens/status_mark_dark.png
git commit -m "Add StatusMark"
```

---
### Task 10: StatTile

**Files:**
- Create: `lib/widgets/atlas/stat_tile.dart`
- Create: `test/widgets/atlas/stat_tile_test.dart`

**Interfaces:**
- Consumes: `context.atlas` (Task 3); `AtlasSpace`, `AtlasRadius` (Task 1); `AtlasTypography` (Task 4); `pumpAtlas` (Task 8).
- Produces: `class StatTile extends StatelessWidget` with `const StatTile({super.key, required String value, required String label, String? unit, IconData? icon})`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/atlas/stat_tile_test.dart`:

```dart
import 'dart:ui' show FontFeature;

import 'package:exercise_app/widgets/atlas/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('shows value, unit and label', (tester) async {
    await pumpAtlas(
      tester,
      const StatTile(value: '1 240', label: 'Weekly volume', unit: 'kg'),
    );
    expect(find.text('1 240'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('Weekly volume'), findsOneWidget);
  });

  testWidgets('the number uses tabular figures', (tester) async {
    await pumpAtlas(
      tester,
      const StatTile(value: '1 240', label: 'Weekly volume'),
    );
    final text = tester.widget<Text>(find.text('1 240'));
    expect(
      text.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('the label is muted, the value is not', (tester) async {
    late BuildContext ctx;
    await pumpAtlas(
      tester,
      Builder(builder: (context) {
        ctx = context;
        return const StatTile(value: '7', label: 'Day streak');
      }),
    );
    expect(tester.widget<Text>(find.text('Day streak')).style!.color,
        ctx.atlas.textMuted);
    expect(tester.widget<Text>(find.text('7')).style!.color,
        ctx.atlas.textPrimary);
  });

  testWidgets('golden: stat tile in dark', (tester) async {
    await pumpAtlas(
      tester,
      const SizedBox(
        width: 180,
        child: StatTile(
          value: '1 240',
          label: 'Weekly volume',
          unit: 'kg',
          icon: Icons.local_fire_department,
        ),
      ),
      surfaceSize: const Size(240, 200),
    );
    await expectLater(
      find.byType(StatTile),
      matchesGoldenFile('goldens/stat_tile_dark.png'),
    );
  });

  testWidgets('golden: stat tile in light', (tester) async {
    await pumpAtlas(
      tester,
      const SizedBox(
        width: 180,
        child: StatTile(value: '1 240', label: 'Weekly volume', unit: 'kg'),
      ),
      brightness: Brightness.light,
      surfaceSize: const Size(240, 200),
    );
    await expectLater(
      find.byType(StatTile),
      matchesGoldenFile('goldens/stat_tile_light.png'),
    );
  });
}
```

Add `import 'package:exercise_app/theme/atlas_colors.dart';` to that file for `ctx.atlas`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/atlas/stat_tile_test.dart`
Expected: FAIL at compile time — `stat_tile.dart` does not exist.

- [ ] **Step 3: Write StatTile**

Create `lib/widgets/atlas/stat_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';

/// One number, stated plainly, with the thing it measures underneath.
///
/// The unit sits on the baseline beside the figure rather than inside it, so
/// the number itself stays a single tabular run and columns of tiles line up.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.icon,
  });

  final String value;
  final String label;
  final String? unit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AtlasSpace.lg),
      decoration: BoxDecoration(
        color: atlas.surface,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
        border: isDark ? Border.all(color: atlas.line) : null,
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1A171B22),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: atlas.teamMark),
            const SizedBox(height: AtlasSpace.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtlasTypography.display.copyWith(
                    color: atlas.textPrimary,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AtlasSpace.sm),
                Text(
                  unit!,
                  style: AtlasTypography.label.copyWith(
                    color: atlas.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AtlasSpace.xs),
          Text(
            label,
            style: AtlasTypography.label.copyWith(color: atlas.textMuted),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Generate the goldens and run the tests**

Run: `flutter test test/widgets/atlas/stat_tile_test.dart --update-goldens`
Then run: `flutter test test/widgets/atlas/stat_tile_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/atlas/stat_tile.dart test/widgets/atlas/stat_tile_test.dart \
        test/widgets/atlas/goldens/stat_tile_dark.png \
        test/widgets/atlas/goldens/stat_tile_light.png
git commit -m "Add StatTile"
```

---

### Task 11: TeamHeader

This is where the design spends its boldness: a saturated kit-colour field carrying the team's name and crest. Everything around it stays graphite so this lands.

**Files:**
- Create: `lib/widgets/atlas/team_header.dart`
- Create: `test/widgets/atlas/team_header_test.dart`

**Interfaces:**
- Consumes: `TeamCrest`, `CrestSize` (Task 8); `context.atlas`; `AtlasSpace`, `AtlasRadius`; `AtlasTypography`; `pumpAtlas`.
- Produces: `class TeamHeader extends StatelessWidget` with `const TeamHeader({super.key, required String teamName, required String memberSummary, String? description})`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/atlas/team_header_test.dart`:

```dart
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/team_crest.dart';
import 'package:exercise_app/widgets/atlas/team_header.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('states the name and the member summary beside the crest',
      (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.violet,
        child: TeamHeader(
          teamName: 'Kadıköy Barbell',
          memberSummary: '12 members',
        ),
      ),
      surfaceSize: const Size(390, 260),
    );
    expect(find.text('Kadıköy Barbell'), findsOneWidget);
    expect(find.text('12 members'), findsOneWidget);
    expect(find.byType(TeamCrest), findsOneWidget);
  });

  testWidgets('fills with the kit fill, not the mark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.violet,
        child: TeamHeader(teamName: 'Atlas', memberSummary: '3 members'),
      ),
      surfaceSize: const Size(390, 260),
    );
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(TeamHeader),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, swatchOf(KitColor.violet).fill);
  });

  testWidgets('shows the description only when given', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.teal,
        child: TeamHeader(
          teamName: 'Atlas',
          memberSummary: '3 members',
          description: 'Tuesday and Thursday, 19:00',
        ),
      ),
      surfaceSize: const Size(390, 280),
    );
    expect(find.text('Tuesday and Thursday, 19:00'), findsOneWidget);
  });

  testWidgets('golden: team header in dark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.crimson,
        child: TeamHeader(
          teamName: 'Kadıköy Barbell',
          memberSummary: '12 members',
          description: 'Tuesday and Thursday, 19:00',
        ),
      ),
      surfaceSize: const Size(390, 300),
    );
    await expectLater(
      find.byType(TeamHeader),
      matchesGoldenFile('goldens/team_header_dark.png'),
    );
  });

  testWidgets('golden: team header in light', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.crimson,
        child: TeamHeader(
          teamName: 'Kadıköy Barbell',
          memberSummary: '12 members',
          description: 'Tuesday and Thursday, 19:00',
        ),
      ),
      brightness: Brightness.light,
      surfaceSize: const Size(390, 300),
    );
    await expectLater(
      find.byType(TeamHeader),
      matchesGoldenFile('goldens/team_header_light.png'),
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/atlas/team_header_test.dart`
Expected: FAIL at compile time — `team_header.dart` does not exist.

- [ ] **Step 3: Write TeamHeader**

Create `lib/widgets/atlas/team_header.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import 'team_crest.dart';

/// The team's colour, stated at full strength.
///
/// The header is the one loud surface in the app. It uses the kit fill and
/// its paired foreground, which the palette guarantees clears 4.5:1, so text
/// here needs no extra scrim.
class TeamHeader extends StatelessWidget {
  const TeamHeader({
    super.key,
    required this.teamName,
    required this.memberSummary,
    this.description,
  });

  final String teamName;
  final String memberSummary;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: atlas.teamFill,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // A crest on a same-coloured field needs separating from it,
              // so it wears a ring in the header's own foreground.
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: atlas.teamOnFill.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: TeamCrest(
                  teamName: teamName,
                  size: CrestSize.large,
                ),
              ),
              const SizedBox(width: AtlasSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamName,
                      style: AtlasTypography.title.copyWith(
                        color: atlas.teamOnFill,
                      ),
                    ),
                    const SizedBox(height: AtlasSpace.xs),
                    Text(
                      memberSummary,
                      style: AtlasTypography.label.copyWith(
                        color: atlas.teamOnFill.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AtlasSpace.lg),
            Text(
              description!,
              style: AtlasTypography.body.copyWith(
                color: atlas.teamOnFill.withValues(alpha: 0.82),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

The crest sits on a field of its own fill colour, which is why it wears the ring: without it the circle would disappear into the header. The ring uses the header's foreground at reduced alpha rather than a new token, so it follows whatever kit the team wears.

- [ ] **Step 4: Generate the goldens and run the tests**

Run: `flutter test test/widgets/atlas/team_header_test.dart --update-goldens`
Then run: `flutter test test/widgets/atlas/team_header_test.dart`
Expected: PASS, 5 tests. If the "fills with the kit fill" test matches the crest's container instead of the header's, the `.first` finder is picking the wrong `Container`; change it to match on the widget whose decoration colour is non-null and whose `borderRadius` is set.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/atlas/team_header.dart test/widgets/atlas/team_header_test.dart \
        test/widgets/atlas/goldens/team_header_dark.png \
        test/widgets/atlas/goldens/team_header_light.png
git commit -m "Add TeamHeader"
```

---

### Task 12: LeaderboardRow and the one animated moment

**Files:**
- Create: `lib/widgets/atlas/leaderboard_row.dart`
- Create: `test/widgets/atlas/leaderboard_row_test.dart`

**Interfaces:**
- Consumes: `TeamCrest`, `CrestSize` (Task 8); `context.atlas`; `AtlasSpace`, `AtlasRadius`, `AtlasMotion`; `AtlasTypography`; `pumpAtlas`.
- Produces: `class LeaderboardEntry` with `const LeaderboardEntry({required String id, required String name, required String metric})`; `class LeaderboardRow extends StatelessWidget` with `const LeaderboardRow({super.key, required int rank, required LeaderboardEntry entry, bool isViewer = false})`; `class AnimatedLeaderboard extends StatelessWidget` with `const AnimatedLeaderboard({super.key, required List<LeaderboardEntry> entries, String? viewerId})` and `static const double rowHeight = 72`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/atlas/leaderboard_row_test.dart`:

```dart
import 'dart:ui' show FontFeature;

import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/leaderboard_row.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _entries = <LeaderboardEntry>[
  LeaderboardEntry(id: 'a', name: 'Deniz', metric: '4 210 kg'),
  LeaderboardEntry(id: 'b', name: 'Mert', metric: '3 980 kg'),
  LeaderboardEntry(id: 'c', name: 'Ayşe', metric: '3 640 kg'),
];

void main() {
  testWidgets('a row states rank, name and metric', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: LeaderboardRow(rank: 2, entry: _entries[1]),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Mert'), findsOneWidget);
    expect(find.text('3 980 kg'), findsOneWidget);
  });

  testWidgets('rank and metric both use tabular figures', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: LeaderboardRow(rank: 2, entry: _entries[1]),
      ),
    );
    for (final label in ['2', '3 980 kg']) {
      expect(
        tester.widget<Text>(find.text(label)).style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: '$label is not tabular',
      );
    }
  });

  testWidgets('the viewer row carries the kit rail', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.forest,
        child: LeaderboardRow(rank: 1, entry: _entries[0], isViewer: true),
      ),
    );
    final rail = tester.widget<Container>(
      find.byKey(const ValueKey('leaderboard-rail')),
    );
    expect((rail.decoration! as BoxDecoration).color,
        swatchOf(KitColor.forest).darkMark);
  });

  testWidgets('a non-viewer row has no rail', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.forest,
        child: LeaderboardRow(rank: 3, entry: _entries[2]),
      ),
    );
    expect(find.byKey(const ValueKey('leaderboard-rail')), findsNothing);
  });

  testWidgets('rows move to new positions when the order changes',
      (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: AnimatedLeaderboard(entries: _entries),
      ),
      surfaceSize: const Size(390, 320),
    );
    final before = tester.getTopLeft(find.text('Mert')).dy;

    const reordered = <LeaderboardEntry>[
      LeaderboardEntry(id: 'b', name: 'Mert', metric: '4 400 kg'),
      LeaderboardEntry(id: 'a', name: 'Deniz', metric: '4 210 kg'),
      LeaderboardEntry(id: 'c', name: 'Ayşe', metric: '3 640 kg'),
    ];
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: AnimatedLeaderboard(entries: reordered),
      ),
      surfaceSize: const Size(390, 320),
    );
    final after = tester.getTopLeft(find.text('Mert')).dy;
    expect(after, lessThan(before));
  });

  testWidgets('reduced motion removes the animation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: const Scaffold(
            body: TeamTheme(
              kit: KitColor.royal,
              child: AnimatedLeaderboard(entries: _entries),
            ),
          ),
          theme: buildDarkTheme(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned).first,
    );
    expect(positioned.duration, Duration.zero);
  });

  testWidgets('golden: leaderboard in dark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.crimson,
        child: AnimatedLeaderboard(entries: _entries, viewerId: 'b'),
      ),
      surfaceSize: const Size(390, 320),
    );
    await expectLater(
      find.byType(AnimatedLeaderboard),
      matchesGoldenFile('goldens/leaderboard_dark.png'),
    );
  });
}
```

The reduced-motion test builds its own `MaterialApp` rather than using `pumpAtlas`, because it needs to inject a `MediaQuery` above the app. It still uses the real theme, so add `import 'package:exercise_app/theme/atlas_theme.dart';` to the file.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/atlas/leaderboard_row_test.dart`
Expected: FAIL at compile time — `leaderboard_row.dart` does not exist.

- [ ] **Step 3: Write the row and the list**

Create `lib/widgets/atlas/leaderboard_row.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import 'team_crest.dart';

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.metric,
  });

  final String id;
  final String name;
  final String metric;
}

/// A results line: the placing, who earned it, and the number that did.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.entry,
    this.isViewer = false,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isViewer;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return Row(
      children: [
        if (isViewer)
          Container(
            key: const ValueKey('leaderboard-rail'),
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: atlas.teamMark,
              borderRadius: BorderRadius.circular(AtlasRadius.rail),
            ),
          )
        else
          const SizedBox(width: 4),
        const SizedBox(width: AtlasSpace.lg),
        SizedBox(
          width: 44,
          child: Text(
            '$rank',
            textAlign: TextAlign.right,
            style: AtlasTypography.display.copyWith(
              fontSize: 28,
              color: isViewer ? atlas.teamMark : atlas.textMuted,
            ),
          ),
        ),
        const SizedBox(width: AtlasSpace.lg),
        TeamCrest(teamName: entry.name, size: CrestSize.small),
        const SizedBox(width: AtlasSpace.md),
        Expanded(
          child: Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtlasTypography.body.copyWith(color: atlas.textPrimary),
          ),
        ),
        Text(
          entry.metric,
          style: AtlasTypography.numeric(AtlasTypography.label).copyWith(
            color: atlas.textPrimary,
          ),
        ),
        const SizedBox(width: AtlasSpace.lg),
      ],
    );
  }
}

/// The app's one piece of ambient motion.
///
/// Rows are positioned by index and animate when that index changes, so a
/// refresh that moves someone up the table shows the move rather than
/// redrawing silently. Nothing else in the app animates on its own.
class AnimatedLeaderboard extends StatelessWidget {
  const AnimatedLeaderboard({
    super.key,
    required this.entries,
    this.viewerId,
  });

  final List<LeaderboardEntry> entries;
  final String? viewerId;

  static const double rowHeight = 72;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: entries.length * rowHeight,
      child: Stack(
        children: [
          for (var i = 0; i < entries.length; i++)
            AnimatedPositioned(
              key: ValueKey(entries[i].id),
              duration: reduceMotion ? Duration.zero : AtlasMotion.reorder,
              curve: AtlasMotion.reorderCurve,
              top: i * rowHeight,
              left: 0,
              right: 0,
              height: rowHeight,
              child: LeaderboardRow(
                rank: i + 1,
                entry: entries[i],
                isViewer: entries[i].id == viewerId,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Generate the golden and run the tests**

Run: `flutter test test/widgets/atlas/leaderboard_row_test.dart --update-goldens`
Then run: `flutter test test/widgets/atlas/leaderboard_row_test.dart`
Expected: PASS, 7 tests. Open `goldens/leaderboard_dark.png` and check the three metric figures form a straight right-hand column — if they do not, tabular figures are not reaching the metric style.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/atlas/leaderboard_row.dart \
        test/widgets/atlas/leaderboard_row_test.dart \
        test/widgets/atlas/goldens/leaderboard_dark.png
git commit -m "Add LeaderboardRow and the animated reorder"
```

---

### Task 13: FeedItem

**Files:**
- Create: `lib/widgets/atlas/feed_item.dart`
- Create: `test/widgets/atlas/feed_item_test.dart`

**Interfaces:**
- Consumes: `TeamCrest`, `CrestSize` (Task 8); `context.atlas`; `AtlasSpace`, `AtlasRadius`; `AtlasTypography`; `pumpAtlas`.
- Produces: `class FeedItem extends StatelessWidget` with `const FeedItem({super.key, required String actor, required String action, String? metric, required String timestamp, VoidCallback? onTap})`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/atlas/feed_item_test.dart`:

```dart
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/feed_item.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('states actor, action, metric and time', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'finished Upper body A',
          metric: '4 210 kg',
          timestamp: '2 hours ago',
        ),
      ),
    );
    expect(find.text('Deniz'), findsOneWidget);
    expect(find.text('finished Upper body A'), findsOneWidget);
    expect(find.text('4 210 kg'), findsOneWidget);
    expect(find.text('2 hours ago'), findsOneWidget);
  });

  testWidgets('the spine takes the kit mark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.claret,
        child: FeedItem(
          actor: 'Deniz',
          action: 'finished Upper body A',
          timestamp: '2 hours ago',
        ),
      ),
    );
    final spine = tester.widget<Container>(
      find.byKey(const ValueKey('feed-spine')),
    );
    expect((spine.decoration! as BoxDecoration).color,
        swatchOf(KitColor.claret).darkMark);
  });

  testWidgets('omits the metric row when there is no metric',
      (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'joined the team',
          timestamp: 'just now',
        ),
      ),
    );
    expect(find.byKey(const ValueKey('feed-metric')), findsNothing);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var taps = 0;
    await pumpAtlas(
      tester,
      TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'joined the team',
          timestamp: 'just now',
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(FeedItem));
    expect(taps, 1);
  });

  testWidgets('golden: feed item in dark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.gold,
        child: FeedItem(
          actor: 'Deniz',
          action: 'finished Upper body A',
          metric: '4 210 kg',
          timestamp: '2 hours ago',
        ),
      ),
      surfaceSize: const Size(390, 200),
    );
    await expectLater(
      find.byType(FeedItem),
      matchesGoldenFile('goldens/feed_item_dark.png'),
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widgets/atlas/feed_item_test.dart`
Expected: FAIL at compile time — `feed_item.dart` does not exist.

- [ ] **Step 3: Write FeedItem**

Create `lib/widgets/atlas/feed_item.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import 'team_crest.dart';

/// One thing somebody on the team did.
///
/// The kit-coloured spine down the leading edge is how a feed of several
/// teams stays legible: the colour says whose team, the crest and name say
/// who.
class FeedItem extends StatelessWidget {
  const FeedItem({
    super.key,
    required this.actor,
    required this.action,
    required this.timestamp,
    this.metric,
    this.onTap,
  });

  final String actor;
  final String action;
  final String timestamp;
  final String? metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: atlas.surface,
      borderRadius: BorderRadius.circular(AtlasRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AtlasRadius.card),
            border: isDark ? Border.all(color: atlas.line) : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  key: const ValueKey('feed-spine'),
                  width: 4,
                  decoration: BoxDecoration(color: atlas.teamMark),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpace.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TeamCrest(teamName: actor, size: CrestSize.small),
                        const SizedBox(width: AtlasSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                actor,
                                style: AtlasTypography.label.copyWith(
                                  color: atlas.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AtlasSpace.xs),
                              Text(
                                action,
                                style: AtlasTypography.body.copyWith(
                                  color: atlas.textPrimary,
                                ),
                              ),
                              if (metric != null) ...[
                                const SizedBox(height: AtlasSpace.sm),
                                Text(
                                  metric!,
                                  key: const ValueKey('feed-metric'),
                                  style: AtlasTypography.numeric(
                                    AtlasTypography.label,
                                  ).copyWith(color: atlas.teamMark),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AtlasSpace.md),
                        Text(
                          timestamp,
                          style: AtlasTypography.micro.copyWith(
                            color: atlas.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

The crest inside a feed item shows the actor's initial, which is a person rather than a team — it still takes the team fill, which is intended: it marks whose team the actor belongs to.

- [ ] **Step 4: Generate the golden and run the tests**

Run: `flutter test test/widgets/atlas/feed_item_test.dart --update-goldens`
Then run: `flutter test test/widgets/atlas/`
Expected: PASS across all component tests.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/atlas/feed_item.dart test/widgets/atlas/feed_item_test.dart \
        test/widgets/atlas/goldens/feed_item_dark.png
git commit -m "Add FeedItem"
```

---
### Task 14: The groups.color migration

**Files:**
- Create: `supabase/migrations/202609200001_team_kit_colour.sql`
- Modify: `supabase/setup_fresh_project.sql:79-84` (the `public.groups` table definition)

**Interfaces:**
- Consumes: the eight slugs from `lib/theme/team_palette.dart` (Task 2).
- Produces: `public.groups.color`, a `TEXT NOT NULL DEFAULT 'steel'` constrained to the eight slugs.

No RLS or function changes are needed, and this has been verified rather than assumed: `join_team_by_invite_token` is declared `RETURNS public.groups` and does `SELECT * INTO v_group`, so the new column travels through the join path untouched, and the policy `"Admins can update their group"` already uses `is_team_admin(id) OR owner_id = auth.uid()` in both `USING` and `WITH CHECK`.

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/202609200001_team_kit_colour.sql`:

```sql
-- Adds each team's kit colour.
--
-- The column stores a slug, not a hex value. Light and dark transforms live
-- in the client (lib/theme/team_palette.dart), and the CHECK constraint stops
-- a team setting itself to something unreadable.
--
-- Re-runnable: every statement guards itself, matching the convention
-- established in 202609160001.

ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS color TEXT NOT NULL DEFAULT 'steel';

ALTER TABLE public.groups
  DROP CONSTRAINT IF EXISTS groups_color_check;

ALTER TABLE public.groups
  ADD CONSTRAINT groups_color_check
  CHECK (color IN (
    'crimson', 'claret', 'violet', 'royal',
    'teal', 'forest', 'gold', 'steel'
  ));

COMMENT ON COLUMN public.groups.color IS
  'Kit colour slug; resolved to hex per scheme by the Flutter client.';
```

- [ ] **Step 2: Update the fresh-install schema**

In `supabase/setup_fresh_project.sql`, change the `public.groups` definition at lines 79-84 so a fresh project matches a migrated one:

```sql
CREATE TABLE public.groups (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  invite_token TEXT UNIQUE NOT NULL,
  color TEXT NOT NULL DEFAULT 'steel'
    CHECK (color IN ('crimson', 'claret', 'violet', 'royal',
                     'teal', 'forest', 'gold', 'steel')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

- [ ] **Step 3: Apply the migration**

Run it against the Supabase project through whatever path the team already uses for `supabase/migrations/` (the SQL editor or `supabase db push`). Then confirm:

```sql
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'groups' AND column_name = 'color';
```

Expected: one row, `text`, `'steel'::text`, `NO`.

Then confirm the constraint rejects junk:

```sql
-- Expected: ERROR violates check constraint "groups_color_check"
UPDATE public.groups SET color = 'chartreuse' WHERE false;
```

The `WHERE false` keeps it from touching data; the constraint is still validated against the statement.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/202609200001_team_kit_colour.sql \
        supabase/setup_fresh_project.sql
git commit -m "Add a kit colour slug to teams"
```

---

### Task 15: Carry the colour through the model and the provider

**Files:**
- Modify: `lib/models/team.dart`
- Modify: `lib/providers/team_provider.dart:105` (the select column list), `:141` (the insert)
- Create: `test/models/team_test.dart`

**Interfaces:**
- Consumes: `KitColor`, `kitFromSlug`, `kDefaultKit`, `swatchOf` (Task 2).
- Produces: `Team.color` as a `String` slug; `Team.kit` as a `KitColor` getter; `TeamProvider.createTeam({required String name, String? description, KitColor kit = kDefaultKit})`; `Future<void> TeamProvider.setTeamColor(String teamId, KitColor kit)`.

- [ ] **Step 1: Write the failing test**

Create `test/models/team_test.dart`:

```dart
import 'package:exercise_app/models/team.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row({String? color}) => <String, dynamic>{
      'id': 'g1',
      'name': 'Kadıköy Barbell',
      'description': null,
      'owner_id': 'u1',
      'invite_token': 'ABC123',
      'created_at': '2026-09-20T10:00:00.000Z',
      if (color != null) 'color': color,
    };

void main() {
  test('parses the colour slug', () {
    final team = Team.fromJson(row(color: 'claret'));
    expect(team.color, 'claret');
    expect(team.kit, KitColor.claret);
  });

  test('a row without a colour falls back to the default kit', () {
    final team = Team.fromJson(row());
    expect(team.kit, kDefaultKit);
  });

  test('an unrecognised slug falls back rather than throwing', () {
    final team = Team.fromJson(row(color: 'chartreuse'));
    expect(team.kit, kDefaultKit);
  });

  test('toJson round-trips the colour', () {
    final team = Team.fromJson(row(color: 'gold'));
    expect(team.toJson()['color'], 'gold');
  });

  test('copyWith replaces the colour and equality notices', () {
    final team = Team.fromJson(row(color: 'gold'));
    final recoloured = team.copyWith(color: 'forest');
    expect(recoloured.kit, KitColor.forest);
    expect(recoloured == team, isFalse);
    expect(team.copyWith() == team, isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/models/team_test.dart`
Expected: FAIL — `Team` has no `color` member.

- [ ] **Step 3: Add the field to the model**

In `lib/models/team.dart`, add the import:

```dart
import '../theme/team_palette.dart';
```

Add `final String color;` beside the other fields, `required this.color,` — no, give it a default so existing construction sites keep compiling: `this.color = 'steel',` in the constructor.

In `fromJson`, add:

```dart
      color: json['color'] as String? ?? kDefaultKit.name,
```

In `toJson`, add `'color': color,`.

In `copyWith`, add the `String? color` parameter and `color: color ?? this.color,`.

Add `color` to `operator ==` and to `hashCode` (`color.hashCode` XORed with the rest), and to `toString`.

Add the resolved getter:

```dart
  /// The kit colour this team wears. Unknown or missing slugs resolve to the
  /// default rather than throwing, so a row written by a newer client cannot
  /// break an older one.
  KitColor get kit => kitFromSlug(color);
```

- [ ] **Step 4: Run the model test**

Run: `flutter test test/models/team_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Carry it through the provider**

In `lib/providers/team_provider.dart`, add the import:

```dart
import '../theme/team_palette.dart';
```

At line 105, add `color` to the explicit column list:

```dart
      final response = await _supabase.from('group_members').select('''
        group_id,
        groups(id, name, description, owner_id, invite_token, created_at, color)
      ''').eq('user_id', userId);
```

Change `createTeam`'s signature to accept a kit and include it in the insert at line 141:

```dart
  Future<Team> createTeam({
    required String name,
    String? description,
    KitColor kit = kDefaultKit,
  }) async {
```

```dart
      final response = await _supabase.from('groups').insert({
        'name': name,
        'description': description,
        'owner_id': userId,
        'invite_token': inviteToken,
        'color': swatchOf(kit).slug,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
```

Add the update method next to the other team mutations:

```dart
  /// Changes a team's kit colour.
  ///
  /// Only admins and the owner may do this; the `Admins can update their
  /// group` RLS policy enforces it, so a member's attempt fails at the
  /// database rather than relying on the UI hiding the control.
  Future<void> setTeamColor(String teamId, KitColor kit) async {
    try {
      await _supabase
          .from('groups')
          .update({'color': swatchOf(kit).slug})
          .eq('id', teamId);

      final index = _myTeams.indexWhere((t) => t.id == teamId);
      if (index != -1) {
        _myTeams[index] = _myTeams[index].copyWith(color: swatchOf(kit).slug);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update team colour: $e';
      notifyListeners();
      rethrow;
    }
  }
```

`joinTeamByInviteToken` needs no change: the RPC returns the whole `groups` row, so `color` arrives on its own.

- [ ] **Step 6: Verify**

Run: `flutter analyze lib/`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/models/team.dart lib/providers/team_provider.dart test/models/team_test.dart
git commit -m "Carry each team's kit colour through the model and provider"
```

---

### Task 16: The colour picker and its strings

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb`
- Create: `lib/widgets/atlas/kit_picker.dart`
- Create: `test/widgets/atlas/kit_picker_test.dart`
- Modify: `lib/screens/create_team_screen.dart`

**Interfaces:**
- Consumes: `KitColor`, `swatchOf`, `kDefaultKit` (Task 2); `context.atlas` (Task 3); `AppLocalizations`.
- Produces: `class KitPicker extends StatelessWidget` with `const KitPicker({super.key, required KitColor selected, required ValueChanged<KitColor> onChanged})`; `String kitColorName(AppLocalizations l10n, KitColor kit)`.

- [ ] **Step 1: Add the strings**

In `lib/l10n/app_en.arb`, add:

```json
  "teamColorLabel": "Team color",
  "@teamColorLabel": {"description": "Label above the team kit color picker"},

  "teamColorHint": "Pick the color your team wears in leaderboards and the feed.",
  "@teamColorHint": {"description": "Helper text under the team color picker"},

  "teamColorChangeAction": "Change color",
  "@teamColorChangeAction": {"description": "Admin action opening the team color picker"},

  "teamColorUpdated": "Team color updated",
  "@teamColorUpdated": {"description": "Confirmation after saving a new team color"},

  "kitColorCrimson": "Crimson",
  "@kitColorCrimson": {"description": "Name of the crimson kit color"},
  "kitColorClaret": "Claret",
  "@kitColorClaret": {"description": "Name of the claret kit color"},
  "kitColorViolet": "Violet",
  "@kitColorViolet": {"description": "Name of the violet kit color"},
  "kitColorRoyal": "Royal",
  "@kitColorRoyal": {"description": "Name of the royal blue kit color"},
  "kitColorTeal": "Teal",
  "@kitColorTeal": {"description": "Name of the teal kit color"},
  "kitColorForest": "Forest",
  "@kitColorForest": {"description": "Name of the forest green kit color"},
  "kitColorGold": "Gold",
  "@kitColorGold": {"description": "Name of the gold kit color"},
  "kitColorSteel": "Steel",
  "@kitColorSteel": {"description": "Name of the steel kit color, the default"},
```

In `lib/l10n/app_tr.arb`, add the matching keys without the `@` metadata blocks (the template file owns those):

```json
  "teamColorLabel": "Takım rengi",
  "teamColorHint": "Takımının sıralamalarda ve akışta taşıyacağı rengi seç.",
  "teamColorChangeAction": "Rengi değiştir",
  "teamColorUpdated": "Takım rengi güncellendi",
  "kitColorCrimson": "Kızıl",
  "kitColorClaret": "Bordo",
  "kitColorViolet": "Mor",
  "kitColorRoyal": "Kraliyet mavisi",
  "kitColorTeal": "Camgöbeği",
  "kitColorForest": "Orman yeşili",
  "kitColorGold": "Altın",
  "kitColorSteel": "Çelik",
```

Run `flutter gen-l10n` (or simply `flutter pub get`, which triggers it via `generate: true`) and confirm the new getters appear in `lib/l10n/app_localizations.dart`.

- [ ] **Step 2: Write the failing picker test**

Create `test/widgets/atlas/kit_picker_test.dart`:

```dart
import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/kit_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: buildDarkTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers every kit colour', (tester) async {
    await _pump(
      tester,
      KitPicker(selected: kDefaultKit, onChanged: (_) {}),
    );
    for (final kit in KitColor.values) {
      expect(find.byKey(ValueKey('kit-${swatchOf(kit).slug}')), findsOneWidget);
    }
  });

  testWidgets('reports the tapped colour', (tester) async {
    KitColor? picked;
    await _pump(
      tester,
      KitPicker(selected: kDefaultKit, onChanged: (kit) => picked = kit),
    );
    await tester.tap(find.byKey(const ValueKey('kit-forest')));
    expect(picked, KitColor.forest);
  });

  testWidgets('names the selected colour in Turkish', (tester) async {
    await _pump(
      tester,
      KitPicker(selected: KitColor.gold, onChanged: (_) {}),
      locale: const Locale('tr'),
    );
    expect(find.text('Altın'), findsOneWidget);
  });

  testWidgets('the selection is not carried by colour alone', (tester) async {
    await _pump(
      tester,
      KitPicker(selected: KitColor.royal, onChanged: (_) {}),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kit-royal')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/widgets/atlas/kit_picker_test.dart`
Expected: FAIL at compile time — `kit_picker.dart` does not exist.

- [ ] **Step 4: Write the picker**

Create `lib/widgets/atlas/kit_picker.dart`:

```dart
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import '../../theme/team_palette.dart';

/// The localised name of a kit colour.
String kitColorName(AppLocalizations l10n, KitColor kit) => switch (kit) {
      KitColor.crimson => l10n.kitColorCrimson,
      KitColor.claret => l10n.kitColorClaret,
      KitColor.violet => l10n.kitColorViolet,
      KitColor.royal => l10n.kitColorRoyal,
      KitColor.teal => l10n.kitColorTeal,
      KitColor.forest => l10n.kitColorForest,
      KitColor.gold => l10n.kitColorGold,
      KitColor.steel => l10n.kitColorSteel,
    };

/// Eight swatches, one of them chosen.
///
/// The selected swatch carries a check mark as well as a ring, because the
/// spec forbids colour from being the only carrier of meaning — a
/// colour-blind user must be able to see which one is picked.
class KitPicker extends StatelessWidget {
  const KitPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final KitColor selected;
  final ValueChanged<KitColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final atlas = context.atlas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.teamColorLabel,
          style: AtlasTypography.heading.copyWith(color: atlas.textPrimary),
        ),
        const SizedBox(height: AtlasSpace.sm),
        Text(
          l10n.teamColorHint,
          style: AtlasTypography.body.copyWith(color: atlas.textMuted),
        ),
        const SizedBox(height: AtlasSpace.lg),
        Wrap(
          spacing: AtlasSpace.md,
          runSpacing: AtlasSpace.md,
          children: [
            for (final kit in KitColor.values)
              _Swatch(
                key: ValueKey('kit-${swatchOf(kit).slug}'),
                kit: kit,
                isSelected: kit == selected,
                label: kitColorName(l10n, kit),
                onTap: () => onChanged(kit),
              ),
          ],
        ),
        const SizedBox(height: AtlasSpace.md),
        Text(
          kitColorName(l10n, selected),
          style: AtlasTypography.label.copyWith(color: atlas.textPrimary),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.kit,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  final KitColor kit;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = swatchOf(kit);
    final atlas = context.atlas;
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: swatch.fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? atlas.textPrimary : atlas.line,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check, size: 22, color: swatch.onFill)
              : null,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the picker test**

Run: `flutter test test/widgets/atlas/kit_picker_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 6: Put the picker in the create-team flow**

In `lib/screens/create_team_screen.dart`:

- Add `import '../theme/team_palette.dart';` and `import '../widgets/atlas/kit_picker.dart';`.
- Add `KitColor _kit = kDefaultKit;` to the state class.
- Insert into the form, below the description field and above the submit button:

```dart
              const SizedBox(height: AtlasSpace.xl),
              KitPicker(
                selected: _kit,
                onChanged: (kit) => setState(() => _kit = kit),
              ),
```

  Add `import '../theme/atlas_tokens.dart';` for `AtlasSpace`.
- Pass the choice to the provider at the `createTeam` call:

```dart
      final team = await provider.createTeam(
        name: _nameController.text.trim(),
        description: description,
        kit: _kit,
      );
```

  Use the existing local names for the controller and description in that file rather than these placeholders if they differ.

- [ ] **Step 7: Verify**

Run: `flutter analyze lib/`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/l10n lib/widgets/atlas/kit_picker.dart \
        test/widgets/atlas/kit_picker_test.dart lib/screens/create_team_screen.dart
git commit -m "Let a team choose its kit colour when it is created"
```

---

### Task 17: Adopt the components on the team screens

The last task connects the two halves: team data now has a colour, and the components know how to wear one.

**Files:**
- Modify: `lib/screens/team_detail_screen.dart`
- Modify: `lib/screens/team_list_screen.dart`
- Modify: `lib/screens/team_leaderboard_screen.dart`
- Modify: `lib/screens/social_feed_screen.dart`
- Create: `test/widgets/atlas/team_theme_adoption_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 8-16.
- Produces: nothing further.

- [ ] **Step 1: Wrap each team-scoped screen in TeamTheme**

In each of the four screens, find the point where a single `Team` is in scope and wrap the body below it:

```dart
    return TeamTheme(
      kit: team.kit,
      child: /* the existing body */,
    );
```

Add `import '../widgets/atlas/team_theme.dart';` to each.

`social_feed_screen.dart` shows several teams' activity in one list, so it does **not** get a screen-level wrapper. Wrap each feed row individually instead, so each item shows its own team's colour:

```dart
            TeamTheme(
              kit: activity.team.kit,
              child: FeedItem(
                actor: activity.actorName,
                action: activity.summary,
                metric: activity.metric,
                timestamp: activity.relativeTime,
              ),
            ),
```

Use the real field names from the feed's model; if the feed row does not currently carry its team, fall back to `kDefaultKit` for that row and leave a comment naming the gap rather than inventing a lookup.

- [ ] **Step 2: Replace the hand-built team UI with the components**

- `team_detail_screen.dart`: replace the existing name-and-member header block with `TeamHeader(teamName: team.name, memberSummary: l10n.teamMembersCount(members.length), description: team.description)`. Use the existing member-count string from the file; do not invent a new l10n key if one is already there.
- `team_leaderboard_screen.dart`: replace the row builder with `AnimatedLeaderboard(entries: entries, viewerId: currentUserId)`, mapping the screen's existing model into `LeaderboardEntry(id:, name:, metric:)`.
- `team_list_screen.dart`: put a `TeamCrest(teamName: team.name)` in each row's `leading`, wrapped in its own `TeamTheme(kit: team.kit, ...)` so each row shows its own colour.

- [ ] **Step 3: Add the admin colour control**

In `team_detail_screen.dart`, inside the block already gated on the viewer being an admin, add an action that opens a bottom sheet holding a `KitPicker` and calls `setTeamColor`:

```dart
  Future<void> _editColor(BuildContext context, Team team) async {
    final provider = context.read<TeamProvider>();
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<KitColor>(
      context: context,
      builder: (sheetContext) {
        var selection = team.kit;
        return StatefulBuilder(
          builder: (builderContext, setSheetState) => Padding(
            padding: const EdgeInsets.all(AtlasSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitPicker(
                  selected: selection,
                  onChanged: (kit) => setSheetState(() => selection = kit),
                ),
                const SizedBox(height: AtlasSpace.xl),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(selection),
                  child: Text(l10n.teamColorChangeAction),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || picked == team.kit) return;
    await provider.setTeamColor(team.id, picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.teamColorUpdated)),
    );
  }
```

Trigger it from a `TextButton` labelled `l10n.teamColorChangeAction` placed beside the other admin controls.

- [ ] **Step 4: Write the adoption test**

Create `test/widgets/atlas/team_theme_adoption_test.dart`:

```dart
import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('nested TeamThemes each scope their own subtree',
      (tester) async {
    final seen = <String, Color>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Scaffold(
          body: Column(
            children: [
              TeamTheme(
                kit: KitColor.crimson,
                child: Builder(builder: (context) {
                  seen['first'] = context.atlas.teamFill;
                  return const SizedBox.shrink();
                }),
              ),
              TeamTheme(
                kit: KitColor.teal,
                child: Builder(builder: (context) {
                  seen['second'] = context.atlas.teamFill;
                  return const SizedBox.shrink();
                }),
              ),
              Builder(builder: (context) {
                seen['outside'] = context.atlas.teamFill;
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );

    expect(seen['first'], swatchOf(KitColor.crimson).fill);
    expect(seen['second'], swatchOf(KitColor.teal).fill);
    expect(seen['outside'], swatchOf(kDefaultKit).fill);
  });
}
```

This is the property the whole architecture rests on: a feed listing three teams shows three colours, and anything outside a team stays steel.

- [ ] **Step 5: Verify the whole suite**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: PASS, including every golden.

- [ ] **Step 6: Run the app and look at it**

Run: `flutter run -d <device>`

Check by eye, in dark and then in light via the theme setting: the team header is the loudest thing on its screen; leaderboard metrics form a straight right-hand column; a leaderboard refresh slides rows rather than snapping; no text anywhere is in capitals; Turkish team names render `ğ`, `ş` and `İ` correctly.

- [ ] **Step 7: Commit**

```bash
git add lib/screens test/widgets/atlas/team_theme_adoption_test.dart
git commit -m "Adopt the Atlas components across the team screens"
```

---

## Self-Review

**Spec coverage.** Section 2's chrome, status hues and kit hues map to Tasks 1-2, and both cross-cutting rules are enforced: "different mark sizes" by `StatusMark` being dot-scale only (Task 9) while `TeamHeader`, the leaderboard rail and the feed spine are the only fills (Tasks 11-13), and "never load-bearing alone" by `TeamCrest` always printing an initial (Task 8) and `KitPicker` printing a check mark and a name (Task 16). Section 3's family, scale, tabular figures and the all-caps prohibition are Task 4, with the prohibition enforced by review rather than a test — noted below. Section 4's radius, space, elevation and single motion moment are Tasks 1, 5 and 12. Section 5's three tiers are Tasks 1-5, 8-13 and 14-17. Section 6's four stages map to Tasks 1-5, 6-7, 8-13 and 14-17 in that order. Section 7's four test commitments are Tasks 1-2 (contrast), 4 (Turkish glyphs), 8-13 (goldens) and Task 5 step 6 (the existing test files).

**One gap found and closed.** The spec's "no all-caps" rule had no enforcement. It is a review item in the Global Constraints rather than a test, because a lint for `toUpperCase()` would fire on legitimate non-display uses such as the invite-token normalisation in `team_provider.dart`. Reviewers should check it on each component task.

**One deliberate omission.** Section 8 puts App Store screenshots out of scope, so no task produces them. Task 17 step 6 is the visual check that would precede them.

**Placeholder scan.** No "TBD" or "handle appropriately" steps; every code step carries the code. Three steps name existing local identifiers the implementer must match rather than guessing (`deep_link_service.dart`'s context, `create_team_screen.dart`'s controllers, the feed's model field names); each says so explicitly and says what to do if they differ.

**Type consistency.** `KitColor`/`KitSwatch`/`swatchOf`/`kitFromSlug`/`kDefaultKit` are defined in Task 2 and used under those exact names in Tasks 3, 8, 15, 16 and 17. `AtlasColors.teamFill`/`teamOnFill`/`teamMark` are defined in Task 3 and read under those names in Tasks 8-13. `CrestSize` is defined in Task 8 and consumed in Tasks 11-13. `AtlasStatus` is confined to Task 9. `LeaderboardEntry`'s three fields are defined and consumed only in Tasks 12 and 17. `Team.kit` is defined in Task 15 and consumed in Task 17.
