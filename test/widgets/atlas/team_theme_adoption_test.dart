import 'package:exercise_app/theme/atlas_colors.dart';
import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/team_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('nested TeamThemes each scope their own subtree',
      (tester) async {
    final seen = <String, Color>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Scaffold(
          body: Column(
            children: [
              TeamTheme(
                kit: KitColor.crimson,
                child: Builder(builder: (context) {
                  seen['first'] = context.atlas.teamFill;
                  return const SizedBox.shrink();
                }),
              ),
              TeamTheme(
                kit: KitColor.teal,
                child: Builder(builder: (context) {
                  seen['second'] = context.atlas.teamFill;
                  return const SizedBox.shrink();
                }),
              ),
              Builder(builder: (context) {
                seen['outside'] = context.atlas.teamFill;
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );

    expect(seen['first'], swatchOf(KitColor.crimson).fill);
    expect(seen['second'], swatchOf(KitColor.teal).fill);
    expect(seen['outside'], swatchOf(kDefaultKit).fill);
  });
}
