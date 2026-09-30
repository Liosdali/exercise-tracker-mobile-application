import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// One record per independently editable entity. Programs/routines are bounded
/// aggregates; history remains separate sessions, entries and measurements.
class AccountStore {
  static const maxBatchOperations = 10000;
  static const keys = <String, String>{
    'custom_programs': 'id',
    'custom_routines': 'id',
    'workout_sessions': 'id',
    'workout_entries': 'id',
    'body_measurements': 'id',
    'user_profile': 'id',
    'account_preferences': 'key',
    'planned_workouts': 'date',
    'program_progress': 'program_key',
    'achievements_unlocked': 'achievement_id',
  };
  static const uuidSql =
      "(lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-a' || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))))";

  static Future<void> migrateV7(Database db) async {
    final profileColumns = await db.rawQuery('PRAGMA table_info(user_profile)');
    if (!profileColumns.any((row) => row['name'] == 'name')) {
      await db.execute(
        "ALTER TABLE user_profile ADD COLUMN name TEXT NOT NULL DEFAULT ''",
      );
    }
    final entryColumns = await db.rawQuery(
      'PRAGMA table_info(workout_entries)',
    );
    if (!entryColumns.any((row) => row['name'] == 'session_id')) {
      await db.execute(
        'ALTER TABLE workout_entries ADD COLUMN session_id INTEGER REFERENCES workout_sessions(id) ON DELETE CASCADE',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entries_session ON workout_entries(session_id)',
    );
    final planColumns = await db.rawQuery(
      'PRAGMA table_info(planned_workouts)',
    );
    if (!planColumns.any((row) => row['name'] == 'day_sync_id')) {
      await db.execute(
        'ALTER TABLE planned_workouts ADD COLUMN day_sync_id TEXT',
      );
    }
    await db.execute(
      'CREATE TABLE IF NOT EXISTS account_preferences (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS sync_control (id INTEGER PRIMARY KEY CHECK(id=1), applying INTEGER NOT NULL DEFAULT 0, cursor INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute('INSERT OR IGNORE INTO sync_control(id) VALUES(1)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_records (
        entity TEXT NOT NULL, local_key TEXT NOT NULL, record_id TEXT NOT NULL,
        revision INTEGER NOT NULL DEFAULT 0, base_payload TEXT,
        version INTEGER NOT NULL DEFAULT 1, acknowledged INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(entity, local_key), UNIQUE(entity, record_id))
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        operation_id TEXT PRIMARY KEY, payload TEXT NOT NULL)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_conflicts (
        entity TEXT NOT NULL, record_id TEXT NOT NULL, base_payload TEXT,
        local_payload TEXT, remote_payload TEXT, remote_revision INTEGER NOT NULL,
        local_version INTEGER NOT NULL DEFAULT 0,
        group_entity TEXT, group_record_id TEXT,
        resolving INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(entity, record_id))
    ''');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS import_receipts (source TEXT PRIMARY KEY, imported_at TEXT NOT NULL)',
    );

    for (final table in [
      'custom_program_days',
      'custom_program_exercises',
      'custom_routine_exercises',
    ]) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      if (!columns.any((row) => row['name'] == 'sync_id')) {
        await db.execute('ALTER TABLE $table ADD COLUMN sync_id TEXT');
      }
      await db.execute(
        'UPDATE $table SET sync_id = $uuidSql WHERE sync_id IS NULL',
      );
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS ${table}_uuid AFTER INSERT ON $table
        WHEN NEW.sync_id IS NULL BEGIN
          UPDATE $table SET sync_id = $uuidSql WHERE id = NEW.id;
        END
      ''');
    }

    for (final entry in keys.entries) {
      final table = entry.key;
      final key = entry.value;
      String identity(String alias) {
        if (table == 'user_profile') return "'profile'";
        if (table == 'program_progress') {
          return "CASE WHEN substr($alias.$key,1,7) = 'custom:' THEN 'custom:' || COALESCE((SELECT record_id FROM sync_records WHERE entity='custom_programs' AND local_key=substr($alias.$key,8)), substr($alias.$key,8)) ELSE $alias.$key END";
        }
        return key == 'id' ? uuidSql : 'CAST($alias.$key AS TEXT)';
      }

      await db.execute('''
        INSERT OR IGNORE INTO sync_records(entity,local_key,record_id)
        SELECT '$table', CAST(r.$key AS TEXT), ${identity('r')} FROM $table r
      ''');
      for (final action in ['INSERT', 'UPDATE', 'DELETE']) {
        final alias = action == 'DELETE' ? 'OLD' : 'NEW';
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS sync_${table}_${action.toLowerCase()}
          AFTER $action ON $table
          WHEN (SELECT applying FROM sync_control WHERE id=1)=0 BEGIN
            INSERT INTO sync_records(entity,local_key,record_id,deleted)
            VALUES('$table',CAST($alias.$key AS TEXT),${identity(alias)},${action == 'DELETE' ? 1 : 0})
            ON CONFLICT(entity,local_key) DO UPDATE SET
              version=version+1, deleted=${action == 'DELETE' ? 1 : 0};
          END
        ''');
      }
    }
    await db.execute('''
      UPDATE planned_workouts SET day_sync_id=(
        SELECT sync_id FROM custom_program_days
        WHERE program_id=CAST(substr(planned_workouts.program_key,8) AS INTEGER)
          AND position=planned_workouts.day_index LIMIT 1)
      WHERE program_key LIKE 'custom:%' AND day_sync_id IS NULL
    ''');
    const parents = {
      'custom_program_days': ['custom_programs', 'program_id'],
      'custom_routine_exercises': ['custom_routines', 'routine_id'],
      'custom_program_exercises': ['custom_programs', 'day_id'],
    };
    for (final child in parents.entries) {
      for (final action in ['INSERT', 'UPDATE', 'DELETE']) {
        final alias = action == 'DELETE' ? 'OLD' : 'NEW';
        final root = child.key == 'custom_program_exercises'
            ? '(SELECT program_id FROM custom_program_days WHERE id=$alias.day_id)'
            : '$alias.${child.value[1]}';
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS sync_${child.key}_${action.toLowerCase()}
          AFTER $action ON ${child.key}
          WHEN (SELECT applying FROM sync_control WHERE id=1)=0 BEGIN
            UPDATE sync_records SET version=version+1
            WHERE entity='${child.value[0]}' AND local_key=CAST($root AS TEXT);
          END
        ''');
      }
    }
    // These references predate foreign-key enforcement and use program keys.
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS cleanup_custom_program AFTER DELETE ON custom_programs BEGIN
        DELETE FROM planned_workouts WHERE program_key='custom:' || OLD.id;
        DELETE FROM program_progress WHERE program_key='custom:' || OLD.id;
        UPDATE account_preferences SET value='null'
          WHERE key='active_program_key' AND value='"custom:' || OLD.id || '"';
      END
    ''');
    for (final table in ['planned_workouts', 'program_progress']) {
      await db.execute('''
        DELETE FROM $table WHERE program_key LIKE 'custom:%'
          AND NOT EXISTS(SELECT 1 FROM custom_programs WHERE id=CAST(substr($table.program_key,8) AS INTEGER))
      ''');
    }
  }

  static Future<String> remoteProgramKey(
    DatabaseExecutor db,
    String key,
  ) async {
    if (!key.startsWith('custom:')) return key;
    final rows = await db.query(
      'sync_records',
      where: 'entity=? AND local_key=?',
      whereArgs: ['custom_programs', key.substring(7)],
    );
    if (rows.isEmpty) throw StateError('Missing custom program reference');
    return 'custom:${rows.first['record_id']}';
  }

  static Future<String> localProgramKey(DatabaseExecutor db, String key) async {
    if (!key.startsWith('custom:')) return key;
    final rows = await db.query(
      'sync_records',
      where: 'entity=? AND record_id=?',
      whereArgs: ['custom_programs', key.substring(7)],
    );
    if (rows.isEmpty) throw StateError('Program has not been downloaded');
    return 'custom:${rows.first['local_key']}';
  }

  static Future<Map<String, dynamic>?> snapshot(
    DatabaseExecutor db,
    Map<String, Object?> record,
  ) async {
    if (record['deleted'] == 1) return null;
    final entity = record['entity'] as String;
    final key = keys[entity]!;
    final rows = await db.query(
      entity,
      where: '$key=?',
      whereArgs: [record['local_key']],
    );
    if (rows.isEmpty) return null;
    final data = Map<String, dynamic>.from(rows.first)..remove('id');
    if (entity == 'custom_programs') {
      final days = await db.query(
        'custom_program_days',
        where: 'program_id=?',
        whereArgs: [record['local_key']],
        orderBy: 'position',
      );
      data['days'] = <Map<String, dynamic>>[];
      for (final day in days) {
        final exercises = await db.query(
          'custom_program_exercises',
          where: 'day_id=?',
          whereArgs: [day['id']],
          orderBy: 'position',
        );
        (data['days'] as List).add(
          Map<String, dynamic>.from(day)
            ..remove('id')
            ..remove('program_id')
            ..['exercises'] = exercises
                .map(
                  (e) => Map<String, dynamic>.from(e)
                    ..remove('id')
                    ..remove('day_id'),
                )
                .toList(),
        );
      }
    } else if (entity == 'custom_routines') {
      final exercises = await db.query(
        'custom_routine_exercises',
        where: 'routine_id=?',
        whereArgs: [record['local_key']],
        orderBy: 'position',
      );
      data['exercises'] = exercises
          .map(
            (e) => Map<String, dynamic>.from(e)
              ..remove('id')
              ..remove('routine_id'),
          )
          .toList();
    } else if (entity == 'workout_entries' && data['session_id'] != null) {
      final session = await db.query(
        'sync_records',
        where: 'entity=? AND local_key=?',
        whereArgs: ['workout_sessions', '${data['session_id']}'],
      );
      if (session.isEmpty) throw StateError('Missing workout session');
      data['session_id'] = session.first['record_id'];
    } else if (entity == 'account_preferences') {
      data['value'] = jsonDecode(data['value'] as String);
      if (data['key'] == 'active_program_key' && data['value'] != null) {
        data['value'] = await remoteProgramKey(db, data['value'] as String);
      }
    }
    if (data['program_key'] != null) {
      data['program_key'] = await remoteProgramKey(
        db,
        data['program_key'] as String,
      );
    }
    return data;
  }

  /// Frozen operations survive ambiguous network failures. New local changes
  /// advance `version` without modifying the already-submitted request.
  static Future<Map<String, dynamic>?> prepareBatch(Database db) =>
      db.transaction((txn) async {
        final saved = await txn.query('sync_outbox', limit: 1);
        if (saved.isNotEmpty) {
          return jsonDecode(saved.first['payload'] as String)
              as Map<String, dynamic>;
        }
        final rows = await txn.rawQuery('''
          SELECT r.* FROM sync_records r WHERE version>acknowledged
          AND NOT EXISTS(SELECT 1 FROM sync_conflicts c WHERE c.entity=r.entity
            AND c.record_id=r.record_id AND c.resolving=0)
          ORDER BY CASE r.entity WHEN 'custom_programs' THEN 0
            WHEN 'custom_routines' THEN 1 WHEN 'workout_sessions' THEN 2 ELSE 3 END
        ''');
        if (rows.isEmpty) return null;
        String identity(Map<String, Object?> row) =>
            '${row['entity']}/${row['record_id']}';
        final records = {for (final row in rows) identity(row): row};
        final links = {for (final key in records.keys) key: <String>{}};
        void link(String a, String b) {
          if (!links.containsKey(a) || !links.containsKey(b)) return;
          links[a]!.add(b);
          links[b]!.add(a);
        }

        final resolvingGroups = await txn.query(
          'sync_conflicts',
          where: 'resolving=1 AND group_entity IS NOT NULL',
        );
        final linkedEntries = await txn.rawQuery('''
      SELECT e.id,p.record_id AS parent_id FROM workout_entries e JOIN sync_records p
        ON p.entity='workout_sessions' AND p.local_key=CAST(e.session_id AS TEXT)
    ''');
        final parentByEntry = {
          for (final row in linkedEntries)
            '${row['id']}': row['parent_id'] as String,
        };
        for (final member in resolvingGroups) {
          link(
            identity(member),
            '${member['group_entity']}/${member['group_record_id']}',
          );
        }
        for (final row in rows) {
          final key = identity(row);
          if (row['base_payload'] != null) {
            final reference = parentReference(
              row['entity'] as String,
              jsonDecode(row['base_payload'] as String)
                  as Map<String, dynamic>?,
            );
            if (reference != null)
              link(key, '${reference['entity']}/${reference['record_id']}');
          }
          if (row['deleted'] == 0 && row['entity'] == 'workout_entries') {
            final parent = parentByEntry[row['local_key']];
            if (parent != null) link(key, 'workout_sessions/$parent');
          } else if (row['deleted'] == 0 &&
              [
                'planned_workouts',
                'program_progress',
                'account_preferences',
              ].contains(row['entity'])) {
            final reference = parentReference(
              row['entity'] as String,
              await snapshot(txn, row),
            );
            if (reference != null)
              link(key, '${reference['entity']}/${reference['record_id']}');
          }
        }
        final selected = <Map<String, Object?>>[];
        final visited = <String>{};
        for (final row in rows) {
          final key = identity(row);
          if (visited.contains(key)) continue;
          final component = <String>{};
          final queue = [key];
          while (queue.isNotEmpty) {
            final current = queue.removeLast();
            if (!component.add(current)) continue;
            queue.addAll(links[current]!);
          }
          if (component.length > maxBatchOperations) {
            throw StateError(
              'A related workout group exceeds the server operation limit',
            );
          }
          if (selected.isNotEmpty && selected.length + component.length > 200)
            break;
          visited.addAll(component);
          selected.addAll(component.map((id) => records[id]!));
          if (selected.length >= 200) break;
        }
        final order = keys.keys.toList();
        selected.sort(
          (a, b) => order
              .indexOf(a['entity'] as String)
              .compareTo(order.indexOf(b['entity'] as String)),
        );
        final operations = <Map<String, dynamic>>[];
        for (final row in selected) {
          operations.add({
            'entity': row['entity'],
            'record_id': row['record_id'],
            'expected_revision': row['revision'],
            'version': row['version'],
            'payload': await snapshot(txn, row),
          });
        }
        final batch = <String, dynamic>{
          'operation_id': const Uuid().v4(),
          'operations': operations,
        };
        await txn.insert('sync_outbox', {
          'operation_id': batch['operation_id'],
          'payload': jsonEncode(batch),
        });
        return batch;
      });

  static Future<void> saveConflict(
    DatabaseExecutor db,
    Map<String, Object?> record,
    Map<String, dynamic> remote, {
    String? groupEntity,
    String? groupRecordId,
    String? localPayloadJson,
  }) async {
    final previous = await db.query(
      'sync_conflicts',
      where: 'entity=? AND record_id=?',
      whereArgs: [record['entity'], record['record_id']],
    );
    final prior = previous.isEmpty ? null : previous.single;
    final local =
        localPayloadJson ??
        (prior != null && prior['local_version'] == record['version']
            ? prior['local_payload'] as String?
            : null) ??
        jsonEncode(await snapshot(db, record));
    var rootEntity =
        groupEntity ??
        remote['group_entity'] as String? ??
        prior?['group_entity'] as String?;
    var rootId =
        groupRecordId ??
        remote['group_record_id'] as String? ??
        prior?['group_record_id'] as String?;
    if (rootEntity == null &&
        (record['entity'] == 'workout_sessions' ||
            record['entity'] == 'custom_programs')) {
      rootEntity = record['entity'] as String;
      rootId = record['record_id'] as String;
    }
    if (rootEntity == null) {
      final candidate =
          jsonDecode(local) as Map<String, dynamic>? ??
          (remote['payload'] as Map?)?.cast<String, dynamic>() ??
          (record['base_payload'] == null
              ? null
              : jsonDecode(record['base_payload'] as String)
                    as Map<String, dynamic>?);
      final reference = parentReference(record['entity'] as String, candidate);
      if (reference != null) {
        final parents = await db.query(
          'sync_conflicts',
          where: 'entity=? AND record_id=?',
          whereArgs: [reference['entity'], reference['record_id']],
        );
        if (parents.isNotEmpty) {
          rootEntity =
              parents.single['group_entity'] as String? ?? reference['entity'];
          rootId =
              parents.single['group_record_id'] as String? ??
              reference['record_id'];
        }
      }
    }
    await db.insert('sync_conflicts', {
      'entity': record['entity'],
      'record_id': record['record_id'],
      'base_payload': record['base_payload'],
      'local_payload': local,
      'remote_payload': jsonEncode(remote['payload']),
      'remote_revision': remote['revision'],
      'local_version': record['version'],
      'resolving': 0,
      'group_entity': rootEntity,
      'group_record_id': rootId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Map<String, String>? parentReference(
    String entity,
    Map<String, dynamic>? payload,
  ) {
    if (payload == null) return null;
    if (entity == 'workout_entries' && payload['session_id'] is String) {
      return {
        'entity': 'workout_sessions',
        'record_id': payload['session_id'] as String,
      };
    }
    final key =
        entity == 'account_preferences' &&
            payload['key'] == 'active_program_key'
        ? payload['value']
        : payload['program_key'];
    if (key is String && key.startsWith('custom:')) {
      return {'entity': 'custom_programs', 'record_id': key.substring(7)};
    }
    return null;
  }

  static Future<List<Map<String, Object?>>> dependants(
    DatabaseExecutor db,
    String entity,
    String recordId,
  ) async {
    final childEntities = entity == 'workout_sessions'
        ? ['workout_entries']
        : entity == 'custom_programs'
        ? ['planned_workouts', 'program_progress', 'account_preferences']
        : <String>[];
    if (childEntities.isEmpty) return [];
    final rows = await db.query(
      'sync_records',
      where: 'entity IN (${List.filled(childEntities.length, '?').join(',')})',
      whereArgs: childEntities,
    );
    final matches = <Map<String, Object?>>[];
    for (final row in rows) {
      final conflicts = await db.query(
        'sync_conflicts',
        where: 'entity=? AND record_id=?',
        whereArgs: [row['entity'], row['record_id']],
      );
      final candidate =
          conflicts.isNotEmpty &&
              conflicts.single['local_version'] == row['version']
          ? jsonDecode(conflicts.single['local_payload'] as String)
                as Map<String, dynamic>?
          : await snapshot(db, row);
      final reference = parentReference(row['entity'] as String, candidate);
      if (reference?['entity'] == entity &&
          reference?['record_id'] == recordId) {
        matches.add(row);
      }
    }
    return matches;
  }

  /// A parent deletion is a conflict for the whole dependency group whenever
  /// applying its local cascade would destroy an unacknowledged child version.
  static Future<bool> preserveDependencyChange(
    DatabaseExecutor db,
    Map<String, Object?> parent,
    Map<String, dynamic> remote,
    Map<String, Map<String, dynamic>> page,
  ) async {
    final entity = parent['entity'] as String;
    final id = parent['record_id'] as String;
    final children = await dependants(db, entity, id);
    final invalidated = <Map<String, Object?>>[];
    for (final child in children) {
      if (remote['payload'] == null) {
        invalidated.add(child);
      } else if (entity == 'custom_programs' &&
          child['entity'] == 'planned_workouts') {
        final candidate = await snapshot(db, child);
        final dayId = candidate?['day_sync_id'];
        final days = (remote['payload'] as Map)['days'] as List? ?? [];
        if (dayId != null &&
            !days.any((dynamic day) => day['sync_id'] == dayId)) {
          invalidated.add(child);
        }
      }
    }
    if (invalidated.isEmpty) return false;
    var protected =
        (parent['version'] as int) > (parent['acknowledged'] as int);
    for (final row in [parent, ...invalidated]) {
      final conflicts = await db.query(
        'sync_conflicts',
        columns: ['record_id'],
        where: 'entity=? AND record_id=?',
        whereArgs: [row['entity'], row['record_id']],
      );
      if (conflicts.isNotEmpty ||
          (row['version'] as int) > (row['acknowledged'] as int)) {
        protected = true;
      }
    }
    if (!protected || children.isEmpty) return false;
    await saveConflict(
      db,
      parent,
      remote,
      groupEntity: entity,
      groupRecordId: id,
    );
    for (final child in children) {
      final existing = await db.query(
        'sync_conflicts',
        where: 'entity=? AND record_id=?',
        whereArgs: [child['entity'], child['record_id']],
      );
      final known = page['${child['entity']}/${child['record_id']}'];
      final removed =
          remote['payload'] == null ||
          invalidated.any(
            (c) =>
                c['entity'] == child['entity'] &&
                c['record_id'] == child['record_id'],
          );
      final childRemote =
          known ??
          {
            'entity': child['entity'], 'record_id': child['record_id'],
            'payload': removed
                ? child['entity'] == 'account_preferences'
                      ? {'key': child['record_id'], 'value': null}
                      : null
                : child['base_payload'] == null
                ? null
                : jsonDecode(child['base_payload'] as String),
            // The actual revision is refreshed by its page before sync completes.
            // A never-uploaded child has no remote row, therefore revision zero.
            'revision': existing.isNotEmpty
                ? existing.single['remote_revision']
                : child['revision'],
          };
      await saveConflict(
        db,
        child,
        childRemote,
        groupEntity: entity,
        groupRecordId: id,
      );
    }
    return true;
  }

  static Future<void> resolveConflict(
    Database db,
    String entity,
    String recordId,
    bool useLocal,
  ) => db.transaction((txn) async {
    final selected = await txn.query(
      'sync_conflicts',
      where: 'entity=? AND record_id=?',
      whereArgs: [entity, recordId],
    );
    if (selected.isEmpty) return;
    final anchor = selected.single;
    final groupEntity = anchor['group_entity'] as String?;
    final groupId = anchor['group_record_id'] as String?;
    final rows =
        (groupEntity == null
                ? selected
                : await txn.query(
                    'sync_conflicts',
                    where: 'group_entity=? AND group_record_id=?',
                    whereArgs: [groupEntity, groupId],
                  ))
            .toList();
    if (rows.length > maxBatchOperations) {
      throw StateError(
        'The related conflict group exceeds the server operation limit',
      );
    }
    final order = keys.keys.toList();
    rows.sort(
      (a, b) => order
          .indexOf(a['entity'] as String)
          .compareTo(order.indexOf(b['entity'] as String)),
    );
    if (!useLocal && groupEntity != null) {
      final parent = rows.where(
        (r) => r['entity'] == groupEntity && r['record_id'] == groupId,
      );
      if (parent.isNotEmpty &&
          jsonDecode(parent.first['remote_payload'] as String) == null) {
        // Children are deliberately cleared before the parent's FK cascade.
        rows.sort(
          (a, b) => order
              .indexOf(b['entity'] as String)
              .compareTo(order.indexOf(a['entity'] as String)),
        );
      }
    }
    await txn.update('sync_control', {'applying': 1}, where: 'id=1');
    for (final conflict in rows) {
      final records = await txn.query(
        'sync_records',
        where: 'entity=? AND record_id=?',
        whereArgs: [conflict['entity'], conflict['record_id']],
      );
      final row = records.single;
      var candidate =
          jsonDecode(
                conflict[useLocal ? 'local_payload' : 'remote_payload']
                    as String,
              )
              as Map<String, dynamic>?;
      if (useLocal && row['version'] != conflict['local_version']) {
        candidate = await snapshot(txn, row);
      }
      await applyRecord(
        txn,
        conflict['entity'] as String,
        conflict['record_id'] as String,
        candidate,
        revision: conflict['remote_revision'] as int,
        imported: true,
      );
      await txn.update(
        'sync_conflicts',
        {'resolving': 1, 'local_version': 1},
        where: 'entity=? AND record_id=?',
        whereArgs: [conflict['entity'], conflict['record_id']],
      );
    }
    await txn.update('sync_control', {'applying': 0}, where: 'id=1');
  });

  static Future<void> importSnapshot(
    DatabaseExecutor db,
    Map<String, dynamic> incoming,
  ) async {
    final entity = incoming['entity'] as String;
    final id = incoming['record_id'] as String;
    final payload = incoming['payload'] as Map<String, dynamic>?;
    final existing = await db.query(
      'sync_records',
      where: 'entity=? AND record_id=?',
      whereArgs: [entity, id],
    );
    final reference = parentReference(entity, payload);
    final parents = reference == null
        ? <Map<String, Object?>>[]
        : await db.query(
            'sync_conflicts',
            where: 'entity=? AND record_id=?',
            whereArgs: [reference['entity'], reference['record_id']],
          );
    if (existing.isEmpty && parents.isEmpty) {
      await applyRecord(db, entity, id, payload, imported: true);
      return;
    }
    if (existing.isEmpty) {
      // Reserve identity only: its guest parent is an unresolved candidate,
      // so inserting a relational row here could violate the local FK.
      await applyRecord(db, entity, id, null, imported: true);
    }
    final record = (await db.query(
      'sync_records',
      where: 'entity=? AND record_id=?',
      whereArgs: [entity, id],
    )).single;
    final isParent =
        entity == 'workout_sessions' || entity == 'custom_programs';
    final groupEntity = parents.isNotEmpty
        ? parents.single['group_entity'] as String? ?? reference!['entity']
        : isParent
        ? entity
        : null;
    final groupId = parents.isNotEmpty
        ? parents.single['group_record_id'] as String? ??
              reference!['record_id']
        : isParent
        ? id
        : null;
    await saveConflict(
      db,
      record,
      {'revision': record['revision'], 'payload': await snapshot(db, record)},
      groupEntity: groupEntity,
      groupRecordId: groupId,
      localPayloadJson: jsonEncode(payload),
    );
  }

  static Future<void> updateCurrentMeasurements(DatabaseExecutor db) async {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final values = <String, Object?>{};
    for (final field in ['weight_kg', 'height_cm']) {
      final rows = await db.query(
        'body_measurements',
        columns: [field],
        where: 'date<=? AND $field IS NOT NULL',
        whereArgs: [today],
        orderBy: 'date DESC, created_at DESC, id DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) values[field] = rows.first[field];
    }
    if (values.isEmpty) return;
    final profiles = await db.query('user_profile', where: 'id=1');
    if (profiles.isNotEmpty &&
        values.entries.every(
          (entry) => profiles.first[entry.key] == entry.value,
        )) {
      return;
    }
    values['updated_at'] = now.toUtc().toIso8601String();
    if (profiles.isEmpty) {
      await db.insert(
        'user_profile',
        values
          ..['id'] = 1
          ..['name'] = '',
      );
    } else {
      await db.update('user_profile', values, where: 'id=1');
    }
  }

  static Future<void> acknowledge(
    Database db,
    Map<String, dynamic> batch,
    List<Map<String, dynamic>> results,
  ) => db.transaction((txn) async {
    final operations = batch['operations'] as List;
    for (final result in results) {
      final rows = await txn.query(
        'sync_records',
        where: 'entity=? AND record_id=?',
        whereArgs: [result['entity'], result['record_id']],
      );
      if (rows.isEmpty) throw StateError('Missing operation identity');
      final row = rows.first;
      if (result['conflict'] == true) {
        await saveConflict(txn, row, result);
      } else {
        final op =
            operations.firstWhere(
                  (dynamic o) =>
                      o['entity'] == result['entity'] &&
                      o['record_id'] == result['record_id'],
                )
                as Map;
        await txn.update(
          'sync_records',
          {
            'revision': result['revision'],
            'base_payload': jsonEncode(result['payload']),
            'acknowledged': op['version'],
          },
          where: 'entity=? AND record_id=?',
          whereArgs: [result['entity'], result['record_id']],
        );
        await txn.update(
          'sync_conflicts',
          {
            'resolving': 2,
            'remote_revision': result['revision'],
            'remote_payload': jsonEncode(result['payload']),
          },
          where: 'entity=? AND record_id=? AND resolving=1',
          whereArgs: [result['entity'], result['record_id']],
        );
      }
    }
    if (results.length != operations.length) {
      throw StateError('Incomplete synchronization acknowledgement');
    }
    await txn.rawDelete('''
      DELETE FROM sync_conflicts WHERE resolving=2 AND (
        group_entity IS NULL OR NOT EXISTS(
          SELECT 1 FROM sync_conflicts pending
          WHERE pending.group_entity=sync_conflicts.group_entity
            AND pending.group_record_id=sync_conflicts.group_record_id
            AND pending.resolving<>2))
    ''');
    await txn.delete(
      'sync_outbox',
      where: 'operation_id=?',
      whereArgs: [batch['operation_id']],
    );
  });

  /// Called only inside a transaction with remote trigger suppression enabled.
  static Future<void> applyRecord(
    DatabaseExecutor db,
    String entity,
    String recordId,
    Map<String, dynamic>? payload, {
    int revision = 0,
    bool imported = false,
  }) async {
    if (!keys.containsKey(entity)) {
      throw FormatException('Unknown entity $entity');
    }
    final matches = await db.query(
      'sync_records',
      where: 'entity=? AND record_id=?',
      whereArgs: [entity, recordId],
    );
    final existing = matches.isEmpty ? null : matches.first;
    final key = keys[entity]!;
    Object? localKey = existing?['local_key'];
    if (payload == null) {
      if (localKey != null) {
        await db.delete(entity, where: '$key=?', whereArgs: [localKey]);
      }
      localKey ??= recordId;
    } else {
      final data = Map<String, dynamic>.from(payload)..remove('id');
      final days = data.remove('days') as List?;
      final exercises = data.remove('exercises') as List?;
      if (entity == 'user_profile') data['id'] = 1;
      if (data['program_key'] != null) {
        data['program_key'] = await localProgramKey(
          db,
          data['program_key'] as String,
        );
      }
      if (entity == 'planned_workouts' && data['day_sync_id'] != null) {
        final days = await db.query(
          'custom_program_days',
          where: 'sync_id=?',
          whereArgs: [data['day_sync_id']],
        );
        if (days.isNotEmpty) data['day_index'] = days.first['position'];
      }
      if (entity == 'account_preferences') {
        if (data['key'] == 'active_program_key' && data['value'] != null) {
          data['value'] = await localProgramKey(db, data['value'] as String);
        }
        data['value'] = jsonEncode(data['value']);
      }
      if (entity == 'workout_entries' && data['session_id'] != null) {
        final refs = await db.query(
          'sync_records',
          where: 'entity=? AND record_id=?',
          whereArgs: ['workout_sessions', data['session_id']],
        );
        if (refs.isEmpty) throw StateError('Session has not been downloaded');
        data['session_id'] = int.parse(refs.first['local_key'] as String);
      }
      if (existing != null &&
          int.tryParse('$localKey') != null &&
          key == 'id') {
        data['id'] = int.parse('$localKey');
      }
      if (key != 'id') localKey = data[key];
      final current = localKey == null
          ? <Map<String, Object?>>[]
          : await db.query(entity, where: '$key=?', whereArgs: [localKey]);
      if (current.isEmpty) {
        final id = await db.insert(entity, data);
        if (key == 'id') localKey = data['id'] ?? id;
      } else {
        await db.update(entity, data, where: '$key=?', whereArgs: [localKey]);
      }
      if (entity == 'custom_programs') {
        await db.delete(
          'custom_program_days',
          where: 'program_id=?',
          whereArgs: [localKey],
        );
        for (final raw in days ?? []) {
          final day = Map<String, dynamic>.from(raw as Map);
          final children = day.remove('exercises') as List? ?? [];
          final id = await db.insert(
            'custom_program_days',
            day..['program_id'] = localKey,
          );
          for (final rawChild in children) {
            await db.insert(
              'custom_program_exercises',
              Map<String, dynamic>.from(rawChild as Map)..['day_id'] = id,
            );
          }
        }
      } else if (entity == 'custom_routines') {
        await db.delete(
          'custom_routine_exercises',
          where: 'routine_id=?',
          whereArgs: [localKey],
        );
        for (final raw in exercises ?? []) {
          await db.insert(
            'custom_routine_exercises',
            Map<String, dynamic>.from(raw as Map)..['routine_id'] = localKey,
          );
        }
      }
    }
    await db.insert('sync_records', {
      'entity': entity,
      'local_key': '$localKey',
      'record_id': recordId,
      'revision': revision,
      'base_payload': imported ? null : jsonEncode(payload),
      'version': imported ? 1 : 0,
      'acknowledged': 0,
      'deleted': payload == null ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> applyPage(
    Database db,
    List<Map<String, dynamic>> changes,
    int cursor,
  ) => db.transaction((txn) async {
    await txn.update('sync_control', {'applying': 1}, where: 'id=1');
    final page = <String, Map<String, dynamic>>{};
    for (final remote in changes) {
      final key = '${remote['entity']}/${remote['record_id']}';
      if (page[key] == null ||
          (page[key]!['revision'] as int) < (remote['revision'] as int)) {
        page[key] = remote;
      }
    }
    final protectedParents = <String>{};
    for (final remote in page.values.where(
      (r) =>
          r['entity'] == 'workout_sessions' || r['entity'] == 'custom_programs',
    )) {
      final rows = await txn.query(
        'sync_records',
        where: 'entity=? AND record_id=?',
        whereArgs: [remote['entity'], remote['record_id']],
      );
      if (rows.isNotEmpty &&
          (remote['revision'] as int) > (rows.single['revision'] as int) &&
          await preserveDependencyChange(txn, rows.single, remote, page)) {
        protectedParents.add('${remote['entity']}/${remote['record_id']}');
      }
    }
    for (final remote in changes) {
      if (protectedParents.contains(
        '${remote['entity']}/${remote['record_id']}',
      )) {
        continue;
      }
      final rows = await txn.query(
        'sync_records',
        where: 'entity=? AND record_id=?',
        whereArgs: [remote['entity'], remote['record_id']],
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        if ((remote['revision'] as int) <= (row['revision'] as int)) continue;
      }
      final reference = parentReference(remote['entity'] as String,
          (remote['payload'] as Map?)?.cast<String,dynamic>());
      if (reference!=null) {
        final parents=await txn.query('sync_conflicts',where:'entity=? AND record_id=?',
            whereArgs:[reference['entity'],reference['record_id']]);
        if (parents.isNotEmpty) {
          if (rows.isEmpty) {
            // Reserve a candidate identity while its deleted local parent is
            // unresolved. Inserting the real row now would violate its FK.
            await applyRecord(txn,remote['entity'] as String,
                remote['record_id'] as String,null,imported:true);
          }
          final record=(await txn.query('sync_records',
              where:'entity=? AND record_id=?',
              whereArgs:[remote['entity'],remote['record_id']])).single;
          await saveConflict(txn,record,remote,
              groupEntity:parents.single['group_entity'] as String? ?? reference['entity'],
              groupRecordId:parents.single['group_record_id'] as String? ?? reference['record_id']);
          continue;
        }
      }
      if (rows.isNotEmpty) {
        final row = rows.first;
        final existingConflict = await txn.query(
          'sync_conflicts',
          where: 'entity=? AND record_id=?',
          whereArgs: [row['entity'], row['record_id']],
        );
        if ((row['version'] as int) > (row['acknowledged'] as int) ||
            existingConflict.isNotEmpty) {
          await saveConflict(txn, row, remote);
          continue;
        }
      }
      await applyRecord(
        txn,
        remote['entity'] as String,
        remote['record_id'] as String,
        (remote['payload'] as Map?)?.cast<String, dynamic>(),
        revision: remote['revision'] as int,
      );
    }
    await txn.update('sync_control', {
      'applying': 0,
      'cursor': cursor,
    }, where: 'id=1');
  });
}
