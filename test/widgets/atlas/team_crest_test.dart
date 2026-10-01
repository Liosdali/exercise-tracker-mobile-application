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
  }, tags: ['golden']);

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
  }, tags: ['golden']);
}
