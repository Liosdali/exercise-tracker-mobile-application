import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/custom_program_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/program_progress_provider.dart';
import 'providers/program_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/team_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/home_shell.dart';
import 'screens/account_section.dart';
import 'screens/onboarding_name_screen.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'services/user_account_service.dart';
import 'theme/atlas_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await SupabaseService().initialize();
  runApp(const ExerciseApp());
}

/// Root widget: wires up app-wide providers and the Material app shell.
class ExerciseApp extends StatelessWidget {
  const ExerciseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(
        gateway: SupabaseService(),
        accounts: UserAccountService.instance,
        beforeWorkspaceSwitch: () async {
          await WidgetsBinding.instance.endOfFrame;
          // Notifications are peripheral; the account workspace is not.
          // A plugin that fails to initialise — an unsupported platform, a
          // revoked permission, an OEM quirk, a test binding with no plugin
          // registered — must not stop the workspace from opening, because
          // AuthProvider treats a throw from this hook as a failed switch
          // and leaves the app with no account store at all.
          try {
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS)) {
              await NotificationService.instance.init();
            }
            await NotificationService.instance.cancelAll();
          } catch (error) {
            debugPrint('[notifications] setup skipped: $error');
          }
        },
      )..initialize(),
      child: const _AccountRoot(),
    );
  }
}

class _AccountRoot extends StatefulWidget {
  const _AccountRoot();

  @override
  State<_AccountRoot> createState() => _AccountRootState();
}

class _AccountRootState extends State<_AccountRoot>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthProvider>().resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.workspaceReady) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child:
                  auth.error == AccountAuthError.workspace ||
                      auth.error == AccountAuthError.operation ||
                      auth.error == AccountAuthError.appleAccountMismatch ||
                      auth.error == AccountAuthError.deletionCleanup
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          accountErrorText(
                            AppLocalizations.of(context)!,
                            auth.error!,
                          ),
                        ),
                        TextButton(
                          onPressed: auth.retryWorkspace,
                          child: Text(
                            AppLocalizations.of(context)!.accountRetry,
                          ),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }
    return MultiProvider(
      key: ValueKey(auth.workspaceKey),
      providers: [
        ChangeNotifierProvider.value(value: UserAccountService.instance),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => CustomProgramProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProgressProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Atlas Workout',
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: settings.themeMode,
            // A manual language override takes precedence; otherwise fall
            // back to the device's system locale (resolved below), with
            // English as the ultimate fallback for unsupported languages.
            locale: settings.languageCode != null
                ? Locale(settings.languageCode!)
                : null,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (deviceLocale != null) {
                for (final locale in supportedLocales) {
                  if (locale.languageCode == deviceLocale.languageCode) {
                    return locale;
                  }
                }
              }
              return const Locale('en');
            },
            home: const AppLoader(),
          );
        },
      ),
    );
  }
}

/// Loads the bundled exercise dataset before showing the main app shell.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  @override
  void initState() {
    super.initState();
    context.read<ExerciseProvider>().load();
    context.read<SettingsProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final loaded = context.watch<ExerciseProvider>().isLoaded;
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    if (auth.accountDeleted) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 48),
                Text(l10n.accountDeletedSuccess, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: auth.acknowledgeDeletion,
                  child: Text(l10n.accountContinueAsGuest),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!loaded || !settings.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!settings.hasCompletedOnboarding &&
        !context.watch<AuthProvider>().signedIn) {
      return const OnboardingNameScreen();
    }
    if (context.watch<AuthProvider>().offerGuestImport) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.accountGuestImportTitle),
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: AccountSection(),
        ),
      );
    }
    return const HomeShell();
  }
}
