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
