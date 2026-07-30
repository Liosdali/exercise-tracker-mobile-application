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
  String get dashboardGreeting => 'Hello';

  @override
  String dashboardGreetingWithName(String name) {
    return 'Hello, $name';
  }

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
  String get settingsBackupSection => 'Backup & Restore';

  @override
  String get settingsBackupPrivacyNote =>
      'Your data is stored entirely on this device. There is no account or cloud sync — back up regularly so you don\'t lose your history if you lose or change your phone.';

  @override
  String get settingsBackupExportButton => 'Export Data (JSON)';

  @override
  String get settingsBackupExportSuccess =>
      'Backup file created — choose where to save or share it.';

  @override
  String get settingsBackupExportError =>
      'Couldn\'t create the backup file. Please try again.';

  @override
  String get settingsBackupImportButton => 'Import Data (JSON)';

  @override
  String get settingsBackupImportConfirmTitle => 'Replace all local data?';

  @override
  String settingsBackupImportConfirmMessage(String counts) {
    return 'Importing this backup will permanently replace your current workout history, programs, and measurements with its contents ($counts). This cannot be undone.';
  }

  @override
  String get settingsBackupImportSuccess => 'Backup restored successfully.';

  @override
  String get settingsBackupImportInvalidFile =>
      'This file isn\'t a valid Exercise App backup.';

  @override
  String get settingsBackupImportError =>
      'Couldn\'t restore the backup. Please try again.';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsDisclaimerButton => 'Health & Liability Disclaimer';

  @override
  String get settingsDisclaimerTitle => 'Health & Liability Disclaimer';

  @override
  String get settingsDisclaimerBody =>
      'This app provides general fitness information and workout tracking tools only; it is not medical advice. Consult a physician before starting any new exercise program, especially if you have a pre-existing health condition. Exercise carries an inherent risk of injury — you are solely responsible for exercising safely and within your own limits. The developer accepts no liability for any injury, loss, or damage arising from the use of this app.';

  @override
  String get settingsDisclaimerClose => 'I Understand';

  @override
  String get settingsNotificationsSection => 'Notification Settings';

  @override
  String get settingsNotificationsMasterToggle => 'Enable notifications';

  @override
  String get settingsNotificationsStreakToggle => 'Streak loss warnings';

  @override
  String get settingsNotificationsStreakSubtitle =>
      'Warns you 2 days and 1 day before your streak resets';

  @override
  String get settingsNotificationsDailyToggle => 'Daily workout reminder';

  @override
  String get settingsNotificationsDailySubtitle =>
      'Reminds you at 07:00 if today\'s workout isn\'t done yet';

  @override
  String get notificationStreakWarning2DaysTitle =>
      'Your streak is at risk! 🔥';

  @override
  String notificationStreakWarning2DaysBody(int count) {
    return 'You have $count day streak. Work out within 2 days or you\'ll lose it!';
  }

  @override
  String get notificationStreakWarningLastDayTitle =>
      'Last chance to save your streak! ⚠️';

  @override
  String notificationStreakWarningLastDayBody(int count) {
    return 'Your $count day streak resets tomorrow if you don\'t work out today!';
  }

  @override
  String get notificationDailyReminderTitle => 'Today\'s workout is waiting';

  @override
  String notificationDailyReminderBody(String programTitle, String dayName) {
    return '$programTitle - $dayName is scheduled for today. Let\'s get it done!';
  }

  @override
  String get aboutBodyText =>
      'The app is currently under development. You can send your thoughts and feedback to [baykal246@gmail.com]. Developer and Publisher: Mete Baykal';

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

  @override
  String get achievementFirstWorkoutTitle => 'First Step';

  @override
  String get achievementFirstWorkoutDesc => 'Log your first workout.';

  @override
  String get achievementTenWorkoutsTitle => 'Consistency';

  @override
  String get achievementTenWorkoutsDesc => 'Complete 10 workout days.';

  @override
  String get achievementFiftyWorkoutsTitle => 'Habit';

  @override
  String get achievementFiftyWorkoutsDesc => 'Complete 50 workout days.';

  @override
  String get achievementHundredWorkoutsTitle => 'Century Club';

  @override
  String get achievementHundredWorkoutsDesc => 'Complete 100 workout days.';

  @override
  String get achievementStreak3Title => '3 Days in a Row!';

  @override
  String get achievementStreak3Desc => 'Work out 3 days in a row.';

  @override
  String get achievementStreak7Title => 'Weekly Streak';

  @override
  String get achievementStreak7Desc => 'Work out 7 days in a row.';

  @override
  String get achievementStreak30Title => 'Iron Will';

  @override
  String get achievementStreak30Desc => 'Work out 30 days in a row.';

  @override
  String get achievementVolume10000Title => 'First 10,000 kg';

  @override
  String get achievementVolume10000Desc => 'Lift a total of 10,000 kg.';

  @override
  String get achievementVolume100000Title => 'First 100,000 kg';

  @override
  String get achievementVolume100000Desc => 'Lift a total of 100,000 kg.';

  @override
  String get achievementMinutes60Title => 'First Hour';

  @override
  String get achievementMinutes60Desc =>
      'Complete a total of 60 minutes of training.';

  @override
  String get achievementMinutes600Title => 'Time Master';

  @override
  String get achievementMinutes600Desc =>
      'Complete a total of 600 minutes of training.';

  @override
  String get achievementCalories1000Title => 'First 1000 Calories';

  @override
  String get achievementCalories1000Desc => 'Burn a total of 1000 calories.';

  @override
  String get achievementCalories10000Title => '10,000 Calorie Club';

  @override
  String get achievementCalories10000Desc => 'Burn a total of 10,000 calories.';

  @override
  String get achievementSets100Title => 'One Hundred Sets';

  @override
  String get achievementSets100Desc => 'Complete a total of 100 sets.';

  @override
  String get achievementSets1000Title => 'One Thousand Sets';

  @override
  String get achievementSets1000Desc => 'Complete a total of 1000 sets.';

  @override
  String get programLevelBeginner => 'Beginner';

  @override
  String get programLevelIntermediate => 'Intermediate';

  @override
  String get programLevelAdvanced => 'Advanced';

  @override
  String get programFullBodyName => 'Full Body (Beginner)';

  @override
  String get programFullBodyDescription =>
      'A basic full-body workout program that can be done 2-3 times a week. Requires barbell and dumbbell equipment.';

  @override
  String get programFullBodyDay1 => 'Full Body';

  @override
  String get programHomeBodyweightName => 'Home Bodyweight (Intermediate)';

  @override
  String get programHomeBodyweightDescription =>
      'A 3-day bodyweight workout program requiring no equipment at all, done at home.';

  @override
  String get programHomeBodyweightDay1 => 'Day 1 - Upper Body';

  @override
  String get programHomeBodyweightDay2 => 'Day 2 - Lower Body & Core';

  @override
  String get programHomeBodyweightDay3 => 'Day 3 - Cardio & Full Body';

  @override
  String get programPplName => 'Push-Pull-Legs (Advanced)';

  @override
  String get programPplDescription =>
      'An advanced split workout program, divided into push/pull/legs, that can be done 3-6 times a week.';

  @override
  String get programPplDay1 => 'Push';

  @override
  String get programPplDay2 => 'Pull';

  @override
  String get programPplDay3 => 'Legs';

  @override
  String workoutsAddedSnackbar(String name) {
    return '\"$name\" program added.';
  }

  @override
  String workoutsDaysCountLabel(int count) {
    return '$count-day program';
  }

  @override
  String get workoutsProgramsSectionTitle => 'Programs';

  @override
  String get workoutsMyProgramsSectionTitle => 'My Programs';

  @override
  String get workoutsMyRoutinesSectionTitle => 'My Routines';

  @override
  String get workoutsNewProgramButton => 'New Program';

  @override
  String get workoutsNewRoutineButton => 'New Routine';

  @override
  String get workoutsImportCodeButton => 'Add with Code';

  @override
  String get workoutsImportDialogTitle => 'Add Program with Code';

  @override
  String get workoutsImportDialogHint => 'Paste the program code here';

  @override
  String get workoutsImportConfirmButton => 'Import';

  @override
  String get workoutsNoCustomProgramsMessage =>
      'You haven\'t created any multi-day program yet.';

  @override
  String get workoutsNoCustomRoutinesMessage =>
      'You haven\'t created any custom routine yet.';

  @override
  String get workoutsActivateProgramMenuItem => 'Set as Active Program';

  @override
  String get workoutsEditMenuItem => 'Edit';

  @override
  String get workoutsDeleteMenuItem => 'Delete';

  @override
  String workoutsExerciseCountLabel(int count) {
    return '$count exercises';
  }

  @override
  String get programDetailShareTooltip => 'Share Program';

  @override
  String get programDetailActiveProgramChip => 'Active Program';

  @override
  String get programDetailAlreadyActiveButton => 'This program is active';

  @override
  String get programDetailTodayDoneLabel => 'Completed today';

  @override
  String get programDetailSuggestedSuffix => ' (Next up)';

  @override
  String programDetailCustomDescription(int count) {
    return 'A user-created $count-day program.';
  }

  @override
  String programDetailShareMessage(String name) {
    return 'Try my Atlas Workout training program: \"$name\"';
  }

  @override
  String programBuilderDayDefaultName(int number) {
    return 'Day $number';
  }

  @override
  String get programBuilderValidationMessage =>
      'Enter a program name and add exercises to at least one day.';

  @override
  String get programBuilderNewProgramTitle => 'New Program';

  @override
  String get programBuilderEditProgramTitle => 'Edit Program';

  @override
  String get programBuilderAddDayButton => 'Add Day';

  @override
  String get programBuilderProgramNameLabel => 'Program name';

  @override
  String get programBuilderDayNameLabel => 'Day name';

  @override
  String programBuilderExercisesSelectedLabel(int count) {
    return '$count exercises selected';
  }

  @override
  String get programBuilderEditExercisesButton => 'Edit Exercises';

  @override
  String get routineBuilderValidationMessage =>
      'Enter a name and select at least one exercise.';

  @override
  String get routineBuilderNewRoutineTitle => 'New Routine';

  @override
  String get routineBuilderEditRoutineTitle => 'Edit Routine';

  @override
  String get routineBuilderNameLabel => 'Routine name';

  @override
  String activeWorkoutExerciseCountLabel(int current, int total) {
    return 'Exercise $current/$total';
  }

  @override
  String activeWorkoutSetProgressLabel(int current, int total, int reps) {
    return 'Set $current/$total • Target: $reps reps';
  }

  @override
  String get activeWorkoutRepsLabel => 'Reps';

  @override
  String get activeWorkoutWeightLabel => 'Weight (kg)';

  @override
  String get activeWorkoutFinishButton => 'Finish Workout';

  @override
  String get activeWorkoutCompleteSetButton => 'Complete Set';

  @override
  String activeWorkoutNotesLabel(String title) {
    return 'Workout: $title';
  }

  @override
  String get workoutSummaryTitle => 'Workout Complete';

  @override
  String get workoutSummaryDurationLabel => 'Duration';

  @override
  String workoutSummaryDurationValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get workoutSummaryCaloriesLabel => 'Estimated calories';

  @override
  String get workoutSummaryBackHomeButton => 'Back to Home';
}
