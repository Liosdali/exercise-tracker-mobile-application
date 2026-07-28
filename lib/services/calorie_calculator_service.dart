/// Estimates calories burned during a workout using the standard MET
/// (Metabolic Equivalent of Task) formula:
///
///   Calories = (MET * 3.5 * weightKg / 200) * durationMinutes
///
/// Defaults to MET 5.5, a commonly used value for general
/// resistance/weight-training sessions.
class CalorieCalculatorService {
  static const double defaultMet = 5.5;

  /// Fallback body weight (kg) used when the user hasn't filled in their
  /// profile or logged any body measurements yet.
  static const double fallbackWeightKg = 70;

  const CalorieCalculatorService._();

  static double calculateCalories({
    double met = defaultMet,
    required double weightKg,
    required double durationMinutes,
  }) {
    if (durationMinutes <= 0 || weightKg <= 0) return 0;
    return (met * 3.5 * weightKg / 200) * durationMinutes;
  }
}
