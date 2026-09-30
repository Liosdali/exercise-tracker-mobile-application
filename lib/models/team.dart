import '../theme/team_palette.dart';

/// Represents a team (group) for social features.
class Team {
  final String id;
  final String name;
  final String? description;
  final String? ownerId;
  final String inviteToken;
  final DateTime createdAt;
  final String color;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.ownerId,
    required this.inviteToken,
    required this.createdAt,
    this.color = 'steel',
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
      color: json['color'] as String? ?? kDefaultKit.name,
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
        'color': color,
      };

  /// Creates a copy of this Team with optional field updates.
  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? inviteToken,
    DateTime? createdAt,
    String? color,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      inviteToken: inviteToken ?? this.inviteToken,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
    );
  }

  /// The kit colour this team wears. Unknown or missing slugs resolve to the
  /// default rather than throwing, so a row written by a newer client cannot
  /// break an older one.
  KitColor get kit => kitFromSlug(color);

  @override
  String toString() =>
      'Team(id: $id, name: $name, description: $description, ownerId: $ownerId, inviteToken: $inviteToken, color: $color)';

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
          createdAt == other.createdAt &&
          color == other.color;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      ownerId.hashCode ^
      inviteToken.hashCode ^
      createdAt.hashCode ^
      color.hashCode;
}
