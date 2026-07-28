import 'dart:math';

/// Computes body fat percentage using the U.S. Navy circumference method
/// (no scale/calipers required - just tape-measure circumferences).
///
/// Male:   %BF = 495 / (1.0324 - 0.19077*log10(waist - neck) + 0.15456*log10(height)) - 450
/// Female: %BF = 495 / (1.29579 - 0.35004*log10(waist + hip - neck) + 0.22100*log10(height)) - 450
///
/// All measurements in centimeters. Returns `null` if the inputs are
/// insufficient or physiologically invalid (e.g. waist <= neck for men).
class BodyFatCalculatorService {
  const BodyFatCalculatorService._();

  static double _log10(double x) => log(x) / ln10;

  static double? calculate({
    required String gender,
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipCm,
  }) {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return null;

    if (gender == 'female') {
      if (hipCm == null || hipCm <= 0) return null;
      final term = waistCm + hipCm - neckCm;
      if (term <= 0) return null;
      final bodyFat =
          495 / (1.29579 - 0.35004 * _log10(term) + 0.22100 * _log10(heightCm)) - 450;
      return bodyFat.isFinite ? bodyFat : null;
    }

    // Default to the male formula for 'male' or unspecified/other.
    final term = waistCm - neckCm;
    if (term <= 0) return null;
    final bodyFat = 495 / (1.0324 - 0.19077 * _log10(term) + 0.15456 * _log10(heightCm)) - 450;
    return bodyFat.isFinite ? bodyFat : null;
  }
}
