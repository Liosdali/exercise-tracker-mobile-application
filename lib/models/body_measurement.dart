/// A single body-measurement log entry (weight, body fat %, circumferences).
class BodyMeasurement {
  final int? id;
  final String date; // yyyy-MM-dd
  final double? weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final String? notes;
  final String createdAt;

  const BodyMeasurement({
    this.id,
    required this.date,
    this.weightKg,
    this.bodyFatPercent,
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
      'body_fat_percent': bodyFatPercent,
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
      bodyFatPercent: (map['body_fat_percent'] as num?)?.toDouble(),
      chestCm: (map['chest_cm'] as num?)?.toDouble(),
      waistCm: (map['waist_cm'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
