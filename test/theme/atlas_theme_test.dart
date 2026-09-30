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
