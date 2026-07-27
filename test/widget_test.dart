// Basic smoke test for the Exercise App: the app launches, loads the bundled
// exercise dataset, and shows the dashboard with 4-tab bottom navigation.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exercise_app/main.dart';

void main() {
  // The test host has no platform sqflite/shared_preferences plugins; use
  // the FFI database implementation and in-memory shared_preferences mock
  // so the app behaves the same way it does on a real device.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launches and shows the dashboard with 4-tab bottom nav',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ExerciseApp());

    // Initially shows the loading indicator while the dataset is parsed.
    await tester.pump();

    // The asset load is genuine async I/O; run it outside testWidgets' fake
    // async zone so it can actually complete, then pump to render the result.
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 2000)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The dashboard (default tab) should now be visible.
    expect(find.text('Ana Sayfa'), findsWidgets);

    // Bottom navigation should offer all 4 tabs.
    expect(find.text('Antrenmanlar'), findsWidgets);
    expect(find.text('Egzersizler'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Switch to the Egzersizler tab.
    await tester.tap(find.text('Egzersizler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Exercise Library'), findsOneWidget);

    // Switch to the Profil tab.
    await tester.tap(find.text('Profil'));
    await tester.pump();

    // The stats/measurements load is genuine async DB I/O kicked off from a
    // post-frame callback; poll with real async waits until it completes.
    for (var i = 0; i < 10; i++) {
      if (find.text('Profil & İstatistikler').evaluate().isNotEmpty) break;
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Profil & İstatistikler'), findsOneWidget);
  });
}
