import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/achievement_definitions.dart';
import '../data/database_helper.dart';
import '../models/achievement.dart';
import '../models/workout_entry.dart';
import '../models/workout_session.dart';

final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

/// One data point in the weekly volume chart (kept for backwards
/// compatibility with any other call sites; the profile screen now uses
/// [WeeklyDuration] instead).
class WeeklyVolume {
  final String weekLabel;
  final double volume;

  const WeeklyVolume(this.weekLabel, this.volume);
}

/// One day's total workout duration within the current week, used by the
/// "Haftalık Antrenman Süresi" chart.
class WeeklyDuration {
  final String dayLabel; // Pzt, Sal, Çar, ...
  final int minutes;

  const WeeklyDuration(this.dayLabel, this.minutes);
}

const List<String> _turkishWeekdayLabels = ['Pzt', 'Sal', 'Çar', 'Perş', 'Cum', 'Cmt', 'Paz'];

/// Computes gamification/progress stats (streaks, volume, calories,
/// achievements, weekly chart data) from the logged workout entries and
/// completed workout sessions.
class StatsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<WorkoutEntry> _entries = [];
  List<WorkoutSession> _sessions = [];
  Map<String, String> _unlockedAchievements = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    _entries = await _db.allEntries();
    _sessions = await _db.allWorkoutSessions();
    _unlockedAchievements = await _db.allUnlockedAchievements();
    await _persistNewlyUnlockedAchievements();
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

  /// Simple heuristic fallback (kept for compatibility); prefer
  /// [totalCaloriesBurned], which uses the MET-based calculation from real
  /// tracked session durations.
  double get estimatedCalories => totalSets * 6 + totalVolume * 0.05;

  /// Sum of MET-based calorie estimates across all completed sessions.
  double get totalCaloriesBurned => _sessions.fold<double>(0, (sum, s) => sum + s.calories);

  /// Sum of tracked workout durations (minutes) across all completed
  /// sessions.
  int get totalWorkoutMinutes => _sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

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

  /// Most recent logged workout date, or null if none logged yet.
  DateTime? get lastWorkoutDate {
    final dates = _entries.map((e) => e.date).toSet().toList()..sort();
    if (dates.isEmpty) return null;
    final d = _dateFmt.parse(dates.last);
    return DateTime(d.year, d.month, d.day);
  }

  /// Days elapsed since [lastWorkoutDate] (0 if a workout was logged today,
  /// or a large sentinel if nothing has ever been logged).
  int get daysSinceLastWorkout {
    final last = lastWorkoutDate;
    if (last == null) return 999;
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day).difference(last).inDays;
  }

  /// Current streak using the flexible "7-day grace" rule: the streak does
  /// NOT reset just because a day was skipped. It only resets to 0 once a
  /// full 7 days have passed since the most recent workout with no new
  /// entry logged. Gaps of up to 6 days keep the streak alive and simply
  /// add 1 for the new day worked.
  int get currentStreak {
    final dates = _entries.map((e) => e.date).toSet().toList()..sort();
    if (dates.isEmpty) return 0;

    final lastDate = _dateFmt.parse(dates.last);
    final daysSinceLast = DateTime.now().difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
    if (daysSinceLast >= 7) return 0;

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final prev = _dateFmt.parse(dates[i - 1]);
      final curr = _dateFmt.parse(dates[i]);
      final gap = curr.difference(prev).inDays;
      if (gap <= 0) continue; // same-day duplicate entries
      if (gap <= 6) {
        streak++;
      } else {
        streak = 1;
      }
    }
    return streak;
  }

  /// Historical record streak ("En Uzun Seri"): the longest consecutive
  /// run ever achieved, using the same 7-day-gap tolerance rule as
  /// [currentStreak], but not clamped to zero by inactivity relative to
  /// today (it's a permanent best-ever record).
  int get maxStreak {
    final dates = _entries.map((e) => e.date).toSet().toList()..sort();
    if (dates.isEmpty) return 0;

    int best = 1;
    int running = 1;
    for (int i = 1; i < dates.length; i++) {
      final prev = _dateFmt.parse(dates[i - 1]);
      final curr = _dateFmt.parse(dates[i]);
      final gap = curr.difference(prev).inDays;
      if (gap <= 0) continue; // same-day duplicate entries
      if (gap <= 6) {
        running++;
      } else {
        running = 1;
      }
      if (running > best) best = running;
    }
    return best;
  }

  /// Weekly total volume for the last 8 calendar weeks (oldest first). Kept
  /// for compatibility with any other consumers.
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

  /// Total workout duration (minutes) per day of the *current* week
  /// (Monday -> Sunday), for the "Haftalık Antrenman Süresi" chart. Days
  /// with no completed session show 0 minutes.
  List<WeeklyDuration> get weeklyDurationSeries {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final result = <WeeklyDuration>[];
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayStr = _dateFmt.format(day);
      final minutes = _sessions
          .where((s) => s.date == dayStr)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      result.add(WeeklyDuration(_turkishWeekdayLabels[i], minutes));
    }
    return result;
  }

  /// Calories burned within the current calendar week (Monday-Sunday).
  double get weeklyCalories {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final mondayStr = _dateFmt.format(monday);
    final todayStr = _dateFmt.format(now);
    return _sessions
        .where((s) => s.date.compareTo(mondayStr) >= 0 && s.date.compareTo(todayStr) <= 0)
        .fold<double>(0, (sum, s) => sum + s.calories);
  }

  /// Calories burned within the current calendar month.
  double get monthlyCalories {
    final now = DateTime.now();
    final monthStart = _dateFmt.format(DateTime(now.year, now.month, 1));
    final todayStr = _dateFmt.format(now);
    return _sessions
        .where((s) => s.date.compareTo(monthStart) >= 0 && s.date.compareTo(todayStr) <= 0)
        .fold<double>(0, (sum, s) => sum + s.calories);
  }

  StatsSnapshot get _snapshot => StatsSnapshot(
        totalWorkouts: totalWorkouts,
        totalSets: totalSets,
        totalVolume: totalVolume,
        currentStreak: currentStreak,
        totalCaloriesBurned: totalCaloriesBurned,
        totalWorkoutMinutes: totalWorkoutMinutes,
      );

  /// Full achievement list (locked + unlocked), built from the extensible
  /// [achievementDefinitions] registry. Unlock dates come from the
  /// `achievements_unlocked` table (persisted the first time each one is
  /// reached), not recomputed live.
  List<AchievementModel> get achievements {
    final snapshot = _snapshot;
    return [
      for (final def in achievementDefinitions)
        AchievementModel(
          id: def.id,
          title: def.title,
          description: def.description,
          iconName: def.iconName,
          category: def.category,
          unlocked: def.isUnlocked(snapshot),
          unlockedAt: _unlockedAchievements[def.id] != null
              ? DateTime.tryParse(_unlockedAchievements[def.id]!)
              : null,
        ),
    ];
  }

  /// Persists the first-unlock date for any achievement definition that's
  /// newly satisfied but not yet recorded in the database.
  Future<void> _persistNewlyUnlockedAchievements() async {
    final snapshot = _snapshot;
    final now = DateTime.now().toIso8601String();
    for (final def in achievementDefinitions) {
      if (def.isUnlocked(snapshot) && !_unlockedAchievements.containsKey(def.id)) {
        await _db.markAchievementUnlocked(def.id, now);
        _unlockedAchievements[def.id] = now;
      }
    }
  }
}
