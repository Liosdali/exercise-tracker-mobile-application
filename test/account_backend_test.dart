import 'dart:convert';
import 'dart:io';

import 'package:exercise_app/data/account_store.dart';
import 'package:exercise_app/data/database_helper.dart';
import 'package:exercise_app/models/body_measurement.dart';
import 'package:exercise_app/models/custom_program.dart';
import 'package:exercise_app/models/user_profile.dart';
import 'package:exercise_app/models/workout_entry.dart';
import 'package:exercise_app/models/workout_session.dart';
import 'package:exercise_app/providers/settings_provider.dart';
import 'package:exercise_app/services/backup_service.dart';
import 'package:exercise_app/services/sync_service.dart';
import 'package:exercise_app/services/user_account_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class MemoryTransport implements AccountSyncTransport {
  final records = <String, Map<String, dynamic>>{};
  final receipts = <String, List<Map<String, dynamic>>>{};
  int cursor = 0;
  int commits = 0;
  int pageSize = 200;
  bool loseResponse = false;
  int? failPullAfter;
  int pulls = 0;

  @override
  Future<List<Map<String, dynamic>>> push(Map<String, dynamic> batch) async {
    final id = batch['operation_id'] as String;
    if (receipts.containsKey(id)) return receipts[id]!;
    final results = <Map<String, dynamic>>[];
    for (final raw in batch['operations'] as List) {
      final op = raw as Map;
      final key = '${op['entity']}/${op['record_id']}';
      final old = records[key];
      final revision = old?['revision'] as int? ?? 0;
      if (revision != op['expected_revision']) {
        results.add({...old!, 'conflict': true});
      } else {
        final record = <String, dynamic>{
          'entity': op['entity'],
          'record_id': op['record_id'],
          'payload': op['payload'],
          'revision': revision + 1,
          'cursor': ++cursor,
        };
        records[key] = record;
        results.add({...record, 'conflict': false});
      }
    }
    commits++;
    receipts[id] = results;
    if (loseResponse) {
      loseResponse = false;
      throw const SocketException('Response lost after server commit');
    }
    return results;
  }

  @override
  Future<Map<String, dynamic>> pull(int after) async {
    if (failPullAfter != null && pulls++ >= failPullAfter!) {
      throw const SocketException('Interrupted page');
    }
    final changes =
        records.values.where((r) => (r['cursor'] as int) > after).toList()
          ..sort((a, b) => (a['cursor'] as int).compareTo(b['cursor'] as int));
    final page = changes.take(pageSize).toList();
    return {
      'changes': page,
      'cursor': page.isEmpty ? after : page.last['cursor'],
      'has_more': changes.length > page.length,
    };
  }
}

class DependencyTransport extends MemoryTransport {
  bool rejectMissingParents = false;

  @override
  Future<List<Map<String, dynamic>>> push(Map<String, dynamic> batch) async {
    final operationId = batch['operation_id'] as String;
    if (receipts.containsKey(operationId)) return receipts[operationId]!;
    final staged = records.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
    var nextCursor = cursor;
    final results = <Map<String, dynamic>>[];
    for (final raw in batch['operations'] as List) {
      final op = Map<String, dynamic>.from(raw as Map);
      final key = '${op['entity']}/${op['record_id']}';
      final old = staged[key];
      final revision = old?['revision'] as int? ?? 0;
      if (revision != op['expected_revision']) {
        results.add({
          ...old!,
          'conflict': jsonEncode(old['payload']) != jsonEncode(op['payload']),
        });
        continue;
      }
      final payload = op['payload'] as Map<String, dynamic>?;
      final reference = AccountStore.parentReference(
        op['entity'] as String,
        payload,
      );
      if (reference != null &&
          staged['${reference['entity']}/${reference['record_id']}']?['payload'] ==
              null) {
        if (rejectMissingParents) throw const SyncWriteRejected('23503');
        results.add({
          'entity': op['entity'],
          'record_id': op['record_id'],
          'revision': revision,
          'payload': old?['payload'],
          'conflict': true,
        });
        continue;
      }
      final accepted = <String, dynamic>{
        'entity': op['entity'],
        'record_id': op['record_id'],
        'payload': payload,
        'revision': revision + 1,
        'cursor': ++nextCursor,
      };
      staged[key] = accepted;
      results.add({...accepted, 'conflict': false});
      if (payload == null &&
          (op['entity'] == 'workout_sessions' ||
              op['entity'] == 'custom_programs')) {
        for (final child in staged.entries.toList()) {
          final parent = AccountStore.parentReference(
            child.value['entity'] as String,
            child.value['payload'] as Map<String, dynamic>?,
          );
          if (parent?['entity'] == op['entity'] &&
              parent?['record_id'] == op['record_id']) {
            staged[child.key] = {
              ...child.value,
              'payload': child.value['entity'] == 'account_preferences'
                  ? {'key': child.value['record_id'], 'value': null}
                  : null,
              'revision': (child.value['revision'] as int) + 1,
              'cursor': ++nextCursor,
            };
          }
        }
      }
    }
    records
      ..clear()
      ..addAll(staged);
    cursor = nextCursor;
    commits++;
    receipts[operationId] = results;
    if (loseResponse) {
      loseResponse = false;
      throw const SocketException('Response lost after server commit');
    }
    return results;
  }

  Future<void> deleteParent(String entity, String id) async {
    final current = records['$entity/$id']!;
    await push({
      'operation_id': const Uuid().v4(),
      'operations': [
        {
          'entity': entity,
          'record_id': id,
          'expected_revision': current['revision'],
          'version': 1,
          'payload': null,
        },
      ],
    });
  }
}

class RevisionCheckedTransport extends DependencyTransport {
  @override
  Future<List<Map<String, dynamic>>> push(Map<String, dynamic> batch) async {
    final operationId = batch['operation_id'] as String;
    if (receipts.containsKey(operationId)) return receipts[operationId]!;
    final operations = (batch['operations'] as List).cast<Map>();
    for (final root in operations.where(
      (op) =>
          op['payload'] == null &&
          ['workout_sessions', 'custom_programs'].contains(op['entity']),
    )) {
      final rootRecord = records['${root['entity']}/${root['record_id']}'];
      var stale =
          rootRecord != null &&
          rootRecord['payload'] != null &&
          rootRecord['revision'] != root['expected_revision'];
      for (final child in records.values.where((r) => r['payload'] != null)) {
        final parent = AccountStore.parentReference(
          child['entity'] as String,
          child['payload'] as Map<String, dynamic>?,
        );
        if (parent?['entity'] != root['entity'] ||
            parent?['record_id'] != root['record_id'])
          continue;
        final writes = operations.where(
          (op) =>
              op['entity'] == child['entity'] &&
              op['record_id'] == child['record_id'],
        );
        if (writes.isEmpty ||
            writes.single['expected_revision'] != child['revision'])
          stale = true;
      }
      if (stale) {
        final results = operations.map((op) {
          final current = records['${op['entity']}/${op['record_id']}'];
          return <String, dynamic>{
            'entity': op['entity'],
            'record_id': op['record_id'],
            'revision': current?['revision'] ?? 0,
            'payload': current?['payload'],
            'conflict': true,
            'group_entity': root['entity'],
            'group_record_id': root['record_id'],
          };
        }).toList();
        receipts[operationId] = results;
        return results;
      }
    }
    return super.push(batch);
  }
}

WorkoutEntry entry({String name = 'Squat', String date = '2026-09-07'}) =>
    WorkoutEntry(
      date: date,
      exerciseId: 'squat',
      exerciseName: name,
      category: 'legs',
      sets: 3,
      reps: 8,
      weight: 60,
      createdAt: '2026-09-07T10:00:00Z',
    );

const session = WorkoutSession(
  date: '2026-09-07',
  durationMinutes: 30,
  calories: 180,
  exerciseCount: 1,
  totalSets: 3,
  totalVolume: 1440,
  title: 'Strength',
  createdAt: '2026-09-07T10:00:00Z',
);

CustomProgram program(String name) => CustomProgram(
  name: name,
  createdAt: '2026-09-07T10:00:00Z',
  days: [
    CustomProgramDay(
      name: 'Day 1',
      position: 0,
      exercises: [
        CustomProgramExercise(
          exerciseId: 'squat',
          exerciseName: 'Squat',
          category: 'legs',
          targetSets: 3,
          targetReps: 8,
          position: 0,
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper.instance;
  late Directory directory;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = Directory(
      p.join(Directory.current.path, '.dart_tool', 'account_backend_${const Uuid().v4()}'),
    );
    await directory.create(recursive: true);
    await databaseFactory.setDatabasesPath(directory.path);
    SharedPreferences.setMockInitialValues({});
  });
  setUp(() async {
    await helper.switchAccount(const Uuid().v4());
  });
  tearDownAll(() async {
    UserAccountService.instance.dispose();
    await helper.closeWorkspace();
    await directory.delete(recursive: true);
  });

  test(
    'stale parent deletion cannot erase a newer server entry and remote group choice restores it',
    () async {
      final remote = RevisionCheckedTransport();
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        final sessionId = await helper.insertCompletedWorkout(session, [
          entry(),
        ]);
        await account.sync();
        final child = remote.records.values.firstWhere(
          (r) => r['entity'] == 'workout_entries',
        );
        await remote.push({
          'operation_id': const Uuid().v4(),
          'operations': [
            {
              'entity': 'workout_entries',
              'record_id': child['record_id'],
              'expected_revision': 1,
              'version': 1,
              'payload': {
                ...child['payload'] as Map<String, dynamic>,
                'notes': 'Device B newer edit',
              },
            },
          ],
        });
        final db = await helper.database;
        await db.delete(
          'workout_sessions',
          where: 'id=?',
          whereArgs: [sessionId],
        );
        await account.sync();
        expect(
          remote.records.values.firstWhere(
            (r) => r['entity'] == 'workout_entries',
          )['payload']['notes'],
          'Device B newer edit',
        );
        expect(
          remote.records.values.firstWhere(
            (r) => r['entity'] == 'workout_sessions',
          )['payload'],
          isNotNull,
        );
        final conflicts = await account.conflicts();
        expect(conflicts, hasLength(2));
        expect(
          conflicts
              .firstWhere((c) => c.entity == 'workout_entries')
              .remote!['notes'],
          'Device B newer edit',
        );
        expect(await helper.allEntries(), isEmpty);
        await account.resolveConflict(
          conflicts.first.entity,
          conflicts.first.recordId,
          false,
        );
        expect(await account.conflicts(), isEmpty);
        expect((await helper.allEntries()).single.notes, 'Device B newer edit');
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'new unseen server child blocks parent deletion and downloads as a deferred group candidate',
    () async {
      final remote = RevisionCheckedTransport();
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        final sessionId = await helper.insertCompletedWorkout(session, [
          entry(),
        ]);
        await account.sync();
        final root = remote.records.values.firstWhere(
          (r) => r['entity'] == 'workout_sessions',
        );
        final newId = const Uuid().v4();
        await remote.push({
          'operation_id': const Uuid().v4(),
          'operations': [
            {
              'entity': 'workout_entries',
              'record_id': newId,
              'expected_revision': 0,
              'version': 1,
              'payload':
                  Map<String, dynamic>.from(
                      entry(name: 'New on device B').toMap(),
                    )
                    ..remove('id')
                    ..['session_id'] = root['record_id'],
            },
          ],
        });
        final db = await helper.database;
        await db.delete(
          'workout_sessions',
          where: 'id=?',
          whereArgs: [sessionId],
        );
        await account.sync();
        expect(
          remote.records.values.where((r) => r['payload'] != null),
          hasLength(3),
        );
        final conflicts = await account.conflicts();
        expect(conflicts, hasLength(3));
        final newChild = conflicts.singleWhere((c) => c.recordId == newId);
        expect(newChild.local, isNull);
        expect(newChild.remote!['exercise_name'], 'New on device B');
        expect(newChild.groupRecordId, root['record_id']);
        await account.resolveConflict(newChild.entity, newChild.recordId, true);
        expect(await account.conflicts(), isEmpty);
        expect(
          remote.records.values.where((r) => r['payload'] != null),
          isEmpty,
        );
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'remote session deletion retains edited and clean entry candidates as one resolvable group',
    () async {
      final remote = DependencyTransport()..pageSize = 1;
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        await helper.insertCompletedWorkout(session, [
          entry(),
          entry(name: 'Press'),
        ]);
        await account.sync();
        final entries = await helper.allEntries();
        await helper.updateEntry(
          entries.first.copyWith(notes: 'offline edit that must survive'),
        );
        final rootId =
            remote.records.values.firstWhere(
                  (r) => r['entity'] == 'workout_sessions',
                )['record_id']
                as String;
        await remote.deleteParent('workout_sessions', rootId);
        await account.sync();
        expect(await helper.allWorkoutSessions(), hasLength(1));
        expect(await helper.allEntries(), hasLength(2));
        final conflicts = await account.conflicts();
        expect(conflicts, hasLength(3));
        final edited = conflicts.singleWhere(
          (c) => c.local?['notes'] == 'offline edit that must survive',
        );
        expect(edited.groupEntity, 'workout_sessions');
        expect(conflicts.every((c) => c.groupRecordId == rootId), isTrue);
        remote.loseResponse = true;
        await expectLater(
          account.resolveConflict(edited.entity, edited.recordId, true),
          throwsA(isA<SocketException>()),
        );
        expect(await account.conflicts(), hasLength(3));
        await account.sync();
        expect(await account.conflicts(), isEmpty);
        expect(
          remote.records.values.where((r) => r['payload'] != null),
          hasLength(3),
        );
        expect(
          (await helper.allEntries()).first.notes,
          'offline edit that must survive',
        );
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'choosing remote for a dependency conflict deliberately deletes the whole group',
    () async {
      final remote = DependencyTransport();
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        await helper.insertCompletedWorkout(session, [entry()]);
        await account.sync();
        await helper.updateEntry(
          (await helper.allEntries()).single.copyWith(notes: 'local'),
        );
        final rootId =
            remote.records.values.firstWhere(
                  (r) => r['entity'] == 'workout_sessions',
                )['record_id']
                as String;
        await remote.deleteParent('workout_sessions', rootId);
        await account.sync();
        final child = (await account.conflicts()).firstWhere(
          (c) => c.entity == 'workout_entries',
        );
        await account.resolveConflict(child.entity, child.recordId, false);
        expect(await account.conflicts(), isEmpty);
        expect(await helper.allEntries(), isEmpty);
        expect(await helper.allWorkoutSessions(), isEmpty);
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'definitely rejected new entry write downloads deleted parent and becomes resolvable',
    () async {
      final remote = DependencyTransport()..rejectMissingParents = true;
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        final sessionId = await helper.insertWorkoutSession(session);
        await account.sync();
        await helper.insertEntry(
          entry(name: 'Offline new').copyWith(sessionId: sessionId),
        );
        final rootId = remote.records.values.single['record_id'] as String;
        await remote.deleteParent('workout_sessions', rootId);
        await expectLater(account.sync(), throwsA(isA<SyncWriteRejected>()));
        final db = await helper.database;
        expect(await db.query('sync_outbox'), isEmpty);
        expect((await helper.allEntries()).single.exerciseName, 'Offline new');
        expect(await account.conflicts(), hasLength(2));
        await account.sync();
        final child = (await account.conflicts()).firstWhere(
          (c) => c.entity == 'workout_entries',
        );
        await account.resolveConflict(child.entity, child.recordId, true);
        expect(await account.conflicts(), isEmpty);
        expect(
          remote.records.values.where((r) => r['payload'] != null),
          hasLength(2),
        );
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'custom program deletion preserves edited plan, progress and active preference until group resolution',
    () async {
      final remote = DependencyTransport()..pageSize = 1;
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        final programId = await helper.insertProgram(program('Local program'));
        await helper.setPlannedWorkout(
          '2026-09-20',
          'custom:$programId',
          0,
          'Day 1',
        );
        await helper.setNextDayIndex('custom:$programId', 1, '2026-09-07');
        final db = await helper.database;
        await db.insert('account_preferences', {
          'key': 'active_program_key',
          'value': jsonEncode('custom:$programId'),
        });
        await account.sync();
        await helper.setPlannedWorkout(
          '2026-09-20',
          'custom:$programId',
          0,
          'Offline plan name',
        );
        final rootId =
            remote.records.values.firstWhere(
                  (r) => r['entity'] == 'custom_programs',
                )['record_id']
                as String;
        await remote.deleteParent('custom_programs', rootId);
        await account.sync();
        expect(await helper.allPrograms(), hasLength(1));
        expect(
          (await helper.allPlannedWorkouts())['2026-09-20']!['day_name'],
          'Offline plan name',
        );
        final conflicts = await account.conflicts();
        expect(conflicts, hasLength(4));
        final plan = conflicts.firstWhere(
          (c) => c.entity == 'planned_workouts',
        );
        await account.resolveConflict(plan.entity, plan.recordId, true);
        expect(await account.conflicts(), isEmpty);
        expect(
          jsonDecode(
            (await db.query('account_preferences')).single['value'] as String,
          ),
          'custom:$programId',
        );
        expect(
          remote.records.values.where((r) => r['payload'] != null),
          hasLength(4),
        );
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'guest parent collision with a remote tombstone preserves uninsertable child candidates',
    () async {
      final db = await helper.database;
      final parentId = const Uuid().v4();
      final childId = const Uuid().v4();
      await AccountStore.applyPage(db, [
        {
          'entity': 'workout_sessions',
          'record_id': parentId,
          'revision': 2,
          'payload': null,
        },
      ], 1);
      final parentPayload = Map<String, dynamic>.from(session.toMap())
        ..remove('id');
      final childPayload =
          Map<String, dynamic>.from(entry(name: 'Guest child').toMap())
            ..remove('id')
            ..['session_id'] = parentId;
      await db.transaction((txn) async {
        await txn.update('sync_control', {'applying': 1}, where: 'id=1');
        await AccountStore.importSnapshot(txn, {
          'entity': 'workout_sessions',
          'record_id': parentId,
          'payload': parentPayload,
        });
        await AccountStore.importSnapshot(txn, {
          'entity': 'workout_entries',
          'record_id': childId,
          'payload': childPayload,
        });
        await txn.update('sync_control', {'applying': 0}, where: 'id=1');
      });
      expect(await helper.allEntries(), isEmpty);
      expect(await db.query('sync_conflicts'), hasLength(2));
      await AccountStore.resolveConflict(db, 'workout_entries', childId, true);
      expect((await helper.allEntries()).single.exerciseName, 'Guest child');
      expect(
        (await helper.allEntries()).single.sessionId,
        (await helper.allWorkoutSessions()).single.id,
      );
      final batch = (await AccountStore.prepareBatch(db))!;
      expect((batch['operations'] as List).map((dynamic o) => o['entity']), [
        'workout_sessions',
        'workout_entries',
      ]);
    },
  );

  test(
    'a session with more than 200 entries remains one bounded atomic batch',
    () async {
      await helper.insertCompletedWorkout(
        session,
        List.generate(250, (_) => entry()),
      );
      final batch = (await AccountStore.prepareBatch(await helper.database))!;
      expect(batch['operations'], hasLength(251));
      expect(
        (batch['operations'] as List).length,
        lessThanOrEqualTo(AccountStore.maxBatchOperations),
      );
    },
  );

  test(
    'profile serialization preserves nullable values and rejects invalid measurements',
    () {
      final profile = UserProfile.fromMap({
        'name': 'Alex',
        'age': 34,
        'weight_kg': 82,
        'height_cm': 180.5,
        'gender': null,
      }, userId: 'identity');
      expect(profile.id, 'identity');
      expect(profile.weightKg, 82.0);
      expect(UserProfile.fromMap(profile.toMap()).toMap(), profile.toMap());
      profile.validate();
      const UserProfile(age: 151).validate();
      expect(
        () => const UserProfile(weightKg: -1).validate(),
        throwsArgumentError,
      );

      expect(
        () => const UserProfile(heightCm: double.infinity).validate(),
        throwsArgumentError,
      );
      expect(() => const UserProfile(age: -1).validate(), throwsArgumentError);
    },
  );

  test(
    'interrupted dependency pages retain accepted group members until every conflict is resolved',
    () async {
      final remote = DependencyTransport()..pageSize = 1;
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        await helper.insertCompletedWorkout(session, [
          entry(),
          entry(name: 'Clean dependent'),
        ]);
        await account.sync();
        await helper.updateEntry(
          (await helper.allEntries()).first.copyWith(notes: 'keep'),
        );
        final rootId =
            remote.records.values.firstWhere(
                  (r) => r['entity'] == 'workout_sessions',
                )['record_id']
                as String;
        await remote.deleteParent('workout_sessions', rootId);
        remote
          ..pulls = 0
          ..failPullAfter = 1;
        await expectLater(account.sync(), throwsA(isA<SocketException>()));
        expect(await account.conflicts(), hasLength(3));
        remote.failPullAfter = null;
        final root = (await account.conflicts()).firstWhere(
          (c) => c.entity == 'workout_sessions',
        );
        await account.resolveConflict(root.entity, root.recordId, true);
        // The clean child's deletion revision was not downloaded before the
        // first decision, so only that child conflicts again. Keep all candidates.
        final db = await helper.database;
        final pending = await db.query('sync_conflicts');
        expect(pending, hasLength(3));
        expect(pending.any((row) => row['resolving'] == 2), isTrue);
        final child = pending.firstWhere((row) => row['resolving'] == 0);
        await account.resolveConflict(
          child['entity'] as String,
          child['record_id'] as String,
          true,
        );
        expect(await account.conflicts(), isEmpty);
        expect(await helper.allEntries(), hasLength(2));
        expect(
          remote.records.values.where((r) => r['payload'] != null),
          hasLength(3),
        );
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'removing a custom day remotely preserves a dirty plan and its prior program definition',
    () async {
      final remote = DependencyTransport();
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        final id = await helper.insertProgram(program('Before day deletion'));
        await helper.setPlannedWorkout('2026-09-21', 'custom:$id', 0, 'Day 1');
        await account.sync();
        await helper.setPlannedWorkout(
          '2026-09-21',
          'custom:$id',
          0,
          'Offline note',
        );
        final root = remote.records.values.firstWhere(
          (r) => r['entity'] == 'custom_programs',
        );
        root['payload'] = {
          ...root['payload'] as Map<String, dynamic>,
          'days': <dynamic>[],
        };
        root['revision'] = (root['revision'] as int) + 1;
        root['cursor'] = ++remote.cursor;
        final plan = remote.records.values.firstWhere(
          (r) => r['entity'] == 'planned_workouts',
        );
        plan['payload'] = null;
        plan['revision'] = (plan['revision'] as int) + 1;
        plan['cursor'] = ++remote.cursor;
        await account.sync();
        expect((await helper.allPrograms()).single.days, hasLength(1));
        final conflicts = await account.conflicts();
        expect(conflicts, hasLength(2));
        await account.resolveConflict(
          conflicts.first.entity,
          conflicts.first.recordId,
          true,
        );
        expect(await account.conflicts(), isEmpty);
        expect(
          (remote.records.values.firstWhere(
                (r) => r['entity'] == 'custom_programs',
              )['payload']['days']
              as List),
          hasLength(1),
        );
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'server-limit overflow preserves local data without persisting an unsendable operation',
    () async {
      await helper.insertCompletedWorkout(
        session,
        List.generate(AccountStore.maxBatchOperations, (_) => entry()),
      );
      final db = await helper.database;
      await expectLater(AccountStore.prepareBatch(db), throwsStateError);
      expect(await db.query('sync_outbox'), isEmpty);
      expect(
        await helper.allEntries(),
        hasLength(AccountStore.maxBatchOperations),
      );
    },
  );
  test(
    'fresh V7 has foreign keys, stable IDs and transactional dirty records',
    () async {
      final db = await helper.database;
      expect(await db.getVersion(), 7);
      expect(
        (await db.rawQuery('PRAGMA foreign_keys')).single.values.single,
        1,
      );
      final id = await helper.insertEntry(entry());
      final meta = (await db.query(
        'sync_records',
        where: 'entity=?',
        whereArgs: ['workout_entries'],
      )).single;
      expect(meta['local_key'], '$id');
      expect(Uuid.isValidUUID(fromString: meta['record_id'] as String), isTrue);
      await expectLater(
        db.transaction((txn) async {
          await txn.insert('workout_entries', entry().toMap()..remove('id'));
          throw StateError('rollback');
        }),
        throwsStateError,
      );
      expect(await db.query('workout_entries'), hasLength(1));
      expect(await db.query('sync_records'), hasLength(1));
    },
  );

  test(
    'V6 migration preserves legacy rows without guessing session relationships',
    () async {
      await helper.closeWorkspace();
      final id = const Uuid().v4();
      final path = p.join(directory.path, 'account_$id.db');
      // Produce the actual legacy schema using the existing additive creators,
      // then remove only V7 additions in this isolated fixture.
      await helper.switchAccount(id);
      final original = await helper.database;
      await helper.insertEntry(entry());
      final triggers = await original.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='trigger'",
      );
      for (final trigger in triggers) {
        await original.execute('DROP TRIGGER "${trigger['name']}"');
      }
      for (final table in [
        'sync_records',
        'sync_outbox',
        'sync_conflicts',
        'sync_control',
        'import_receipts',
        'account_preferences',
      ]) {
        await original.execute('DROP TABLE $table');
      }
      await original.execute('DROP INDEX idx_entries_session');
      await original.execute(
        'ALTER TABLE workout_entries DROP COLUMN session_id',
      );
      await original.execute('ALTER TABLE user_profile DROP COLUMN name');
      await original.setVersion(6);
      await helper.closeWorkspace();
      expect(await File(path).exists(), isTrue);
      await helper.switchAccount(id);
      final upgraded = await helper.database;
      expect(await upgraded.getVersion(), 7);
      expect((await helper.allEntries()).single.sessionId, isNull);
      expect(await upgraded.query('sync_records'), hasLength(1));
    },
  );

  test(
    'account A, B and guest are isolated and late workspace writes fail',
    () async {
      final accountA = helper.userId!;
      final boundA = helper.workspace();
      await boundA.insertEntry(entry(name: 'A'));
      await helper.switchAccount(const Uuid().v4());
      expect(await helper.allEntries(), isEmpty);
      await expectLater(
        boundA.insertEntry(entry(name: 'late')),
        throwsStateError,
      );
      await helper.insertEntry(entry(name: 'B'));
      await helper.switchAccount(null);
      expect(await helper.allEntries(), isEmpty);
      await helper.switchAccount(accountA);
      expect((await helper.allEntries()).single.exerciseName, 'A');
    },
  );

  test(
    'session and entries commit atomically and session deletion cascades',
    () async {
      final db = await helper.database;
      await expectLater(
        db.transaction((txn) async {
          final id = await txn.insert(
            'workout_sessions',
            session.toMap()..remove('id'),
          );
          await txn.insert('workout_entries', {
            'session_id': id,
            'date': '2026-09-07',
          });
        }),
        throwsA(isA<DatabaseException>()),
      );
      expect(await helper.allWorkoutSessions(), isEmpty);
      final id = await helper.insertCompletedWorkout(session, [entry()]);
      expect((await helper.allEntries()).single.sessionId, id);
      final batch = await AccountStore.prepareBatch(db);
      final ops = batch!['operations'] as List;
      expect(ops.map((dynamic op) => op['entity']), [
        'workout_sessions',
        'workout_entries',
      ]);
      expect(
        (ops.last as Map)['payload']['session_id'],
        (ops.first as Map)['record_id'],
      );
      await db.delete('workout_sessions', where: 'id=?', whereArgs: [id]);
      expect(await helper.allEntries(), isEmpty);
      expect(
        (await db.query('sync_records')).every((row) => row['deleted'] == 1),
        isTrue,
      );
    },
  );

  test(
    'retry after committed response loss reuses operation; later edits are not acknowledged',
    () async {
      final db = await helper.database;
      final id = await helper.insertEntry(entry());
      final remote = MemoryTransport()..loseResponse = true;
      await expectLater(
        SyncService(remote).synchronize(db),
        throwsA(isA<SocketException>()),
      );
      final frozen = (await db.query('sync_outbox')).single['operation_id'];
      await helper.updateEntry(entry(name: 'Edited').copyWith(id: id));
      final batch = await AccountStore.prepareBatch(db);
      expect(batch!['operation_id'], frozen);
      await SyncService(remote).synchronize(db);
      expect(remote.commits, 2);
      expect(remote.records, hasLength(1));
      expect(
        remote.records.values.single['payload']['exercise_name'],
        'Edited',
      );
      expect(await db.query('sync_outbox'), isEmpty);
      expect(
        (await db.query('sync_records')).single['version'],
        (await db.query('sync_records')).single['acknowledged'],
      );
    },
  );

  test(
    'new device restores full custom definition, active program and session references',
    () async {
      final remote = MemoryTransport();
      final source = await helper.database;
      final id = await helper.insertProgram(program('Strength'));
      await helper.setPlannedWorkout('2026-10-25', 'custom:$id', 0, 'Day 1');
      await helper.setNextDayIndex('custom:$id', 1, '2026-09-07');
      await source.insert('account_preferences', {
        'key': 'active_program_key',
        'value': jsonEncode('custom:$id'),
      });
      await helper.insertCompletedWorkout(session, [entry()]);
      await SyncService(remote).synchronize(source);
      final plan = remote.records.values.firstWhere(
        (r) => r['entity'] == 'planned_workouts',
      );
      expect(plan['payload']['program_key'], isNot('custom:$id'));
      await helper.switchAccount(const Uuid().v4());
      // Occupy integer 1 locally; remote UUID references must map to integer 2.
      await helper.insertProgram(program('Different local program'));
      final destination = await helper.database;
      await SyncService(remote).synchronize(destination);
      final restored = (await helper.allPrograms()).firstWhere(
        (p) => p.name == 'Strength',
      );
      expect(restored.id, isNot(id));
      expect(restored.days.single.exercises.single.exerciseId, 'squat');
      expect(
        (await helper.allPlannedWorkouts())['2026-10-25']!['program_key'],
        'custom:${restored.id}',
      );
      expect(
        (await helper.allEntries()).single.sessionId,
        (await helper.allWorkoutSessions()).single.id,
      );
      expect(
        jsonDecode(
          (await destination.query('account_preferences')).single['value']
              as String,
        ),
        'custom:${restored.id}',
      );
    },
  );

  test(
    'interrupted pagination persists each checkpoint and resumes without duplicates',
    () async {
      final remote = MemoryTransport()..pageSize = 1;
      await helper.insertEntry(entry(date: '2026-09-05'));
      await helper.insertEntry(entry(date: '2026-09-06'));
      await helper.insertEntry(entry());
      await SyncService(remote).synchronize(await helper.database);
      await helper.switchAccount(const Uuid().v4());
      final db = await helper.database;
      remote
        ..pulls = 0
        ..failPullAfter = 1;
      await expectLater(
        SyncService(remote).synchronize(db),
        throwsA(isA<SocketException>()),
      );
      expect(await helper.allEntries(), hasLength(1));
      expect((await db.query('sync_control')).single['cursor'], 1);
      remote.failPullAfter = null;
      await SyncService(remote).synchronize(db);
      expect(await helper.allEntries(), hasLength(3));
    },
  );

  test(
    'concurrent same-date plans retain both versions and deletion remains a tombstone',
    () async {
      final remote = MemoryTransport();
      final a = helper.userId!;
      await helper.setPlannedWorkout('2026-09-07', 'builtin:strength', 0, 'A');
      await SyncService(remote).synchronize(await helper.database);
      await helper.switchAccount(const Uuid().v4());
      await SyncService(remote).synchronize(await helper.database);
      await helper.setPlannedWorkout('2026-09-07', 'builtin:strength', 1, 'B');
      await SyncService(remote).synchronize(await helper.database);
      await helper.switchAccount(a);
      await helper.clearPlannedWorkout('2026-09-07');
      final db = await helper.database;
      await SyncService(remote).synchronize(db);
      final conflict = (await db.query('sync_conflicts')).single;
      expect(jsonDecode(conflict['local_payload'] as String), isNull);
      expect(jsonDecode(conflict['remote_payload'] as String)['day_name'], 'B');
      expect(jsonDecode(conflict['base_payload'] as String)['day_name'], 'A');
      expect(await helper.allPlannedWorkouts(), isEmpty);
      expect((await db.query('sync_records')).single['deleted'], 1);
    },
  );

  test(
    'deleting a custom program clears calendar, progress and active preference',
    () async {
      final db = await helper.database;
      final id = await helper.insertProgram(program('Delete'));
      await helper.setPlannedWorkout('2026-09-07', 'custom:$id', 0, 'Day');
      await helper.setNextDayIndex('custom:$id', 1, '2026-09-07');
      await db.insert('account_preferences', {
        'key': 'active_program_key',
        'value': jsonEncode('custom:$id'),
      });
      await helper.deleteProgram(id);
      expect(await db.query('custom_program_exercises'), isEmpty);
      expect(await helper.allPlannedWorkouts(), isEmpty);
      expect(await db.query('program_progress'), isEmpty);
      expect(
        jsonDecode(
          (await db.query('account_preferences')).single['value'] as String,
        ),
        isNull,
      );
    },
  );

  test(
    'backup excludes sync metadata, accepts format 1 and restore/reset remain tracked',
    () async {
      final db = await helper.database;
      await helper.insertCompletedWorkout(session, [entry()]);
      final exported = await BackupService.buildExportJson();
      expect(exported, isNot(contains('operation_id')));
      expect(exported, isNot(contains('sync_records')));
      final doc = jsonDecode(exported) as Map<String, dynamic>;
      doc['formatVersion'] = 1;
      await BackupService.restoreFromJson(jsonEncode(doc));
      expect(
        (await helper.allEntries()).single.sessionId,
        (await helper.allWorkoutSessions()).single.id,
      );
      expect(await AccountStore.prepareBatch(db), isNotNull);
      final invalid = jsonDecode(exported) as Map<String, dynamic>;
      invalid['tables']['workout_entries'][0]['session_id'] = 999999;
      await expectLater(
        BackupService.restoreFromJson(jsonEncode(invalid)),
        throwsA(isA<DatabaseException>()),
      );
      expect(await helper.allEntries(), hasLength(1));
      await helper.resetAllData();
      expect(await helper.allEntries(), isEmpty);
      expect(
        (await db.query('sync_records')).every((r) => r['deleted'] == 1),
        isTrue,
      );
      expect(
        () => BackupService.previewCounts(
          '{"app":"atlas_workout","formatVersion":99,"tables":{}}',
        ),
        throwsA(isA<BackupFormatException>()),
      );
    },
  );

  test(
    'backdated measurement does not replace latest applicable profile weight',
    () async {
      await helper.insertMeasurement(
        const BodyMeasurement(
          date: '2026-01-02',
          weightKg: 80,
          heightCm: 180,
          createdAt: '2026-01-02T10:00:00Z',
        ),
      );
      await helper.insertMeasurement(
        const BodyMeasurement(
          date: '2026-01-01',
          weightKg: 90,
          createdAt: '2026-09-07T10:00:00Z',
        ),
      );
      final db = await helper.database;
      expect((await db.query('user_profile')).single['weight_kg'], 80);
    },
  );

  test(
    'guest import is explicit, reference preserving and idempotent; preferences stay scoped',
    () async {
      final account = UserAccountService.instance;
      await account.initialize(null);
      final guestId = await helper.insertProgram(program('Guest strength'));
      await helper.setPlannedWorkout(
        '2026-09-08',
        'custom:$guestId',
        0,
        'Guest day',
      );
      final guestSettings = SettingsProvider();
      await guestSettings.load();
      await guestSettings.setWeeklyGoal(5);
      await guestSettings.completeOnboarding('Guest name');
      await guestSettings.setNotificationsEnabled(false);
      await guestSettings.setStreakWarningsEnabled(false);
      await guestSettings.setDailyReminderEnabled(false);
      final accountId = const Uuid().v4();
      await account.initialize(accountId);
      expect(await helper.allPrograms(), isEmpty);
      expect(await account.hasGuestData(), isTrue);
      final settings = SettingsProvider();
      await settings.load();
      expect(settings.weeklyGoal, 3);
      expect(settings.userName, isNull);
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.streakWarningsEnabled, isTrue);
      expect(settings.dailyReminderEnabled, isTrue);
      await account.importGuestData();
      await account.importGuestData();
      expect(await account.hasGuestData(), isFalse);
      expect(await helper.allPrograms(), hasLength(1));
      expect(
        (await helper.allPlannedWorkouts())['2026-09-08']!['program_key'],
        'custom:${(await helper.allPrograms()).single.id}',
      );
      await settings.reloadAccount();
      expect(settings.weeklyGoal, 5);
      expect(settings.userName, 'Guest name');
      expect(settings.hasCompletedOnboarding, isTrue);
      expect(settings.notificationsEnabled, isFalse);
      expect(settings.streakWarningsEnabled, isFalse);
      expect(settings.dailyReminderEnabled, isFalse);
      await expectLater(guestSettings.setWeeklyGoal(2), throwsStateError);
      guestSettings.dispose();
      settings.dispose();
      await account.initialize(null);
      expect(await helper.allPrograms(), hasLength(1));
    },
  );

  test(
    'profile edits create dated measurements and sync errors remain visible',
    () async {
      final remote = MemoryTransport();
      final account = UserAccountService.forTesting((_) => remote);
      try {
        await account.initialize(helper.userId);
        await account.updateProfile(
          name: 'Alex',
          age: 31,
          weightKg: 75,
          heightCm: 177,
        );
        await account.sync();
        expect(account.profile!.name, 'Alex');
        expect((await helper.allMeasurements()).single.weightKg, 75);
        expect(account.pendingCount, 0);
        await account.updateProfile(
          name: 'Alex edited',
          age: 31,
          weightKg: 75,
          heightCm: 177,
        );
        remote.loseResponse = true;
        await expectLater(account.sync(), throwsA(isA<SocketException>()));
        expect(account.syncError, contains('Response lost'));
        expect(account.pendingCount, greaterThan(0));
        await account.sync();
        expect(account.syncError, isNull);
        expect(await helper.allMeasurements(), hasLength(1));
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'conflict resolution persists both candidates until acceptance and may conflict again',
    () async {
      final remote = MemoryTransport();
      final account = UserAccountService.forTesting((_) => remote);
      final id = helper.userId!;
      try {
        await account.initialize(id);
        await helper.setPlannedWorkout(
          '2026-09-09',
          'builtin:strength',
          0,
          'Base',
        );
        await account.sync();
        final remoteRecord = remote.records.values.single;
        remoteRecord['payload'] = {
          ...remoteRecord['payload'] as Map<String, dynamic>,
          'day_name': 'Server',
        };
        remoteRecord['revision'] = 2;
        remoteRecord['cursor'] = ++remote.cursor;
        await helper.setPlannedWorkout(
          '2026-09-09',
          'builtin:strength',
          1,
          'Local',
        );
        await account.sync();
        expect(account.conflictCount, 1);
        final conflict = (await account.conflicts()).single;
        remote.loseResponse = true;
        await expectLater(
          account.resolveConflict(conflict.entity, conflict.recordId, true),
          throwsA(isA<SocketException>()),
        );
        expect(await account.conflicts(), hasLength(1));
        await account.sync();
        expect(await account.conflicts(), isEmpty);
        expect(remote.records.values.single['payload']['day_name'], 'Local');

        remoteRecord['payload'] = {
          ...remoteRecord['payload'] as Map<String, dynamic>,
          'day_name': 'Other',
        };
        // Retrieve the current record because push replaces map instances.
        final latest = remote.records.values.single;
        latest['payload'] = {
          ...latest['payload'] as Map<String, dynamic>,
          'day_name': 'Other',
        };
        latest['revision'] = (latest['revision'] as int) + 1;
        latest['cursor'] = ++remote.cursor;
        await helper.setPlannedWorkout(
          '2026-09-09',
          'builtin:strength',
          2,
          'Another local edit',
        );
        await account.sync();
        final second = (await account.conflicts()).single;
        latest['revision'] = (latest['revision'] as int) + 1;
        latest['payload'] = {
          ...latest['payload'] as Map<String, dynamic>,
          'day_name': 'Newest',
        };
        latest['cursor'] = ++remote.cursor;
        await account.resolveConflict(second.entity, second.recordId, true);
        expect(await account.conflicts(), hasLength(1));
        expect(
          (await account.conflicts()).single.remote!['day_name'],
          'Newest',
        );
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'bounded uploads keep each session and all its entries in one batch',
    () async {
      final db = await helper.database;
      for (var i = 0; i < 205; i++) {
        await helper.insertCompletedWorkout(session, [entry()]);
      }
      final batch = (await AccountStore.prepareBatch(db))!;
      final operations = batch['operations'] as List;
      expect(operations, hasLength(200));
      final sessionIds = operations
          .where((dynamic o) => o['entity'] == 'workout_sessions')
          .map((dynamic o) => o['record_id'])
          .toSet();
      final entrySessions = operations
          .where((dynamic o) => o['entity'] == 'workout_entries')
          .map((dynamic o) => o['payload']['session_id'])
          .toSet();
      expect(entrySessions, sessionIds);
      final remote = MemoryTransport();
      await SyncService(remote).synchronize(db);
      expect(remote.records, hasLength(410));
    },
  );

  test(
    'program edits preserve day identity used by calendar assignments',
    () async {
      final id = await helper.insertProgram(program('Original'));
      await helper.setPlannedWorkout('2026-09-10', 'custom:$id', 0, 'Day 1');
      final before = (await helper.allPrograms()).single;
      // The builder retains integer day IDs, even when it reconstructs models.
      await helper.updateProgram(
        before.copyWith(
          name: 'Renamed',
          days: [
            CustomProgramDay(
              id: before.days.single.id,
              name: 'Renamed day',
              position: 0,
              exercises: before.days.single.exercises,
            ),
          ],
        ),
      );
      final after = (await helper.allPrograms()).single;
      expect(after.days.single.syncId, before.days.single.syncId);
      final planned = (await helper.allPlannedWorkouts())['2026-09-10']!;
      expect(planned['day_sync_id'], after.days.single.syncId);
      expect(planned['day_name'], 'Renamed day');
      final exported = await BackupService.buildExportJson();
      await BackupService.restoreFromJson(exported);
      expect(
        (await helper.allPlannedWorkouts())['2026-09-10']!['day_sync_id'],
        (await helper.allPrograms()).single.days.single.syncId,
      );
    },
  );

  test(
    'confirmed deletion cleanup removes only the selected account workspace',
    () async {
      final account = UserAccountService.forTesting((_) => MemoryTransport());
      try {
        final a = helper.userId!;
        await account.initialize(a);
        await helper.insertEntry(entry(name: 'A'));
        final b = const Uuid().v4();
        await account.initialize(b);
        await helper.insertEntry(entry(name: 'B'));
        await account.clearDeletedAccount(a);
        expect(account.userId, b);
        expect((await helper.allEntries()).single.exerciseName, 'B');
        await account.initialize(a);
        expect(await helper.allEntries(), isEmpty);
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'deletion cleanup is idempotent before account service initialization',
    () async {
      final id = helper.userId!;
      await helper.insertEntry(entry());
      final account = UserAccountService.forTesting((_) => MemoryTransport());
      try {
        expect(account.userId, isNull);
        await account.clearDeletedAccount(id);
        await account.clearDeletedAccount(id);
        expect(
          await File(p.join(directory.path, 'account_$id.db')).exists(),
          isFalse,
        );
        await account.initialize(id);
        expect(await helper.allEntries(), isEmpty);
      } finally {
        account.dispose();
      }
    },
  );
}
