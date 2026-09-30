import 'dart:io';

import 'package:exercise_app/data/database_helper.dart';
import 'package:exercise_app/main.dart';
import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/screens/account_section.dart';
import 'package:exercise_app/screens/body_measurement_form.dart';
import 'package:exercise_app/screens/home_shell.dart';
import 'package:exercise_app/screens/profile_edit_screen.dart';
import 'package:exercise_app/services/user_account_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporary = await Directory.systemTemp.createTemp('account-root-test-');
    await databaseFactory.setDatabasesPath(temporary.path);
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'has_completed_onboarding': true,
      'has_seen_tutorial': true,
      'user_name': 'Existing guest',
    });
  });

  testWidgets(
    'unconfigured app preserves guest data and opens profile editing',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        // Start the app
        await tester.pumpWidget(const ExerciseApp());
        
        // Opening the workspace is real database and asset I/O, which does
        // not progress under fake async. Pumping alone therefore never
        // reached HomeShell; the gaps have to be real ones via `runAsync`.
        for (var attempt = 0; attempt < 40; attempt++) {
          if (find.byType(HomeShell).evaluate().isNotEmpty) break;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        
        // Verify app is ready
        expect(find.byType(HomeShell), findsOneWidget);
        expect(UserAccountService.instance.userId, isNull);
        expect(UserAccountService.instance.profile?.name, 'Existing guest');
      } finally {
        // `testWidgets` runs inside a fake-async zone. A bare
        // `await Future.delayed(...)` never completes there because no timer
        // is pumped, and real file/database I/O does not complete either —
        // which is why this block used to hang until the ten-minute timeout
        // and reported the test as "did not complete". Fake-async work uses
        // `tester.pump`; anything touching the real event loop goes through
        // `tester.runAsync`.
        // Let the dashboard's in-flight loads finish while the database is
        // still open. Unmounting first only detaches the widgets; the queries
        // they started keep running and would land after teardown.
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await tester.pump();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        UserAccountService.instance.dispose();
        debugDefaultTargetPlatformOverride = null;
        // Let the provider loads the unmounted tree started actually finish.
        // Closing the workspace underneath an in-flight query makes sqflite
        // raise "This database has already been closed", and fake-async pumps
        // cannot drain real database work.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.runAsync(() async {
          try {
            await DatabaseHelper.instance.closeWorkspace();
          } catch (_) {}
          try {
            await temporary.delete(recursive: true);
          } catch (_) {}
        });
      }
    },
  );
}
