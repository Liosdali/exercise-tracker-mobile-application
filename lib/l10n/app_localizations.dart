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
  /// **'Exercise App'**
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
  /// **'Hello! 👋'**
  String get dashboardGreeting;

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
