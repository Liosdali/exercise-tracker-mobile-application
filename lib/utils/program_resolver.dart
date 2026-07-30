import '../l10n/app_localizations.dart';
import '../models/custom_program.dart';
import '../models/workout_program.dart';
import '../providers/custom_program_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/program_provider.dart';
import '../screens/active_workout_screen.dart';
import '../services/program_localizer.dart';

/// A training day resolved from either a built-in [WorkoutProgram] or a
/// user-created [CustomProgram], used by the Dashboard/Calendar to build a
/// guided workout session regardless of which kind of program it came from.
class ResolvedProgramDay {
  final String programKey;
  final String programTitle;
  final String dayName;
  final int dayIndex;
  final int totalDays;
  final List<ActiveWorkoutStep> Function(ExerciseProvider) buildSteps;

  const ResolvedProgramDay({
    required this.programKey,
    required this.programTitle,
    required this.dayName,
    required this.dayIndex,
    required this.totalDays,
    required this.buildSteps,
  });
}

/// Finds the program (built-in or custom) referenced by [programKey]
/// (`builtin:<id>` or `custom:<id>`) and resolves the day at [dayIndex],
/// clamped to the program's day count. Returns null if the program (or any
/// days) can no longer be found (e.g. it was deleted).
ResolvedProgramDay? resolveProgramDay({
  required String programKey,
  required int dayIndex,
  required ProgramProvider builtinPrograms,
  required CustomProgramProvider customPrograms,
  AppLocalizations? l10n,
}) {
  if (programKey.startsWith('builtin:')) {
    final id = programKey.substring('builtin:'.length);
    final program = builtinPrograms.byId(id);
    if (program == null || program.days.isEmpty) return null;
    final index = dayIndex % program.days.length;
    final day = program.days[index];
    return ResolvedProgramDay(
      programKey: programKey,
      programTitle: l10n != null ? ProgramLocalizer.name(l10n, program.id, program.name) : program.name,
      dayName: l10n != null ? ProgramLocalizer.dayName(l10n, program.id, index, day.name) : day.name,
      dayIndex: index,
      totalDays: program.days.length,
      buildSteps: (exerciseProvider) => day.exercises
          .map((pe) {
            final exercise = exerciseProvider.byId(pe.exerciseId);
            if (exercise == null) return null;
            return ActiveWorkoutStep(
              exercise: exercise,
              targetSets: pe.targetSets,
              targetReps: pe.targetReps,
              restSeconds: pe.restSeconds,
            );
          })
          .whereType<ActiveWorkoutStep>()
          .toList(),
    );
  }

  if (programKey.startsWith('custom:')) {
    final id = int.tryParse(programKey.substring('custom:'.length));
    if (id == null) return null;
    final program = customPrograms.byId(id);
    if (program == null || program.days.isEmpty) return null;
    final index = dayIndex % program.days.length;
    final day = program.days[index];
    return ResolvedProgramDay(
      programKey: programKey,
      programTitle: program.name,
      dayName: day.name,
      dayIndex: index,
      totalDays: program.days.length,
      buildSteps: (exerciseProvider) => day.exercises
          .map((pe) {
            final exercise = exerciseProvider.byId(pe.exerciseId);
            if (exercise == null) return null;
            return ActiveWorkoutStep(
              exercise: exercise,
              targetSets: pe.targetSets,
              targetReps: pe.targetReps,
            );
          })
          .whereType<ActiveWorkoutStep>()
          .toList(),
    );
  }

  return null;
}

/// All available programs, as `(key, name, totalDays)` triples, for pickers
/// (calendar assignment, active-program selection).
List<({String key, String name, int totalDays})> allProgramOptions(
  ProgramProvider builtinPrograms,
  CustomProgramProvider customPrograms, {
  AppLocalizations? l10n,
}) {
  return [
    for (final p in builtinPrograms.programs)
      (
        key: 'builtin:${p.id}',
        name: l10n != null ? ProgramLocalizer.name(l10n, p.id, p.name) : p.name,
        totalDays: p.days.length,
      ),
    for (final p in customPrograms.programs)
      (key: p.key, name: p.name, totalDays: p.days.length),
  ];
}

/// Day names for a given program key (for the calendar's day picker).
List<String> dayNamesFor(
  String programKey,
  ProgramProvider builtinPrograms,
  CustomProgramProvider customPrograms, {
  AppLocalizations? l10n,
}) {
  if (programKey.startsWith('builtin:')) {
    final id = programKey.substring('builtin:'.length);
    final program = builtinPrograms.byId(id);
    if (program == null) return [];
    return [
      for (var i = 0; i < program.days.length; i++)
        l10n != null ? ProgramLocalizer.dayName(l10n, program.id, i, program.days[i].name) : program.days[i].name,
    ];
  }
  if (programKey.startsWith('custom:')) {
    final id = int.tryParse(programKey.substring('custom:'.length));
    if (id == null) return [];
    return customPrograms.byId(id)?.days.map((d) => d.name).toList() ?? [];
  }
  return [];
}
