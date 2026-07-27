import 'package:flutter/foundation.dart';

import '../models/workout_program.dart';

/// Exposes the built-in workout programs to the widget tree. Programs are
/// static data (no persistence needed), but kept as a ChangeNotifier for
/// consistency with the rest of the provider layer and future extension.
class ProgramProvider extends ChangeNotifier {
  List<WorkoutProgram> get programs => builtInPrograms;

  WorkoutProgram? byId(String id) {
    try {
      return builtInPrograms.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
