import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import 'team_crest.dart';

/// The team's colour, stated at full strength.
///
/// The header is the one loud surface in the app. It uses the kit fill and
/// its paired foreground, which the palette guarantees clears 4.5:1, so text
/// here needs no extra scrim.
class TeamHeader extends StatelessWidget {
  const TeamHeader({
    super.key,
    required this.teamName,
    required this.memberSummary,
    this.description,
  });

  final String teamName;
  final String memberSummary;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AtlasSpace.xl),
      decoration: BoxDecoration(
        color: atlas.teamFill,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // A crest on a same-coloured field needs separating from it,
              // so it wears a ring in the header's own foreground.
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: atlas.teamOnFill.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: TeamCrest(
                  teamName: teamName,
                  size: CrestSize.large,
                ),
              ),
              const SizedBox(width: AtlasSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamName,
                      style: AtlasTypography.title.copyWith(
                        color: atlas.teamOnFill,
                      ),
                    ),
                    const SizedBox(height: AtlasSpace.xs),
                    Text(
                      memberSummary,
                      style: AtlasTypography.label.copyWith(
                        color: atlas.teamOnFill.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AtlasSpace.lg),
            Text(
              description!,
              style: AtlasTypography.body.copyWith(
                color: atlas.teamOnFill.withValues(alpha: 0.82),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
