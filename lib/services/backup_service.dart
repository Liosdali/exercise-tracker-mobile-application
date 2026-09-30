import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database_helper.dart';
import '../models/user_profile.dart';
import 'user_account_service.dart';

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
/// backend/account. Only the active workspace's data is exported.
///
/// Tables are listed parent-before-child so import can safely re-insert
/// rows (preserving original ids, since some tables reference others by
/// id) while foreign-key enforcement remains enabled.
class BackupService {
  static const int _formatVersion = 2;

  static const List<String> _tablesInOrder = [
    'custom_routines',
    'custom_routine_exercises',
    'body_measurements',
    'custom_programs',
    'custom_program_days',
    'custom_program_exercises',
    'workout_sessions',
    'workout_entries',
    'program_progress',
    'planned_workouts',
    'achievements_unlocked',
    'user_profile',
    'account_preferences',
  ];

  /// Reads every table into a single JSON document and shares it via the
  /// OS share sheet (Files/Drive/WhatsApp/e-mail/etc. can all save it).
  static Future<void> exportAndShare() async {
    final jsonString = await buildExportJson();

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final file = File('${dir.path}/atlas_workout_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'Atlas Workout backup ($timestamp)',
      ),
    );
  }

  static Future<String> buildExportJson() async {
    final db = await DatabaseHelper.instance.database;
    final tables = await db.transaction((txn) async {
      final result = <String, List<Map<String, Object?>>>{};
      for (final table in _tablesInOrder) {
        result[table] = (await txn.query(
          table,
        )).map((row) => Map<String, Object?>.from(row)).toList();
      }
      return result;
    });
    final document = {
      'app': 'atlas_workout',
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
      // Delete children before parents with foreign-key enforcement enabled.
      for (final table in _tablesInOrder.reversed) {
        await txn.delete(table);
      }
      // Insert parents before children, preserving original row ids.
      for (final table in _tablesInOrder) {
        final rows = tables[table];
        if (rows == null) continue;
        final columns = (await txn.rawQuery(
          'PRAGMA table_info($table)',
        )).map((c) => c['name'] as String).toSet();
        for (final row in rows) {
          final sanitized = Map<String, Object?>.from(row)
            ..removeWhere((key, _) => !columns.contains(key));
          if (table == 'user_profile') {
            UserProfile.fromMap(sanitized).validate();
            sanitized['id'] = 1;
          }
          if (table == 'body_measurements') {
            for (final key in [
              'weight_kg',
              'height_cm',
              'neck_cm',
              'hip_cm',
              'chest_cm',
              'waist_cm',
            ]) {
              final value = sanitized[key];
              if (value != null &&
                  (value is! num || !value.isFinite || value <= 0)) {
                throw const BackupFormatException(
                  'Measurements must be positive.',
                );
              }
            }
          }
          if (table == 'account_preferences') {
            final key = sanitized['key'];
            if (!UserAccountService.preferenceKeys.contains(key)) {
              throw const BackupFormatException('Unknown account preference.');
            }
            final value = jsonDecode(sanitized['value'] as String);
            if (key == 'weekly_goal') {
              if (value is! int || value < 1 || value > 7) {
                throw const BackupFormatException('Invalid weekly goal.');
              }
            } else if (key == 'active_program_key') {
              if (value != null &&
                  (value is! String ||
                      (!value.startsWith('builtin:') &&
                          !value.startsWith('custom:')))) {
                throw const BackupFormatException('Invalid active program.');
              }
            } else if (value is! bool) {
              throw const BackupFormatException('Invalid account preference.');
            }
          }
          await txn.insert(
            table,
            sanitized,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }
      final dangling = await txn.rawQuery('''
        SELECT date FROM planned_workouts WHERE program_key LIKE 'custom:%'
        AND NOT EXISTS(SELECT 1 FROM custom_programs WHERE id=CAST(substr(planned_workouts.program_key,8) AS INTEGER))
        UNION ALL
        SELECT program_key FROM program_progress WHERE program_key LIKE 'custom:%'
        AND NOT EXISTS(SELECT 1 FROM custom_programs WHERE id=CAST(substr(program_progress.program_key,8) AS INTEGER))
      ''');
      if (dangling.isNotEmpty) {
        throw const BackupFormatException(
          'Backup contains a missing custom program.',
        );
      }
      await txn.execute('''
        UPDATE planned_workouts SET day_sync_id=(
          SELECT sync_id FROM custom_program_days
          WHERE program_id=CAST(substr(planned_workouts.program_key,8) AS INTEGER)
            AND position=planned_workouts.day_index LIMIT 1)
        WHERE program_key LIKE 'custom:%'
      ''');
      final active = await txn.query(
        'account_preferences',
        where: 'key=?',
        whereArgs: ['active_program_key'],
      );
      if (active.isNotEmpty) {
        final key = jsonDecode(active.single['value'] as String);
        if (key is String &&
            key.startsWith('custom:') &&
            (await txn.query(
              'custom_programs',
              where: 'id=?',
              whereArgs: [key.substring(7)],
            )).isEmpty) {
          throw const BackupFormatException(
            'Backup active program does not exist.',
          );
        }
      }
    });
    DatabaseHelper.instance.notifyChanged();
  }

  static Map<String, List<Map<String, Object?>>> _parseTables(
    String jsonString,
  ) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const BackupFormatException('Invalid JSON file.');
    }
    if (decoded is! Map<String, dynamic> || decoded['tables'] is! Map) {
      throw const BackupFormatException(
        'This file is not a valid Atlas Workout backup.',
      );
    }
    if (decoded['app'] != 'atlas_workout' ||
        decoded['formatVersion'] is! int ||
        (decoded['formatVersion'] as int) < 1 ||
        (decoded['formatVersion'] as int) > _formatVersion) {
      throw const BackupFormatException('Unsupported backup format.');
    }
    final rawTables = decoded['tables'] as Map<String, dynamic>;
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in _tablesInOrder) {
      final rawRows = rawTables[table];
      if (rawRows == null) continue;
      if (rawRows is! List ||
          rawRows.any((row) => row is! Map<String, dynamic>)) {
        throw const BackupFormatException('Invalid backup rows.');
      }
      result[table] = rawRows
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => row.map((key, value) => MapEntry(key, value as Object?)),
          )
          .toList();
    }
    return result;
  }
}
