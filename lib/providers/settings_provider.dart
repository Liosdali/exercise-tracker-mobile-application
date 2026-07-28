import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user settings (weekly goal, sound/vibration toggles for the
/// rest timer), persisted via shared_preferences.
class SettingsProvider extends ChangeNotifier {
  static const _keyWeeklyGoal = 'weekly_goal';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyActiveProgramKey = 'active_program_key';
  static const _keyLanguageCode = 'app_language';
  static const _keyUserName = 'user_name';
  static const _keyHasCompletedOnboarding = 'has_completed_onboarding';

  int _weeklyGoal = 3;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String? _activeProgramKey;
  String? _languageCode;
  String? _userName;
  bool _hasCompletedOnboarding = false;
  bool _loaded = false;

  int get weeklyGoal => _weeklyGoal;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get isLoaded => _loaded;

  /// Optional display name captured during first-launch onboarding, shown
  /// in the Dashboard greeting ("Merhaba, [İsim]"). Null/empty if skipped.
  String? get userName => _userName;

  /// Whether the user has already been shown (or skipped) the first-launch
  /// onboarding name dialog.
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// Manually-selected UI language ('tr'/'en'), or null to follow the
  /// device's system locale (with English as the ultimate fallback).
  String? get languageCode => _languageCode;

  /// Key of the program (e.g. `builtin:full_body_beginner` or `custom:3`)
  /// used for the Dashboard's sequential "next day" auto-suggestion.
  String? get activeProgramKey => _activeProgramKey;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _weeklyGoal = prefs.getInt(_keyWeeklyGoal) ?? 3;
    _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    _vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;
    _activeProgramKey = prefs.getString(_keyActiveProgramKey);
    _languageCode = prefs.getString(_keyLanguageCode);
    _userName = prefs.getString(_keyUserName);
    _hasCompletedOnboarding = prefs.getBool(_keyHasCompletedOnboarding) ?? false;
    _loaded = true;
    notifyListeners();
  }

  /// Saves the optional onboarding name (or clears it if null/empty) and
  /// marks onboarding as completed so the dialog isn't shown again.
  Future<void> completeOnboarding(String? name) async {
    final trimmed = name?.trim();
    _userName = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    _hasCompletedOnboarding = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_userName == null) {
      await prefs.remove(_keyUserName);
    } else {
      await prefs.setString(_keyUserName, _userName!);
    }
    await prefs.setBool(_keyHasCompletedOnboarding, true);
  }

  Future<void> setLanguageCode(String? code) async {
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_keyLanguageCode);
    } else {
      await prefs.setString(_keyLanguageCode, code);
    }
  }

  Future<void> setActiveProgramKey(String? key) async {
    _activeProgramKey = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (key == null) {
      await prefs.remove(_keyActiveProgramKey);
    } else {
      await prefs.setString(_keyActiveProgramKey, key);
    }
  }

  Future<void> setWeeklyGoal(int goal) async {
    _weeklyGoal = goal;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWeeklyGoal, goal);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrationEnabled, enabled);
  }

  /// Resets weekly goal / rest-timer / active-program preferences to their
  /// defaults, used by the "Reset all data" action in Settings. The chosen
  /// UI language is intentionally left untouched.
  Future<void> resetToDefaults() async {
    _weeklyGoal = 3;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _activeProgramKey = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWeeklyGoal);
    await prefs.remove(_keySoundEnabled);
    await prefs.remove(_keyVibrationEnabled);
    await prefs.remove(_keyActiveProgramKey);
  }
}
