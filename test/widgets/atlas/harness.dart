import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget inside a real Atlas theme, centred on the scheme
/// background, so goldens show the component as it actually ships.
Future<void> pumpAtlas(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  Size surfaceSize = const Size(390, 300),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark
          ? buildDarkTheme()
          : buildLightTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
