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
