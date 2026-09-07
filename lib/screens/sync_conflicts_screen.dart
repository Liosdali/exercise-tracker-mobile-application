import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/sync_conflict.dart';
import '../services/user_account_service.dart';

class SyncConflictsScreen extends StatefulWidget {
  const SyncConflictsScreen({super.key});

  @override
  State<SyncConflictsScreen> createState() => _SyncConflictsScreenState();
}

class _SyncConflictsScreenState extends State<SyncConflictsScreen> {
  final _account = UserAccountService.instance;
  late Future<List<SyncConflict>> _conflicts;
  bool _busy = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
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
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final conflict = snapshot.data![index];
                    final entityName =
                        {
                          'custom_programs':
                              l10n.workoutsMyProgramsSectionTitle,
                          'custom_routines':
                              l10n.workoutsMyRoutinesSectionTitle,
                          'workout_sessions': l10n.profileCalendarLinkTitle,
                          'workout_entries': l10n.profileCalendarLinkTitle,
                          'body_measurements':
                              l10n.profileBodyMeasurementsTitle,
                          'user_profile': l10n.navProfile,
                          'account_preferences': l10n.settingsTitle,
                          'planned_workouts': l10n.calendarScreenTitle,
                          'program_progress': l10n.workoutsProgramsSectionTitle,
                          'achievements_unlocked':
                              l10n.profileAchievementsTitle,
                        }[conflict.entity] ??
                        l10n.syncConflictsTitle;
                    String version(Map<String, dynamic>? payload) =>
                        payload == null
                        ? l10n.syncConflictDeleted
                        : const JsonEncoder.withIndent('  ').convert(payload);
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entityName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (conflict.groupEntity != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(l10n.syncRelatedRecordsNotice),
                              ),
                            const SizedBox(height: 12),
                            Text(l10n.syncLocalVersion),
                            SelectableText(version(conflict.local)),
                            const Divider(),
                            Text(l10n.syncRemoteVersion),
                            SelectableText(version(conflict.remote)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              children: [
                                FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _resolve(conflict, true),
                                  child: Text(l10n.syncKeepLocal),
                                ),
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _resolve(conflict, false),
                                  child: Text(l10n.syncKeepRemote),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
