import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/feed_item.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('states actor, action, metric and time', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'finished Upper body A',
          metric: '4 210 kg',
          timestamp: '2 hours ago',
        ),
      ),
    );
    expect(find.text('Deniz'), findsOneWidget);
    expect(find.text('finished Upper body A'), findsOneWidget);
    expect(find.text('4 210 kg'), findsOneWidget);
    expect(find.text('2 hours ago'), findsOneWidget);
  });

  testWidgets('the spine takes the kit mark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.claret,
        child: FeedItem(
          actor: 'Deniz',
          action: 'finished Upper body A',
          timestamp: '2 hours ago',
        ),
      ),
    );
    final spine = tester.widget<Container>(
      find.byKey(const ValueKey('feed-spine')),
    );
    expect((spine.decoration! as BoxDecoration).color,
        swatchOf(KitColor.claret).darkMark);
  });

  testWidgets('omits the metric row when there is no metric',
      (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'joined the team',
          timestamp: 'just now',
        ),
      ),
    );
    expect(find.byKey(const ValueKey('feed-metric')), findsNothing);
  });

  testWidgets('trailing renders beside the timestamp', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'joined the team',
          timestamp: 'just now',
          trailing: Icon(Icons.more_vert, key: ValueKey('feed-trailing')),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('feed-trailing')), findsOneWidget);
  });

  testWidgets('trailing is absent when null', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'joined the team',
          timestamp: 'just now',
        ),
      ),
    );
    expect(find.byKey(const ValueKey('feed-trailing')), findsNothing);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var taps = 0;
    await pumpAtlas(
      tester,
      TeamTheme(
        kit: KitColor.teal,
        child: FeedItem(
          actor: 'Deniz',
          action: 'joined the team',
          timestamp: 'just now',
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(FeedItem));
    expect(taps, 1);
  });

  testWidgets('golden: feed item in dark', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.gold,
        child: FeedItem(
          actor: 'Deniz',
          action: 'finished Upper body A',
          metric: '4 210 kg',
          timestamp: '2 hours ago',
        ),
      ),
      surfaceSize: const Size(390, 200),
    );
    await expectLater(
      find.byType(FeedItem),
      matchesGoldenFile('goldens/feed_item_dark.png'),
    );
  }, tags: ['golden']);

  testWidgets('golden: feed item in light', (tester) async {
    await pumpAtlas(
      tester,
      const TeamTheme(
        kit: KitColor.gold,
        child: FeedItem(
          actor: 'Deniz',
          action: 'finished Upper body A',
          metric: '4 210 kg',
          timestamp: '2 hours ago',
        ),
      ),
      brightness: Brightness.light,
      surfaceSize: const Size(390, 200),
    );
    await expectLater(
      find.byType(FeedItem),
      matchesGoldenFile('goldens/feed_item_light.png'),
    );
  }, tags: ['golden']);
}
