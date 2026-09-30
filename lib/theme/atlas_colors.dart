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
        teamFill = kSteelFill,
        teamOnFill = kSteelOnFill,
        teamMark = kSteelDarkMark;

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
        teamFill = kSteelFill,
        teamOnFill = kSteelOnFill,
        teamMark = kSteelLightMark;

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
