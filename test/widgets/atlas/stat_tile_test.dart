import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/theme/atlas_tokens.dart';
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

  testWidgets('long values scale down instead of truncating', (tester) async {
    await pumpAtlas(
      tester,
      const SizedBox(
        width: 180,
        child: StatTile(
          value: '1 234 567',
          label: 'Large number',
        ),
      ),
    );
    // The full string must still be there — scaling down is not truncating.
    expect(find.text('1 234 567'), findsOneWidget);
    // And it must actually have been scaled to fit: the FittedBox wrapping
    // the value can be no wider than the tile minus its horizontal padding.
    // Asserting on `Text.overflow` alone can never fail here — the widget is
    // built with no `overflow` argument, so it is null regardless of whether
    // scaling logic exists at all. Rendered geometry is the only signal that
    // actually depends on the FittedBox being present.
    final tileWidth = tester.getSize(find.byType(StatTile)).width;
    final fittedBoxWidth = tester.getSize(find.byType(FittedBox)).width;
    expect(
      fittedBoxWidth,
      lessThanOrEqualTo(tileWidth - 2 * AtlasSpace.lg),
    );
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
