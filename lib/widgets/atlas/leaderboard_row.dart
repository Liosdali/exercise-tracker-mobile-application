import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import 'team_crest.dart';

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.metric,
  });

  final String id;
  final String name;
  final String metric;
}

/// A results line: the placing, who earned it, and the number that did.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.entry,
    this.isViewer = false,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isViewer;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    return Row(
      children: [
        if (isViewer)
          Container(
            key: const ValueKey('leaderboard-rail'),
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: atlas.teamMark,
              borderRadius: BorderRadius.circular(AtlasRadius.rail),
            ),
          )
        else
          const SizedBox(width: 4),
        const SizedBox(width: AtlasSpace.lg),
        SizedBox(
          width: 44,
          child: Text(
            '$rank',
            textAlign: TextAlign.right,
            style: AtlasTypography.display.copyWith(
              fontSize: 28,
              color: isViewer ? atlas.teamMark : atlas.textMuted,
            ),
          ),
        ),
        const SizedBox(width: AtlasSpace.lg),
        TeamCrest(teamName: entry.name, size: CrestSize.small),
        const SizedBox(width: AtlasSpace.md),
        Expanded(
          child: Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AtlasTypography.body.copyWith(color: atlas.textPrimary),
          ),
        ),
        Text(
          entry.metric,
          style: AtlasTypography.numeric(AtlasTypography.label).copyWith(
            color: atlas.textPrimary,
          ),
        ),
        const SizedBox(width: AtlasSpace.lg),
      ],
    );
  }
}

/// The app's one piece of ambient motion.
///
/// Rows are positioned by index and animate when that index changes, so a
/// refresh that moves someone up the table shows the move rather than
/// redrawing silently. Nothing else in the app animates on its own.
class AnimatedLeaderboard extends StatelessWidget {
  const AnimatedLeaderboard({
    super.key,
    required this.entries,
    this.viewerId,
  });

  final List<LeaderboardEntry> entries;
  final String? viewerId;

  static const double rowHeight = 72;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: entries.length * rowHeight,
      child: Stack(
        children: [
          for (var i = 0; i < entries.length; i++)
            AnimatedPositioned(
              key: ValueKey(entries[i].id),
              duration: reduceMotion ? Duration.zero : AtlasMotion.reorder,
              curve: AtlasMotion.reorderCurve,
              top: i * rowHeight,
              left: 0,
              right: 0,
              height: rowHeight,
              child: LeaderboardRow(
                rank: i + 1,
                entry: entries[i],
                isViewer: entries[i].id == viewerId,
              ),
            ),
        ],
      ),
    );
  }
}
