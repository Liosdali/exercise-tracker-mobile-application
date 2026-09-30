import 'dart:io';

import 'package:exercise_app/data/database_helper.dart';
import 'package:exercise_app/providers/settings_provider.dart';
import 'package:exercise_app/services/user_account_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// The interactive tour must run once per installation.
///
/// It used to be gated by a flag in `account_preferences`, which the
/// "Reset all data" action deletes along with everything else, so resetting
/// replayed the tour on top of the Settings screen.
void main() {
  final helper = DatabaseHelper.instance;
  late Directory directory;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = Directory(
      '${Directory.current.path}/.dart_tool/tutorial_flag_${const Uuid().v4()}',
    );
    await directory.create(recursive: true);
    await databaseFactory.setDatabasesPath(directory.path);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await helper.switchAccount(const Uuid().v4());
  });

  tearDownAll(() async {
    UserAccountService.instance.dispose();
    await helper.closeWorkspace();
    await directory.delete(recursive: true);
  });

  test('resetting all data does not replay the tour', () async {
    final settings = SettingsProvider();
    await settings.load();
    expect(settings.hasSeenTutorial, isFalse);

    await settings.setHasSeenTutorial(true);
    expect(settings.hasSeenTutorial, isTrue);

    // Exactly what the Settings screen does: wipe the workspace, then reload.
    await helper.resetAllData();
    await settings.reloadAccount();

    expect(
      settings.hasSeenTutorial,
      isTrue,
      reason: 'the tour describes the app, not the data that was reset',
    );
  });

  test('replaying the tour is not undone by a stale workspace flag', () async {
    // An account that upgraded from the old scheme still carries
    // has_seen_tutorial=true in its workspace. Choosing "Replay tutorial"
    // must win over it, or the button would appear to do nothing.
    final db = await DatabaseHelper.instance.workspace().database;
    await db.insert('account_preferences', {
      'key': 'has_seen_tutorial',
      'value': 'true',
    });

    final settings = SettingsProvider();
    await settings.load();
    expect(settings.hasSeenTutorial, isTrue, reason: 'migrated from workspace');

    await settings.setHasSeenTutorial(false);
    await settings.reloadAccount();
    expect(settings.hasSeenTutorial, isFalse);
  });

  test('a fresh install still sees the tour', () async {
    final settings = SettingsProvider();
    await settings.load();
    expect(settings.hasSeenTutorial, isFalse);
  });

  test('the tour is not replayed when switching accounts', () async {
    final settings = SettingsProvider();
    await settings.load();
    await settings.setHasSeenTutorial(true);

    await helper.switchAccount(const Uuid().v4());
    final afterSwitch = SettingsProvider();
    await afterSwitch.load();

    expect(
      afterSwitch.hasSeenTutorial,
      isTrue,
      reason: 'the tour belongs to the installation, not to the account',
    );
  });
}
