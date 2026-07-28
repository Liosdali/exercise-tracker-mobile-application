import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../models/user_profile.dart';

/// Holds the user's current body profile (height/age/gender/weight/body-fat),
/// backed by the `user_profile` table. Used as the primary weight source for
/// calorie calculations.
class UserProfileProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  UserProfile? _profile;
  bool _loaded = false;

  UserProfile? get profile => _profile;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _profile = await _db.getUserProfile();
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile({
    double? heightCm,
    int? age,
    String? gender,
    double? weightKg,
    double? bodyFatPercent,
  }) async {
    final updated = UserProfile(
      heightCm: heightCm,
      age: age,
      gender: gender,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _db.saveUserProfile(updated);
    _profile = updated;
    notifyListeners();
  }
}
