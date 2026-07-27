import 'package:flutter/foundation.dart';

import '../data/exercise_repository.dart';
import '../models/exercise.dart';

/// Exposes the loaded exercises dataset to the widget tree.
class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _repository = ExerciseRepository();

  bool get isLoaded => _repository.isLoaded;

  Future<void> load() async {
    if (_repository.isLoaded) return;
    await _repository.load();
    notifyListeners();
  }

  List<String> get categories => _repository.categories;

  int countForCategory(String category) =>
      _repository.countForCategory(category);

  Exercise? representativeForCategory(String category) =>
      _repository.representativeForCategory(category);

  List<Exercise> byCategory(String category) => _repository.byCategory(category);

  Exercise? byId(String id) => _repository.byId(id);

  List<Exercise> search(String query, {String? category}) =>
      _repository.search(query, category: category);
}
