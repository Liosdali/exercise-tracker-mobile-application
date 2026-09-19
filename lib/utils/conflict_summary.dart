import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/sync_conflict.dart';
import '../services/achievement_localizer.dart';
import '../services/exercise_localizer.dart';
import '../services/program_localizer.dart';

/// Which side of a conflict a value came from.
enum ConflictSide { local, remote }

/// Who changed a record since the last successful sync.
///
/// Derived by comparing each side against [SyncConflict.base], the last
/// payload the server and this device agreed on. This is the honest
/// replacement for a "which is newer" headline: nine of the ten synced
/// entities carry no modification timestamp at all, so newness cannot be
/// computed for them, but authorship always can.
enum ChangeOrigin {
  /// Both sides moved away from the common ancestor.
  both,

  /// Only this device edited the record; the server still holds the ancestor.
  localOnly,

  /// Only the server edited the record.
  remoteOnly,

  /// No common ancestor was stored, so nothing can be said.
  unknown,
}

/// How a nested collection differs between the two sides.
enum CollectionChange { none, countDiffers, contentDiffers, orderDiffers }

/// One field that differs between the local and remote versions.
///
/// [collection] is set only for the nested lists (a program's days, a
/// routine's exercises); for those, [localValue] and [remoteValue] are left
/// null because the raw lists are never rendered directly.
@immutable
class FieldChange {
  final String field;
  final Object? localValue;
  final Object? remoteValue;
  final CollectionDelta? collection;

  const FieldChange({
    required this.field,
    this.localValue,
    this.remoteValue,
    this.collection,
  });
}

/// The difference between two nested collections, matched by identity.
@immutable
class CollectionDelta {
  final int localCount;
  final int remoteCount;
  final CollectionChange change;

  /// Present remotely but not locally, by display name.
  final List<String> addedNames;

  /// Present locally but not remotely.
  final List<String> removedNames;

  /// Present on both sides with differing contents.
  final List<String> editedNames;

  const CollectionDelta({
    required this.localCount,
    required this.remoteCount,
    required this.change,
    this.addedNames = const [],
    this.removedNames = const [],
    this.editedNames = const [],
  });
}

/// Everything the conflict card needs, with no localization applied.
@immutable
class ConflictSummary {
  final String entity;
  final bool localDeleted;
  final bool remoteDeleted;
  final ChangeOrigin origin;

  /// Differing fields that are meaningful to a person, in display order.
  final List<FieldChange> changes;

  /// Differing fields suppressed by [hiddenConflictFields] or by the
  /// per-entity policy. Kept as a count so the card can say "the visible
  /// details match" instead of the nonsensical "0 fields differ".
  final int hiddenChangeCount;

  const ConflictSummary({
    required this.entity,
    required this.localDeleted,
    required this.remoteDeleted,
    required this.origin,
    required this.changes,
    required this.hiddenChangeCount,
  });

  /// True when both versions agree on everything a person can see.
  bool get hasOnlyHiddenChanges =>
      changes.isEmpty && hiddenChangeCount > 0 && !localDeleted && !remoteDeleted;
}

/// A set of conflicts that resolve together.
///
/// `AccountStore.resolveConflict` resolves every row sharing a
/// `(group_entity, group_record_id)` pair, so rendering one card per row
/// would offer buttons whose real blast radius is hidden.
@immutable
class ConflictGroup {
  final SyncConflict anchor;
  final List<SyncConflict> members;
  final String rootEntity;

  const ConflictGroup({
    required this.anchor,
    required this.members,
    required this.rootEntity,
  });

  /// Total records this group's buttons would rewrite, anchor included.
  int get recordCount => members.length + 1;
}

/// Columns that never mean anything to the person resolving a conflict.
///
/// These are row identity, foreign keys, ordering and bookkeeping. They
/// differ constantly without representing an edit anyone made on purpose.
const Set<String> hiddenConflictFields = {
  'id',
  'sync_id',
  'day_sync_id',
  'session_id',
  'exercise_id',
  'program_id',
  'day_id',
  'routine_id',
  'position',
  'created_at',
  'updated_at',
  'key',
  'day_index',
  // Recomputed from weight/waist/neck/height, so showing it would report a
  // single edit twice.
  'calculated_body_fat',
};

/// Visible fields per entity, in the order the card should list them.
///
/// Anything absent from this list is counted into
/// [ConflictSummary.hiddenChangeCount] rather than shown. For
/// `workout_sessions` the aggregates (`total_volume`, `total_sets`,
/// `exercise_count`, `calories`) are deliberately omitted: they are
/// mechanical sums of the entries, so a one-entry edit would otherwise
/// present itself as six differing fields.
const Map<String, List<String>> conflictFieldOrder = {
  'custom_programs': ['name', 'days'],
  'custom_routines': ['name', 'exercises'],
  'workout_sessions': ['date', 'title', 'duration_minutes'],
  'workout_entries': [
    'date',
    'exercise_name',
    'category',
    'sets',
    'reps',
    'weight',
    'notes',
  ],
  'body_measurements': [
    'date',
    'weight_kg',
    'height_cm',
    'body_fat_percent',
    'chest_cm',
    'waist_cm',
    'neck_cm',
    'hip_cm',
    'gender',
    'notes',
  ],
  'user_profile': [
    'name',
    'age',
    'gender',
    'weight_kg',
    'height_cm',
    'body_fat_percent',
  ],
  'account_preferences': ['value'],
  'planned_workouts': ['date', 'program_key', 'day_name'],
  'program_progress': ['program_key', 'next_day_index', 'last_completed_date'],
  'achievements_unlocked': ['unlocked_at'],
};

/// The nested list each entity carries, with the key that identifies an
/// element and the key that names it.
const Map<String, _CollectionSpec> _collections = {
  'custom_programs': _CollectionSpec(
    field: 'days',
    identityKey: 'sync_id',
    nameKey: 'name',
  ),
  'custom_routines': _CollectionSpec(
    field: 'exercises',
    identityKey: 'sync_id',
    nameKey: 'exercise_name',
  ),
};

@immutable
class _CollectionSpec {
  final String field;
  final String identityKey;
  final String nameKey;
  const _CollectionSpec({
    required this.field,
    required this.identityKey,
    required this.nameKey,
  });
}

/// True when [field] should be shown for [entity].
bool isVisibleConflictField(String entity, String field) =>
    !hiddenConflictFields.contains(field) &&
    (conflictFieldOrder[entity]?.contains(field) ?? false);

/// Who edited the record since the last sync. See [ChangeOrigin].
ChangeOrigin changeOrigin(SyncConflict conflict) {
  final base = conflict.base;
  if (base == null) return ChangeOrigin.unknown;
  final localChanged = !_deepEquals(base, conflict.local);
  final remoteChanged = !_deepEquals(base, conflict.remote);
  if (localChanged && remoteChanged) return ChangeOrigin.both;
  if (remoteChanged) return ChangeOrigin.remoteOnly;
  if (localChanged) return ChangeOrigin.localOnly;
  return ChangeOrigin.unknown;
}

/// The moment [payload] was last modified, or null when the entity keeps no
/// such column.
///
/// Only `user_profile` has one. `created_at` is deliberately not consulted:
/// it does not move when a row is edited, so a record created last year and
/// edited a minute ago would report as a year old — a confidently wrong
/// answer on the one screen where being wrong destroys data.
DateTime? modifiedAt(String entity, Map<String, dynamic>? payload) {
  if (entity != 'user_profile' || payload == null) return null;
  final raw = payload['updated_at'];
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Which side was edited more recently, or null when that is not knowable.
///
/// Returns null for nine of the ten entities by design; callers must render
/// no freshness line at all rather than guessing.
ConflictSide? newerSide(SyncConflict conflict) {
  final local = modifiedAt(conflict.entity, conflict.local);
  final remote = modifiedAt(conflict.entity, conflict.remote);
  if (local == null || remote == null) return null;
  if (local.isAtSameMomentAs(remote)) return null;
  return local.isAfter(remote) ? ConflictSide.local : ConflictSide.remote;
}

/// Compares two nested collections by [identityKey] rather than by position.
///
/// Index-based comparison is what makes this output garbage: inserting a day
/// at the front shifts every later index, so an index diff reports the whole
/// list as changed for a single insertion.
CollectionDelta? collectionDelta(
  List<dynamic>? local,
  List<dynamic>? remote, {
  required String identityKey,
  required String nameKey,
}) {
  if (local == null && remote == null) return null;
  final localItems = _byIdentity(local, identityKey);
  final remoteItems = _byIdentity(remote, identityKey);

  final added = <String>[];
  final removed = <String>[];
  final edited = <String>[];
  for (final entry in remoteItems.entries) {
    if (!localItems.containsKey(entry.key)) {
      added.add(_nameOf(entry.value, nameKey));
    } else if (!_deepEquals(
      _withoutOrdering(localItems[entry.key]),
      _withoutOrdering(entry.value),
    )) {
      edited.add(_nameOf(localItems[entry.key], nameKey));
    }
  }
  for (final entry in localItems.entries) {
    if (!remoteItems.containsKey(entry.key)) {
      removed.add(_nameOf(entry.value, nameKey));
    }
  }

  final localCount = local?.length ?? 0;
  final remoteCount = remote?.length ?? 0;
  final CollectionChange change;
  if (localCount != remoteCount) {
    change = CollectionChange.countDiffers;
  } else if (added.isNotEmpty || removed.isNotEmpty) {
    change = CollectionChange.countDiffers;
  } else if (edited.isNotEmpty) {
    change = CollectionChange.contentDiffers;
  } else if (!_sameOrder(local, remote, identityKey)) {
    change = CollectionChange.orderDiffers;
  } else {
    change = CollectionChange.none;
  }

  return CollectionDelta(
    localCount: localCount,
    remoteCount: remoteCount,
    change: change,
    addedNames: added,
    removedNames: removed,
    editedNames: edited,
  );
}

/// Reduces a conflict to the differences a person can act on.
ConflictSummary summarizeConflict(SyncConflict conflict) {
  final local = conflict.local;
  final remote = conflict.remote;
  final origin = changeOrigin(conflict);

  if (local == null || remote == null) {
    return ConflictSummary(
      entity: conflict.entity,
      localDeleted: local == null,
      remoteDeleted: remote == null,
      origin: origin,
      changes: const [],
      hiddenChangeCount: 0,
    );
  }

  final visible = conflictFieldOrder[conflict.entity] ?? const <String>[];
  final spec = _collections[conflict.entity];
  final changes = <FieldChange>[];

  for (final field in visible) {
    if (spec != null && field == spec.field) {
      final delta = collectionDelta(
        local[field] as List<dynamic>?,
        remote[field] as List<dynamic>?,
        identityKey: spec.identityKey,
        nameKey: spec.nameKey,
      );
      if (delta != null && delta.change != CollectionChange.none) {
        changes.add(FieldChange(field: field, collection: delta));
      }
      continue;
    }
    if (_deepEquals(local[field], remote[field])) continue;
    changes.add(
      FieldChange(
        field: field,
        localValue: local[field],
        remoteValue: remote[field],
      ),
    );
  }

  // Everything else that differs is real, just not worth showing. Counting it
  // keeps the card from claiming the versions are identical.
  var hidden = 0;
  for (final field in {...local.keys, ...remote.keys}) {
    if (visible.contains(field)) continue;
    if (!_deepEquals(local[field], remote[field])) hidden++;
  }

  return ConflictSummary(
    entity: conflict.entity,
    localDeleted: false,
    remoteDeleted: false,
    origin: origin,
    changes: changes,
    hiddenChangeCount: hidden,
  );
}

/// Collapses conflicts that resolve together into one group each.
///
/// Conflicts with no group key become singletons. The anchor is the group's
/// root record when it is present in the list, so the card is titled after
/// the session rather than after an arbitrary entry.
List<ConflictGroup> groupConflicts(List<SyncConflict> conflicts) {
  final groups = <String, List<SyncConflict>>{};
  final singles = <SyncConflict>[];
  for (final conflict in conflicts) {
    final entity = conflict.groupEntity;
    final id = conflict.groupRecordId;
    if (entity == null || id == null) {
      singles.add(conflict);
    } else {
      groups.putIfAbsent('$entity/$id', () => []).add(conflict);
    }
  }

  final result = <ConflictGroup>[
    for (final conflict in singles)
      ConflictGroup(
        anchor: conflict,
        members: const [],
        rootEntity: conflict.entity,
      ),
  ];
  for (final entry in groups.entries) {
    final rootEntity = entry.value.first.groupEntity!;
    final rootId = entry.value.first.groupRecordId!;
    final anchorIndex = entry.value.indexWhere(
      (c) => c.entity == rootEntity && c.recordId == rootId,
    );
    final anchor = entry.value[anchorIndex == -1 ? 0 : anchorIndex];
    result.add(
      ConflictGroup(
        anchor: anchor,
        members: [
          for (final c in entry.value)
            if (!identical(c, anchor)) c,
        ],
        rootEntity: rootEntity,
      ),
    );
  }
  return result;
}

Map<String, Map<String, dynamic>> _byIdentity(
  List<dynamic>? items,
  String identityKey,
) {
  final result = <String, Map<String, dynamic>>{};
  if (items == null) return result;
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    // Fall back to the index so elements written before sync ids existed
    // still line up with themselves rather than looking added and removed.
    final identity = map[identityKey]?.toString() ?? '#$i';
    result[identity] = map;
  }
  return result;
}

String _nameOf(Map<String, dynamic>? item, String nameKey) {
  final value = item?[nameKey];
  return value is String && value.isNotEmpty ? value : '';
}

/// Drops ordering-only keys so a reorder is not reported as a content edit.
Map<String, dynamic> _withoutOrdering(Map<String, dynamic>? item) {
  if (item == null) return const {};
  return {
    for (final entry in item.entries)
      if (entry.key != 'position') entry.key: entry.value,
  };
}

bool _sameOrder(List<dynamic>? local, List<dynamic>? remote, String key) {
  if (local == null || remote == null) return true;
  if (local.length != remote.length) return false;
  for (var i = 0; i < local.length; i++) {
    final a = local[i];
    final b = remote[i];
    if (a is! Map || b is! Map) continue;
    if (a[key]?.toString() != b[key]?.toString()) return false;
  }
  return true;
}

/// Structural equality for decoded JSON: maps, lists and primitives.
bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

// ---------------------------------------------------------------------------
// Localization. Everything below turns the structures above into text; nothing
// above depends on a locale, so the comparison logic tests without one.
// ---------------------------------------------------------------------------

/// Shown as the card's title: what kind of record this conflict is about.
///
/// Where the record names itself — an achievement, a program day, a setting —
/// that name is used in preference to the generic entity name, because
/// "Achievements" tells the user far less than "First workout".
String conflictEntityLabel(AppLocalizations l10n, SyncConflict conflict) {
  final payload = conflict.local ?? conflict.remote ?? const {};
  switch (conflict.entity) {
    case 'achievements_unlocked':
      final id = payload['achievement_id'];
      if (id is String && id.isNotEmpty) {
        return AchievementLocalizer.title(l10n, id);
      }
      return l10n.profileAchievementsTitle;
    case 'account_preferences':
      final key = payload['key'];
      return key is String ? _preferenceLabel(l10n, key) : l10n.settingsTitle;
    case 'planned_workouts':
    case 'program_progress':
      final key = payload['program_key'];
      if (key is String && key.isNotEmpty) {
        return _programLabel(l10n, key);
      }
      return conflict.entity == 'planned_workouts'
          ? l10n.calendarScreenTitle
          : l10n.workoutsProgramsSectionTitle;
    default:
      return _entityNames(l10n)[conflict.entity] ?? l10n.syncConflictsTitle;
  }
}

Map<String, String> _entityNames(AppLocalizations l10n) => {
  'custom_programs': l10n.workoutsMyProgramsSectionTitle,
  'custom_routines': l10n.workoutsMyRoutinesSectionTitle,
  'workout_sessions': l10n.profileCalendarLinkTitle,
  'workout_entries': l10n.profileCalendarLinkTitle,
  'body_measurements': l10n.profileBodyMeasurementsTitle,
  'user_profile': l10n.navProfile,
  'account_preferences': l10n.settingsTitle,
  'planned_workouts': l10n.calendarScreenTitle,
  'program_progress': l10n.workoutsProgramsSectionTitle,
  'achievements_unlocked': l10n.profileAchievementsTitle,
};

String _preferenceLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'weekly_goal':
      return l10n.settingsWeeklyGoalLabel;
    case 'notifications_enabled':
      return l10n.settingsNotificationsMasterToggle;
    case 'streak_warnings_enabled':
      return l10n.settingsNotificationsStreakToggle;
    case 'daily_reminder_enabled':
      return l10n.settingsNotificationsDailyToggle;
    case 'active_program_key':
      return l10n.workoutsProgramsSectionTitle;
    default:
      return humanizeFieldKey(key);
  }
}

String _programLabel(AppLocalizations l10n, String programKey) {
  final id = programKey.contains(':')
      ? programKey.substring(programKey.indexOf(':') + 1)
      : programKey;
  return ProgramLocalizer.name(l10n, id, id);
}

/// A field's label. Never returns null or an empty string.
///
/// Falls back to [humanizeFieldKey] so a column added later degrades to a
/// readable-ish English name instead of crashing or vanishing from the diff.
/// That fallback is what keeps the ARB set a quality floor rather than a
/// correctness requirement.
String conflictFieldLabel(AppLocalizations l10n, String entity, String field) {
  switch (field) {
    case 'name':
      return l10n.conflictFieldName;
    case 'title':
      return l10n.conflictFieldTitle;
    case 'notes':
      return l10n.conflictFieldNotes;
    case 'date':
      return l10n.logEntryDateLabel;
    case 'weight':
    case 'weight_kg':
      return l10n.conflictFieldWeight;
    case 'height_cm':
      return l10n.conflictFieldHeight;
    case 'age':
      return l10n.conflictFieldAge;
    case 'gender':
      return l10n.conflictFieldGender;
    case 'body_fat_percent':
      return l10n.conflictFieldBodyFat;
    case 'chest_cm':
      return l10n.conflictFieldChest;
    case 'waist_cm':
      return l10n.conflictFieldWaist;
    case 'neck_cm':
      return l10n.conflictFieldNeck;
    case 'hip_cm':
      return l10n.conflictFieldHip;
    case 'exercise_name':
      return l10n.conflictFieldExercise;
    case 'category':
      return l10n.conflictFieldCategory;
    case 'sets':
    case 'target_sets':
      return l10n.logEntrySetsLabel;
    case 'reps':
    case 'target_reps':
      return l10n.logEntryRepsLabel;
    case 'duration_minutes':
      return l10n.conflictFieldDuration;
    case 'days':
      return l10n.conflictFieldDays;
    case 'exercises':
      return l10n.conflictFieldExercises;
    case 'day_name':
      return l10n.conflictFieldDayName;
    case 'value':
      return l10n.conflictFieldValue;
    case 'unlocked_at':
      return l10n.conflictFieldUnlockedAt;
    case 'program_key':
      return l10n.conflictFieldProgram;
    case 'next_day_index':
      return l10n.conflictFieldNextDay;
    case 'last_completed_date':
      return l10n.conflictFieldLastCompleted;
    default:
      return humanizeFieldKey(field);
  }
}

/// `weight_kg` -> `Weight Kg`. A last resort, never a designed label.
String humanizeFieldKey(String field) => field
    .split(RegExp(r'[_\s]+'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// The em dash stands in for a value that is absent or was cleared. Rendering
/// the literal "null" would be indistinguishable from a note reading "null".
const String conflictEmptyValue = '—';

/// A single value, formatted for a person rather than for a database.
String conflictValueText(
  AppLocalizations l10n,
  String entity,
  String field,
  Object? value,
) {
  if (value == null) return conflictEmptyValue;
  if (value is bool) {
    return value ? l10n.syncConflictValueOn : l10n.syncConflictValueOff;
  }
  if (field == 'program_key' && value is String) {
    return _programLabel(l10n, value);
  }
  if (field == 'gender' && value is String) {
    switch (value) {
      case 'female':
        return l10n.accountGenderFemale;
      case 'male':
        return l10n.accountGenderMale;
      case 'other':
        return l10n.accountGenderOther;
    }
  }
  if (field == 'category' && value is String) {
    return ExerciseLocalizer.localizedBodyPart(value, l10n.localeName);
  }
  if (_dateFields.contains(field) && value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      // Bare constructor, as elsewhere in the app: it follows the ambient
      // locale that flutter_localizations sets, and naming a locale here
      // would throw wherever that locale's date symbols are not loaded.
      return DateFormat.yMMMd().format(parsed.toLocal());
    }
  }
  if (value is num) return _number(value);
  if (value is String) return value.isEmpty ? conflictEmptyValue : value;
  // account_preferences.value is whatever was stored; never assume a type.
  return value.toString();
}

const Set<String> _dateFields = {
  'date',
  'unlocked_at',
  'last_completed_date',
};

String _number(num value) {
  if (value is int) return value.toString();
  return value == value.roundToDouble()
      ? value.toStringAsFixed(value.abs() < 1000 ? 1 : 0)
      : value.toString();
}

/// The one-line summary under the card title.
String conflictHeadline(AppLocalizations l10n, ConflictSummary summary) {
  if (summary.localDeleted && summary.remoteDeleted) {
    return l10n.syncConflictDeletedBoth;
  }
  if (summary.localDeleted) return l10n.syncConflictDeletedLocally;
  if (summary.remoteDeleted) return l10n.syncConflictDeletedRemotely;
  if (summary.changes.isEmpty) return l10n.syncConflictNoVisibleDifference;
  final names = summary.changes
      .map((change) => conflictFieldLabel(l10n, summary.entity, change.field))
      .join(', ');
  return l10n.syncConflictFieldsDiffer(summary.changes.length, names);
}

/// The authorship line, or null when no common ancestor was stored.
String? conflictOriginText(AppLocalizations l10n, ChangeOrigin origin) {
  switch (origin) {
    case ChangeOrigin.both:
      return l10n.syncConflictOriginBoth;
    case ChangeOrigin.localOnly:
      return l10n.syncConflictOriginLocalOnly;
    case ChangeOrigin.remoteOnly:
      return l10n.syncConflictOriginRemoteOnly;
    case ChangeOrigin.unknown:
      return null;
  }
}

/// How a nested collection changed, in one line.
String conflictCollectionText(
  AppLocalizations l10n,
  String entity,
  String field,
  CollectionDelta delta,
) {
  switch (delta.change) {
    case CollectionChange.countDiffers:
      return l10n.syncConflictCollectionCount(
        '${delta.localCount}',
        '${delta.remoteCount}',
      );
    case CollectionChange.orderDiffers:
      return l10n.syncConflictCollectionOrder;
    case CollectionChange.contentDiffers:
      return l10n.syncConflictCollectionContent(
        delta.editedNames.length,
        _capped(delta.editedNames),
      );
    case CollectionChange.none:
      return '';
  }
}

/// At most two names, so a wholesale change does not fill the card.
String _capped(List<String> names, {int limit = 2}) {
  final shown = names.where((name) => name.isNotEmpty).take(limit).toList();
  final remaining = names.length - shown.length;
  if (shown.isEmpty) return '';
  return remaining > 0 ? '${shown.join(', ')} +$remaining' : shown.join(', ');
}
