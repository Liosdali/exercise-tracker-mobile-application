import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/leaderboard_row.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _entries = <LeaderboardEntry>[
  LeaderboardEntry(id: 'a', name: 'Deniz', metric: '4 210 kg'),
  LeaderboardEntry(id: 'b', name: 'Mert', metric: '3 980 kg'),
  LeaderboardEntry(id: 'c', name: 'Ayşe', metric: '3 640 kg'),
];

void main() {
  testWidgets('a row states rank, name and metric', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: LeaderboardRow(
          rank: 2,
          entry: LeaderboardEntry(id: 'b', name: 'Mert', metric: '3 980 kg'),
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Mert'), findsOneWidget);
    expect(find.text('3 980 kg'), findsOneWidget);
  });

  testWidgets('rank and metric both use tabular figures', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: LeaderboardRow(
          rank: 2,
          entry: LeaderboardEntry(id: 'b', name: 'Mert', metric: '3 980 kg'),
        ),
      ),
    );
    for (final label in ['2', '3 980 kg']) {
      expect(
        tester.widget<Text>(find.text(label)).style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: '$label is not tabular',
      );
    }
  });

  testWidgets('the viewer row carries the kit rail', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.forest,
        child: LeaderboardRow(
          rank: 1,
          entry: LeaderboardEntry(id: 'a', name: 'Deniz', metric: '4 210 kg'),
          isViewer: true,
        ),
      ),
    );
    final rail = tester.widget<Container>(
      find.byKey(const ValueKey('leaderboard-rail')),
    );
    expect((rail.decoration! as BoxDecoration).color,
        swatchOf(KitColor.forest).darkMark);
  });

  testWidgets('a non-viewer row has no rail', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.forest,
        child: LeaderboardRow(
          rank: 3,
          entry: LeaderboardEntry(id: 'c', name: 'Ayşe', metric: '3 640 kg'),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('leaderboard-rail')), findsNothing);
  });

  testWidgets('rows move to new positions when the order changes',
      (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: AnimatedLeaderboard(entries: _entries),
      ),
      surfaceSize: const Size(390, 320),
    );
    final before = tester.getTopLeft(find.text('Mert')).dy;

    const reordered = <LeaderboardEntry>[
      LeaderboardEntry(id: 'b', name: 'Mert', metric: '4 400 kg'),
      LeaderboardEntry(id: 'a', name: 'Deniz', metric: '4 210 kg'),
      LeaderboardEntry(id: 'c', name: 'Ayşe', metric: '3 640 kg'),
    ];
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.royal,
        child: AnimatedLeaderboard(entries: reordered),
      ),
      surfaceSize: const Size(390, 320),
    );
    final after = tester.getTopLeft(find.text('Mert')).dy;
    expect(after, lessThan(before));
  });

  testWidgets('reduced motion removes the animation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: const Scaffold(
            body: TeamTheme(
              kit: KitColor.royal,
              child: AnimatedLeaderboard(entries: _entries),
            ),
          ),
          theme: buildDarkTheme(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned).first,
    );
    expect(positioned.duration, Duration.zero);
  });

  testWidgets('golden: leaderboard in dark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.crimson,
        child: AnimatedLeaderboard(entries: _entries, viewerId: 'b'),
      ),
      surfaceSize: const Size(390, 320),
    );
    await expectLater(
      find.byType(AnimatedLeaderboard),
      matchesGoldenFile('goldens/leaderboard_dark.png'),
    );
  });
}
