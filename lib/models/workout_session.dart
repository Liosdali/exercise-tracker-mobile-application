/// A completed guided-workout session (started/finished in
/// [ActiveWorkoutScreen]), used to drive the weekly-duration chart and
/// calorie stats. Distinct from [WorkoutEntry] (one row per exercise); this
/// is one row per whole session.
class WorkoutSession {
  final int? id;
  final String date; // yyyy-MM-dd
  final int durationMinutes;
  final double calories;
  final int exerciseCount;
  final int totalSets;
  final double totalVolume;
  final String title;
  final String createdAt;

  const WorkoutSession({
    this.id,
    required this.date,
    required this.durationMinutes,
    required this.calories,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolume,
    required this.title,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'duration_minutes': durationMinutes,
      'calories': calories,
      'exercise_count': exerciseCount,
      'total_sets': totalSets,
      'total_volume': totalVolume,
      'title': title,
      'created_at': createdAt,
    };
  }

  factory WorkoutSession.fromMap(Map<String, Object?> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      date: map['date'] as String,
      durationMinutes: map['duration_minutes'] as int,
      calories: (map['calories'] as num).toDouble(),
      exerciseCount: map['exercise_count'] as int,
      totalSets: map['total_sets'] as int,
      totalVolume: (map['total_volume'] as num).toDouble(),
      title: map['title'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}
