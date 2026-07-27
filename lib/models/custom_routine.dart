/// A user-created custom workout routine (a single day made of chosen
/// exercises with target sets/reps), persisted in the local database.
class CustomRoutine {
  final int? id;
  final String name;
  final String createdAt;
  final List<CustomRoutineExercise> exercises;

  const CustomRoutine({
    this.id,
    required this.name,
    required this.createdAt,
    required this.exercises,
  });

  CustomRoutine copyWith({
    int? id,
    String? name,
    String? createdAt,
    List<CustomRoutineExercise>? exercises,
  }) {
    return CustomRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      exercises: exercises ?? this.exercises,
    );
  }
}

/// A single exercise entry within a [CustomRoutine].
class CustomRoutineExercise {
  final int? id;
  final int? routineId;
  final String exerciseId;
  final String exerciseName;
  final String category;
  final int targetSets;
  final int targetReps;
  final int position;

  const CustomRoutineExercise({
    this.id,
    this.routineId,
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
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'category': category,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'position': position,
    };
  }

  factory CustomRoutineExercise.fromMap(Map<String, Object?> map) {
    return CustomRoutineExercise(
      id: map['id'] as int?,
      routineId: map['routine_id'] as int?,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      category: map['category'] as String,
      targetSets: map['target_sets'] as int,
      targetReps: map['target_reps'] as int,
      position: map['position'] as int,
    );
  }
}
