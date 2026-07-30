import '../l10n/app_localizations.dart';

/// Maps an [AchievementDefinition.id] to its localized title/description,
/// keeping `achievement_definitions.dart` free of any Flutter/l10n
/// dependency (it stays a pure, easily-extensible data registry) while
/// still letting the UI show fully translated badge text.
///
/// Adding a new achievement: add its definition as before, then add a
/// `achievement<Id>Title`/`achievement<Id>Desc` pair to both ARB files and
/// a case here.
class AchievementLocalizer {
  AchievementLocalizer._();

  static String title(AppLocalizations l10n, String id) {
    switch (id) {
      case 'first_workout':
        return l10n.achievementFirstWorkoutTitle;
      case 'ten_workouts':
        return l10n.achievementTenWorkoutsTitle;
      case 'fifty_workouts':
        return l10n.achievementFiftyWorkoutsTitle;
      case 'hundred_workouts':
        return l10n.achievementHundredWorkoutsTitle;
      case 'streak_3':
        return l10n.achievementStreak3Title;
      case 'streak_7':
        return l10n.achievementStreak7Title;
      case 'streak_30':
        return l10n.achievementStreak30Title;
      case 'volume_10000':
        return l10n.achievementVolume10000Title;
      case 'volume_100000':
        return l10n.achievementVolume100000Title;
      case 'minutes_60':
        return l10n.achievementMinutes60Title;
      case 'minutes_600':
        return l10n.achievementMinutes600Title;
      case 'calories_1000':
        return l10n.achievementCalories1000Title;
      case 'calories_10000':
        return l10n.achievementCalories10000Title;
      case 'sets_100':
        return l10n.achievementSets100Title;
      case 'sets_1000':
        return l10n.achievementSets1000Title;
      default:
        return id;
    }
  }

  static String description(AppLocalizations l10n, String id) {
    switch (id) {
      case 'first_workout':
        return l10n.achievementFirstWorkoutDesc;
      case 'ten_workouts':
        return l10n.achievementTenWorkoutsDesc;
      case 'fifty_workouts':
        return l10n.achievementFiftyWorkoutsDesc;
      case 'hundred_workouts':
        return l10n.achievementHundredWorkoutsDesc;
      case 'streak_3':
        return l10n.achievementStreak3Desc;
      case 'streak_7':
        return l10n.achievementStreak7Desc;
      case 'streak_30':
        return l10n.achievementStreak30Desc;
      case 'volume_10000':
        return l10n.achievementVolume10000Desc;
      case 'volume_100000':
        return l10n.achievementVolume100000Desc;
      case 'minutes_60':
        return l10n.achievementMinutes60Desc;
      case 'minutes_600':
        return l10n.achievementMinutes600Desc;
      case 'calories_1000':
        return l10n.achievementCalories1000Desc;
      case 'calories_10000':
        return l10n.achievementCalories10000Desc;
      case 'sets_100':
        return l10n.achievementSets100Desc;
      case 'sets_1000':
        return l10n.achievementSets1000Desc;
      default:
        return '';
    }
  }
}
