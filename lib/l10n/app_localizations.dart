import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Atlas Workout'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get navExercises;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get dashboardGreeting;

  /// No description provided for @dashboardGreetingWithName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String dashboardGreetingWithName(String name);

  /// No description provided for @dashboardStreakActive.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak, keep it up!'**
  String dashboardStreakActive(int count);

  /// No description provided for @dashboardStreakStart.
  ///
  /// In en, this message translates to:
  /// **'Work out today to start your streak!'**
  String get dashboardStreakStart;

  /// No description provided for @dashboardWeeklyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal'**
  String get dashboardWeeklyGoalTitle;

  /// No description provided for @dashboardWeeklyGoalCount.
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} workouts'**
  String dashboardWeeklyGoalCount(int done, int goal);

  /// No description provided for @dashboardTodaysWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workout'**
  String get dashboardTodaysWorkoutTitle;

  /// No description provided for @dashboardCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardCompletedLabel;

  /// No description provided for @dashboardNoProgramSelected.
  ///
  /// In en, this message translates to:
  /// **'No program selected yet. Choose one from the Workouts tab.'**
  String get dashboardNoProgramSelected;

  /// No description provided for @dashboardManualAssignmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned for today'**
  String get dashboardManualAssignmentSubtitle;

  /// No description provided for @dashboardNextWorkoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get dashboardNextWorkoutSubtitle;

  /// No description provided for @dashboardStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get dashboardStartButton;

  /// No description provided for @dashboardTotalWorkoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Workouts'**
  String get dashboardTotalWorkoutsLabel;

  /// No description provided for @dashboardTotalVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Weight Lifted'**
  String get dashboardTotalVolumeLabel;

  /// No description provided for @dashboardMaxStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get dashboardMaxStreakLabel;

  /// No description provided for @dashboardTotalDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Workout Time'**
  String get dashboardTotalDurationLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Stats'**
  String get profileTitle;

  /// No description provided for @profileBadgesLabel.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get profileBadgesLabel;

  /// No description provided for @profileStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get profileStreakLabel;

  /// No description provided for @profileWeeklyVolumeChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Workout Duration (Minutes)'**
  String get profileWeeklyVolumeChartTitle;

  /// No description provided for @profileAchievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievementsTitle;

  /// No description provided for @profileCalendarLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Calendar / History'**
  String get profileCalendarLinkTitle;

  /// No description provided for @profileBodyMeasurementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Body Measurements'**
  String get profileBodyMeasurementsTitle;

  /// No description provided for @profileNoMeasurements.
  ///
  /// In en, this message translates to:
  /// **'No measurements logged yet.'**
  String get profileNoMeasurements;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTurkish;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsWeeklyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal (workouts)'**
  String get settingsWeeklyGoalLabel;

  /// No description provided for @settingsRestTimerSound.
  ///
  /// In en, this message translates to:
  /// **'Rest timer sound'**
  String get settingsRestTimerSound;

  /// No description provided for @settingsRestTimerVibration.
  ///
  /// In en, this message translates to:
  /// **'Rest timer vibration'**
  String get settingsRestTimerVibration;

  /// No description provided for @settingsResetDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsResetDataSection;

  /// No description provided for @settingsResetDataButton.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get settingsResetDataButton;

  /// No description provided for @settingsResetDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get settingsResetDataConfirmTitle;

  /// No description provided for @settingsResetDataConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all workout history, custom programs/routines, body measurements and achievements. This action cannot be undone.'**
  String get settingsResetDataConfirmMessage;

  /// No description provided for @settingsResetDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data has been reset.'**
  String get settingsResetDataSuccess;

  /// No description provided for @settingsBackupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackupSection;

  /// No description provided for @settingsBackupPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored entirely on this device. There is no account or cloud sync — back up regularly so you don\'t lose your history if you lose or change your phone.'**
  String get settingsBackupPrivacyNote;

  /// No description provided for @settingsBackupExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export Data (JSON)'**
  String get settingsBackupExportButton;

  /// No description provided for @settingsBackupExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup file created — choose where to save or share it.'**
  String get settingsBackupExportSuccess;

  /// No description provided for @settingsBackupExportError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the backup file. Please try again.'**
  String get settingsBackupExportError;

  /// No description provided for @settingsBackupImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import Data (JSON)'**
  String get settingsBackupImportButton;

  /// No description provided for @settingsBackupImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all local data?'**
  String get settingsBackupImportConfirmTitle;

  /// No description provided for @settingsBackupImportConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Importing this backup will permanently replace your current workout history, programs, and measurements with its contents ({counts}). This cannot be undone.'**
  String settingsBackupImportConfirmMessage(String counts);

  /// No description provided for @settingsBackupImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get settingsBackupImportSuccess;

  /// No description provided for @settingsBackupImportInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a valid Atlas Workout backup.'**
  String get settingsBackupImportInvalidFile;

  /// No description provided for @settingsBackupImportError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore the backup. Please try again.'**
  String get settingsBackupImportError;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsDisclaimerButton.
  ///
  /// In en, this message translates to:
  /// **'Health & Liability Disclaimer'**
  String get settingsDisclaimerButton;

  /// No description provided for @settingsDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Health & Liability Disclaimer'**
  String get settingsDisclaimerTitle;

  /// No description provided for @settingsDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'This app provides general fitness information and workout tracking tools only; it is not medical advice. Consult a physician before starting any new exercise program, especially if you have a pre-existing health condition. Exercise carries an inherent risk of injury — you are solely responsible for exercising safely and within your own limits. The developer accepts no liability for any injury, loss, or damage arising from the use of this app.'**
  String get settingsDisclaimerBody;

  /// No description provided for @settingsDisclaimerClose.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get settingsDisclaimerClose;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get settingsNotificationsSection;

  /// No description provided for @settingsNotificationsMasterToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get settingsNotificationsMasterToggle;

  /// No description provided for @settingsNotificationsStreakToggle.
  ///
  /// In en, this message translates to:
  /// **'Streak loss warnings'**
  String get settingsNotificationsStreakToggle;

  /// No description provided for @settingsNotificationsStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warns you 2 days and 1 day before your streak resets'**
  String get settingsNotificationsStreakSubtitle;

  /// No description provided for @settingsNotificationsDailyToggle.
  ///
  /// In en, this message translates to:
  /// **'Daily workout reminder'**
  String get settingsNotificationsDailyToggle;

  /// No description provided for @settingsNotificationsDailySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminds you at 07:00 if today\'s workout isn\'t done yet'**
  String get settingsNotificationsDailySubtitle;

  /// No description provided for @notificationStreakWarning2DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Your streak is at risk! 🔥'**
  String get notificationStreakWarning2DaysTitle;

  /// No description provided for @notificationStreakWarning2DaysBody.
  ///
  /// In en, this message translates to:
  /// **'You have {count} day streak. Work out within 2 days or you\'ll lose it!'**
  String notificationStreakWarning2DaysBody(int count);

  /// No description provided for @notificationStreakWarningLastDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Last chance to save your streak! ⚠️'**
  String get notificationStreakWarningLastDayTitle;

  /// No description provided for @notificationStreakWarningLastDayBody.
  ///
  /// In en, this message translates to:
  /// **'Your {count} day streak resets tomorrow if you don\'t work out today!'**
  String notificationStreakWarningLastDayBody(int count);

  /// No description provided for @notificationDailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s workout is waiting'**
  String get notificationDailyReminderTitle;

  /// No description provided for @notificationDailyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{programTitle} - {dayName} is scheduled for today. Let\'s get it done!'**
  String notificationDailyReminderBody(String programTitle, String dayName);

  /// No description provided for @aboutBodyText.
  ///
  /// In en, this message translates to:
  /// **'The app is currently under development. You can send your thoughts and feedback to [baykal246@gmail.com]. Developer and Publisher: Mete Baykal'**
  String get aboutBodyText;

  /// No description provided for @calendarScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Calendar'**
  String get calendarScreenTitle;

  /// No description provided for @calendarAssignProgramButton.
  ///
  /// In en, this message translates to:
  /// **'Assign a program'**
  String get calendarAssignProgramButton;

  /// No description provided for @calendarClearAssignmentButton.
  ///
  /// In en, this message translates to:
  /// **'Remove assignment'**
  String get calendarClearAssignmentButton;

  /// No description provided for @calendarPlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get calendarPlannedLabel;

  /// No description provided for @calendarChangeAssignmentButton.
  ///
  /// In en, this message translates to:
  /// **'Change assignment'**
  String get calendarChangeAssignmentButton;

  /// No description provided for @calendarAddExerciseButton.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get calendarAddExerciseButton;

  /// No description provided for @calendarCompletedChip.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get calendarCompletedChip;

  /// No description provided for @calendarNoProgramsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'First create a program from the Workouts tab.'**
  String get calendarNoProgramsSnackbar;

  /// No description provided for @calendarChooseProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a program'**
  String get calendarChooseProgramTitle;

  /// No description provided for @calendarChooseDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Which day?'**
  String get calendarChooseDayTitle;

  /// No description provided for @calendarAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {dayName}'**
  String calendarAssignedLabel(String dayName);

  /// No description provided for @calendarNoEntriesMessage.
  ///
  /// In en, this message translates to:
  /// **'No exercises logged for this day.'**
  String get calendarNoEntriesMessage;

  /// No description provided for @calendarTotalDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String calendarTotalDaysLabel(int count);

  /// No description provided for @exerciseDetailTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target: {target}'**
  String exerciseDetailTargetLabel(String target);

  /// No description provided for @exerciseDetailSecondaryMusclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Secondary muscles'**
  String get exerciseDetailSecondaryMusclesTitle;

  /// No description provided for @exerciseDetailInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get exerciseDetailInstructionsTitle;

  /// No description provided for @exerciseDetailLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log this exercise'**
  String get exerciseDetailLogButton;

  /// No description provided for @exercisePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an exercise'**
  String get exercisePickerTitle;

  /// No description provided for @exerciseSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get exerciseSearchLabel;

  /// No description provided for @exercisePickerAllChip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exercisePickerAllChip;

  /// No description provided for @exerciseSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No exercises found.'**
  String get exerciseSearchNoResults;

  /// No description provided for @logEntryTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Log workout'**
  String get logEntryTitleAdd;

  /// No description provided for @logEntryTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get logEntryTitleEdit;

  /// No description provided for @logEntryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get logEntryDateLabel;

  /// No description provided for @logEntrySetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get logEntrySetsLabel;

  /// No description provided for @logEntryRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get logEntryRepsLabel;

  /// No description provided for @logEntryWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg, optional)'**
  String get logEntryWeightLabel;

  /// No description provided for @logEntryNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get logEntryNotesLabel;

  /// No description provided for @logEntrySaveEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get logEntrySaveEntryButton;

  /// No description provided for @logEntrySaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get logEntrySaveChangesButton;

  /// No description provided for @programBuilderPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select exercises'**
  String get programBuilderPickerTitle;

  /// No description provided for @programBuilderSetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get programBuilderSetsLabel;

  /// No description provided for @programBuilderRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get programBuilderRepsLabel;

  /// No description provided for @programBuilderRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get programBuilderRemoveButton;

  /// No description provided for @achievementFirstWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'First Step'**
  String get achievementFirstWorkoutTitle;

  /// No description provided for @achievementFirstWorkoutDesc.
  ///
  /// In en, this message translates to:
  /// **'Log your first workout.'**
  String get achievementFirstWorkoutDesc;

  /// No description provided for @achievementTenWorkoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get achievementTenWorkoutsTitle;

  /// No description provided for @achievementTenWorkoutsDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 workout days.'**
  String get achievementTenWorkoutsDesc;

  /// No description provided for @achievementFiftyWorkoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get achievementFiftyWorkoutsTitle;

  /// No description provided for @achievementFiftyWorkoutsDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 workout days.'**
  String get achievementFiftyWorkoutsDesc;

  /// No description provided for @achievementHundredWorkoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Century Club'**
  String get achievementHundredWorkoutsTitle;

  /// No description provided for @achievementHundredWorkoutsDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 workout days.'**
  String get achievementHundredWorkoutsDesc;

  /// No description provided for @achievementStreak3Title.
  ///
  /// In en, this message translates to:
  /// **'3 Days in a Row!'**
  String get achievementStreak3Title;

  /// No description provided for @achievementStreak3Desc.
  ///
  /// In en, this message translates to:
  /// **'Work out 3 days in a row.'**
  String get achievementStreak3Desc;

  /// No description provided for @achievementStreak7Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Streak'**
  String get achievementStreak7Title;

  /// No description provided for @achievementStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'Work out 7 days in a row.'**
  String get achievementStreak7Desc;

  /// No description provided for @achievementStreak30Title.
  ///
  /// In en, this message translates to:
  /// **'Iron Will'**
  String get achievementStreak30Title;

  /// No description provided for @achievementStreak30Desc.
  ///
  /// In en, this message translates to:
  /// **'Work out 30 days in a row.'**
  String get achievementStreak30Desc;

  /// No description provided for @achievementVolume10000Title.
  ///
  /// In en, this message translates to:
  /// **'First 10,000 kg'**
  String get achievementVolume10000Title;

  /// No description provided for @achievementVolume10000Desc.
  ///
  /// In en, this message translates to:
  /// **'Lift a total of 10,000 kg.'**
  String get achievementVolume10000Desc;

  /// No description provided for @achievementVolume100000Title.
  ///
  /// In en, this message translates to:
  /// **'First 100,000 kg'**
  String get achievementVolume100000Title;

  /// No description provided for @achievementVolume100000Desc.
  ///
  /// In en, this message translates to:
  /// **'Lift a total of 100,000 kg.'**
  String get achievementVolume100000Desc;

  /// No description provided for @achievementMinutes60Title.
  ///
  /// In en, this message translates to:
  /// **'First Hour'**
  String get achievementMinutes60Title;

  /// No description provided for @achievementMinutes60Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete a total of 60 minutes of training.'**
  String get achievementMinutes60Desc;

  /// No description provided for @achievementMinutes600Title.
  ///
  /// In en, this message translates to:
  /// **'Time Master'**
  String get achievementMinutes600Title;

  /// No description provided for @achievementMinutes600Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete a total of 600 minutes of training.'**
  String get achievementMinutes600Desc;

  /// No description provided for @achievementCalories1000Title.
  ///
  /// In en, this message translates to:
  /// **'First 1000 Calories'**
  String get achievementCalories1000Title;

  /// No description provided for @achievementCalories1000Desc.
  ///
  /// In en, this message translates to:
  /// **'Burn a total of 1000 calories.'**
  String get achievementCalories1000Desc;

  /// No description provided for @achievementCalories10000Title.
  ///
  /// In en, this message translates to:
  /// **'10,000 Calorie Club'**
  String get achievementCalories10000Title;

  /// No description provided for @achievementCalories10000Desc.
  ///
  /// In en, this message translates to:
  /// **'Burn a total of 10,000 calories.'**
  String get achievementCalories10000Desc;

  /// No description provided for @achievementSets100Title.
  ///
  /// In en, this message translates to:
  /// **'One Hundred Sets'**
  String get achievementSets100Title;

  /// No description provided for @achievementSets100Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete a total of 100 sets.'**
  String get achievementSets100Desc;

  /// No description provided for @achievementSets1000Title.
  ///
  /// In en, this message translates to:
  /// **'One Thousand Sets'**
  String get achievementSets1000Title;

  /// No description provided for @achievementSets1000Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete a total of 1000 sets.'**
  String get achievementSets1000Desc;

  /// No description provided for @programLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get programLevelBeginner;

  /// No description provided for @programLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get programLevelIntermediate;

  /// No description provided for @programLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get programLevelAdvanced;

  /// No description provided for @programFullBodyName.
  ///
  /// In en, this message translates to:
  /// **'Full Body (Beginner)'**
  String get programFullBodyName;

  /// No description provided for @programFullBodyDescription.
  ///
  /// In en, this message translates to:
  /// **'A basic full-body workout program that can be done 2-3 times a week. Requires barbell and dumbbell equipment.'**
  String get programFullBodyDescription;

  /// No description provided for @programFullBodyDay1.
  ///
  /// In en, this message translates to:
  /// **'Full Body'**
  String get programFullBodyDay1;

  /// No description provided for @programHomeBodyweightName.
  ///
  /// In en, this message translates to:
  /// **'Home Bodyweight (Intermediate)'**
  String get programHomeBodyweightName;

  /// No description provided for @programHomeBodyweightDescription.
  ///
  /// In en, this message translates to:
  /// **'A 3-day bodyweight workout program requiring no equipment at all, done at home.'**
  String get programHomeBodyweightDescription;

  /// No description provided for @programHomeBodyweightDay1.
  ///
  /// In en, this message translates to:
  /// **'Day 1 - Upper Body'**
  String get programHomeBodyweightDay1;

  /// No description provided for @programHomeBodyweightDay2.
  ///
  /// In en, this message translates to:
  /// **'Day 2 - Lower Body & Core'**
  String get programHomeBodyweightDay2;

  /// No description provided for @programHomeBodyweightDay3.
  ///
  /// In en, this message translates to:
  /// **'Day 3 - Cardio & Full Body'**
  String get programHomeBodyweightDay3;

  /// No description provided for @programPplName.
  ///
  /// In en, this message translates to:
  /// **'Push-Pull-Legs (Advanced)'**
  String get programPplName;

  /// No description provided for @programPplDescription.
  ///
  /// In en, this message translates to:
  /// **'An advanced split workout program, divided into push/pull/legs, that can be done 3-6 times a week.'**
  String get programPplDescription;

  /// No description provided for @programPplDay1.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get programPplDay1;

  /// No description provided for @programPplDay2.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get programPplDay2;

  /// No description provided for @programPplDay3.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get programPplDay3;

  /// No description provided for @workoutsAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" program added.'**
  String workoutsAddedSnackbar(String name);

  /// No description provided for @workoutsDaysCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}-day program'**
  String workoutsDaysCountLabel(int count);

  /// No description provided for @workoutsProgramsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get workoutsProgramsSectionTitle;

  /// No description provided for @workoutsMyProgramsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'My Programs'**
  String get workoutsMyProgramsSectionTitle;

  /// No description provided for @workoutsMyRoutinesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'My Routines'**
  String get workoutsMyRoutinesSectionTitle;

  /// No description provided for @workoutsNewProgramButton.
  ///
  /// In en, this message translates to:
  /// **'New Program'**
  String get workoutsNewProgramButton;

  /// No description provided for @workoutsNewRoutineButton.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get workoutsNewRoutineButton;

  /// No description provided for @workoutsImportCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Add with Code'**
  String get workoutsImportCodeButton;

  /// No description provided for @workoutsImportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Program with Code'**
  String get workoutsImportDialogTitle;

  /// No description provided for @workoutsImportDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the program code here'**
  String get workoutsImportDialogHint;

  /// No description provided for @workoutsImportConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get workoutsImportConfirmButton;

  /// No description provided for @workoutsNoCustomProgramsMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any multi-day program yet.'**
  String get workoutsNoCustomProgramsMessage;

  /// No description provided for @workoutsNoCustomRoutinesMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any custom routine yet.'**
  String get workoutsNoCustomRoutinesMessage;

  /// No description provided for @workoutsActivateProgramMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Set as Active Program'**
  String get workoutsActivateProgramMenuItem;

  /// No description provided for @workoutsEditMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get workoutsEditMenuItem;

  /// No description provided for @workoutsDeleteMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get workoutsDeleteMenuItem;

  /// No description provided for @workoutsExerciseCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String workoutsExerciseCountLabel(int count);

  /// No description provided for @programDetailShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share Program'**
  String get programDetailShareTooltip;

  /// No description provided for @programDetailActiveProgramChip.
  ///
  /// In en, this message translates to:
  /// **'Active Program'**
  String get programDetailActiveProgramChip;

  /// No description provided for @programDetailAlreadyActiveButton.
  ///
  /// In en, this message translates to:
  /// **'This program is active'**
  String get programDetailAlreadyActiveButton;

  /// No description provided for @programDetailTodayDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed today'**
  String get programDetailTodayDoneLabel;

  /// No description provided for @programDetailSuggestedSuffix.
  ///
  /// In en, this message translates to:
  /// **' (Next up)'**
  String get programDetailSuggestedSuffix;

  /// No description provided for @programDetailCustomDescription.
  ///
  /// In en, this message translates to:
  /// **'A user-created {count}-day program.'**
  String programDetailCustomDescription(int count);

  /// No description provided for @programDetailShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Try my Atlas Workout training program: \"{name}\"'**
  String programDetailShareMessage(String name);

  /// No description provided for @programBuilderDayDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Day {number}'**
  String programBuilderDayDefaultName(int number);

  /// No description provided for @programBuilderValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a program name and add exercises to at least one day.'**
  String get programBuilderValidationMessage;

  /// No description provided for @programBuilderNewProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'New Program'**
  String get programBuilderNewProgramTitle;

  /// No description provided for @programBuilderEditProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Program'**
  String get programBuilderEditProgramTitle;

  /// No description provided for @programBuilderAddDayButton.
  ///
  /// In en, this message translates to:
  /// **'Add Day'**
  String get programBuilderAddDayButton;

  /// No description provided for @programBuilderProgramNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Program name'**
  String get programBuilderProgramNameLabel;

  /// No description provided for @programBuilderDayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Day name'**
  String get programBuilderDayNameLabel;

  /// No description provided for @programBuilderExercisesSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises selected'**
  String programBuilderExercisesSelectedLabel(int count);

  /// No description provided for @programBuilderEditExercisesButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Exercises'**
  String get programBuilderEditExercisesButton;

  /// No description provided for @routineBuilderValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and select at least one exercise.'**
  String get routineBuilderValidationMessage;

  /// No description provided for @routineBuilderNewRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get routineBuilderNewRoutineTitle;

  /// No description provided for @routineBuilderEditRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine'**
  String get routineBuilderEditRoutineTitle;

  /// No description provided for @routineBuilderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineBuilderNameLabel;

  /// No description provided for @activeWorkoutExerciseCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise {current}/{total}'**
  String activeWorkoutExerciseCountLabel(int current, int total);

  /// No description provided for @activeWorkoutSetProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {current}/{total} • Target: {reps} reps'**
  String activeWorkoutSetProgressLabel(int current, int total, int reps);

  /// No description provided for @activeWorkoutRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get activeWorkoutRepsLabel;

  /// No description provided for @activeWorkoutWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get activeWorkoutWeightLabel;

  /// No description provided for @activeWorkoutFinishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish Workout'**
  String get activeWorkoutFinishButton;

  /// No description provided for @activeWorkoutCompleteSetButton.
  ///
  /// In en, this message translates to:
  /// **'Complete Set'**
  String get activeWorkoutCompleteSetButton;

  /// No description provided for @activeWorkoutNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout: {title}'**
  String activeWorkoutNotesLabel(String title);

  /// No description provided for @workoutSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Complete'**
  String get workoutSummaryTitle;

  /// No description provided for @workoutSummaryDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutSummaryDurationLabel;

  /// No description provided for @workoutSummaryDurationValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String workoutSummaryDurationValue(int minutes);

  /// No description provided for @workoutSummaryCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated calories'**
  String get workoutSummaryCaloriesLabel;

  /// No description provided for @workoutSummaryBackHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get workoutSummaryBackHomeButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
