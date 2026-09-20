import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/team_palette.dart';

/// Scopes a team's kit colour to a subtree.
///
/// This is the whole interface between team data and the component layer.
/// Wrap a team screen in it and every Atlas component inside picks up the
/// right colour; components read `context.atlas.teamFill` and never learn
/// where the team came from.
class TeamTheme extends StatelessWidget {
  const TeamTheme({super.key, required this.kit, required this.child});

  final KitColor kit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = swatchOf(kit);
    final atlas = theme.extension<AtlasColors>()!.copyWith(
          teamFill: swatch.fill,
          teamOnFill: swatch.onFill,
          teamMark: swatch.markFor(theme.brightness),
        );
    return Theme(
      data: theme.copyWith(
        extensions: <ThemeExtension<dynamic>>[atlas],
      ),
      child: child,
    );
  }
}
