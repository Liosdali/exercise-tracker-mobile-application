# Atlas Workout — Visual Identity Design

Date: 2026-09-20
Status: Approved for implementation planning

## 1. Brief

Atlas Workout is a Flutter training app with roughly thirty screens covering
workouts, programs and routines, body measurements, a dashboard, and a social
layer of teams, leaderboards, team activity and a feed.

The app has no visual identity today. `lib/main.dart:141-152` is stock Flutter:
`ColorScheme.fromSeed(seedColor: Colors.deepPurple)` with Material 3 defaults,
no custom typography, no component themes. `lib/widgets/` holds three widgets.
Around forty-five hand-written `Colors.red`, `Colors.green` and `Colors.orange`
calls do semantic work across the screens with no shared definition.

The audience is team and coach driven. Rankings, shared activity and mutual
accountability are what distinguish this app from a solo training log, so the
identity is built to express membership rather than personal record keeping.

### Decisions taken

| Axis | Decision |
|---|---|
| Audience | Team and coach driven; social and competitive |
| Ambition | Design tokens plus a custom component layer, Material underneath |
| Schemes | Dark-first; light is a faithful derivative, not an afterthought |
| Type | Bundle one open-source family; no runtime font fetching |
| Direction | Club Kit — team colour is a real theming axis |

### Direction: Club Kit

The identity comes from team sportswear: jersey numerals, club colours, the
roster board. Each team carries its own colour, and that colour propagates
through team headers, leaderboards, feed items and team activity. App chrome
stays deliberately quiet graphite so the team colour is the loud thing, and two
teams' screens look meaningfully different from one another.

This was chosen over a scoreboard or meet-results direction because a scoreboard
is generic to the whole fitness category, while a team colour that follows a
member through the app is the design doing the product's actual job.

## 2. Colour

### Chrome

Dark-first, blue-leaning graphite rather than a tinted near-black.

| Token | Dark | Light |
|---|---|---|
| `ink` (app background) | `#161A21` | `#F4F6F9` |
| `surface` (cards, list rows) | `#1E232C` | `#FFFFFF` |
| `surfaceRaised` (sheets, dialogs) | `#262C37` | `#FFFFFF` with shadow |
| `line` (hairline borders) | `#333A47` | `#DDE2EA` |
| `textPrimary` | `#EEF1F6` | `#171B22` |
| `textMuted` | `#98A1B0` | `#5D6675` |

Measured text contrast: dark primary 15.41, dark muted 6.70 on `ink` and 6.05 on
`surface`, light primary 15.95, light muted 5.35.

### Status hues

These replace the scattered `Colors.*` calls. Each is measured against both the
scheme background and the scheme surface, because status marks appear on cards
as often as on the page. The ratio shown is the lower of the two, and all four
clear 4.5:1, so they are usable as text and not only as marks.

| Token | Dark | Ratio | Light | Ratio | Meaning |
|---|---|---|---|---|---|
| `success` | `#3FBF87` | 6.77 | `#1E7A52` | 4.90 | Personal best, completed, synced |
| `warn` | `#E0A62E` | 7.25 | `#8A6410` | 4.96 | Unsynced work, conflicts pending |
| `danger` | `#E16151` | 4.53 | `#B33A2E` | 5.45 | Destructive actions, failed sync |
| `info` | `#4C8DF0` | 4.79 | `#2B5FB8` | 5.65 | Neutral notices |

An earlier dark `danger` of `#E05B4B` was rejected: it cleared `ink` at 4.79 but
fell to 4.33 on `surface`, so it was lightened to `#E16151`.

### Kit hues

Eight colours a team can adopt. `steel` is the default, so a user who has not
joined a team sees neutral chrome. Each hue is listed with the foreground it
takes when used as a filled field, and the measured ratio.

| Slug | Hex | Foreground | Ratio |
|---|---|---|---|
| `crimson` | `#CE3B34` | white | 4.88 |
| `claret` | `#A6276B` | white | 6.72 |
| `violet` | `#7A4DD4` | white | 5.47 |
| `royal` | `#2F5FD0` | white | 5.72 |
| `teal` | `#17727D` | white | 5.62 |
| `forest` | `#2C7A46` | white | 5.28 |
| `gold` | `#B8891B` | `ink` | 5.51 |
| `steel` | `#5A6472` | white | 6.00 |

An earlier teal of `#1E8C99` was rejected: it measured 3.99 against white and
4.37 against ink, clearing neither, and was darkened to `#17727D`.

### Kit hues have two roles

A `fill` sits behind its own foreground, so it needs no scheme transform and is
identical in light and dark — a team's header is the same colour on both. A
`mark` sits on the scheme's own background, as a leaderboard rail, a crest
border or team-coloured text, so it must clear the background instead.

Measured against both the scheme background and the scheme surface, taking the
lower of the two:

| Slug | Dark mark | Ratio | Light mark | Ratio |
|---|---|---|---|---|
| `crimson` | `#D96660` | 4.52 | `#CE3B34` | 4.51 |
| `claret` | `#D95D9F` | 4.52 | `#A6276B` | 6.21 |
| `violet` | `#9976DE` | 4.51 | `#7A4DD4` | 5.05 |
| `royal` | `#6387DC` | 4.53 | `#2F5FD0` | 5.29 |
| `teal` | `#1E97A5` | 4.52 | `#17727D` | 5.19 |
| `forest` | `#389B59` | 4.51 | `#2C7A46` | 4.87 |
| `gold` | `#B8891B` | 4.98 | `#906B15` | 4.51 |
| `steel` | `#7F8A9A` | 4.51 | `#5A6472` | 5.54 |

Seven of the eight light marks are the fill value unchanged; only `gold` needs
darkening. In dark, seven need lightening and `gold` alone passes as-is. This
asymmetry is expected — `gold` is the one hue whose fill takes `ink` rather than
white as its foreground.

### Two rules that keep kit colour and status colour apart

1. **Different mark sizes.** Kit colour only fills large fields: team header,
   leaderboard rail, crest, feed-item spine. Status colour only appears on small
   marks: a dot, an icon, a line of text. They never compete for the same pixel.
2. **Never load-bearing alone.** Team identity always ships with the team name or
   initial beside the colour, so colour blindness and greyscale App Store
   screenshots both survive.

## 3. Typography

One family, **Archivo** (SIL Open Font License), in two widths. Archivo Expanded
Bold carries display text and rank numerals for its squared-off jersey
character; normal-width Archivo Regular and Medium handle everything else. One
family across roughly five static weights keeps the bundle near 400KB, and
expanded-bold against normal-regular is a wide enough gap to read as two voices.

Turkish coverage must be verified against the shipped font files as a build
step. The glyphs to check are `ğ Ğ ş Ş İ ı ç Ç ö Ö ü Ü`.

All numeric columns — weights, reps, ranks, volume, durations — use
`FontFeature.tabularFigures()` so digits align vertically rather than jittering
down a leaderboard.

### Scale

| Role | Size (dp) | Face | Notes |
|---|---|---|---|
| `display` | 40 | Expanded 700 | Rank numerals, the one big number per screen |
| `title` | 24 | Expanded 600 | Screen and team titles |
| `heading` | 19 | Regular 600 | Section headings |
| `body` | 15 | Regular 400 | 1.5 line height |
| `label` | 13 | Medium 500 | Buttons, field labels |
| `micro` | 11.5 | Medium 500 | Timestamps, counts; used sparingly |

### Prohibitions

- **No all-caps text anywhere.** It is the commonest generated-interface tell,
  and in Turkish `i` uppercases to `İ`, so Dart's locale-less `toUpperCase()`
  silently mangles the second language. Sentence case throughout.
- No tracked-out label above a heading.
- No arrow glyph appended to button or link text.
- No meta strings joined with middle dots.

Body text is capped below 80 characters per line, which is automatic at phone
width and requires a max width on tablet layouts.

## 4. Shape, space, elevation, motion

**Radius carries role** rather than one value everywhere: fields and chips 8,
cards and feed items 14, bottom sheets 24 on the top corners only, kit-colour
rails 2, crests and avatars fully round.

**Space** runs on a 4pt base: 4, 8, 12, 16, 24, 32, 48, with 24 as the rhythm
between sections.

**Elevation differs by scheme.** Shadows read as grey smudge against `#161A21`,
so dark mode separates layers with a `surface` to `surfaceRaised` step plus a
`line` hairline. Light mode uses real shadows. The same component takes two
honest strategies rather than one compromise.

**Motion is spent once.** When a leaderboard refreshes and a position changes,
rows animate to their new places; this is the only ambient motion in the app and
it earns itself by showing what actually changed. There are no fade-and-slide
section entrances and no press lift on cards. All other motion responds to a
direct action. Every animation respects the platform reduced-motion setting.

**The boldness is spent on the team header and the rank numeral.** A saturated
kit-colour field carrying an oversized expanded numeral is the memorable
element; every other surface stays graphite and disciplined so that moment lands.

## 5. Architecture

Material's component themes do most of the restyling. The screens contain 34
`Scaffold`s, 31 `AppBar`s, 31 `SnackBar`s, 27 `Card`s, 27 `ListTile`s, 22
`TextField`s, 22 buttons and 8 `Chip`s. All of these restyle from `ThemeData`
alone, with no screen-level edits.

### Tier 1 — token layer

```
lib/theme/
  atlas_tokens.dart      colour, space, radius and duration constants, both schemes
  atlas_typography.dart  TextTheme plus a tabular-figures helper for numeric styles
  atlas_colors.dart      ThemeExtension<AtlasColors>: status hues and teamAccent
  team_palette.dart      the eight kit hues: fill, foreground, dark mark, light mark
  atlas_theme.dart       buildLightTheme() and buildDarkTheme() with component themes
```

`main.dart:141-152` reduces to two factory calls. Status hues live on a
`ThemeExtension` because Material's `ColorScheme` has no slot for "unsynced" or
"personal best"; this is what lets the scattered `Colors.*` calls become
`context.atlas.warn`.

### Team colour reaches components through the tree

A `TeamTheme` widget wraps any team-scoped subtree and overrides `teamAccent` in
the theme extension. Components read
`Theme.of(context).extension<AtlasColors>()!.teamAccent` and receive the correct
kit colour inside a team context and `steel` outside one. No component imports
`TeamProvider`, so each renders standalone under test.

### Tier 2 — six components

| Component | Job |
|---|---|
| `TeamCrest` | Kit-colour initial in three sizes |
| `TeamHeader` | The bold moment: kit field, team name, member count |
| `LeaderboardRow` | Rank numeral, crest, tabular metric, kit rail, animated reorder |
| `StatTile` | One large tabular number with its label |
| `FeedItem` | Kit-colour spine, actor, action, metric |
| `StatusMark` | Dot and label replacing hand-rolled red and green |

### Tier 3 — team colour as data

Teams are Supabase rows in `public.groups`, not sqflite, so this is a Postgres
migration rather than a local schema bump.

- New migration under `supabase/migrations/` adding
  `color TEXT NOT NULL DEFAULT 'steel'` to `public.groups`, with a `CHECK`
  constraint restricting it to the eight slugs.
- **The slug is stored, not a hex value.** Light and dark transforms stay in the
  client, and no team can set itself to an unreadable colour.
- `Team` in `lib/models/team.dart` gains a `color` field across `fromJson`,
  `toJson`, `copyWith`, `operator ==`, `hashCode` and `toString`.
- The explicit select list at `lib/providers/team_provider.dart:105` and the
  insert at `:141` must both include `color`.
- An eight-swatch picker in `create_team_screen.dart`, and an edit control in
  `team_detail_screen.dart` restricted to team admins. `group_members.role`
  already distinguishes `admin` from `member`; the existing RLS update policy on
  `groups` must be confirmed to cover this before the picker ships.
- Eight colour names added to `lib/l10n/app_en.arb` and `lib/l10n/app_tr.arb`,
  plus the picker label and the edit control's strings.

## 6. Rollout

Four stages, each shippable on its own:

1. **Tokens, typography and fonts.** The whole app changes appearance; no screen
   logic moves.
2. **Status tokens** replace the roughly forty-five scattered `Colors.*` calls.
3. **Components**, introduced screen by screen, beginning with team list, team
   detail, leaderboard and feed.
4. **Team colour as data**, including the migration and the picker.

The backend change is the only piece with an external dependency and it is
deliberately last, so none of the visual work is blocked on a Supabase deploy.
This matters with an App Store submission in flight.

## 7. Testing

- **Golden tests** for the six components across both schemes. Bundled fonts
  make these deterministic in a way system fonts never were.
- **A contrast unit test** covering all three cases in section 2: every kit fill
  against its paired foreground, every kit mark against both the background and
  the surface of its scheme, and every status hue against both backgrounds and
  both surfaces. The floor is 4.5:1 throughout. The rules in section 2 become a
  failing build rather than a paragraph nobody rereads.
- **A Turkish glyph test** asserting the bundled fonts render the Turkish set,
  guarding the l10n commitment in section 3.
- `test/account_ui_test.dart` and `test/widget_test.dart` must be checked for
  locally constructed `ThemeData`; they may need the new factories.

## 8. Out of scope

- Any change to navigation structure or information architecture.
- Category colours. `lib/widgets/category_style.dart` maps body-part categories
  to icons and deliberately gains no colour axis, to avoid a third colour system
  competing with kit and status hues.
- Per-user accent colours. Colour belongs to teams in this design.
- App Store screenshot production, which follows once the identity ships.
