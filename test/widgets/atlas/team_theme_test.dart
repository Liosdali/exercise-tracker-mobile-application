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
