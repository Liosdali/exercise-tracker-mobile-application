import 'package:flutter/widgets.dart';

/// Shared [GlobalKey]s used to anchor the first-launch interactive feature
/// tour (see [HomeShell]) to specific widgets: the Dashboard's "start
/// workout" card and the bottom navigation tabs.
class TutorialKeys {
  TutorialKeys._();

  static final dashboardStartWorkout = GlobalKey(debugLabel: 'tutorial_dashboard_start_workout');
  static final navWorkouts = GlobalKey(debugLabel: 'tutorial_nav_workouts');
  static final navTeam = GlobalKey(debugLabel: 'tutorial_nav_team');
  static final navCalendar = GlobalKey(debugLabel: 'tutorial_nav_calendar');
  static final navExercises = GlobalKey(debugLabel: 'tutorial_nav_exercises');
  static final navProfile = GlobalKey(debugLabel: 'tutorial_nav_profile');

  /// Ordered list of keys used to start the guided tour.
  static List<GlobalKey> get tourOrder => [
        dashboardStartWorkout,
        navWorkouts,
        navTeam,
        navCalendar,
        navExercises,
        navProfile,
      ];
}
