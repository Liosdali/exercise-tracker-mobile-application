/// A single achievement/badge definition, decoupled from how its unlocked
/// state is computed so the registry in `achievement_definitions.dart` can
/// grow to 50+ entries without touching this model or the UI.
class AchievementModel {
  final String id;
  final String title;
  final String description;

  /// Material icon used as the badge artwork (kept as an [int] code point
  /// reference via [icon] rather than importing `material.dart` here, so
  /// this model stays UI-framework agnostic where possible).
  final String iconName;
  final String category;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    required this.unlocked,
    this.unlockedAt,
  });

  AchievementModel copyWith({bool? unlocked, DateTime? unlockedAt}) {
    return AchievementModel(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      category: category,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
