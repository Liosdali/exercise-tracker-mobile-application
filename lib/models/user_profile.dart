/// The user's current body profile snapshot (as opposed to
/// [BodyMeasurement], which is a dated history log). Used as the primary
/// source of body weight for calorie calculations and other personalized
/// stats. Stored as a single row (id = 1) in the `user_profile` table.
class UserProfile {
  final double? heightCm;
  final int? age;
  final String? gender; // 'male' | 'female' | 'other'
  final double? weightKg;
  final double? bodyFatPercent;
  final String updatedAt;

  const UserProfile({
    this.heightCm,
    this.age,
    this.gender,
    this.weightKg,
    this.bodyFatPercent,
    required this.updatedAt,
  });

  bool get isEmpty =>
      heightCm == null && age == null && gender == null && weightKg == null && bodyFatPercent == null;

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'height_cm': heightCm,
      'age': age,
      'gender': gender,
      'weight_kg': weightKg,
      'body_fat_percent': bodyFatPercent,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      bodyFatPercent: (map['body_fat_percent'] as num?)?.toDouble(),
      updatedAt: map['updated_at'] as String,
    );
  }

  factory UserProfile.empty() => UserProfile(updatedAt: DateTime.now().toIso8601String());
}
