import 'package:exercise_app/l10n/app_localizations.dart';
import 'package:exercise_app/models/sync_conflict.dart';
import 'package:exercise_app/utils/conflict_summary.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

SyncConflict conflict(
  String entity, {
  Map<String, dynamic>? base,
  Map<String, dynamic>? local,
  Map<String, dynamic>? remote,
  String recordId = 'r1',
  String? groupEntity,
  String? groupRecordId,
}) => SyncConflict(
  entity: entity,
  recordId: recordId,
  base: base,
  local: local,
  remote: remote,
  remoteRevision: 1,
  groupEntity: groupEntity,
  groupRecordId: groupRecordId,
);

Map<String, dynamic> day(String id, String name, int position) => {
  'sync_id': id,
  'name': name,
  'position': position,
  'exercises': <dynamic>[],
};

void main() {
  test('conflict diff lists only the fields a person can act on', () {
    final summary = summarizeConflict(
      conflict(
        'body_measurements',
        local: {
          'date': '2026-03-12',
          'weight_kg': 82.0,
          'notes': null,
          'created_at': 'A',
        },
        remote: {
          'date': '2026-03-12',
          'weight_kg': 83.5,
          'notes': 'felt heavy',
          'created_at': 'A',
        },
      ),
    );
    expect(summary.changes.map((c) => c.field), ['weight_kg', 'notes']);
    expect(summary.hiddenChangeCount, 0);
    expect(summary.localDeleted, isFalse);
  });

  test('a difference only in hidden columns never reads as zero fields', () {
    final summary = summarizeConflict(
      conflict(
        'body_measurements',
        local: {'date': '2026-03-12', 'weight_kg': 82.0, 'created_at': 'A'},
        remote: {'date': '2026-03-12', 'weight_kg': 82.0, 'created_at': 'B'},
      ),
    );
    expect(summary.changes, isEmpty);
    expect(summary.hiddenChangeCount, 1);
    expect(summary.hasOnlyHiddenChanges, isTrue);
  });

  test('session aggregates are suppressed rather than counted as edits', () {
    final summary = summarizeConflict(
      conflict(
        'workout_sessions',
        local: {
          'date': '2026-03-12',
          'title': 'Push',
          'duration_minutes': 45,
          'total_volume': 1000,
          'total_sets': 12,
          'exercise_count': 4,
        },
        remote: {
          'date': '2026-03-12',
          'title': 'Push',
          'duration_minutes': 45,
          'total_volume': 1200,
          'total_sets': 14,
          'exercise_count': 5,
        },
      ),
    );
    expect(summary.changes, isEmpty);
    expect(summary.hiddenChangeCount, 3);
  });

  test('change origin is derived from the common ancestor', () {
    const base = {'name': 'A'};
    expect(
      changeOrigin(
        conflict(
          'user_profile',
          base: base,
          local: {'name': 'B'},
          remote: {'name': 'C'},
        ),
      ),
      ChangeOrigin.both,
    );
    expect(
      changeOrigin(
        conflict(
          'user_profile',
          base: base,
          local: {'name': 'A'},
          remote: {'name': 'C'},
        ),
      ),
      ChangeOrigin.remoteOnly,
    );
    expect(
      changeOrigin(
        conflict(
          'user_profile',
          base: base,
          local: {'name': 'B'},
          remote: {'name': 'A'},
        ),
      ),
      ChangeOrigin.localOnly,
    );
    // No stored ancestor means nothing can honestly be said.
    expect(
      changeOrigin(
        conflict('user_profile', local: {'name': 'B'}, remote: {'name': 'C'}),
      ),
      ChangeOrigin.unknown,
    );
  });

  test('newerSide refuses to guess without a real modification time', () {
    // user_profile is the one entity carrying updated_at.
    expect(
      newerSide(
        conflict(
          'user_profile',
          local: {'name': 'A', 'updated_at': '2026-03-12T10:00:00Z'},
          remote: {'name': 'B', 'updated_at': '2026-03-11T10:00:00Z'},
        ),
      ),
      ConflictSide.local,
    );
    // created_at and date must never stand in for an edit time. This guards
    // against someone wiring them up later to fill the gap: a record created
    // long ago and edited a minute ago would report as the older version.
    expect(
      newerSide(
        conflict(
          'body_measurements',
          local: {'date': '2020-01-01', 'created_at': '2020-01-01T00:00:00Z'},
          remote: {'date': '2026-03-12', 'created_at': '2026-03-12T00:00:00Z'},
        ),
      ),
      isNull,
    );
  });

  test('a deleted version is reported as a deletion, not as field changes', () {
    final summary = summarizeConflict(
      conflict(
        'body_measurements',
        remote: {'date': '2026-03-12', 'weight_kg': 82.0},
      ),
    );
    expect(summary.localDeleted, isTrue);
    expect(summary.remoteDeleted, isFalse);
    expect(summary.changes, isEmpty);
  });

  test('both sides deleting the record does not throw', () {
    final summary = summarizeConflict(conflict('body_measurements'));
    expect(summary.localDeleted, isTrue);
    expect(summary.remoteDeleted, isTrue);
  });

  test('a swap of equal length names both sides instead of "3 to 3"', () {
    final summary = summarizeConflict(
      conflict(
        'custom_programs',
        local: {
          'name': 'P',
          'days': [day('a', 'Push', 0), day('b', 'Pull', 1)],
        },
        remote: {
          'name': 'P',
          'days': [day('a', 'Push', 0), day('c', 'Legs', 1)],
        },
      ),
    );
    final delta = summary.changes.single.collection!;
    // Reporting countDiffers here rendered "2 to 2", which reads as no change.
    expect(delta.change, CollectionChange.membershipDiffers);
    expect(delta.localCount, delta.remoteCount);
    expect(delta.removedNames, ['Pull']);
    expect(delta.addedNames, ['Legs']);
  });

  test('a collection with a different length reports the counts', () {
    final summary = summarizeConflict(
      conflict(
        'custom_programs',
        local: {
          'name': 'P',
          'days': [day('a', 'Push', 0), day('b', 'Pull', 1)],
        },
        remote: {
          'name': 'P',
          'days': [
            day('a', 'Push', 0),
            day('b', 'Pull', 1),
            day('c', 'Legs', 2),
          ],
        },
      ),
    );
    final delta = summary.changes.single.collection!;
    expect(delta.change, CollectionChange.countDiffers);
    expect(delta.localCount, 2);
    expect(delta.remoteCount, 3);
    expect(delta.addedNames, ['Legs']);
  });

  test('collections match by identity, so a front insert is one addition', () {
    // An index-based comparison fails this case: inserting at the front
    // shifts the position of every existing day.
    final summary = summarizeConflict(
      conflict(
        'custom_programs',
        local: {
          'name': 'P',
          'days': [day('a', 'Push', 0), day('b', 'Pull', 1)],
        },
        remote: {
          'name': 'P',
          'days': [
            day('z', 'Warmup', 0),
            day('a', 'Push', 1),
            day('b', 'Pull', 2),
          ],
        },
      ),
    );
    final delta = summary.changes.single.collection!;
    expect(delta.addedNames, ['Warmup']);
    expect(delta.editedNames, isEmpty);
    expect(delta.removedNames, isEmpty);
  });

  test('a pure reorder is reported as order, not as phantom edits', () {
    final summary = summarizeConflict(
      conflict(
        'custom_programs',
        local: {
          'name': 'P',
          'days': [day('a', 'Push', 0), day('b', 'Pull', 1)],
        },
        remote: {
          'name': 'P',
          'days': [day('b', 'Pull', 0), day('a', 'Push', 1)],
        },
      ),
    );
    final delta = summary.changes.single.collection!;
    expect(delta.change, CollectionChange.orderDiffers);
    expect(delta.addedNames, isEmpty);
    expect(delta.removedNames, isEmpty);
    expect(delta.editedNames, isEmpty);
  });

  test('renaming one element reports just that element as edited', () {
    final summary = summarizeConflict(
      conflict(
        'custom_programs',
        local: {
          'name': 'P',
          'days': [day('a', 'Push', 0), day('b', 'Leg Day', 1)],
        },
        remote: {
          'name': 'P',
          'days': [day('a', 'Push', 0), day('b', 'Lower', 1)],
        },
      ),
    );
    final delta = summary.changes.single.collection!;
    expect(delta.change, CollectionChange.contentDiffers);
    expect(delta.editedNames, ['Leg Day']);
  });

  test('conflicts that resolve together are collapsed into one group', () {
    final session = conflict(
      'workout_sessions',
      recordId: 's1',
      local: {'date': '2026-03-12'},
      remote: {'date': '2026-03-12'},
      groupEntity: 'workout_sessions',
      groupRecordId: 's1',
    );
    final entries = [
      for (var i = 0; i < 5; i++)
        conflict(
          'workout_entries',
          recordId: 'e$i',
          local: {'date': '2026-03-12'},
          remote: {'date': '2026-03-12'},
          groupEntity: 'workout_sessions',
          groupRecordId: 's1',
        ),
    ];
    // The session is listed last to prove the anchor is chosen by identity,
    // not by position in the list.
    final groups = groupConflicts([...entries, session]);
    expect(groups, hasLength(1));
    expect(groups.single.anchor.entity, 'workout_sessions');
    expect(groups.single.members, hasLength(5));
    expect(groups.single.recordCount, 6);
  });

  test('conflicts with no group key stay separate', () {
    final groups = groupConflicts([
      conflict('user_profile', local: {}, remote: {}),
      conflict('body_measurements', local: {}, remote: {}),
    ]);
    expect(groups, hasLength(2));
    expect(groups.every((g) => g.members.isEmpty), isTrue);
  });

  test('every listed field has a real label in both languages', () async {
    // This is what keeps the ARB set honest as entities gain columns: a field
    // added to conflictFieldOrder without a label fails here instead of
    // quietly reaching users as "Body Fat Percent".
    for (final locale in const [Locale('en'), Locale('tr')]) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final entry in conflictFieldOrder.entries) {
        for (final field in entry.value) {
          final label = conflictFieldLabel(l10n, entry.key, field);
          expect(label, isNotEmpty, reason: '${entry.key}.$field in $locale');
          if (locale.languageCode == 'tr') {
            // The humanized fallback is English; seeing it in Turkish means
            // the field was never given a label. (Checked only for Turkish
            // because in English a correct label like "Name" is legitimately
            // identical to the humanized key.)
            expect(
              label,
              isNot(humanizeFieldKey(field)),
              reason: 'untranslated ${entry.key}.$field',
            );
          }
        }
      }
    }
  });

  test('a preference conflict is titled by the setting it belongs to', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      conflictEntityLabel(
        l10n,
        conflict('account_preferences', local: {'key': 'weekly_goal', 'value': 3}),
      ),
      l10n.settingsWeeklyGoalLabel,
    );
    // An unmapped preference degrades to the humanized key rather than
    // throwing or showing the bare column name.
    expect(
      conflictEntityLabel(
        l10n,
        conflict(
          'account_preferences',
          local: {'key': 'has_seen_tutorial', 'value': true},
        ),
      ),
      'Has Seen Tutorial',
    );
  });

  test('an achievement conflict is titled by the achievement, not its id', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final label = conflictEntityLabel(
      l10n,
      conflict(
        'achievements_unlocked',
        local: {'achievement_id': 'first_workout', 'unlocked_at': '2026-03-12'},
      ),
    );
    expect(label, l10n.achievementFirstWorkoutTitle);
    expect(label, isNot(contains('first_workout')));
  });

  test('values are formatted for a person, not for a database', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // A cleared value must not be indistinguishable from a note reading "null".
    expect(
      conflictValueText(l10n, 'body_measurements', 'notes', null),
      conflictEmptyValue,
    );
    expect(
      conflictValueText(l10n, 'body_measurements', 'notes', ''),
      conflictEmptyValue,
    );
    expect(
      conflictValueText(l10n, 'account_preferences', 'value', true),
      l10n.syncConflictValueOn,
    );
    expect(
      conflictValueText(l10n, 'account_preferences', 'value', false),
      l10n.syncConflictValueOff,
    );
    expect(
      conflictValueText(l10n, 'user_profile', 'gender', 'female'),
      l10n.accountGenderFemale,
    );
    expect(
      conflictValueText(l10n, 'body_measurements', 'weight_kg', 82.0),
      '82.0',
    );
    expect(conflictValueText(l10n, 'user_profile', 'age', 35), '35');
    // account_preferences.value holds whatever was stored; an unexpected type
    // must stringify rather than throw.
    expect(
      conflictValueText(l10n, 'account_preferences', 'value', [1, 2]),
      isNotEmpty,
    );
  });

  test('the headline never claims zero fields differ', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final hiddenOnly = summarizeConflict(
      conflict(
        'body_measurements',
        local: {'date': '2026-03-12', 'created_at': 'A'},
        remote: {'date': '2026-03-12', 'created_at': 'B'},
      ),
    );
    expect(
      conflictHeadline(l10n, hiddenOnly),
      l10n.syncConflictNoVisibleDifference,
    );

    final deleted = summarizeConflict(
      conflict('body_measurements', remote: {'date': '2026-03-12'}),
    );
    expect(conflictHeadline(l10n, deleted), l10n.syncConflictDeletedLocally);

    final one = summarizeConflict(
      conflict(
        'body_measurements',
        local: {'weight_kg': 82.0},
        remote: {'weight_kg': 83.0},
      ),
    );
    expect(conflictHeadline(l10n, one), contains(l10n.conflictFieldWeight));
  });

  test('origin text is absent exactly when there is no ancestor', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(conflictOriginText(l10n, ChangeOrigin.unknown), isNull);
    expect(conflictOriginText(l10n, ChangeOrigin.both), isNotNull);
    expect(conflictOriginText(l10n, ChangeOrigin.localOnly), isNotNull);
    expect(conflictOriginText(l10n, ChangeOrigin.remoteOnly), isNotNull);
  });
}
