/// Snapshot of the stats needed to evaluate achievement conditions, kept
/// intentionally small/decoupled from [StatsProvider] so this file has no
/// dependency on Flutter or the database.
class StatsSnapshot {
  final int totalWorkouts;
  final int totalSets;
  final double totalVolume;
  final int currentStreak;
  final double totalCaloriesBurned;
  final int totalWorkoutMinutes;

  const StatsSnapshot({
    required this.totalWorkouts,
    required this.totalSets,
    required this.totalVolume,
    required this.currentStreak,
    required this.totalCaloriesBurned,
    required this.totalWorkoutMinutes,
  });
}

/// A single achievement *definition*: static metadata plus the rule that
/// decides whether it's unlocked for a given [StatsSnapshot]. Adding a new
/// achievement is just adding one more entry to [achievementDefinitions] -
/// no other code needs to change, so this scales cleanly to 50+ badges.
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String category;
  final bool Function(StatsSnapshot) isUnlocked;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    required this.isUnlocked,
  });
}

/// The full achievement registry. Grouped loosely by category as a
/// convention only; the UI doesn't require any particular ordering.
final List<AchievementDefinition> achievementDefinitions = [
  // --- Workout count ---
  AchievementDefinition(
    id: 'first_workout',
    title: 'İlk Adım',
    description: 'İlk antrenmanını kaydet.',
    iconName: 'flag',
    category: 'workouts',
    isUnlocked: (s) => s.totalWorkouts >= 1,
  ),
  AchievementDefinition(
    id: 'ten_workouts',
    title: 'Kararlılık',
    description: '10 antrenman günü tamamla.',
    iconName: 'military_tech',
    category: 'workouts',
    isUnlocked: (s) => s.totalWorkouts >= 10,
  ),
  AchievementDefinition(
    id: 'fifty_workouts',
    title: 'Alışkanlık',
    description: '50 antrenman günü tamamla.',
    iconName: 'workspace_premium',
    category: 'workouts',
    isUnlocked: (s) => s.totalWorkouts >= 50,
  ),
  AchievementDefinition(
    id: 'hundred_workouts',
    title: 'Yüzler Kulübü',
    description: '100 antrenman günü tamamla.',
    iconName: 'emoji_events',
    category: 'workouts',
    isUnlocked: (s) => s.totalWorkouts >= 100,
  ),

  // --- Streaks ---
  AchievementDefinition(
    id: 'streak_3',
    title: '3 Gün Üst Üste!',
    description: '3 gün üst üste antrenman yap.',
    iconName: 'local_fire_department',
    category: 'streak',
    isUnlocked: (s) => s.currentStreak >= 3,
  ),
  AchievementDefinition(
    id: 'streak_7',
    title: 'Haftalık Seri',
    description: '7 gün üst üste antrenman yap.',
    iconName: 'local_fire_department',
    category: 'streak',
    isUnlocked: (s) => s.currentStreak >= 7,
  ),
  AchievementDefinition(
    id: 'streak_30',
    title: 'Demir İrade',
    description: '30 gün üst üste antrenman yap.',
    iconName: 'local_fire_department',
    category: 'streak',
    isUnlocked: (s) => s.currentStreak >= 30,
  ),

  // --- Volume ---
  AchievementDefinition(
    id: 'volume_10000',
    title: 'İlk 10.000 kg',
    description: 'Toplamda 10.000 kg hacim kaldır.',
    iconName: 'fitness_center',
    category: 'volume',
    isUnlocked: (s) => s.totalVolume >= 10000,
  ),
  AchievementDefinition(
    id: 'volume_100000',
    title: 'İlk 100.000 kg',
    description: 'Toplamda 100.000 kg hacim kaldır.',
    iconName: 'fitness_center',
    category: 'volume',
    isUnlocked: (s) => s.totalVolume >= 100000,
  ),

  // --- Duration / calories (enabled by the new workout timer) ---
  AchievementDefinition(
    id: 'minutes_60',
    title: 'İlk Saat',
    description: 'Toplamda 60 dakika antrenman yap.',
    iconName: 'timer',
    category: 'duration',
    isUnlocked: (s) => s.totalWorkoutMinutes >= 60,
  ),
  AchievementDefinition(
    id: 'minutes_600',
    title: 'Zaman Ustası',
    description: 'Toplamda 600 dakika antrenman yap.',
    iconName: 'timer',
    category: 'duration',
    isUnlocked: (s) => s.totalWorkoutMinutes >= 600,
  ),
  AchievementDefinition(
    id: 'calories_1000',
    title: 'İlk 1000 kalori',
    description: 'Toplamda 1000 kalori yak.',
    iconName: 'local_fire_department',
    category: 'calories',
    isUnlocked: (s) => s.totalCaloriesBurned >= 1000,
  ),
  AchievementDefinition(
    id: 'calories_10000',
    title: '10.000 Kalori Kulübü',
    description: 'Toplamda 10.000 kalori yak.',
    iconName: 'local_fire_department',
    category: 'calories',
    isUnlocked: (s) => s.totalCaloriesBurned >= 10000,
  ),

  // --- Sets ---
  AchievementDefinition(
    id: 'sets_100',
    title: 'Yüz Set',
    description: 'Toplamda 100 set tamamla.',
    iconName: 'repeat',
    category: 'sets',
    isUnlocked: (s) => s.totalSets >= 100,
  ),
  AchievementDefinition(
    id: 'sets_1000',
    title: 'Bin Set',
    description: 'Toplamda 1000 set tamamla.',
    iconName: 'repeat',
    category: 'sets',
    isUnlocked: (s) => s.totalSets >= 1000,
  ),
];
