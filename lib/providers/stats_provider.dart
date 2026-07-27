import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../models/workout_entry.dart';

final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

/// A single achievement/badge definition, with its unlocked state computed
/// live from the current stats.
class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

/// One data point in the weekly volume chart.
class WeeklyVolume {
  final String weekLabel;
  final double volume;

  const WeeklyVolume(this.weekLabel, this.volume);
}

/// Computes gamification/progress stats (streaks, volume, calories,
/// achievements, weekly chart data) from the logged workout entries.
class StatsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<WorkoutEntry> _entries = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    _entries = await _db.allEntries();
    _loaded = true;
    notifyListeners();
  }

  /// Distinct workout dates (yyyy-MM-dd), most recent first.
  List<String> get _workoutDates {
    final dates = _entries.map((e) => e.date).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  int get totalWorkouts => _workoutDates.length;

  double get totalVolume => _entries.fold<double>(
        0,
        (sum, e) => sum + (e.sets ?? 0) * (e.reps ?? 0) * (e.weight ?? 0),
      );

  int get totalSets => _entries.fold<int>(0, (sum, e) => sum + (e.sets ?? 0));

  /// Simple heuristic: ~6 kcal per completed set plus a small volume-based
  /// component, so bodyweight-only sessions still count.
  double get estimatedCalories => totalSets * 6 + totalVolume * 0.05;

  /// Number of distinct workout days within the current calendar week
  /// (Monday-Sunday).
  int get thisWeekCount {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr = _dateFmt.format(DateTime(monday.year, monday.month, monday.day));
    final todayStr = _dateFmt.format(now);
    return _workoutDates
        .where((d) => d.compareTo(mondayStr) >= 0 && d.compareTo(todayStr) <= 0)
        .length;
  }

  /// Current streak: number of consecutive days with a logged workout,
  /// counting back from today (or yesterday, so a rest day today doesn't
  /// immediately zero out yesterday's streak).
  int get currentStreak {
    final dateSet = _entries.map((e) => e.date).toSet();
    if (dateSet.isEmpty) return 0;

    DateTime cursor = DateTime.now();
    if (!dateSet.contains(_dateFmt.format(cursor)) &&
        !dateSet.contains(_dateFmt.format(cursor.subtract(const Duration(days: 1))))) {
      return 0;
    }
    if (!dateSet.contains(_dateFmt.format(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (dateSet.contains(_dateFmt.format(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Weekly total volume for the last 8 calendar weeks (oldest first).
  List<WeeklyVolume> get weeklyVolumeSeries {
    final now = DateTime.now();
    final currentMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final result = <WeeklyVolume>[];
    for (int i = 7; i >= 0; i--) {
      final weekStart = currentMonday.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final startStr = _dateFmt.format(weekStart);
      final endStr = _dateFmt.format(weekEnd);
      final volume = _entries
          .where((e) => e.date.compareTo(startStr) >= 0 && e.date.compareTo(endStr) <= 0)
          .fold<double>(0, (sum, e) => sum + (e.sets ?? 0) * (e.reps ?? 0) * (e.weight ?? 0));
      result.add(WeeklyVolume('${weekStart.day}/${weekStart.month}', volume));
    }
    return result;
  }

  List<Achievement> get achievements {
    final streak = currentStreak;
    return [
      Achievement(
        id: 'first_workout',
        title: 'İlk Adım',
        description: 'İlk antrenmanını kaydet.',
        unlocked: totalWorkouts >= 1,
      ),
      Achievement(
        id: 'ten_workouts',
        title: 'Kararlılık',
        description: '10 antrenman günü tamamla.',
        unlocked: totalWorkouts >= 10,
      ),
      Achievement(
        id: 'fifty_workouts',
        title: 'Alışkanlık',
        description: '50 antrenman günü tamamla.',
        unlocked: totalWorkouts >= 50,
      ),
      Achievement(
        id: 'streak_3',
        title: '3 Gün Üst Üste!',
        description: '3 gün üst üste antrenman yap.',
        unlocked: streak >= 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Haftalık Seri',
        description: '7 gün üst üste antrenman yap.',
        unlocked: streak >= 7,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Demir İrade',
        description: '30 gün üst üste antrenman yap.',
        unlocked: streak >= 30,
      ),
      Achievement(
        id: 'volume_10000',
        title: 'İlk 10.000 kg',
        description: 'Toplamda 10.000 kg hacim kaldır.',
        unlocked: totalVolume >= 10000,
      ),
      Achievement(
        id: 'volume_100000',
        title: 'İlk 100.000 kg',
        description: 'Toplamda 100.000 kg hacim kaldır.',
        unlocked: totalVolume >= 100000,
      ),
    ];
  }
}
