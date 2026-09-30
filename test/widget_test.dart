// Smoke test for Atlas Workout: the app launches, loads the bundled exercise
// dataset, shows the dashboard, and can reach the profile tab.
//
// Labels are read from AppLocalizations rather than written out, because the
// app resolves its locale from the platform. Hardcoding Turkish strings made
// this test fail on an English test host for a UI that was working fine.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/main.dart';
import 'package:exercise_app/services/user_account_service.dart';

void main() {
  // The test host has no platform sqflite/shared_preferences plugins; use
  // the FFI database implementation and in-memory shared_preferences mock
  // so the app behaves the same way it does on a real device.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});

    // `defaultTargetPlatform` reports android under `flutter test`, so the
    // app's deep-link guard does not apply here and `app_links` really does
    // try to open its channels. Activating its event channel with no plugin
    // registered raises a MissingPluginException that reaches
    // FlutterError.onError and fails the test, so stub both channels.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in const [
      'com.llfbandit.app_links/messages',
      'com.llfbandit.app_links/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (MethodCall call) async => null,
      );
    }
  });

  /// Pumps with real async gaps until [ready] is satisfied or the budget runs
  /// out. The dataset load and the stats queries are genuine I/O, so they need
  /// `runAsync` rather than a fixed fake-async delay.
  Future<void> settleUntil(
    WidgetTester tester,
    bool Function() ready, {
    int attempts = 20,
  }) async {
    for (var i = 0; i < attempts && !ready(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('app launches, shows the dashboard and reaches the profile tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ExerciseApp());
    await tester.pump();

    await settleUntil(tester, () => find.byType(Scaffold).evaluate().isNotEmpty);

    // Read the strings the app actually resolved, whatever locale that is.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    )!;

    // A fresh install opens on the onboarding name prompt, not the shell.
    // The previous version of this test assumed it went straight to the
    // dashboard, so it could never have passed once onboarding was added.
    if (find.text(l10n.accountSkip).evaluate().isNotEmpty) {
      await tester.tap(find.text(l10n.accountSkip));
      await tester.pump();
    }

    await settleUntil(
      tester,
      () => find.text(l10n.navHome).evaluate().isNotEmpty,
    );

    // The dashboard is the default tab.
    expect(find.text(l10n.navHome), findsWidgets);

    // Four labelled destinations, plus Team, which is the featured centre
    // button and renders as an icon with no text label — so it is matched by
    // its icon rather than by `l10n.navTeam`.
    for (final label in [
      l10n.navHome,
      l10n.navWorkouts,
      l10n.navCalendar,
      l10n.navProfile,
    ]) {
      expect(find.text(label), findsWidgets, reason: 'missing tab: $label');
    }
    expect(find.byIcon(Icons.group_outlined), findsWidgets);

    await tester.tap(find.text(l10n.navProfile).last);
    await tester.pump();

    await settleUntil(
      tester,
      () => find.text(l10n.profileTitle).evaluate().isNotEmpty,
    );
    expect(find.text(l10n.profileTitle), findsWidgets);

    // The account service runs a five-second poll; cancel it so the test does
    // not fail on a pending timer. Same clean shutdown account_app_root_test
    // performs.
    UserAccountService.instance.dispose();
  });
}
