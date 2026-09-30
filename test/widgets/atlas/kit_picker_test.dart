import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/theme/atlas_theme.dart';
import 'package:exercise_app/theme/team_palette.dart';
import 'package:exercise_app/widgets/atlas/kit_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: buildDarkTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers every kit colour', (tester) async {
    await _pump(
      tester,
      KitPicker(selected: kDefaultKit, onChanged: (_) {}),
    );
    for (final kit in KitColor.values) {
      expect(find.byKey(ValueKey('kit-${swatchOf(kit).slug}')), findsOneWidget);
    }
  });

  testWidgets('reports the tapped colour', (tester) async {
    KitColor? picked;
    await _pump(
      tester,
      KitPicker(selected: kDefaultKit, onChanged: (kit) => picked = kit),
    );
    await tester.tap(find.byKey(const ValueKey('kit-forest')));
    expect(picked, KitColor.forest);
  });

  testWidgets('names the selected colour in Turkish', (tester) async {
    await _pump(
      tester,
      KitPicker(selected: KitColor.gold, onChanged: (_) {}),
      locale: const Locale('tr'),
    );
    expect(find.text('Altın'), findsOneWidget);
  });

  testWidgets('the selection is not carried by colour alone', (tester) async {
    await _pump(
      tester,
      KitPicker(selected: KitColor.royal, onChanged: (_) {}),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kit-royal')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}
