import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/models/sync_conflict.dart';
import 'package:exercise_app/models/body_measurement.dart';
import 'package:exercise_app/providers/auth_provider.dart';
import 'package:exercise_app/screens/account_section.dart';
import 'package:exercise_app/screens/profile_edit_screen.dart';
import 'package:exercise_app/screens/measurement_history_screen.dart';
import 'package:exercise_app/screens/settings_screen.dart';
import 'package:exercise_app/screens/sync_conflicts_screen.dart';
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


  test('measurement summary lists only the values that were recorded', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // A weight-only entry must not imply a height or a body fat reading.
    expect(
      measurementSummary(
        l10n,
        const BodyMeasurement(date: '2026-03-12', weightKg: 82, createdAt: ''),
      ),
      '82.0 kg',
    );
    // Body fat is rounded to one decimal; the rest are joined in field order.
    expect(
      measurementSummary(
        l10n,
        const BodyMeasurement(
          date: '2026-03-12',
          weightKg: 82,
          heightCm: 180,
          calculatedBodyFat: 18.246,
          waistCm: 84,
          createdAt: '',
        ),
      ),
      '82.0 kg • 180.0 cm tall • 18.2% fat • Waist 84.0 cm',
    );
    // Nothing recorded yields an empty summary rather than stray separators.
    expect(
      measurementSummary(
        l10n,
        const BodyMeasurement(date: '2026-03-12', createdAt: ''),
      ),
      isEmpty,
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

  testWidgets('conflict cards describe the record instead of dumping JSON', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final accounts = FakeAccounts()
      ..pendingConflicts = const [
        SyncConflict(
          entity: 'body_measurements',
          recordId: 'r1',
          base: {'weight_kg': 80.0, 'notes': null},
          local: {'weight_kg': 82.0, 'notes': null},
          remote: {'weight_kg': 83.5, 'notes': 'felt heavy'},
          remoteRevision: 1,
        ),
      ];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserAccountService>.value(value: accounts),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SyncConflictsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The card speaks the app's vocabulary...
    expect(find.textContaining('Weight'), findsWidgets);
    // ...and no database column name reaches the screen.
    expect(find.textContaining('weight_kg'), findsNothing);
    // Both sides changed, so the origin line says so rather than guessing
    // which one is newer.
    expect(find.textContaining('Both versions changed'), findsOneWidget);

    // The raw payloads survive, two expanders down, for bug reports.
    await tester.tap(find.text('Show details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Raw data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('weight_kg'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    accounts.dispose();
  });
}
