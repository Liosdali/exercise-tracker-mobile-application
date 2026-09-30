import 'account_change_notifier.dart';

import '../data/database_helper.dart';
import '../models/custom_routine.dart';

/// CRUD for user-created custom routines, backed by the local database.
class RoutineProvider extends AccountChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance.workspace();

  @override
  Future<void> reloadAccount() => load();

  List<CustomRoutine> _routines = [];
  bool _loaded = false;

  List<CustomRoutine> get routines => List.unmodifiable(_routines);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _routines = await _db.allRoutines();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addRoutine(CustomRoutine routine) async {
    await _db.insertRoutine(routine);
    await load();
  }

  Future<void> updateRoutine(CustomRoutine routine) async {
    await _db.updateRoutine(routine);
    await load();
  }

  Future<void> deleteRoutine(int id) async {
    await _db.deleteRoutine(id);
    await load();
  }
}
