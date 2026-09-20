import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_typography.dart';

enum CrestSize { small, medium, large }

/// A team's initial on its kit colour.
///
/// The letter is not decoration: the spec forbids colour from being the only
/// carrier of team identity, so the crest always states the initial and
/// callers place the full name beside it.
class TeamCrest extends StatelessWidget {
  const TeamCrest({
    super.key,
    required this.teamName,
    this.size = CrestSize.medium,
  });

  final String teamName;
  final CrestSize size;

  static double diameterOf(CrestSize size) => switch (size) {
        CrestSize.small => 28,
        CrestSize.medium => 40,
        CrestSize.large => 64,
      };

  static double _fontSizeOf(CrestSize size) => switch (size) {
        CrestSize.small => 13,
        CrestSize.medium => 18,
        CrestSize.large => 28,
      };

  /// The first character of the trimmed name, or `?` when there is none.
  /// Deliberately not upper-cased: `toUpperCase()` turns Turkish `i` into
  /// `I` rather than `İ`.
  String get _initial {
    final trimmed = teamName.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final diameter = diameterOf(size);
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: atlas.teamFill,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initial,
        style: AtlasTypography.title.copyWith(
          color: atlas.teamOnFill,
          fontSize: _fontSizeOf(size),
          height: 1,
        ),
      ),
    );
  }
}
