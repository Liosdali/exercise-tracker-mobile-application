import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database_helper.dart';
import '../services/user_account_service.dart';
import 'account_change_notifier.dart';

/// Presentation is device-wide; every personal preference is stored in the
/// current SQLite workspace and participates in revisioned synchronization.
class SettingsProvider extends AccountChangeNotifier {
  final _db = DatabaseHelper.instance.workspace();
  static const _tutorialSeenKey = 'has_seen_tutorial';

  Map<String, dynamic> _values = {};
  bool _loaded = false;
  String? _languageCode;
  ThemeMode _themeMode = ThemeMode.system;
  String? _userName;
  bool _hasSeenTutorial = false;

  bool get isLoaded => _loaded;
  int get weeklyGoal => (_values['weekly_goal'] as num?)?.toInt() ?? 3;
  bool get soundEnabled => _values['sound_enabled'] as bool? ?? true;
  bool get vibrationEnabled => _values['vibration_enabled'] as bool? ?? true;
  String? get activeProgramKey => _values['active_program_key'] as String?;
  String? get languageCode => _languageCode;
  ThemeMode get themeMode => _themeMode;
  String? get userName => _userName;
  bool get hasCompletedOnboarding =>
      _values['has_completed_onboarding'] as bool? ?? false;
  bool get notificationsEnabled =>
      _values['notifications_enabled'] as bool? ?? true;
  bool get streakWarningsEnabled =>
      _values['streak_warnings_enabled'] as bool? ?? true;
  bool get dailyReminderEnabled =>
      _values['daily_reminder_enabled'] as bool? ?? true;

  /// Whether the interactive tour has already run on this installation.
  ///
  /// Stored per device rather than in the account workspace. It used to live
  /// in `account_preferences`, which "Reset all data" deletes wholesale, so
  /// resetting made the tour start over on top of the Settings screen. The
  /// tour describes the app, not the user's data, so wiping the data is no
  /// reason to show it again — it belongs with the language and theme
  /// settings, which are likewise device-wide.
  bool get hasSeenTutorial => _hasSeenTutorial;

  @override
  Future<void> reloadAccount() async {
    _loaded = false;
    await load();
  }

  Future<void> load() async {
    if (_loaded) return;
    final db = await _db.database;
    final rows = await db.query('account_preferences');
    final profile = await db.query('user_profile', where: 'id=1');
    final prefs = await SharedPreferences.getInstance();
    _values = {
      for (final row in rows)
        row['key'] as String: jsonDecode(row['value'] as String),
    };
    _userName = profile.isEmpty ? null : profile.first['name'] as String?;
    if (_userName?.isEmpty == true) _userName = null;
    final storedTutorial = prefs.getBool(_tutorialSeenKey);
    if (storedTutorial != null) {
      _hasSeenTutorial = storedTutorial;
    } else {
      // One-time migration of the old per-workspace flag, so someone who
      // already dismissed the tour does not meet it again on upgrade. Only
      // when nothing is stored on the device: once "Replay tutorial" writes
      // false here, a stale `true` in the workspace must not resurrect it.
      _hasSeenTutorial = _values[_tutorialSeenKey] as bool? ?? false;
      if (_hasSeenTutorial) await prefs.setBool(_tutorialSeenKey, true);
    }
    _languageCode = prefs.getString('app_language');
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == prefs.getString('app_theme_mode'),
      orElse: () => ThemeMode.system,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> _set(String key, Object? value) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'account_preferences',
        where: 'key=?',
        whereArgs: [key],
      );
      if (rows.isEmpty) {
        await txn.insert('account_preferences', {
          'key': key,
          'value': jsonEncode(value),
        });
      } else {
        await txn.update(
          'account_preferences',
          {'value': jsonEncode(value)},
          where: 'key=?',
          whereArgs: [key],
        );
      }
    });
    _values[key] = value;
    notifyListeners();
  }

  Future<void> completeOnboarding(String? name) async {
    // Verify this provider still belongs to the active account before using
    // the shared profile service.
    await _db.database;
    final account = UserAccountService.instance;
    final profile = account.profile;
    await account.updateProfile(
      name: name?.trim() ?? '',
      age: profile?.age,
      weightKg: profile?.weightKg,
      heightCm: profile?.heightCm,
      gender: profile?.gender,
    );
    await _set('has_completed_onboarding', true);
    _userName = name?.trim();
    notifyListeners();
  }

  Future<void> setLanguageCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove('app_language');
    } else {
      await prefs.setString('app_language', code);
    }
    _languageCode = code;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode.name);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setActiveProgramKey(String? key) async {
    if (key?.startsWith('custom:') == true) {
      final db = await _db.database;
      if ((await db.query(
        'custom_programs',
        where: 'id=?',
        whereArgs: [key!.substring(7)],
      )).isEmpty) {
        throw ArgumentError('Custom program does not exist');
      }
    }
    await _set('active_program_key', key);
  }

  Future<void> setWeeklyGoal(int goal) {
    if (goal < 1 || goal > 7) throw ArgumentError('Weekly goal must be 1–7');
    return _set('weekly_goal', goal);
  }

  Future<void> setSoundEnabled(bool value) => _set('sound_enabled', value);
  Future<void> setVibrationEnabled(bool value) =>
      _set('vibration_enabled', value);
  Future<void> setNotificationsEnabled(bool value) =>
      _set('notifications_enabled', value);
  Future<void> setStreakWarningsEnabled(bool value) =>
      _set('streak_warnings_enabled', value);
  Future<void> setDailyReminderEnabled(bool value) =>
      _set('daily_reminder_enabled', value);
  Future<void> setHasSeenTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenKey, value);
    _hasSeenTutorial = value;
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final key in [
        'weekly_goal',
        'sound_enabled',
        'vibration_enabled',
        'active_program_key',
      ]) {
        await txn.delete(
          'account_preferences',
          where: 'key=?',
          whereArgs: [key],
        );
      }
    });
    await reloadAccount();
  }
}
