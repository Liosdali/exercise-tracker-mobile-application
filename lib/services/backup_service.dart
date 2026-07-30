import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database_helper.dart';

/// Thrown when an imported backup file can't be parsed/restored (e.g. not a
/// valid backup produced by this app, or from an incompatible future format).
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);
  @override
  String toString() => message;
}

/// Exports/imports the user's entire local dataset as a single JSON file,
/// so they can back it up (and move it to a new device) without any
/// backend/account — this app is fully offline.
///
/// Tables are listed parent-before-child so import can safely re-insert
/// rows (preserving original ids, since some tables reference others by
/// id) even though this app doesn't currently enforce foreign keys.
class BackupService {
  static const int _formatVersion = 1;

  static const List<String> _tablesInOrder = [
    'workout_entries',
    'custom_routines',
    'custom_routine_exercises',
    'body_measurements',
    'custom_programs',
    'custom_program_days',
    'custom_program_exercises',
    'program_progress',
    'planned_workouts',
    'achievements_unlocked',
    'workout_sessions',
    'user_profile',
  ];

  /// Reads every table into a single JSON document and shares it via the
  /// OS share sheet (Files/Drive/WhatsApp/e-mail/etc. can all save it).
  static Future<void> exportAndShare() async {
    final jsonString = await _buildExportJson();

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/exercise_app_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'Exercise App backup ($timestamp)',
      ),
    );
  }

  static Future<String> _buildExportJson() async {
    final db = await DatabaseHelper.instance.database;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _tablesInOrder) {
      tables[table] = await db.query(table);
    }
    final document = {
      'app': 'exercise_app',
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  /// Opens a file picker for the user to choose a previously exported
  /// `.json` backup, and returns the parsed row-count summary so the UI can
  /// show a confirmation before actually overwriting local data with
  /// [restoreFromJson].
  static Future<PlatformFile?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// Validates [jsonString] as a backup document and returns how many rows
  /// per table it contains, without writing anything to the database yet.
  static Map<String, int> previewCounts(String jsonString) {
    final tables = _parseTables(jsonString);
    return {for (final entry in tables.entries) entry.key: entry.value.length};
  }

  /// Wipes all current local data and replaces it with the contents of
  /// [jsonString] (as produced by [exportAndShare]). This is destructive —
  /// callers must confirm with the user first.
  static Future<void> restoreFromJson(String jsonString) async {
    final tables = _parseTables(jsonString);
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      // Delete children before parents to keep things tidy even though FK
      // enforcement isn't turned on.
      for (final table in _tablesInOrder.reversed) {
        await txn.delete(table);
      }
      // Insert parents before children, preserving original row ids.
      for (final table in _tablesInOrder) {
        final rows = tables[table];
        if (rows == null) continue;
        for (final row in rows) {
          await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  static Map<String, List<Map<String, Object?>>> _parseTables(String jsonString) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const BackupFormatException('Invalid JSON file.');
    }
    if (decoded is! Map<String, dynamic> || decoded['tables'] is! Map) {
      throw const BackupFormatException('This file is not a valid Exercise App backup.');
    }
    final rawTables = decoded['tables'] as Map<String, dynamic>;
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in _tablesInOrder) {
      final rawRows = rawTables[table];
      if (rawRows is! List) continue;
      result[table] = rawRows
          .whereType<Map<String, dynamic>>()
          .map((row) => row.map((key, value) => MapEntry(key, value as Object?)))
          .toList();
    }
    return result;
  }
}
