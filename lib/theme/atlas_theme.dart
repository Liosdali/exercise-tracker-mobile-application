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
