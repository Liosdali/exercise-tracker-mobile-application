import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account_store.dart';

abstract class AccountSyncTransport {
  Future<List<Map<String, dynamic>>> push(Map<String, dynamic> batch);
  Future<Map<String, dynamic>> pull(int cursor);
}

/// The server explicitly rolled back the request, unlike an ambiguous timeout
/// after commit. Only these failures may retire a frozen operation for rebasing.
class SyncWriteRejected implements Exception {
  final String code;
  const SyncWriteRejected(this.code);
  @override
  String toString() => 'The server rejected a synchronization write ($code)';
}

class SupabaseAccountSyncTransport implements AccountSyncTransport {
  final SupabaseClient client;
  final String userId;
  SupabaseAccountSyncTransport(this.client, this.userId);

  void _checkIdentity() {
    if (client.auth.currentUser?.id != userId) {
      throw StateError('Sign in again to synchronize this account');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> push(Map<String, dynamic> batch) async {
    _checkIdentity();
    late final dynamic result;
    try {
      result = await client.rpc(
        'apply_account_changes',
        params: {
          'p_operation_id': batch['operation_id'],
          'p_operations': batch['operations'],
        },
      );
    } on PostgrestException catch (error) {
      final code = error.code ?? '';
      if (code.startsWith('22') ||
          code.startsWith('23') ||
          code == 'P0001' ||
          code == '42501') {
        throw SyncWriteRejected(code);
      }
      rethrow;
    }
    _checkIdentity();
    return (result as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> pull(int cursor) async {
    _checkIdentity();
    final result = await client.rpc(
      'get_account_changes',
      params: {'p_after': cursor, 'p_limit': 200},
    );
    _checkIdentity();
    return Map<String, dynamic>.from(result as Map);
  }
}

class SyncService {
  final AccountSyncTransport transport;
  SyncService(this.transport);

  /// A handle belongs to exactly one workspace for the entire run. The
  /// coordinator waits for this run before closing/switching that workspace.
  Future<void> synchronize(Database db) async {
    // Upload first: a pre-existing frozen request may have committed remotely.
    // Replaying it before downloading avoids spurious self-conflicts.
    for (var batches = 0; batches < 8; batches++) {
      final batch = await AccountStore.prepareBatch(db);
      if (batch == null) break;
      late final List<Map<String, dynamic>> results;
      try {
        results = await transport.push(batch);
      } on SyncWriteRejected {
        await db.delete(
          'sync_outbox',
          where: 'operation_id=?',
          whereArgs: [batch['operation_id']],
        );
        // In particular, learn remote parent tombstones before retrying an
        // entry whose formerly valid parent was deleted on another device.
        await _download(db);
        rethrow;
      }
      await AccountStore.acknowledge(db, batch, results);
    }
    await _download(db);
  }

  Future<void> _download(Database db) async {
    for (var pages = 0; pages < 1000; pages++) {
      final state = (await db.query('sync_control', where: 'id=1')).single;
      final cursor = state['cursor'] as int;
      final page = await transport.pull(cursor);
      final changes = (page['changes'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final next = (page['cursor'] as num).toInt();
      if (next < cursor || (changes.isNotEmpty && next <= cursor)) {
        throw StateError('Invalid synchronization checkpoint');
      }
      await AccountStore.applyPage(db, changes, next);
      if (page['has_more'] != true) return;
    }
    throw StateError('Synchronization page limit reached; retry to continue');
  }
}
