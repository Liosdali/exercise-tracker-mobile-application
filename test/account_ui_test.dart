import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/providers/auth_provider.dart';
import 'package:exercise_app/screens/account_section.dart';
import 'package:exercise_app/screens/profile_edit_screen.dart';
import 'package:exercise_app/screens/settings_screen.dart';
import 'package:exercise_app/services/user_account_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider_test.dart' show FakeAccounts, FakeAuthGateway;

void main() {
  testWidgets(
    'sign-out confirmation discloses pending changes and unresolved conflicts',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeAuthGateway()..userId = 'A';
      final accounts = FakeAccounts()..conflictCount = 3;
      final auth = AuthProvider(gateway: gateway, accounts: accounts);
      await auth.initialize();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider<UserAccountService>.value(value: accounts),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(child: AccountSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('2 pending changes and 3 unresolved conflicts'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.userId, 'A');
      expect(gateway.calls, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
      accounts.dispose();
      await gateway.controller.close();
    },
  );

  test('optional profile validation rejects invalid and nonfinite values', () {
    for (final value in ['', '0', '35', '150', '151']) {
      expect(validOptionalAge(value), isTrue);
    }
    for (final value in ['-1', '1.5', 'abc']) {
      expect(validOptionalAge(value), isFalse);
    }
    for (final value in ['', '60', '65,5', '170.5']) {
      expect(validOptionalMeasurement(value), isTrue);
    }
    for (final value in ['0', '-1', 'NaN', 'Infinity', 'abc']) {
      expect(validOptionalMeasurement(value), isFalse);
    }
  });


  test('destructive data actions warn only when unsynced work would be lost', () {
    // Signed in with everything uploaded: the cloud already has it, so the
    // reset warning stays as it was.
    expect(
      losesUnsyncedWork(signedIn: true, pending: 0, conflicts: 0),
      isFalse,
    );
    // Pending uploads are destroyed by a reset and never reach other devices.
    expect(losesUnsyncedWork(signedIn: true, pending: 1, conflicts: 0), isTrue);
    // An unresolved conflict holds a local version that is equally lost.
    expect(losesUnsyncedWork(signedIn: true, pending: 0, conflicts: 1), isTrue);
    // A guest has no cloud copy; the plain guest warning already applies and
    // promising anything about "other devices" would be false.
    expect(
      losesUnsyncedWork(signedIn: false, pending: 9, conflicts: 9),
      isFalse,
    );
  });



  testWidgets('mobile guest shows both providers and optional profile editor', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final gateway = FakeAuthGateway();
    final accounts = FakeAccounts();
    final auth = AuthProvider(gateway: gateway, accounts: accounts);
    await auth.initialize();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider<UserAccountService>.value(value: accounts),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: AccountSection())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    await tester.tap(find.text('Edit personal profile'));
    await tester.pumpAndSettle();
    expect(find.text('Age (optional)'), findsOneWidget);
    expect(find.text('Weight (kg, optional)'), findsOneWidget);
    expect(find.text('Height (cm, optional)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    accounts.dispose();
    await gateway.controller.close();
  });

  testWidgets(
    'misconfigured accounts preserve guest access and disable login',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeAuthGateway()..configured = false;
      final accounts = FakeAccounts();
      final auth = AuthProvider(gateway: gateway, accounts: accounts);
      await auth.initialize();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider<UserAccountService>.value(value: accounts),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(child: AccountSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Guest'), findsOneWidget);
      expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
      final login = tester.widget<FilledButton>(
        find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(login.onPressed, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
      accounts.dispose();
      await gateway.controller.close();
    },
  );
}
