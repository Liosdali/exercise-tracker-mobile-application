import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/date_watcher.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'profile_stats_screen.dart';
import 'workouts_screen.dart';

/// Root shell with bottom navigation across the 4 main sections: Dashboard,
/// Workouts, Exercise library, Profile & Stats.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    WorkoutsScreen(),
    CategoriesScreen(),
    ProfileStatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppDateWatcher(
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_view_week_outlined),
              selectedIcon: const Icon(Icons.calendar_view_week),
              label: l10n.navWorkouts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.fitness_center_outlined),
              selectedIcon: const Icon(Icons.fitness_center),
              label: l10n.navExercises,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
