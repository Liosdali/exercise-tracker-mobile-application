import 'package:intl/intl.dart';

/// Represents a team member's ranking in the leaderboard
class LeaderboardEntry {
  final String id;
  final String teamId;
  final String userId;
  final DateTime periodStartDate;
  final int workoutCount;
  final double totalWeightLifted;
  final double totalCalories;
  final int rank;
  final DateTime updatedAt;

  // User details (populated separately via join)
  String? userName;
  String? userAvatarUrl;

  LeaderboardEntry({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.periodStartDate,
    required this.workoutCount,
    required this.totalWeightLifted,
    required this.totalCalories,
    required this.rank,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? '',
      teamId: json['team_id'] ?? '',
      userId: json['user_id'] ?? '',
      periodStartDate: _parseDate(json['week_start_date'] ?? json['month_start_date']),
      workoutCount: json['workout_count'] ?? 0,
      totalWeightLifted: (json['total_weight_lifted'] ?? 0).toDouble(),
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      rank: json['rank'] ?? 0,
      updatedAt: _parseTimestamp(json['updated_at']),
      userName: json['social_users']?['display_name'] ?? json['userName'],
      userAvatarUrl: json['social_users']?['avatar_url'] ?? json['userAvatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'period_start_date': DateFormat('yyyy-MM-dd').format(periodStartDate),
      'workout_count': workoutCount,
      'total_weight_lifted': totalWeightLifted,
      'total_calories': totalCalories,
      'rank': rank,
      'updated_at': updatedAt.toIso8601String(),
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
    };
  }

  LeaderboardEntry copyWith({
    String? id,
    String? teamId,
    String? userId,
    DateTime? periodStartDate,
    int? workoutCount,
    double? totalWeightLifted,
    double? totalCalories,
    int? rank,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      periodStartDate: periodStartDate ?? this.periodStartDate,
      workoutCount: workoutCount ?? this.workoutCount,
      totalWeightLifted: totalWeightLifted ?? this.totalWeightLifted,
      totalCalories: totalCalories ?? this.totalCalories,
      rank: rank ?? this.rank,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }

  /// Returns the medal emoji for top 3 positions, or rank number
  String getRankDisplay() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  /// Returns true if this is a top 3 rank (medal-worthy)
  bool get isTopThree => rank >= 1 && rank <= 3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          teamId == other.teamId &&
          userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ teamId.hashCode ^ userId.hashCode;

  @override
  String toString() =>
      'LeaderboardEntry(rank: $rank, user: $userName, workouts: $workoutCount, weight: $totalWeightLifted kg)';
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
