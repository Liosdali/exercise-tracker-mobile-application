import 'dart:convert';

import '../models/custom_program.dart';

/// Encodes/decodes a [CustomProgram] into a shareable, offline text code
/// (no backend required), e.g. for sending via WhatsApp/Telegram with
/// `share_plus`.
///
/// Format: `ATLAS-WORKOUT-CODE:<base64(json)>`
class ProgramShareService {
  static const String _prefix = 'ATLAS-WORKOUT-CODE:';

  const ProgramShareService._();

  /// Serializes [program] (name + days + exercises) into a shareable code.
  static String encodeProgram(CustomProgram program) {
    final data = {
      'name': program.name,
      'days': [
        for (final day in program.days)
          {
            'name': day.name,
            'position': day.position,
            'exercises': [
              for (final exercise in day.exercises)
                {
                  'exerciseId': exercise.exerciseId,
                  'exerciseName': exercise.exerciseName,
                  'category': exercise.category,
                  'targetSets': exercise.targetSets,
                  'targetReps': exercise.targetReps,
                  'position': exercise.position,
                },
            ],
          },
      ],
    };
    final json = jsonEncode(data);
    final base64Str = base64Encode(utf8.encode(json));
    return '$_prefix$base64Str';
  }

  /// Parses a code produced by [encodeProgram] back into a [CustomProgram]
  /// ready for insertion (all ids left `null` so a fresh copy is created).
  /// Throws a [FormatException] with a user-friendly message if [code] is
  /// not a valid/well-formed program code.
  static CustomProgram decodeProgram(String code) {
    final trimmed = code.trim();
    if (!trimmed.startsWith(_prefix)) {
      throw const FormatException('Geçersiz program kodu. Kodun başında ATLAS-WORKOUT-CODE bulunmalı.');
    }
    final base64Str = trimmed.substring(_prefix.length);

    late final Map<String, dynamic> data;
    try {
      final json = utf8.decode(base64Decode(base64Str));
      data = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Program kodu okunamadı. Kod bozuk veya eksik olabilir.');
    }

    try {
      final name = data['name'] as String;
      final daysJson = data['days'] as List<dynamic>;
      if (daysJson.isEmpty) {
        throw const FormatException('Program kodu en az bir gün içermeli.');
      }
      final days = <CustomProgramDay>[];
      for (final dayJson in daysJson) {
        final dayMap = dayJson as Map<String, dynamic>;
        final exercisesJson = dayMap['exercises'] as List<dynamic>;
        final exercises = <CustomProgramExercise>[
          for (final exerciseJson in exercisesJson)
            CustomProgramExercise(
              exerciseId: (exerciseJson as Map<String, dynamic>)['exerciseId'] as String,
              exerciseName: exerciseJson['exerciseName'] as String,
              category: exerciseJson['category'] as String,
              targetSets: exerciseJson['targetSets'] as int,
              targetReps: exerciseJson['targetReps'] as int,
              position: exerciseJson['position'] as int,
            ),
        ];
        days.add(
          CustomProgramDay(
            name: dayMap['name'] as String,
            position: dayMap['position'] as int,
            exercises: exercises,
          ),
        );
      }
      return CustomProgram(
        name: name,
        createdAt: DateTime.now().toIso8601String(),
        days: days,
      );
    } catch (_) {
      throw const FormatException('Program kodu geçersiz bir formatta. Lütfen kodu kontrol edin.');
    }
  }
}
