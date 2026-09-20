import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/widgets/atlas/status_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('each status resolves to its token', (tester) async {
    late BuildContext ctx;
    await pumpAtlas(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        },
      ),
    );
    final atlas = ctx.atlas;
    expect(StatusMark.colorOf(ctx, AtlasStatus.success), atlas.success);
    expect(StatusMark.colorOf(ctx, AtlasStatus.warn), atlas.warn);
    expect(StatusMark.colorOf(ctx, AtlasStatus.danger), atlas.danger);
    expect(StatusMark.colorOf(ctx, AtlasStatus.info), atlas.info);
  });

  testWidgets('shows a dot when no icon is given', (tester) async {
    await pumpAtlas(
      tester,
      const StatusMark(status: AtlasStatus.warn, label: 'Not synced'),
    );
    expect(find.text('Not synced'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('shows the icon when one is given', (tester) async {
    await pumpAtlas(
      tester,
      const StatusMark(
        status: AtlasStatus.success,
        label: 'Synced',
        icon: Icons.check_circle,
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
    expect(icon.size, 16);
  });

  testWidgets('label is never upper-cased', (tester) async {
    await pumpAtlas(
      tester,
      const StatusMark(status: AtlasStatus.info, label: 'İstanbul kaydı'),
    );
    expect(find.text('İstanbul kaydı'), findsOneWidget);
  });

  testWidgets('golden: all four statuses in dark', (tester) async {
    await pumpAtlas(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusMark(
              status: AtlasStatus.success,
              label: 'Synced',
              icon: Icons.check_circle),
          SizedBox(height: 8),
          StatusMark(status: AtlasStatus.warn, label: 'Not synced'),
          SizedBox(height: 8),
          StatusMark(status: AtlasStatus.danger, label: 'Sync failed'),
          SizedBox(height: 8),
          StatusMark(status: AtlasStatus.info, label: '3 conflicts'),
        ],
      ),
      surfaceSize: const Size(300, 220),
    );
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/status_mark_dark.png'),
    );
  });
}
