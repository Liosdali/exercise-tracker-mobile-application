import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../models/custom_program.dart';

/// CRUD for user-created, multi-day custom workout programs, backed by the
/// local database.
class CustomProgramProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CustomProgram> _programs = [];
  bool _loaded = false;

  List<CustomProgram> get programs => List.unmodifiable(_programs);
  bool get isLoaded => _loaded;

  CustomProgram? byId(int id) {
    try {
      return _programs.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    _programs = await _db.allPrograms();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addProgram(CustomProgram program) async {
    await _db.insertProgram(program);
    await load();
  }

  Future<void> updateProgram(CustomProgram program) async {
    await _db.updateProgram(program);
    await load();
  }

  Future<void> deleteProgram(int id) async {
    await _db.deleteProgram(id);
    await load();
  }
}
