import 'package:exercise_app/theme/atlas_colors.dart';
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
