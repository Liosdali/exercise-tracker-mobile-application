import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import 'team_crest.dart';

/// One thing somebody on the team did.
///
/// The kit-coloured spine down the leading edge is how a feed of several
/// teams stays legible: the colour says whose team, the crest and name say
/// who.
class FeedItem extends StatelessWidget {
  const FeedItem({
    super.key,
    required this.actor,
    required this.action,
    required this.timestamp,
    this.metric,
    this.onTap,
  });

  final String actor;
  final String action;
  final String timestamp;
  final String? metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: atlas.surface,
      borderRadius: BorderRadius.circular(AtlasRadius.card),
      elevation: isDark ? 0 : 2,
      shadowColor: isDark ? Colors.transparent : const Color(0x1A171B22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AtlasRadius.card),
            border: isDark ? Border.all(color: atlas.line) : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  key: const ValueKey('feed-spine'),
                  width: 4,
                  decoration: BoxDecoration(color: atlas.teamMark),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AtlasSpace.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TeamCrest(teamName: actor, size: CrestSize.small),
                        const SizedBox(width: AtlasSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                actor,
                                style: AtlasTypography.label.copyWith(
                                  color: atlas.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AtlasSpace.xs),
                              Text(
                                action,
                                style: AtlasTypography.body.copyWith(
                                  color: atlas.textPrimary,
                                ),
                              ),
                              if (metric != null) ...[
                                const SizedBox(height: AtlasSpace.sm),
                                Text(
                                  metric!,
                                  key: const ValueKey('feed-metric'),
                                  style: AtlasTypography.numeric(
                                    AtlasTypography.label,
                                  ).copyWith(color: atlas.teamMark),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AtlasSpace.md),
                        Text(
                          timestamp,
                          style: AtlasTypography.micro.copyWith(
                            color: atlas.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
