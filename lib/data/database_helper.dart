import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/body_measurement.dart';
import '../models/custom_program.dart';
import '../models/custom_routine.dart';
import '../models/workout_entry.dart';
import '../models/workout_session.dart';

/// Manages the local SQLite database that stores logged workout entries,
/// user-created custom routines/programs, body measurements, and workout
/// program progress/calendar assignments.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const int _dbVersion = 5;

  Database? _db;
  Future<Database>? _dbOpening;

  /// Returns the shared database instance, opening it on first use. Caches
  /// the in-flight opening [Future] (not just the resolved [Database]) so
  /// concurrent first-access calls (e.g. several providers loading at app
  /// startup) all await the same open/migration instead of racing to open
  /// the same file multiple times.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _dbOpening ??= _initDatabase();
    _db = await _dbOpening;
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'exercise_app.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createV1Tables(db);
        await _createV2Tables(db);
        await _createV3Tables(db);
        await _createV4Tables(db);
        await _createV5Migration(db);
        // await _createV6Migration(db); // <- add new versions here too.
      },
      // Standard safe-migration recipe for this project (no data loss):
      // 1. Bump `_dbVersion` above by exactly 1.
      // 2. Add a new `_createVN_Migration(db)` method containing ONLY the
      //    new `CREATE TABLE IF NOT EXISTS ...` / additive
      //    `ALTER TABLE ... ADD COLUMN ...` statements for that version.
      //    NEVER `DROP TABLE`/`DROP COLUMN` or rewrite existing columns in
      //    place — SQLite's ALTER TABLE can't remove/rename columns
      //    without a full table rebuild, and existing users' rows must
      //    survive the upgrade.
      // 3. Wrap every `ADD COLUMN` in try/catch (see `_createV5Migration`)
      //    so re-running an already-applied step (e.g. if onCreate and
      //    onUpgrade both touch the same version during testing) is a
      //    harmless no-op instead of throwing.
      // 4. Add both a call in `onCreate` (so brand-new installs get the
      //    latest schema in one pass) AND a guarded call in `onUpgrade`
      //    below (so existing installs get only what they're missing).
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
        }
        if (oldVersion < 3) {
          await _createV3Tables(db);
        }
        if (oldVersion < 4) {
          await _createV4Tables(db);
        }
        if (oldVersion < 5) {
          await _createV5Migration(db);
        }
        // if (oldVersion < 6) {
        //   await _createV6Migration(db);
        // }
      },
    );
  }

  // Template for the next migration (copy/rename when actually needed):
  //
  // Future<void> _createV6Migration(Database db) async {
  //   await db.execute('''
  //     CREATE TABLE IF NOT EXISTS some_new_table (
  //       id INTEGER PRIMARY KEY AUTOINCREMENT,
  //       ...
  //     )
  //   ''');
  //   try {
  //     await db.execute('ALTER TABLE workout_entries ADD COLUMN some_new_col TEXT');
  //   } on DatabaseException {
  //     // Column already present — safe to ignore.
  //   }
  // }

  Future<void> _createV1Tables(Database db) async {
    await db.execute('''
      CREATE TABLE workout_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        category TEXT NOT NULL,
        sets INTEGER,
        reps INTEGER,
        weight REAL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_workout_entries_date ON workout_entries(date)',
    );
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE custom_routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_routine_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        category TEXT NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps INTEGER NOT NULL,
        position INTEGER NOT NULL,
        FOREIGN KEY (routine_id) REFERENCES custom_routines (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE body_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight_kg REAL,
        body_fat_percent REAL,
        chest_cm REAL,
        waist_cm REAL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_body_measurements_date ON body_measurements(date)',
    );
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_program_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        position INTEGER NOT NULL,
        FOREIGN KEY (program_id) REFERENCES custom_programs (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_program_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_id INTEGER NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        category TEXT NOT NULL,
        target_sets INTEGER NOT NULL,
        target_reps INTEGER NOT NULL,
        position INTEGER NOT NULL,
        FOREIGN KEY (day_id) REFERENCES custom_program_days (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS program_progress (
        program_key TEXT PRIMARY KEY,
        next_day_index INTEGER NOT NULL,
        last_completed_date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS planned_workouts (
        date TEXT PRIMARY KEY,
        program_key TEXT NOT NULL,
        day_index INTEGER NOT NULL,
        day_name TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements_unlocked (
        achievement_id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        calories REAL NOT NULL,
        exercise_count INTEGER NOT NULL,
        total_sets INTEGER NOT NULL,
        total_volume REAL NOT NULL,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_workout_sessions_date ON workout_sessions(date)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY,
        height_cm REAL,
        age INTEGER,
        gender TEXT,
        weight_kg REAL,
        body_fat_percent REAL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Adds the extra body-composition columns (height/gender/neck/hip +
  /// the auto-calculated U.S. Navy body fat %) to `body_measurements`.
  /// `ALTER TABLE ADD COLUMN` throws if a column already exists, so each
  /// statement is wrapped defensively (harmless no-op on re-run).
  Future<void> _createV5Migration(Database db) async {
    final columns = <String, String>{
      'height_cm': 'REAL',
      'gender': 'TEXT',
      'neck_cm': 'REAL',
      'hip_cm': 'REAL',
      'calculated_body_fat': 'REAL',
    };
    for (final entry in columns.entries) {
      try {
        await db.execute('ALTER TABLE body_measurements ADD COLUMN ${entry.key} ${entry.value}');
      } on DatabaseException {
        // Column already present (e.g. onCreate ran this once already) -
        // safe to ignore.
      }
    }
  }

  // ---- Workout entries (v1) ----

  Future<int> insertEntry(WorkoutEntry entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    return db.insert('workout_entries', map);
  }

  Future<int> updateEntry(WorkoutEntry entry) async {
    final db = await database;
    return db.update(
      'workout_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('workout_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WorkoutEntry>> entriesForDate(String date) async {
    final db = await database;
    final rows = await db.query(
      'workout_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id ASC',
    );
    return rows.map(WorkoutEntry.fromMap).toList();
  }

  /// All distinct dates (yyyy-MM-dd) that have at least one logged entry.
  Future<Set<String>> loggedDates() async {
    final db = await database;
    final rows = await db.query('workout_entries', distinct: true, columns: ['date']);
    return rows.map((r) => r['date'] as String).toSet();
  }

  Future<List<WorkoutEntry>> allEntries() async {
    final db = await database;
    final rows = await db.query('workout_entries', orderBy: 'date DESC, id ASC');
    return rows.map(WorkoutEntry.fromMap).toList();
  }

  /// Entries with date within [start, end] (inclusive, yyyy-MM-dd strings),
  /// used for weekly/monthly stats and charts.
  Future<List<WorkoutEntry>> entriesBetween(String start, String end) async {
    final db = await database;
    final rows = await db.query(
      'workout_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date ASC',
    );
    return rows.map(WorkoutEntry.fromMap).toList();
  }

  // ---- Custom routines (v2) ----

  Future<int> insertRoutine(CustomRoutine routine) async {
    final db = await database;
    return db.transaction((txn) async {
      final routineId = await txn.insert('custom_routines', {
        'name': routine.name,
        'created_at': routine.createdAt,
      });
      for (final exercise in routine.exercises) {
        final map = exercise.toMap()
          ..remove('id')
          ..['routine_id'] = routineId;
        await txn.insert('custom_routine_exercises', map);
      }
      return routineId;
    });
  }

  Future<void> updateRoutine(CustomRoutine routine) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'custom_routines',
        {'name': routine.name},
        where: 'id = ?',
        whereArgs: [routine.id],
      );
      await txn.delete(
        'custom_routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routine.id],
      );
      for (final exercise in routine.exercises) {
        final map = exercise.toMap()
          ..remove('id')
          ..['routine_id'] = routine.id;
        await txn.insert('custom_routine_exercises', map);
      }
    });
  }

  Future<void> deleteRoutine(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'custom_routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [id],
      );
      await txn.delete('custom_routines', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<CustomRoutine>> allRoutines() async {
    final db = await database;
    final routineRows = await db.query('custom_routines', orderBy: 'id DESC');
    final routines = <CustomRoutine>[];
    for (final row in routineRows) {
      final id = row['id'] as int;
      final exerciseRows = await db.query(
        'custom_routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [id],
        orderBy: 'position ASC',
      );
      routines.add(
        CustomRoutine(
          id: id,
          name: row['name'] as String,
          createdAt: row['created_at'] as String,
          exercises: exerciseRows.map(CustomRoutineExercise.fromMap).toList(),
        ),
      );
    }
    return routines;
  }

  // ---- Body measurements (v2) ----

  Future<int> insertMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    final map = measurement.toMap()..remove('id');
    return db.insert('body_measurements', map);
  }

  Future<int> deleteMeasurement(int id) async {
    final db = await database;
    return db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BodyMeasurement>> allMeasurements() async {
    final db = await database;
    final rows = await db.query('body_measurements', orderBy: 'date DESC, id DESC');
    return rows.map(BodyMeasurement.fromMap).toList();
  }

  // ---- Custom programs (v3) ----

  Future<int> insertProgram(CustomProgram program) async {
    final db = await database;
    return db.transaction((txn) async {
      final programId = await txn.insert('custom_programs', {
        'name': program.name,
        'created_at': program.createdAt,
      });
      for (final day in program.days) {
        final dayId = await txn.insert('custom_program_days', {
          'program_id': programId,
          'name': day.name,
          'position': day.position,
        });
        for (final exercise in day.exercises) {
          final map = exercise.toMap()
            ..remove('id')
            ..['day_id'] = dayId;
          await txn.insert('custom_program_exercises', map);
        }
      }
      return programId;
    });
  }

  Future<void> updateProgram(CustomProgram program) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'custom_programs',
        {'name': program.name},
        where: 'id = ?',
        whereArgs: [program.id],
      );
      final oldDayRows = await txn.query(
        'custom_program_days',
        where: 'program_id = ?',
        whereArgs: [program.id],
      );
      for (final row in oldDayRows) {
        await txn.delete(
          'custom_program_exercises',
          where: 'day_id = ?',
          whereArgs: [row['id']],
        );
      }
      await txn.delete(
        'custom_program_days',
        where: 'program_id = ?',
        whereArgs: [program.id],
      );
      for (final day in program.days) {
        final dayId = await txn.insert('custom_program_days', {
          'program_id': program.id,
          'name': day.name,
          'position': day.position,
        });
        for (final exercise in day.exercises) {
          final map = exercise.toMap()
            ..remove('id')
            ..['day_id'] = dayId;
          await txn.insert('custom_program_exercises', map);
        }
      }
    });
  }

  Future<void> deleteProgram(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      final dayRows = await txn.query(
        'custom_program_days',
        where: 'program_id = ?',
        whereArgs: [id],
      );
      for (final row in dayRows) {
        await txn.delete(
          'custom_program_exercises',
          where: 'day_id = ?',
          whereArgs: [row['id']],
        );
      }
      await txn.delete('custom_program_days', where: 'program_id = ?', whereArgs: [id]);
      await txn.delete('custom_programs', where: 'id = ?', whereArgs: [id]);
      await txn.delete('program_progress', where: 'program_key = ?', whereArgs: ['custom:$id']);
    });
  }

  Future<List<CustomProgram>> allPrograms() async {
    final db = await database;
    final programRows = await db.query('custom_programs', orderBy: 'id DESC');
    final programs = <CustomProgram>[];
    for (final row in programRows) {
      final id = row['id'] as int;
      final dayRows = await db.query(
        'custom_program_days',
        where: 'program_id = ?',
        whereArgs: [id],
        orderBy: 'position ASC',
      );
      final days = <CustomProgramDay>[];
      for (final dayRow in dayRows) {
        final dayId = dayRow['id'] as int;
        final exerciseRows = await db.query(
          'custom_program_exercises',
          where: 'day_id = ?',
          whereArgs: [dayId],
          orderBy: 'position ASC',
        );
        days.add(
          CustomProgramDay(
            id: dayId,
            programId: id,
            name: dayRow['name'] as String,
            position: dayRow['position'] as int,
            exercises: exerciseRows.map(CustomProgramExercise.fromMap).toList(),
          ),
        );
      }
      programs.add(
        CustomProgram(
          id: id,
          name: row['name'] as String,
          createdAt: row['created_at'] as String,
          days: days,
        ),
      );
    }
    return programs;
  }

  // ---- Program progress (v3) ----

  /// Returns the next-day index for [programKey], or 0 if never tracked.
  /// If 7 or more days have elapsed since the last completed workout for
  /// this program, the sequence resets back to day 0 (Day 1).
  Future<int> nextDayIndex(String programKey) async {
    final db = await database;
    final rows = await db.query(
      'program_progress',
      where: 'program_key = ?',
      whereArgs: [programKey],
    );
    if (rows.isEmpty) return 0;
    final lastCompletedStr = rows.first['last_completed_date'] as String?;
    if (lastCompletedStr != null) {
      final lastCompleted = DateTime.tryParse(lastCompletedStr);
      if (lastCompleted != null) {
        final today = DateTime.now();
        final daysSince = DateTime(today.year, today.month, today.day)
            .difference(DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day))
            .inDays;
        if (daysSince >= 7) return 0;
      }
    }
    return rows.first['next_day_index'] as int;
  }

  Future<void> setNextDayIndex(String programKey, int nextDayIndex, String completedDate) async {
    final db = await database;
    await db.insert(
      'program_progress',
      {
        'program_key': programKey,
        'next_day_index': nextDayIndex,
        'last_completed_date': completedDate,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---- Planned workouts / calendar assignment (v3) ----

  Future<Map<String, Map<String, Object?>>> allPlannedWorkouts() async {
    final db = await database;
    final rows = await db.query('planned_workouts');
    return {for (final row in rows) row['date'] as String: row};
  }

  Future<void> setPlannedWorkout(
    String date,
    String programKey,
    int dayIndex,
    String dayName,
  ) async {
    final db = await database;
    await db.insert(
      'planned_workouts',
      {
        'date': date,
        'program_key': programKey,
        'day_index': dayIndex,
        'day_name': dayName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearPlannedWorkout(String date) async {
    final db = await database;
    await db.delete('planned_workouts', where: 'date = ?', whereArgs: [date]);
  }

  // ---- Achievements unlock dates (v4) ----

  /// All unlocked achievement ids mapped to their first-unlocked timestamp.
  Future<Map<String, String>> allUnlockedAchievements() async {
    final db = await database;
    final rows = await db.query('achievements_unlocked');
    return {
      for (final row in rows) row['achievement_id'] as String: row['unlocked_at'] as String,
    };
  }

  /// Records [achievementId] as unlocked at [unlockedAt] if not already
  /// recorded (keeps the original first-unlock date on repeated calls).
  Future<void> markAchievementUnlocked(String achievementId, String unlockedAt) async {
    final db = await database;
    await db.insert(
      'achievements_unlocked',
      {'achievement_id': achievementId, 'unlocked_at': unlockedAt},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ---- Workout sessions (v4) ----

  Future<int> insertWorkoutSession(WorkoutSession session) async {
    final db = await database;
    final map = session.toMap()..remove('id');
    return db.insert('workout_sessions', map);
  }

  Future<List<WorkoutSession>> allWorkoutSessions() async {
    final db = await database;
    final rows = await db.query('workout_sessions', orderBy: 'date DESC, id DESC');
    return rows.map(WorkoutSession.fromMap).toList();
  }

  /// Sessions with date within [start, end] (inclusive, yyyy-MM-dd strings).
  Future<List<WorkoutSession>> workoutSessionsBetween(String start, String end) async {
    final db = await database;
    final rows = await db.query(
      'workout_sessions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date ASC',
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  // ---- Factory reset ----

  /// Deletes all user data (workout history, custom routines/programs,
  /// body measurements, program progress and calendar assignments) while
  /// keeping the table schemas intact. Used by the "Reset all data" action
  /// in Settings.
  Future<void> resetAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('workout_entries');
      await txn.delete('custom_routine_exercises');
      await txn.delete('custom_routines');
      await txn.delete('body_measurements');
      await txn.delete('custom_program_exercises');
      await txn.delete('custom_program_days');
      await txn.delete('custom_programs');
      await txn.delete('program_progress');
      await txn.delete('planned_workouts');
      await txn.delete('achievements_unlocked');
      await txn.delete('workout_sessions');
      await txn.delete('user_profile');
    });
  }
}
