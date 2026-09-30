/// Represents a member of a team.
class TeamMember {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  TeamMember({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  /// Creates a TeamMember from a Supabase row.
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'] as String,
      displayName: json['social_users']['display_name'] as String? ?? '',
      avatarUrl: json['social_users']['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  /// Alternative constructor when social_users data is flat/separate.
  factory TeamMember.fromJsonFlat(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  /// Converts TeamMember to JSON.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'joined_at': joinedAt.toIso8601String(),
      };

  /// Creates a copy of this TeamMember with optional field updates.
  TeamMember copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? role,
    DateTime? joinedAt,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// Checks if this member is an admin.
  bool get isAdmin => role == 'admin';

  @override
  String toString() =>
      'TeamMember(userId: $userId, displayName: $displayName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl &&
          role == other.role &&
          joinedAt == other.joinedAt;

  @override
  int get hashCode =>
      userId.hashCode ^
      displayName.hashCode ^
      avatarUrl.hashCode ^
      role.hashCode ^
      joinedAt.hashCode;
}
