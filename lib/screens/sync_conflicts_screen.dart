import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/sync_conflict.dart';
import '../services/user_account_service.dart';
import '../utils/conflict_summary.dart';

/// Lets the user choose between the device's and the server's version of a
/// record.
///
/// The card describes each conflict in the app's own vocabulary. The raw
/// payloads are still reachable, two expanders down, because they are the
/// only thing worth pasting into a bug report — but they are no longer the
/// first thing a person meets when their data is at stake.
class SyncConflictsScreen extends StatefulWidget {
  const SyncConflictsScreen({super.key});

  @override
  State<SyncConflictsScreen> createState() => _SyncConflictsScreenState();
}

class _SyncConflictsScreenState extends State<SyncConflictsScreen> {
  late final UserAccountService _account;
  late Future<List<SyncConflict>> _conflicts;
  bool _busy = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _account = context.read<UserAccountService>();
    _conflicts = _account.conflicts();
  }

  Future<void> _resolve(SyncConflict conflict, bool local) async {
    setState(() {
      _busy = true;
      _hasError = false;
    });
    try {
      await _account.resolveConflict(conflict.entity, conflict.recordId, local);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _conflicts = _account.conflicts();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncConflictsTitle)),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_hasError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.syncConflictResolveError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<SyncConflict>>(
              future: _conflicts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(l10n.accountSyncError));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return Center(child: Text(l10n.syncNoConflicts));
                }
                // One card per group: resolveConflict rewrites every record
                // sharing a group key, so a card per row would hide what the
                // buttons actually do.
                final groups = groupConflicts(snapshot.data!);
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) => _ConflictCard(
                    group: groups[index],
                    busy: _busy,
                    onResolve: _resolve,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final ConflictGroup group;
  final bool busy;
  final void Function(SyncConflict conflict, bool local) onResolve;

  const _ConflictCard({
    required this.group,
    required this.busy,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final conflict = group.anchor;
    final summary = summarizeConflict(conflict);
    final origin = conflictOriginText(l10n, summary.origin);
    final deletes = summary.localDeleted || summary.remoteDeleted;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflictEntityLabel(l10n, conflict),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _Freshness(conflict: conflict),
            if (origin != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(origin, style: theme.textTheme.bodySmall),
              ),
            Text(conflictHeadline(l10n, summary)),
            if (summary.changes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Legend(),
              for (final change in summary.changes)
                _ChangeRow(entity: summary.entity, change: change),
            ],
            if (group.members.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.syncConflictGroupSummary(group.recordCount),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (deletes)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.syncConflictDeleteWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: busy ? null : () => onResolve(conflict, true),
                  child: Text(l10n.syncKeepLocal),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => onResolve(conflict, false),
                  child: Text(l10n.syncKeepRemote),
                ),
              ],
            ),
            _Details(group: group),
          ],
        ),
      ),
    );
  }
}

/// Which side was edited more recently — rendered only when that is a fact.
///
/// Nine of the ten synced entities keep no modification timestamp, so for
/// them this builds nothing at all rather than inferring a date from
/// `created_at`, which does not move when a record is edited.
class _Freshness extends StatelessWidget {
  final SyncConflict conflict;

  const _Freshness({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final side = newerSide(conflict);
    if (side == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final local = modifiedAt(conflict.entity, conflict.local);
    final remote = modifiedAt(conflict.entity, conflict.remote);
    if (local == null || remote == null) return const SizedBox.shrink();
    final format = DateFormat.yMMMd().add_jm();

    Widget line(String label, DateTime at, bool newer) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        newer
            ? '$label: ${format.format(at.toLocal())} (${l10n.syncConflictNewer})'
            : '$label: ${format.format(at.toLocal())}',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: newer ? FontWeight.bold : null,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(l10n.syncLocalVersion, local, side == ConflictSide.local),
          line(l10n.syncRemoteVersion, remote, side == ConflictSide.remote),
        ],
      ),
    );
  }
}

/// Names the direction of the arrow used in every change row.
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${l10n.syncLocalVersion}  →  ${l10n.syncRemoteVersion}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final String entity;
  final FieldChange change;

  const _ChangeRow({required this.entity, required this.change});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = conflictFieldLabel(l10n, entity, change.field);
    final collection = change.collection;
    final value = collection != null
        ? conflictCollectionText(l10n, entity, change.field, collection)
        : '${conflictValueText(l10n, entity, change.field, change.localValue)}'
              '  →  '
              '${conflictValueText(l10n, entity, change.field, change.remoteValue)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(value),
        ],
      ),
    );
  }
}

/// The structured detail view, with the raw payloads nested one level deeper.
class _Details extends StatelessWidget {
  final ConflictGroup group;

  const _Details({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = [group.anchor, ...group.members];
    return Theme(
      // Keep the expander from drawing dividers across the card.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          group.members.isEmpty
              ? l10n.syncConflictShowDetails
              : l10n.syncConflictDetailsWithCount(group.recordCount),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          for (final member in members) _MemberDetail(conflict: member),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              l10n.syncConflictRawData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              for (final member in members) _RawPayloads(conflict: member),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberDetail extends StatelessWidget {
  final SyncConflict conflict;

  const _MemberDetail({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = summarizeConflict(conflict);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conflictEntityLabel(l10n, conflict),
            style: theme.textTheme.labelLarge,
          ),
          Text(
            conflictHeadline(l10n, summary),
            style: theme.textTheme.bodySmall,
          ),
          for (final change in summary.changes)
            _ChangeRow(entity: summary.entity, change: change),
        ],
      ),
    );
  }
}

class _RawPayloads extends StatelessWidget {
  final SyncConflict conflict;

  const _RawPayloads({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String text(Map<String, dynamic>? payload) => payload == null
        ? l10n.syncConflictDeleted
        : const JsonEncoder.withIndent('  ').convert(payload);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.syncLocalVersion, style: Theme.of(context).textTheme.labelSmall),
        _Monospace(text: text(conflict.local)),
        const SizedBox(height: 8),
        Text(
          l10n.syncRemoteVersion,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        _Monospace(text: text(conflict.remote)),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Bounded height so one large program cannot produce a metre of card, and
/// still selectable so it can be copied into a bug report.
class _Monospace extends StatelessWidget {
  final String text;

  const _Monospace({required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
      ),
    );
  }
}
