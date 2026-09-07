import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account_store.dart';
import '../data/database_helper.dart';
import '../models/sync_conflict.dart';
import '../models/user_profile.dart';
import 'sync_service.dart';

class UserAccountService extends ChangeNotifier with WidgetsBindingObserver {
  UserAccountService._();
  @visibleForTesting
  UserAccountService.forTesting(this._transportFactory);
  static final instance = UserAccountService._();
  AccountSyncTransport Function(String userId)? _transportFactory;
  final _helper = DatabaseHelper.instance;
  String? _userId;
  UserProfile? _profile;
  String? _syncError;
  int _pendingCount = 0;
  int _conflictCount = 0;
  String _pendingFingerprint = '';
  String _lastAttemptFingerprint = '';
  Future<void>? _syncing;
  Future<void> _lifecycle = Future.value();
  Timer? _poll;
  bool _observing = false;
  bool _switching = false;
  int _failures = 0;
  DateTime _retryAt = DateTime.fromMillisecondsSinceEpoch(0);

  String? get userId => _userId;
  UserProfile? get profile => _profile;
  bool get isSyncing => _syncing != null;
  int get pendingCount => _pendingCount;
  int get conflictCount => _conflictCount;
  String? get syncError => _syncError;

  Future<void> initialize(String? userId) {
    final next = _lifecycle.then((_) async {
      _switching = true;
      _poll?.cancel();
      try {
        try {
          await _syncing;
        } catch (_) {
          /* Error remains visible until switch. */
        }
        await _helper.switchAccount(userId);
        _userId = userId;
        _syncError = null;
        _failures = 0;
        _lastAttemptFingerprint = '';
        await _migrateGuestPreferences();
        await refresh();
        if (!_observing) {
          WidgetsBinding.instance.addObserver(this);
          _observing = true;
        }
        // A bounded periodic probe also recovers after connectivity returns
        // without adding a platform-specific connectivity dependency.
        _poll = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _automaticSync(),
        );
      } finally {
        _switching = false;
        notifyListeners();
      }
    });
    _lifecycle = next.catchError((Object _) {});
    return next;
  }

  static const preferenceKeys = [
    'weekly_goal',
    'sound_enabled',
    'vibration_enabled',
    'active_program_key',
    'has_completed_onboarding',
    'notifications_enabled',
    'streak_warnings_enabled',
    'daily_reminder_enabled',
    'has_seen_tutorial',
  ];

  Future<void> _migrateGuestPreferences([Database? guest]) async {
    if (_userId != null && guest == null) return;
    final db = guest ?? await _helper.database;
    final receipt = await db.query(
      'import_receipts',
      where: 'source=?',
      whereArgs: ['legacy_preferences'],
    );
    if (receipt.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await db.transaction((txn) async {
      for (final key in preferenceKeys) {
        var value = prefs.get(key);
        if (key == 'active_program_key' &&
            value is String &&
            value.startsWith('custom:')) {
          if ((await txn.query(
            'custom_programs',
            where: 'id=?',
            whereArgs: [value.substring(7)],
          )).isEmpty) {
            value = null;
          }
        }
        if (value != null) {
          await txn.insert('account_preferences', {
            'key': key,
            'value': jsonEncode(value),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      final profile = await txn.query('user_profile', where: 'id=1');
      if (profile.isEmpty) {
        await txn.insert('user_profile', {
          'id': 1,
          'name': prefs.getString('user_name') ?? '',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else if ((profile.first['name'] as String? ?? '').isEmpty &&
          prefs.getString('user_name') != null) {
        await txn.update('user_profile', {
          'name': prefs.getString('user_name'),
        }, where: 'id=1');
      }
      await txn.insert('import_receipts', {
        'source': 'legacy_preferences',
        'imported_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  Future<void> refresh() async {
    final generation = _helper.generation;
    final db = await _helper.database;
    final rows = await db.query('user_profile', where: 'id=1');
    final pending =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT count(*) FROM sync_records WHERE version>acknowledged',
          ),
        ) ??
        0;
    final conflicts =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT count(*) FROM sync_conflicts'),
        ) ??
        0;
    final versions = await db.rawQuery(
      'SELECT COALESCE(sum(version),0) AS total FROM sync_records WHERE version>acknowledged',
    );
    if (generation != _helper.generation) return;
    _profile = rows.isEmpty
        ? UserProfile(id: _userId)
        : UserProfile.fromMap(rows.first, userId: _userId);
    _pendingCount = pending;
    _conflictCount = conflicts;
    _pendingFingerprint = '$pending:${versions.single['total']}';
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
  }) async {
    if (_switching) throw StateError('Account is changing');
    final profile = UserProfile(
      id: _userId,
      name: name.trim(),
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      gender: gender,
    );
    profile.validate();
    final db = await _helper.database;
    final now = DateTime.now();
    final timestamp = now.toUtc().toIso8601String();
    await db.transaction((txn) async {
      final old = await txn.query('user_profile', where: 'id=1');
      final previous = old.isEmpty
          ? const UserProfile()
          : UserProfile.fromMap(old.first);
      final data = profile.toMap()
        ..['id'] = 1
        ..['updated_at'] = timestamp;
      if (old.isEmpty) {
        await txn.insert('user_profile', data);
      } else {
        await txn.update('user_profile', data, where: 'id=1');
      }
      if ((weightKg != null && weightKg != previous.weightKg) ||
          (heightCm != null && heightCm != previous.heightCm)) {
        await txn.insert('body_measurements', {
          'date': DateFormat('yyyy-MM-dd').format(now),
          'weight_kg': weightKg,
          'height_cm': heightCm,
          'gender': gender,
          'created_at': timestamp,
        });
      }
    });
    await refresh();
    _helper.notifyChanged();
    _automaticSync();
  }

  Future<bool> hasGuestData() async {
    if (_userId != null) {
      final account = await _helper.database;
      if ((await account.query(
        'import_receipts',
        where: 'source=?',
        whereArgs: ['guest_v7'],
      )).isNotEmpty) {
        return false;
      }
    }
    final db = await _helper.openGuestDatabase();
    try {
      await _migrateGuestPreferences(db);
      for (final table in AccountStore.keys.keys) {
        if (table == 'account_preferences') continue;
        final rows = await db.query(table, limit: 1);
        if (rows.isNotEmpty &&
            (table != 'user_profile' ||
                (rows.first['name'] as String? ?? '').isNotEmpty ||
                rows.first['weight_kg'] != null ||
                rows.first['age'] != null ||
                rows.first['height_cm'] != null ||
                rows.first['gender'] != null)) {
          return true;
        }
      }
      return false;
    } finally {
      if (_helper.userId != null) await db.close();
    }
  }

  Future<void> importGuestData() async {
    if (_userId == null || _switching) {
      throw StateError('Sign in before importing guest data');
    }
    final db = await _helper.database;
    final guest = await _helper.openGuestDatabase();
    try {
      await _migrateGuestPreferences(guest);
      final records = (await guest.query(
        'sync_records',
        where: 'deleted=0',
      )).toList();
      records.sort(
        (a, b) => AccountStore.keys.keys
            .toList()
            .indexOf(a['entity'] as String)
            .compareTo(
              AccountStore.keys.keys.toList().indexOf(b['entity'] as String),
            ),
      );
      final snapshots = <Map<String, dynamic>>[];
      for (final record in records) {
        snapshots.add({
          'entity': record['entity'],
          'record_id': record['record_id'],
          'payload': await AccountStore.snapshot(guest, record),
        });
      }
      await db.transaction((txn) async {
        if ((await txn.query(
          'import_receipts',
          where: 'source=?',
          whereArgs: ['guest_v7'],
        )).isNotEmpty) {
          return;
        }
        if ((await txn.query('sync_conflicts', limit: 1)).isNotEmpty) {
          throw StateError(
            'Resolve account conflicts before importing guest data',
          );
        }
        await txn.update('sync_control', {'applying': 1}, where: 'id=1');
        for (final snapshot in snapshots) {
          await AccountStore.importSnapshot(txn, snapshot);
        }
        await txn.update('sync_control', {'applying': 0}, where: 'id=1');
        await txn.insert('import_receipts', {
          'source': 'guest_v7',
          'imported_at': DateTime.now().toUtc().toIso8601String(),
        });
      });
    } finally {
      await guest.close();
    }
    await refresh();
    _helper.notifyChanged();
    _automaticSync();
  }

  Future<void> sync() {
    if (_syncing != null) return _syncing!;
    if (_userId == null) return refresh();
    if (_switching) return Future.error(StateError('Account is changing'));
    final future = _runSync();
    _syncing = future;
    notifyListeners();
    return future;
  }

  Future<void> _runSync() async {
    try {
      _lastAttemptFingerprint = _pendingFingerprint;
      final db = await _helper.database;
      final transport =
          _transportFactory?.call(_userId!) ??
          SupabaseAccountSyncTransport(Supabase.instance.client, _userId!);
      await SyncService(transport).synchronize(db);
      _syncError = null;
      _failures = 0;
      _retryAt = DateTime.now().add(const Duration(seconds: 60));
    } catch (error) {
      _syncError = error.toString();
      _failures++;
      _retryAt = DateTime.now().add(
        Duration(seconds: 15 * (1 << _failures.clamp(0, 6))),
      );
      rethrow;
    } finally {
      _syncing = null;
      await refresh();
      _helper.notifyChanged();
    }
  }

  Future<void> _automaticSync() async {
    if (_switching || isSyncing) return;
    try {
      await refresh();
      final newChanges =
          _pendingCount > 0 &&
          _pendingFingerprint != _lastAttemptFingerprint &&
          _failures == 0;
      if (_userId == null ||
          (!newChanges && DateTime.now().isBefore(_retryAt))) {
        return;
      }
      await sync();
    } catch (error) {
      _syncError = error.toString();
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retryAt = DateTime.fromMillisecondsSinceEpoch(0);
      _automaticSync();
    }
  }

  Future<List<SyncConflict>> conflicts() async {
    final db = await _helper.database;
    return db.transaction((txn) async {
      final changed = await txn.rawQuery('''
        SELECT r.* FROM sync_records r JOIN sync_conflicts c
        ON r.entity=c.entity AND r.record_id=c.record_id
        WHERE r.version<>c.local_version AND c.resolving=0
      ''');
      for (final row in changed) {
        await txn.update(
          'sync_conflicts',
          {
            'local_payload': jsonEncode(await AccountStore.snapshot(txn, row)),
            'local_version': row['version'],
          },
          where: 'entity=? AND record_id=?',
          whereArgs: [row['entity'], row['record_id']],
        );
      }
      return (await txn.query(
        'sync_conflicts',
      )).map(SyncConflict.fromMap).toList();
    });
  }

  Future<void> resolveConflict(
    String entity,
    String recordId,
    bool useLocal,
  ) async {
    if (_switching || isSyncing) {
      throw StateError('Wait for synchronization to finish');
    }
    final db = await _helper.database;
    await AccountStore.resolveConflict(db, entity, recordId, useLocal);
    await refresh();
    _helper.notifyChanged();
    await sync();
  }

  Future<void> clearDeletedAccount(String userId) async {
    if (_userId == userId) await initialize(null);
    await _helper.deleteAccountDatabase(userId);
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where(
      (k) => k.startsWith('account:$userId:'),
    )) {
      await prefs.remove(key);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
