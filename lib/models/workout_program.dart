/// Difficulty level of a built-in workout program.
enum ProgramLevel { beginner, intermediate, advanced }

extension ProgramLevelLabel on ProgramLevel {
  String get label {
    switch (this) {
      case ProgramLevel.beginner:
        return 'Başlangıç';
      case ProgramLevel.intermediate:
        return 'Orta';
      case ProgramLevel.advanced:
        return 'İleri';
    }
  }
}

/// A single exercise slot within a program day: which exercise, how many
/// target sets/reps, and how long to rest between sets.
class ProgramExercise {
  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final int restSeconds;

  const ProgramExercise({
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
    this.restSeconds = 60,
  });
}

/// One training day within a program (e.g. "Push Günü").
class ProgramDay {
  final String name;
  final List<ProgramExercise> exercises;

  const ProgramDay({required this.name, required this.exercises});
}

/// A full, named workout program made up of one or more training days.
class WorkoutProgram {
  final String id;
  final String name;
  final String description;
  final ProgramLevel level;
  final List<ProgramDay> days;

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.days,
  });
}

/// The 3 built-in programs, referencing real exercise ids from
/// storage/data/exercises.json.
const List<WorkoutProgram> builtInPrograms = [
  WorkoutProgram(
    id: 'full_body_beginner',
    name: 'Full Body (Başlangıç)',
    description:
        'Haftada 2-3 kez uygulanabilecek, tüm vücudu çalıştıran temel bir '
        'antrenman programı. Barbell ve dumbbell ekipmanı gerektirir.',
    level: ProgramLevel.beginner,
    days: [
      ProgramDay(
        name: 'Tüm Vücut',
        exercises: [
          ProgramExercise(exerciseId: '0025', targetSets: 3, targetReps: 10), // barbell bench press
          ProgramExercise(exerciseId: '0026', targetSets: 3, targetReps: 10), // barbell bench squat
          ProgramExercise(exerciseId: '0293', targetSets: 3, targetReps: 10, restSeconds: 75), // dumbbell bent over row
          ProgramExercise(exerciseId: '0405', targetSets: 3, targetReps: 10), // dumbbell seated shoulder press
          ProgramExercise(exerciseId: '0294', targetSets: 2, targetReps: 12, restSeconds: 45), // dumbbell biceps curl
          ProgramExercise(exerciseId: '0274', targetSets: 3, targetReps: 15, restSeconds: 30), // crunch floor
        ],
      ),
    ],
  ),
  WorkoutProgram(
    id: 'home_bodyweight_intermediate',
    name: 'Evde Ekipmansız (Orta)',
    description:
        'Hiçbir ekipman gerektirmeyen, evde uygulanabilecek 3 günlük '
        'vücut ağırlığı antrenman programı.',
    level: ProgramLevel.intermediate,
    days: [
      ProgramDay(
        name: 'Gün 1 - Üst Vücut',
        exercises: [
          ProgramExercise(exerciseId: '0662', targetSets: 4, targetReps: 12), // push-up
          ProgramExercise(exerciseId: '0652', targetSets: 4, targetReps: 6, restSeconds: 75), // pull-up
          ProgramExercise(exerciseId: '1399', targetSets: 3, targetReps: 12, restSeconds: 45), // bench dip on floor
        ],
      ),
      ProgramDay(
        name: 'Gün 2 - Alt Vücut & Core',
        exercises: [
          ProgramExercise(exerciseId: '0514', targetSets: 4, targetReps: 15), // jump squat
          ProgramExercise(exerciseId: '1460', targetSets: 3, targetReps: 12), // walking lunge
          ProgramExercise(exerciseId: '3665', targetSets: 3, targetReps: 30, restSeconds: 30), // power point plank
          ProgramExercise(exerciseId: '0274', targetSets: 3, targetReps: 15, restSeconds: 30), // crunch floor
        ],
      ),
      ProgramDay(
        name: 'Gün 3 - Kardiyo & Tüm Vücut',
        exercises: [
          ProgramExercise(exerciseId: '1160', targetSets: 4, targetReps: 10, restSeconds: 45), // burpee
          ProgramExercise(exerciseId: '0630', targetSets: 4, targetReps: 20, restSeconds: 30), // mountain climber
          ProgramExercise(exerciseId: '0662', targetSets: 3, targetReps: 12), // push-up
          ProgramExercise(exerciseId: '0514', targetSets: 3, targetReps: 15), // jump squat
        ],
      ),
    ],
  ),
  WorkoutProgram(
    id: 'push_pull_legs_advanced',
    name: 'Push-Pull-Legs (İleri)',
    description:
        'Haftada 3-6 kez uygulanabilecek, itiş/çekiş/bacak olarak ayrılmış '
        'ileri seviye bir split antrenman programı.',
    level: ProgramLevel.advanced,
    days: [
      ProgramDay(
        name: 'Push (İtiş)',
        exercises: [
          ProgramExercise(exerciseId: '0025', targetSets: 4, targetReps: 8, restSeconds: 90), // barbell bench press
          ProgramExercise(exerciseId: '0405', targetSets: 4, targetReps: 10, restSeconds: 75), // dumbbell seated shoulder press
          ProgramExercise(exerciseId: '1399', targetSets: 3, targetReps: 12, restSeconds: 45), // bench dip on floor
        ],
      ),
      ProgramDay(
        name: 'Pull (Çekiş)',
        exercises: [
          ProgramExercise(exerciseId: '0652', targetSets: 4, targetReps: 8, restSeconds: 90), // pull-up
          ProgramExercise(exerciseId: '0293', targetSets: 4, targetReps: 10, restSeconds: 75), // dumbbell bent over row
          ProgramExercise(exerciseId: '0294', targetSets: 3, targetReps: 12, restSeconds: 45), // dumbbell biceps curl
        ],
      ),
      ProgramDay(
        name: 'Legs (Bacak)',
        exercises: [
          ProgramExercise(exerciseId: '0026', targetSets: 4, targetReps: 8, restSeconds: 90), // barbell bench squat
          ProgramExercise(exerciseId: '0032', targetSets: 4, targetReps: 6, restSeconds: 120), // barbell deadlift
          ProgramExercise(exerciseId: '0054', targetSets: 3, targetReps: 10, restSeconds: 75), // barbell lunge
          ProgramExercise(exerciseId: '1460', targetSets: 3, targetReps: 12, restSeconds: 45), // walking lunge
        ],
      ),
    ],
  ),
];
