class UserProfile {
  final String? id;
  final String name;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? gender;

  const UserProfile({
    this.id,
    this.name = '',
    this.age,
    this.weightKg,
    this.heightCm,
    this.gender,
  });

  void validate() {
    if (name.length > 200) throw ArgumentError('Name is too long');
    if (age != null && age! < 0) {
      throw ArgumentError('Age must be nonnegative');
    }
    for (final value in [weightKg, heightCm]) {
      if (value != null && (!value.isFinite || value <= 0)) {
        throw ArgumentError('Measurements must be positive');
      }
    }
    if (gender != null && gender!.length > 50) {
      throw ArgumentError('Gender is too long');
    }
  }

  Map<String, Object?> toMap() => {
    'name': name,
    'age': age,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'gender': gender,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? userId}) =>
      UserProfile(
        id: userId ?? (map['id'] is String ? map['id'] as String : null),
        name: map['name'] as String? ?? '',
        age: (map['age'] as num?)?.toInt(),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        gender: map['gender'] as String?,
      );
}
