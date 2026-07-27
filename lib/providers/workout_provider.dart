import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../models/workout_entry.dart';

/// Exposes the workout log (recorded working days + exercises) to the
/// widget tree, backed by the local SQLite database.
class WorkoutProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Set<String> _loggedDates = {};
  final Map<String, List<WorkoutEntry>> _entriesByDate = {};

  Set<String> get loggedDates => _loggedDates;

  List<WorkoutEntry> entriesFor(String date) => _entriesByDate[date] ?? const [];

  Future<void> init() async {
    _loggedDates = await _db.loggedDates();
    notifyListeners();
  }

  Future<void> loadEntriesFor(String date) async {
    _entriesByDate[date] = await _db.entriesForDate(date);
    notifyListeners();
  }

  Future<void> addEntry(WorkoutEntry entry) async {
    await _db.insertEntry(entry);
    await loadEntriesFor(entry.date);
    _loggedDates = await _db.loggedDates();
    notifyListeners();
  }

  Future<void> updateEntry(WorkoutEntry entry) async {
    await _db.updateEntry(entry);
    await loadEntriesFor(entry.date);
    notifyListeners();
  }

  Future<void> deleteEntry(WorkoutEntry entry) async {
    if (entry.id == null) return;
    await _db.deleteEntry(entry.id!);
    await loadEntriesFor(entry.date);
    _loggedDates = await _db.loggedDates();
    notifyListeners();
  }
}
