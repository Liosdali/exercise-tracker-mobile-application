/// A single logged workout entry: one exercise performed on one date.
class WorkoutEntry {
  final int? id;
  final String date; // yyyy-MM-dd
  final String exerciseId;
  final String exerciseName;
  final String category;
  final int? sets;
  final int? reps;
  final double? weight;
  final String? notes;
  final String createdAt;

  const WorkoutEntry({
    this.id,
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    this.sets,
    this.reps,
    this.weight,
    this.notes,
    required this.createdAt,
  });

  WorkoutEntry copyWith({
    int? id,
    String? date,
    String? exerciseId,
    String? exerciseName,
    String? category,
    int? sets,
    int? reps,
    double? weight,
    String? notes,
    String? createdAt,
  }) {
    return WorkoutEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'category': category,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory WorkoutEntry.fromMap(Map<String, Object?> map) {
    return WorkoutEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      category: map['category'] as String,
      sets: map['sets'] as int?,
      reps: map['reps'] as int?,
      weight: (map['weight'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
