import 'dart:convert';

class SyncConflict {
  final String entity;
  final String recordId;
  final Map<String, dynamic>? base;
  final Map<String, dynamic>? local;
  final Map<String, dynamic>? remote;
  final int remoteRevision;
  final String? groupEntity;
  final String? groupRecordId;

  const SyncConflict({
    required this.entity,
    required this.recordId,
    required this.base,
    required this.local,
    required this.remote,
    required this.remoteRevision,
    this.groupEntity,
    this.groupRecordId,
  });

  factory SyncConflict.fromMap(Map<String, Object?> row) {
    Map<String, dynamic>? decode(Object? value) => value == null
        ? null
        : jsonDecode(value as String) as Map<String, dynamic>?;
    return SyncConflict(
      entity: row['entity'] as String,
      recordId: row['record_id'] as String,
      base: decode(row['base_payload']),
      local: decode(row['local_payload']),
      remote: decode(row['remote_payload']),
      remoteRevision: row['remote_revision'] as int,
      groupEntity: row['group_entity'] as String?,
      groupRecordId: row['group_record_id'] as String?,
    );
  }
}
