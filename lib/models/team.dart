/// Represents a team (group) for social features.
class Team {
  final String id;
  final String name;
  final String? description;
  final String? ownerId;
  final String inviteToken;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.ownerId,
    required this.inviteToken,
    required this.createdAt,
  });

  /// Creates a Team from a Supabase row.
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String?,
      inviteToken: json['invite_token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts Team to JSON for Supabase.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'owner_id': ownerId,
        'invite_token': inviteToken,
        'created_at': createdAt.toIso8601String(),
      };

  /// Creates a copy of this Team with optional field updates.
  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? inviteToken,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      inviteToken: inviteToken ?? this.inviteToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Team(id: $id, name: $name, description: $description, ownerId: $ownerId, inviteToken: $inviteToken)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          ownerId == other.ownerId &&
          inviteToken == other.inviteToken &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      ownerId.hashCode ^
      inviteToken.hashCode ^
      createdAt.hashCode;
}
