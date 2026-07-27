import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';

/// A workout manually assigned to a specific calendar date (e.g. "12th of
/// the month -> Leg day"), overriding the sequential auto-suggestion.
class PlannedWorkout {
  final String date;
  final String programKey;
  final int dayIndex;
  final String dayName;

  const PlannedWorkout({
    required this.date,
    required this.programKey,
    required this.dayIndex,
    required this.dayName,
  });
}

/// Tracks per-program sequential day progress (which day comes next once the
/// user trains again, advancing only when a workout is actually completed -
/// skipped calendar days don't affect it) and manual per-date program/day
/// assignments made from the calendar.
class ProgramProgressProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  final Map<String, int> _nextDayIndexByProgram = {};
  Map<String, PlannedWorkout> _plannedByDate = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final planned = await _db.allPlannedWorkouts();
    _plannedByDate = planned.map(
      (date, row) => MapEntry(
        date,
        PlannedWorkout(
          date: date,
          programKey: row['program_key'] as String,
          dayIndex: row['day_index'] as int,
          dayName: row['day_name'] as String,
        ),
      ),
    );
    // Drop the in-memory next-day-index cache too, so a full reload (e.g.
    // after a factory data reset) doesn't keep serving stale values.
    _nextDayIndexByProgram.clear();
    _loaded = true;
    notifyListeners();
  }

  /// The next suggested day index for [programKey] (0-based), clamped to
  /// [totalDays]. Cached in-memory after the first DB read.
  Future<int> nextDayIndex(String programKey, int totalDays) async {
    if (totalDays <= 0) return 0;
    if (!_nextDayIndexByProgram.containsKey(programKey)) {
      _nextDayIndexByProgram[programKey] = await _db.nextDayIndex(programKey);
    }
    return _nextDayIndexByProgram[programKey]! % totalDays;
  }

  /// Synchronous read of the cached next-day index (0 if not yet loaded).
  int cachedNextDayIndex(String programKey, int totalDays) {
    if (totalDays <= 0) return 0;
    return (_nextDayIndexByProgram[programKey] ?? 0) % totalDays;
  }

  /// Call once a guided workout for [programKey]/[dayIndex] is finished, so
  /// the following visit suggests the next day in sequence.
  Future<void> markCompleted(String programKey, int dayIndex, int totalDays, String date) async {
    if (totalDays <= 0) return;
    final next = (dayIndex + 1) % totalDays;
    await _db.setNextDayIndex(programKey, next, date);
    _nextDayIndexByProgram[programKey] = next;
    notifyListeners();
  }

  PlannedWorkout? plannedFor(String date) => _plannedByDate[date];

  Future<void> setPlanned(String date, String programKey, int dayIndex, String dayName) async {
    await _db.setPlannedWorkout(date, programKey, dayIndex, dayName);
    _plannedByDate[date] = PlannedWorkout(
      date: date,
      programKey: programKey,
      dayIndex: dayIndex,
      dayName: dayName,
    );
    notifyListeners();
  }

  Future<void> clearPlanned(String date) async {
    await _db.clearPlannedWorkout(date);
    _plannedByDate.remove(date);
    notifyListeners();
  }
}
