/// Enum for program suggestion types
enum SuggestionType {
  exercise('exercise'),
  programChange('program_change'),
  feedback('feedback');

  final String value;
  const SuggestionType(this.value);

  factory SuggestionType.fromString(String? value) {
    return SuggestionType.values
        .firstWhere((e) => e.value == value, orElse: () => SuggestionType.feedback);
  }
}

/// Enum for program suggestion status
enum SuggestionStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  final String value;
  const SuggestionStatus(this.value);

  factory SuggestionStatus.fromString(String? value) {
    return SuggestionStatus.values
        .firstWhere((e) => e.value == value, orElse: () => SuggestionStatus.pending);
  }
}

/// Represents a program suggestion between team members
class ProgramSuggestion {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String teamId;
  final SuggestionType suggestionType;
  final String? relatedExerciseId;
  final String? relatedProgramId;
  final String? message;
  final String? responseMessage;
  final SuggestionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProgramSuggestion({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.teamId,
    required this.suggestionType,
    this.relatedExerciseId,
    this.relatedProgramId,
    this.message,
    this.responseMessage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProgramSuggestion.fromJson(Map<String, dynamic> json) {
    return ProgramSuggestion(
      id: json['id'] ?? '',
      fromUserId: json['from_user_id'] ?? '',
      toUserId: json['to_user_id'] ?? '',
      teamId: json['team_id'] ?? '',
      suggestionType: SuggestionType.fromString(json['suggestion_type']),
      relatedExerciseId: json['related_exercise_id'],
      relatedProgramId: json['related_program_id'],
      message: json['message'],
      responseMessage: json['response_message'],
      status: SuggestionStatus.fromString(json['status']),
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'team_id': teamId,
      'suggestion_type': suggestionType.value,
      'related_exercise_id': relatedExerciseId,
      'related_program_id': relatedProgramId,
      'message': message,
      'response_message': responseMessage,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProgramSuggestion copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? teamId,
    SuggestionType? suggestionType,
    String? relatedExerciseId,
    String? relatedProgramId,
    String? message,
    String? responseMessage,
    SuggestionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgramSuggestion(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      teamId: teamId ?? this.teamId,
      suggestionType: suggestionType ?? this.suggestionType,
      relatedExerciseId: relatedExerciseId ?? this.relatedExerciseId,
      relatedProgramId: relatedProgramId ?? this.relatedProgramId,
      message: message ?? this.message,
      responseMessage: responseMessage ?? this.responseMessage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramSuggestion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fromUserId == other.fromUserId &&
          toUserId == other.toUserId;

  @override
  int get hashCode => id.hashCode ^ fromUserId.hashCode ^ toUserId.hashCode;

  @override
  String toString() =>
      'ProgramSuggestion(id: $id, from: $fromUserId, to: $toUserId, type: ${suggestionType.value}, status: ${status.value})';
}

DateTime _parseTimestamp(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}
