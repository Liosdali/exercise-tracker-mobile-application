import 'package:intl/intl.dart';

/// Represents a team member's daily activity log (workouts, calories, duration).
class TeamActivityLog {
  final String id;
  final String teamId;
  final String userId;
  final DateTime activityDate;
  final int workoutsCount;
  final double totalCalories;
  final double totalWeightLifted;
  final int totalDurationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamActivityLog({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.activityDate,
    required this.workoutsCount,
    required this.totalCalories,
    required this.totalWeightLifted,
    required this.totalDurationMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamActivityLog.fromJson(Map<String, dynamic> json) {
    return TeamActivityLog(
      id: json['id'] ?? '',
      teamId: json['team_id'] ?? '',
      userId: json['user_id'] ?? '',
      activityDate: _parseDate(json['activity_date']),
      workoutsCount: json['workouts_count'] ?? 0,
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      totalWeightLifted: (json['total_weight_lifted'] ?? 0).toDouble(),
      totalDurationMinutes: json['total_duration_minutes'] ?? 0,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'activity_date': DateFormat('yyyy-MM-dd').format(activityDate),
      'workouts_count': workoutsCount,
      'total_calories': totalCalories,
      'total_weight_lifted': totalWeightLifted,
      'total_duration_minutes': totalDurationMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TeamActivityLog copyWith({
    String? id,
    String? teamId,
    String? userId,
    DateTime? activityDate,
    int? workoutsCount,
    double? totalCalories,
    double? totalWeightLifted,
    int? totalDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamActivityLog(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      activityDate: activityDate ?? this.activityDate,
      workoutsCount: workoutsCount ?? this.workoutsCount,
      totalCalories: totalCalories ?? this.totalCalories,
      totalWeightLifted: totalWeightLifted ?? this.totalWeightLifted,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamActivityLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          teamId == other.teamId &&
          userId == other.userId &&
          activityDate == other.activityDate;

  @override
  int get hashCode =>
      id.hashCode ^ teamId.hashCode ^ userId.hashCode ^ activityDate.hashCode;

  @override
  String toString() =>
      'TeamActivityLog(id: $id, teamId: $teamId, userId: $userId, date: $activityDate, workouts: $workoutsCount)';
}

DateTime _parseDate(dynamic value) {
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
