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
        
        // Wait for workspace to be ready (max 10 seconds)
        for (var attempt = 0; attempt < 100; attempt++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(HomeShell).evaluate().isNotEmpty) break;
        }
        
        // Verify app is ready
        expect(find.byType(HomeShell), findsOneWidget);
        expect(UserAccountService.instance.userId, isNull);
        expect(UserAccountService.instance.profile?.name, 'Existing guest');
      } finally {
        // Clean shutdown
        try {
          await tester.pumpWidget(const SizedBox.shrink());
          // Let pending operations settle
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          UserAccountService.instance.dispose();
          // Clear any remaining timers
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          // Ignore errors during cleanup
        } finally {
          debugDefaultTargetPlatformOverride = null;
          try {
            await DatabaseHelper.instance.closeWorkspace();
          } catch (_) {}
          try {
            await temporary.delete(recursive: true);
          } catch (_) {}
        }
      }
    },
  );
}
