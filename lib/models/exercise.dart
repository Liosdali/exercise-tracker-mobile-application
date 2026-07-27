/// A single exercise record, matching storage/data/exercises.schema.json.
class Exercise {
  final String id;
  final String name;
  final String category;
  final String bodyPart;
  final String equipment;
  final Map<String, String> instructions;
  final Map<String, List<String>> instructionSteps;
  final String muscleGroup;
  final List<String> secondaryMuscles;
  final String target;
  final String mediaId;
  final String image;
  final String gifUrl;
  final String attribution;
  final String createdAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.bodyPart,
    required this.equipment,
    required this.instructions,
    required this.instructionSteps,
    required this.muscleGroup,
    required this.secondaryMuscles,
    required this.target,
    required this.mediaId,
    required this.image,
    required this.gifUrl,
    required this.attribution,
    required this.createdAt,
  });

  /// Full path to the thumbnail image asset, as declared in pubspec.yaml.
  String get imageAsset => 'storage/$image';

  /// Full path to the animated GIF asset, as declared in pubspec.yaml.
  String get gifAsset => 'storage/$gifUrl';

  /// English instructions text (falls back to the first available language).
  String get instructionsEn =>
      instructions['en'] ?? instructions.values.firstOrNull ?? '';

  /// English step-by-step instructions (falls back to the first available
  /// language).
  List<String> get stepsEn =>
      instructionSteps['en'] ?? instructionSteps.values.firstOrNull ?? const [];

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      bodyPart: json['body_part'] as String,
      equipment: json['equipment'] as String,
      instructions: Map<String, String>.from(
        (json['instructions'] as Map).map(
          (key, value) => MapEntry(key as String, value as String),
        ),
      ),
      instructionSteps: Map<String, List<String>>.from(
        (json['instruction_steps'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            List<String>.from(value as List),
          ),
        ),
      ),
      muscleGroup: json['muscle_group'] as String,
      secondaryMuscles: List<String>.from(json['secondary_muscles'] as List),
      target: json['target'] as String,
      mediaId: json['media_id'] as String,
      image: json['image'] as String,
      gifUrl: json['gif_url'] as String,
      attribution: json['attribution'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
