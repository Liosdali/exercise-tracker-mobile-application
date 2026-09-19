// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Atlas Workout';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkouts => 'Workouts';

  @override
  String get navTeam => 'Team';

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
  String get settingsThemeSection => 'Theme';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

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
      'This file isn\'t a valid Atlas Workout backup.';

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
  String get settingsTutorialSection => 'Help';

  @override
  String get settingsReplayTutorialButton => 'Show Feature Tour Again';

  @override
  String get tutorialStartWorkoutTitle => 'Start a Workout';

  @override
  String get tutorialStartWorkoutDescription =>
      'Start today\'s suggested workout here and log your sets as you go.';

  @override
  String get tutorialWorkoutsTabTitle => 'Workouts';

  @override
  String get tutorialWorkoutsTabDescription =>
      'Browse ready-made programs, or build your own custom routines and multi-day programs.';

  @override
  String get tutorialTeamTabTitle => 'Team';

  @override
  String get tutorialTeamTabDescription =>
      'Connect with friends, share your progress, and find motivation in our community.';

  @override
  String get tutorialCalendarTabTitle => 'Calendar';

  @override
  String get tutorialCalendarTabDescription =>
      'See your workout history and plan upcoming sessions on the calendar.';

  @override
  String get tutorialExercisesTabTitle => 'Exercises';

  @override
  String get tutorialExercisesTabDescription =>
      'Explore the exercise library, grouped by muscle category.';

  @override
  String get tutorialProfileTabTitle => 'Profile & Stats';

  @override
  String get tutorialProfileTabDescription =>
      'Track your streaks, badges, and overall progress here.';

  @override
  String get tutorialSkipButton => 'Skip Tour';

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

  @override
  String get accountTitle => 'Account';

  @override
  String get accountGuest => 'Guest';

  @override
  String get accountGuestDescription =>
      'Your guest data stays on this device. Sign in to privately sync across devices.';

  @override
  String get accountSignedIn => 'Signed in';

  @override
  String get accountEditProfile => 'Edit personal profile';

  @override
  String get accountGoogle => 'Continue with Google';

  @override
  String get accountApple => 'Continue with Apple';

  @override
  String get accountConfigurationError =>
      'Accounts are unavailable: SUPABASE_URL and SUPABASE_ANON_KEY must be configured correctly. You can still use guest mode offline.';

  @override
  String get accountMobileOnly =>
      'Google and Apple sign-in is available on Android and iOS.';

  @override
  String get accountLoginError =>
      'Sign-in failed. Check your connection and try again.';

  @override
  String get accountLoginCancelled =>
      'Sign-in was cancelled or timed out. Your local data is unchanged.';

  @override
  String get accountSessionExpired =>
      'Your session needs renewal. Sign in again to sync; your saved data remains available offline.';

  @override
  String get accountOperationError =>
      'The operation could not be completed. Your saved data is retained. Please try again.';

  @override
  String get accountWorkspaceError =>
      'Your local workspace could not be opened. Retry to safely load your data.';

  @override
  String get accountRetry => 'Retry';

  @override
  String get accountBrowserWaiting =>
      'Complete sign-in in your browser. If you closed it, cancel here to try again.';

  @override
  String get accountGuestImportTitle => 'Import guest data?';

  @override
  String get accountGuestImportMessage =>
      'Copy this device\'s guest workouts, programs, profile and history into this account? Only import data that belongs to you. Guest data is kept separately, and importing may upload it to your private account.';

  @override
  String get accountGuestImportAccept => 'Import my guest data';

  @override
  String get accountGuestImportDecline => 'Keep guest data separate';

  @override
  String get accountSyncing => 'Syncing private account data…';

  @override
  String accountPending(int count) {
    return '$count pending changes';
  }

  @override
  String get accountSyncError =>
      'Sync failed. Your changes are saved on this device. Check your connection and retry.';

  @override
  String get accountSyncNow => 'Sync / retry';

  @override
  String accountConflicts(int count) {
    return 'Resolve conflicts ($count)';
  }

  @override
  String get accountSignOut => 'Sign out';

  @override
  String accountSignOutWarning(int count, int conflicts) {
    return 'There are $count pending changes and $conflicts unresolved conflicts. Unsynced data and both conflict versions stay in this account\'s workspace on this device, but may not yet be available elsewhere. Sign out and return to the separate guest workspace?';
  }

  @override
  String get accountProfileOptional =>
      'All fields are optional. Age and measurements are not required for sign-in. Changes are saved in your current workspace.';

  @override
  String get accountName => 'Name';

  @override
  String get accountAge => 'Age (optional)';

  @override
  String get accountWeight => 'Weight (kg, optional)';

  @override
  String get accountHeight => 'Height (cm, optional)';

  @override
  String get accountGender => 'Gender (optional)';

  @override
  String get accountGenderUnspecified => 'Prefer not to say';

  @override
  String get accountGenderFemale => 'Female';

  @override
  String get accountGenderMale => 'Male';

  @override
  String get accountGenderOther => 'Other';

  @override
  String get accountAgeInvalid =>
      'Enter a nonnegative whole number or leave blank.';

  @override
  String get accountMeasurementInvalid =>
      'Enter a finite number greater than zero or leave blank.';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteSummary =>
      'Permanently remove your account and server data.';

  @override
  String get accountDeleteWarning =>
      'Permanently delete this account and all its private and social server data? Pending local changes will also be removed. Guest data is separate. This cannot be undone and requires a connection. If linked to Apple, its authorization must be revoked by the server before deletion can complete.';

  @override
  String get accountDeleteError =>
      'Account deletion could not be completed. No success has been confirmed. Reconnect and retry; contact support if Apple authorization cannot be revoked.';

  @override
  String get accountCloudResetWarning =>
      'This resets only the signed-in account\'s workspace. Deletions will sync to this account on your other devices. Guest data and other accounts are unaffected.';

  @override
  String get accountCloudImportWarning =>
      'This replaces data in the signed-in account\'s workspace. The imported changes and deletions will sync to this account on other devices. Guest data and other accounts are unaffected.';

  @override
  String get accountGuestResetWarning =>
      'Only this device\'s guest workspace is affected. Signed-in account workspaces are unchanged.';

  @override
  String get accountBackupScope =>
      'Exports contain only the current workspace, never sign-in tokens or credentials. Keep backups private: they may include personal profile and health data.';

  @override
  String get accountWelcome => 'Welcome!';

  @override
  String get accountOnboardingName => 'What should we call you? (Optional)';

  @override
  String get accountContinue => 'Continue';

  @override
  String get accountSkip => 'Skip';

  @override
  String get accountDeletionCleanupError =>
      'Your server account was deleted, but device cleanup did not finish. Retry to remove its local data and credentials safely.';

  @override
  String get syncConflictsTitle => 'Resolve sync conflicts';

  @override
  String get syncConflictResolveError =>
      'The conflict could not be resolved. Both versions are retained; reconnect and retry.';

  @override
  String get syncNoConflicts => 'No unresolved conflicts.';

  @override
  String get syncConflictDeleted => 'Deleted record';

  @override
  String get syncLocalVersion => 'This device\'s version';

  @override
  String get syncRemoteVersion => 'Account\'s server version';

  @override
  String get syncKeepLocal => 'Use device version';

  @override
  String get syncKeepRemote => 'Use server version';

  @override
  String get accountDeletedSuccess =>
      'Your account has been deleted from the server and its local data has been removed. Your separate guest data is unchanged.';

  @override
  String get accountContinueAsGuest => 'Continue as guest';

  @override
  String get accountAppleReauthentication =>
      'Apple authorization must be revoked before deletion. Sign in with Apple again on Android, then retry deleting your account. If Apple does not supply a refresh token, use an iOS device or contact support. No account data has been deleted.';

  @override
  String get accountAppleReauthenticateButton => 'Reauthenticate with Apple';

  @override
  String get accountDeletionCancelled =>
      'Account deletion was cancelled. Your account and data are unchanged.';

  @override
  String get accountDeletionUnavailable =>
      'Account deletion is not configured on the server. Contact support to complete deletion. Your account and data have not been deleted.';

  @override
  String get accountAppleMismatch =>
      'This Apple account does not match the Apple identity linked to your current account. Reauthenticate with the correct Apple account and retry. Nothing has been deleted.';

  @override
  String get syncRelatedRecordsNotice =>
      'This conflict includes related workout records. Choosing a version applies to the whole group.';

  @override
  String get teamCreateTeam => 'Create Team';

  @override
  String get teamJoinTeam => 'Join Team';

  @override
  String get teamEmptyTitle => 'No Teams Yet';

  @override
  String get teamEmptyDescription =>
      'Create a new team to start connecting with friends, or join an existing one with an invite code.';

  @override
  String get teamCreateDescription =>
      'Create a new team to collaborate with friends and track workouts together.';

  @override
  String get teamNameLabel => 'Team Name';

  @override
  String get teamNameRequired => 'Please enter a team name';

  @override
  String get teamDescriptionLabel => 'Team Description';

  @override
  String get teamCreatedSuccess => 'Team created successfully!';

  @override
  String get teamCreateNote =>
      'You\'ll be automatically added as the team admin with an invite code to share.';

  @override
  String get teamJoinDescription =>
      'Enter the invite code to join an existing team. You can get this code from the team owner.';

  @override
  String get teamInviteCodeLabel => 'Invite Code';

  @override
  String get teamCodeRequired => 'Please enter an invite code';

  @override
  String get teamInviteCodeHint =>
      'Share this code with others to invite them to your team';

  @override
  String get teamInviteCodeTip => 'Tips for finding your invite code:';

  @override
  String get teamInviteCodeTip1 =>
      'Ask the team owner to share the invite code from team settings';

  @override
  String get teamInviteCodeTip2 =>
      'The code is typically 8 characters long and all uppercase';

  @override
  String get teamCodeInvalid =>
      'Invalid invite code. Please check and try again.';

  @override
  String get teamAlreadyMember => 'You are already a member of this team.';

  @override
  String get teamJoinError => 'Error joining team. Please try again.';

  @override
  String teamJoinedSuccess(String teamName) {
    return 'Successfully joined $teamName!';
  }

  @override
  String get teamMembers => 'Members';

  @override
  String get teamNoMembers => 'No members yet';

  @override
  String get teamAdmin => 'Admin';

  @override
  String get teamInviteMembers => 'Invite Members';

  @override
  String get teamInviteCode => 'Invite Code';

  @override
  String get teamInviteLink => 'Invite Link';

  @override
  String get teamCodeCopied => 'Invite code copied to clipboard';

  @override
  String get teamLeave => 'Leave Team';

  @override
  String get teamLeaveConfirmTitle => 'Leave Team';

  @override
  String teamLeaveConfirmMessage(String teamName) {
    return 'Are you sure you want to leave $teamName?';
  }

  @override
  String get teamLeftSuccess => 'You have left the team';

  @override
  String get teamLeaveError => 'Error leaving team. Please try again.';

  @override
  String get teamDeleteConfirmTitle => 'Delete Team';

  @override
  String teamDeleteConfirmMessage(String teamName) {
    return 'Are you sure you want to delete $teamName? This action cannot be undone.';
  }

  @override
  String get teamDeletedSuccess => 'Team deleted successfully';

  @override
  String get teamDeleteError => 'Error deleting team. Please try again.';

  @override
  String get teamSelectTeam => 'Select a team';

  @override
  String get teamSignInRequired =>
      'Sign in to create or join a team. Your guest workouts stay on this device.';

  @override
  String get teamLoadError =>
      'Couldn\'t load your teams. Check your connection and try again.';

  @override
  String get teamFeedError =>
      'Couldn\'t load the activity feed. Check your connection and try again.';

  @override
  String get teamMyTeams => 'My Teams';

  @override
  String get teamShareInvite => 'Share Invite Link';

  @override
  String get teamLinkCopied => 'Invite link copied to clipboard';

  @override
  String get suggestionInbox => 'Suggestions';

  @override
  String teamInviteMessage(String teamName) {
    return 'Join my team $teamName on Atlas Workout!';
  }

  @override
  String get teamAllMembers => 'All Members';

  @override
  String get teamNoActivity =>
      'No social activity yet.\nJoin a team or invite friends!';

  @override
  String get teamActivity => 'Team Activity';

  @override
  String get teamActivityWorkouts => 'Workouts';

  @override
  String get teamActivityCalories => 'Calories';

  @override
  String get teamActivityMinutes => 'Minutes';

  @override
  String get memberActivityDetail => 'Member Activity Details';

  @override
  String get teamMember => 'Team Member';

  @override
  String get actionSuggest => 'Suggest';

  @override
  String get suggestionTitle => 'Suggest Program Change';

  @override
  String get teamLeaderboard => 'Leaderboard';

  @override
  String get leaderboardWeekly => 'Weekly';

  @override
  String get leaderboardMonthly => 'Monthly';

  @override
  String get leaderboardMetricWorkouts => 'Workouts';

  @override
  String get leaderboardMetricWeight => 'Weight Lifted';

  @override
  String get leaderboardMetricCalories => 'Calories';

  @override
  String get leaderboardEmpty => 'Leaderboard is empty';

  @override
  String get leaderboardWorkouts => 'workouts';

  @override
  String get leaderboardRank => 'Rank';

  @override
  String get leaderboardStats => 'Statistics';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get suggestionPending => 'Pending';

  @override
  String get suggestionAccepted => 'Accepted';

  @override
  String get suggestionRejected => 'Rejected';

  @override
  String get suggestionNoPending => 'No pending suggestions';

  @override
  String get suggestionNone => 'No suggestions';

  @override
  String get suggestionNoMessage => '(No message provided)';

  @override
  String get suggestionStatusPending => 'Pending';

  @override
  String get suggestionStatusAccepted => 'Accepted';

  @override
  String get suggestionStatusRejected => 'Rejected';

  @override
  String get suggestionDetail => 'Suggestion Details';

  @override
  String get suggestionType => 'Type';

  @override
  String get suggestionMessage => 'Message';

  @override
  String get suggestionYourResponse => 'Your Response';

  @override
  String get suggestionResponseHint => 'Add an optional response (optional)';

  @override
  String get suggestionTheirResponse => 'Their Response';

  @override
  String get suggestionReject => 'Reject';

  @override
  String get suggestionAccept => 'Accept';

  @override
  String get suggestionAcceptedSuccess => 'Suggestion accepted!';

  @override
  String get suggestionRejectedSuccess => 'Suggestion rejected!';

  @override
  String get suggestionTypeExercise => 'Exercise';

  @override
  String get suggestionTypeProgram => 'Program Change';

  @override
  String get suggestionTypeFeedback => 'Feedback';
}
