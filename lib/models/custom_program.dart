/// A single exercise entry within a [CustomProgramDay].
class CustomProgramExercise {
  final int? id;
  final int? dayId;
  final String exerciseId;
  final String exerciseName;
  final String category;
  final int targetSets;
  final int targetReps;
  final int position;

  const CustomProgramExercise({
    this.id,
    this.dayId,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.targetSets,
    required this.targetReps,
    required this.position,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'day_id': dayId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'category': category,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'position': position,
    };
  }

  factory CustomProgramExercise.fromMap(Map<String, Object?> map) {
    return CustomProgramExercise(
      id: map['id'] as int?,
      dayId: map['day_id'] as int?,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      category: map['category'] as String,
      targetSets: map['target_sets'] as int,
      targetReps: map['target_reps'] as int,
      position: map['position'] as int,
    );
  }
}

/// One training day within a user-created [CustomProgram] (e.g. "Gün 1").
class CustomProgramDay {
  final int? id;
  final int? programId;
  final String name;
  final int position;
  final List<CustomProgramExercise> exercises;

  const CustomProgramDay({
    this.id,
    this.programId,
    required this.name,
    required this.position,
    required this.exercises,
  });

  CustomProgramDay copyWith({
    int? id,
    int? programId,
    String? name,
    int? position,
    List<CustomProgramExercise>? exercises,
  }) {
    return CustomProgramDay(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      position: position ?? this.position,
      exercises: exercises ?? this.exercises,
    );
  }
}

/// A user-created, multi-day workout program (e.g. a 4-day Push-Pull-Legs
/// split), persisted in the local database. Unlike [CustomRoutine] (a single
/// session), a [CustomProgram] is made of several ordered [CustomProgramDay]s
/// that can be followed sequentially.
class CustomProgram {
  final int? id;
  final String name;
  final String createdAt;
  final List<CustomProgramDay> days;

  const CustomProgram({
    this.id,
    required this.name,
    required this.createdAt,
    required this.days,
  });

  /// Stable key used to identify this program across the app (progress
  /// tracking, calendar assignment, active-program setting).
  String get key => 'custom:$id';

  CustomProgram copyWith({
    int? id,
    String? name,
    String? createdAt,
    List<CustomProgramDay>? days,
  }) {
    return CustomProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      days: days ?? this.days,
    );
  }
}
