import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exercise_app/main.dart';

void main() {
  testWidgets('debug', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});

    FlutterError.onError = (details) {
      print('FLUTTER ERROR: ${details.exceptionAsString()}');
    };

    await tester.pumpWidget(const ExerciseApp());
    await tester.pump();

    // Poll until the dashboard's initial loading indicator is gone, instead
    // of guessing a fixed delay.
    for (var i = 0; i < 20; i++) {
      if (find.text('Ana Sayfa').evaluate().isNotEmpty) break;
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Profil'));
    await tester.pump();

    // Poll (real async waits) until the stats/measurements load finishes,
    // instead of guessing a fixed delay - avoids late notifyListeners()
    // firing after this test's widget tree has already been torn down.
    for (var i = 0; i < 20; i++) {
      if (find.text('Profil & İstatistikler').evaluate().isNotEmpty) break;
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));

    debugDumpApp();
    print('istatistik candidates: ' +
        find.textContaining('statistik').evaluate().length.toString());
    print('profil candidates: ' + find.textContaining('Profil').evaluate().length.toString());
    for (final el in find.textContaining('Profil').evaluate()) {
      final w = el.widget;
      if (w is Text) print('TEXT: [${w.data}]');
    }
  });
}
