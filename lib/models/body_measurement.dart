/// A single body-measurement log entry (weight, circumferences, and an
/// automatically computed body fat percentage via the U.S. Navy method).
class BodyMeasurement {
  final int? id;
  final String date; // yyyy-MM-dd
  final double? weightKg;
  final double? heightCm;
  final String? gender; // 'male' | 'female'
  final double? neckCm;
  final double? hipCm;
  final double? calculatedBodyFat;
  final double? chestCm;
  final double? waistCm;
  final String? notes;
  final String createdAt;

  const BodyMeasurement({
    this.id,
    required this.date,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.neckCm,
    this.hipCm,
    this.calculatedBodyFat,
    this.chestCm,
    this.waistCm,
    this.notes,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'gender': gender,
      'neck_cm': neckCm,
      'hip_cm': hipCm,
      'calculated_body_fat': calculatedBodyFat,
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, Object?> map) {
    return BodyMeasurement(
      id: map['id'] as int?,
      date: map['date'] as String,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      gender: map['gender'] as String?,
      neckCm: (map['neck_cm'] as num?)?.toDouble(),
      hipCm: (map['hip_cm'] as num?)?.toDouble(),
      calculatedBodyFat: (map['calculated_body_fat'] as num?)?.toDouble(),
      chestCm: (map['chest_cm'] as num?)?.toDouble(),
      waistCm: (map['waist_cm'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
