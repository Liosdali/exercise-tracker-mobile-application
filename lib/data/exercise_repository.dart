import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/exercise.dart';

/// Loads and caches the bundled exercises dataset (storage/data/exercises.json)
/// and exposes convenient category/search lookups.
class ExerciseRepository {
  List<Exercise> _exercises = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<Exercise> get all => List.unmodifiable(_exercises);

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('storage/data/exercises.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    _exercises = decoded
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  /// Sorted list of distinct body-part categories.
  List<String> get categories {
    final set = _exercises.map((e) => e.bodyPart).toSet().toList();
    set.sort();
    return set;
  }

  int countForCategory(String category) =>
      _exercises.where((e) => e.bodyPart == category).length;

  /// A representative exercise for a category, used for thumbnail previews.
  Exercise? representativeForCategory(String category) {
    final matches = _exercises.where((e) => e.bodyPart == category);
    return matches.isEmpty ? null : matches.first;
  }

  List<Exercise> byCategory(String category) =>
      _exercises.where((e) => e.bodyPart == category).toList();

  Exercise? byId(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Exercise> search(String query, {String? category}) {
    final lower = query.trim().toLowerCase();
    return _exercises.where((e) {
      final matchesCategory = category == null || e.bodyPart == category;
      final matchesQuery = lower.isEmpty ||
          e.name.toLowerCase().contains(lower) ||
          e.target.toLowerCase().contains(lower) ||
          e.equipment.toLowerCase().contains(lower);
      return matchesCategory && matchesQuery;
    }).toList();
  }
}
