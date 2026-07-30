import '../l10n/app_localizations.dart';
import '../models/workout_program.dart';

/// Localizes the built-in [WorkoutProgram] catalog's display strings (name,
/// description, day names, difficulty label) so they follow the active app
/// language, while custom user-created programs keep whatever the user
/// typed (returned unchanged via the [fallback] parameters).
///
/// Exercise *names* are intentionally NOT touched here - they always stay
/// English per product decision, this only covers program/day metadata.
class ProgramLocalizer {
  ProgramLocalizer._();

  static String name(AppLocalizations l10n, String programId, String fallback) {
    switch (programId) {
      case 'full_body_beginner':
        return l10n.programFullBodyName;
      case 'home_bodyweight_intermediate':
        return l10n.programHomeBodyweightName;
      case 'push_pull_legs_advanced':
        return l10n.programPplName;
      default:
        return fallback;
    }
  }

  static String description(AppLocalizations l10n, String programId, String fallback) {
    switch (programId) {
      case 'full_body_beginner':
        return l10n.programFullBodyDescription;
      case 'home_bodyweight_intermediate':
        return l10n.programHomeBodyweightDescription;
      case 'push_pull_legs_advanced':
        return l10n.programPplDescription;
      default:
        return fallback;
    }
  }

  static String dayName(AppLocalizations l10n, String programId, int dayIndex, String fallback) {
    switch (programId) {
      case 'full_body_beginner':
        if (dayIndex == 0) return l10n.programFullBodyDay1;
        break;
      case 'home_bodyweight_intermediate':
        switch (dayIndex) {
          case 0:
            return l10n.programHomeBodyweightDay1;
          case 1:
            return l10n.programHomeBodyweightDay2;
          case 2:
            return l10n.programHomeBodyweightDay3;
        }
        break;
      case 'push_pull_legs_advanced':
        switch (dayIndex) {
          case 0:
            return l10n.programPplDay1;
          case 1:
            return l10n.programPplDay2;
          case 2:
            return l10n.programPplDay3;
        }
        break;
    }
    return fallback;
  }

  static String levelLabel(AppLocalizations l10n, ProgramLevel level) {
    switch (level) {
      case ProgramLevel.beginner:
        return l10n.programLevelBeginner;
      case ProgramLevel.intermediate:
        return l10n.programLevelIntermediate;
      case ProgramLevel.advanced:
        return l10n.programLevelAdvanced;
    }
  }
}
