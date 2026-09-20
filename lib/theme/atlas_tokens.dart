import 'package:flutter/animation.dart';

/// Raw colour tokens for both schemes.
///
/// Every value here is measured against the 4.5:1 contrast floor in
/// `test/theme/contrast_test.dart`. Change a value and the test decides
/// whether the change ships.
abstract final class AtlasTokens {
  // Dark scheme chrome. Blue-leaning graphite, not a tinted black.
  static const Color darkInk = Color(0xFF161A21);
  static const Color darkSurface = Color(0xFF1E232C);
  static const Color darkSurfaceRaised = Color(0xFF262C37);
  static const Color darkLine = Color(0xFF333A47);
  static const Color darkTextPrimary = Color(0xFFEEF1F6);
  static const Color darkTextMuted = Color(0xFF98A1B0);

  // Light scheme chrome.
  static const Color lightInk = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightLine = Color(0xFFDDE2EA);
  static const Color lightTextPrimary = Color(0xFF171B22);
  static const Color lightTextMuted = Color(0xFF5D6675);

  // Status hues. Small marks only: a dot, an icon, a line of text.
  static const Color darkSuccess = Color(0xFF3FBF87);
  static const Color darkWarn = Color(0xFFE0A62E);
  static const Color darkDanger = Color(0xFFE16151);
  static const Color darkInfo = Color(0xFF4C8DF0);

  static const Color lightSuccess = Color(0xFF1E7A52);
  static const Color lightWarn = Color(0xFF8A6410);
  static const Color lightDanger = Color(0xFFB33A2E);
  static const Color lightInfo = Color(0xFF2B5FB8);
}

/// The 4pt spacing scale. `xl` is the rhythm between sections.
abstract final class AtlasSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Radius carries role rather than being one value everywhere.
abstract final class AtlasRadius {
  static const double field = 8;
  static const double card = 14;
  static const double sheet = 24;
  static const double rail = 2;
}

/// The app spends its ambient motion once, on the leaderboard reorder.
abstract final class AtlasMotion {
  static const Duration reorder = Duration(milliseconds: 240);
  static const Curve reorderCurve = Curves.easeOutCubic;
}
