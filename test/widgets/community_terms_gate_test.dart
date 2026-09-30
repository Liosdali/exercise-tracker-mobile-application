import 'package:exercise_app/config/legal_links.dart';
import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/widgets/community_terms_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late bool? result;

  Future<void> openGate(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await ensureCommunityTermsAccepted(context),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks first, remembers acceptance, then passes silently',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await openGate(tester);
    expect(find.text('Community terms'), findsOneWidget);
    await tester.tap(find.text('I agree'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt(communityTermsAcceptedKey),
      LegalLinks.communityTermsVersion,
    );

    await openGate(tester);
    expect(find.text('Community terms'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('declining blocks the action and asks again next time',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await openGate(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await openGate(tester);
    expect(find.text('Community terms'), findsOneWidget);
  });

  testWidgets('an older accepted version is asked again', (tester) async {
    SharedPreferences.setMockInitialValues({
      communityTermsAcceptedKey: LegalLinks.communityTermsVersion - 1,
    });

    await openGate(tester);
    expect(find.text('Community terms'), findsOneWidget);
  });
}
