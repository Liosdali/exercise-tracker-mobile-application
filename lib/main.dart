import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/custom_program_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/program_progress_provider.dart';
import 'providers/program_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_name_screen.dart';

void main() {
  runApp(const ExerciseApp());
}

/// Root widget: wires up app-wide providers and the Material app shell.
class ExerciseApp extends StatelessWidget {
  const ExerciseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => CustomProgramProvider()),
        ChangeNotifierProvider(create: (_) => ProgramProgressProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Exercise App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            // A manual language override takes precedence; otherwise fall
            // back to the device's system locale (resolved below), with
            // English as the ultimate fallback for unsupported languages.
            locale: settings.languageCode != null ? Locale(settings.languageCode!) : null,
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
    if (!loaded || !settings.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!settings.hasCompletedOnboarding) {
      return const OnboardingNameScreen();
    }
    return const HomeShell();
  }
}
