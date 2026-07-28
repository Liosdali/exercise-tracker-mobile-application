// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Exercise App';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkouts => 'Workouts';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get dashboardGreeting => 'Hello! 👋';

  @override
  String dashboardStreakActive(int count) {
    return '$count day streak, keep it up!';
  }

  @override
  String get dashboardStreakStart => 'Work out today to start your streak!';

  @override
  String get dashboardWeeklyGoalTitle => 'Weekly Goal';

  @override
  String dashboardWeeklyGoalCount(int done, int goal) {
    return '$done / $goal workouts';
  }

  @override
  String get dashboardTodaysWorkoutTitle => 'Today\'s Workout';

  @override
  String get dashboardCompletedLabel => 'Completed';

  @override
  String get dashboardNoProgramSelected =>
      'No program selected yet. Choose one from the Workouts tab.';

  @override
  String get dashboardManualAssignmentSubtitle => 'Assigned for today';

  @override
  String get dashboardNextWorkoutSubtitle => 'Next up';

  @override
  String get dashboardStartButton => 'Start';

  @override
  String get dashboardTotalWorkoutsLabel => 'Total Workouts';

  @override
  String get dashboardTotalVolumeLabel => 'Total Weight Lifted';

  @override
  String get dashboardMaxStreakLabel => 'Best Streak';

  @override
  String get dashboardTotalDurationLabel => 'Total Workout Time';

  @override
  String get profileTitle => 'Profile & Stats';

  @override
  String get profileBadgesLabel => 'Badges';

  @override
  String get profileStreakLabel => 'Streak';

  @override
  String get profileWeeklyVolumeChartTitle =>
      'Weekly Workout Duration (Minutes)';

  @override
  String get profileAchievementsTitle => 'Achievements';

  @override
  String get profileCalendarLinkTitle => 'Workout Calendar / History';

  @override
  String get profileBodyMeasurementsTitle => 'Body Measurements';

  @override
  String get profileNoMeasurements => 'No measurements logged yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsWeeklyGoalLabel => 'Weekly goal (workouts)';

  @override
  String get settingsRestTimerSound => 'Rest timer sound';

  @override
  String get settingsRestTimerVibration => 'Rest timer vibration';

  @override
  String get settingsResetDataSection => 'Data';

  @override
  String get settingsResetDataButton => 'Reset All Data';

  @override
  String get settingsResetDataConfirmTitle => 'Are you sure?';

  @override
  String get settingsResetDataConfirmMessage =>
      'This will permanently delete all workout history, custom programs/routines, body measurements and achievements. This action cannot be undone.';

  @override
  String get settingsResetDataSuccess => 'All data has been reset.';

  @override
  String get calendarScreenTitle => 'Workout Calendar';

  @override
  String get calendarAssignProgramButton => 'Assign a program';

  @override
  String get calendarClearAssignmentButton => 'Remove assignment';

  @override
  String get calendarPlannedLabel => 'Planned';

  @override
  String get calendarChangeAssignmentButton => 'Change assignment';

  @override
  String get calendarAddExerciseButton => 'Add exercise';

  @override
  String get calendarCompletedChip => 'Completed';

  @override
  String get calendarNoProgramsSnackbar =>
      'First create a program from the Workouts tab.';

  @override
  String get calendarChooseProgramTitle => 'Choose a program';

  @override
  String get calendarChooseDayTitle => 'Which day?';

  @override
  String calendarAssignedLabel(String dayName) {
    return 'Assigned: $dayName';
  }

  @override
  String get calendarNoEntriesMessage => 'No exercises logged for this day.';

  @override
  String calendarTotalDaysLabel(int count) {
    return '$count days';
  }

  @override
  String exerciseDetailTargetLabel(String target) {
    return 'Target: $target';
  }

  @override
  String get exerciseDetailSecondaryMusclesTitle => 'Secondary muscles';

  @override
  String get exerciseDetailInstructionsTitle => 'Instructions';

  @override
  String get exerciseDetailLogButton => 'Log this exercise';

  @override
  String get exercisePickerTitle => 'Pick an exercise';

  @override
  String get exerciseSearchLabel => 'Search exercises';

  @override
  String get exercisePickerAllChip => 'All';

  @override
  String get exerciseSearchNoResults => 'No exercises found.';

  @override
  String get logEntryTitleAdd => 'Log workout';

  @override
  String get logEntryTitleEdit => 'Edit entry';

  @override
  String get logEntryDateLabel => 'Date';

  @override
  String get logEntrySetsLabel => 'Sets';

  @override
  String get logEntryRepsLabel => 'Reps';

  @override
  String get logEntryWeightLabel => 'Weight (kg, optional)';

  @override
  String get logEntryNotesLabel => 'Notes (optional)';

  @override
  String get logEntrySaveEntryButton => 'Save entry';

  @override
  String get logEntrySaveChangesButton => 'Save changes';

  @override
  String get programBuilderPickerTitle => 'Select exercises';

  @override
  String get programBuilderSetsLabel => 'Sets';

  @override
  String get programBuilderRepsLabel => 'Reps';

  @override
  String get programBuilderRemoveButton => 'Remove';
}
