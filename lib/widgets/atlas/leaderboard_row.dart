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
    this.detail,
  });

  final String id;
  final String name;
  final String metric;

  /// An optional line beneath the name saying what the metric measures,
  /// e.g. "12 workouts". Renders nothing when null.
  final String? detail;
}

/// A results line: the placing, who earned it, and the number that did.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.entry,
    this.isViewer = false,
    this.onTap,
    this.trailing,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isViewer;

  /// Makes the whole row tappable with a visible ink response. Null keeps
  /// the row exactly as it was before this hook existed.
  final VoidCallback? onTap;

  /// An optional widget after the metric, e.g. a trend indicator. Null
  /// renders nothing extra.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final content = Row(
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
          child: entry.detail == null
              ? Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AtlasTypography.body.copyWith(color: atlas.textPrimary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtlasTypography.body
                          .copyWith(color: atlas.textPrimary),
                    ),
                    const SizedBox(height: AtlasSpace.xs),
                    Text(
                      entry.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtlasTypography.micro
                          .copyWith(color: atlas.textMuted),
                    ),
                  ],
                ),
        ),
        Text(
          entry.metric,
          style: AtlasTypography.numeric(AtlasTypography.label).copyWith(
            color: atlas.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AtlasSpace.md),
          trailing!,
        ],
        const SizedBox(width: AtlasSpace.lg),
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
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
    this.onEntryTap,
    this.trailingBuilder,
  });

  final List<LeaderboardEntry> entries;
  final String? viewerId;

  /// Called with the tapped entry. Null (the default) leaves every row
  /// non-interactive, exactly as before this hook existed.
  final void Function(LeaderboardEntry entry)? onEntryTap;

  /// Builds an optional trailing widget per row, e.g. a trend indicator.
  /// Null (the default) renders nothing extra.
  final Widget Function(LeaderboardEntry entry)? trailingBuilder;

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
                onTap: onEntryTap == null
                    ? null
                    : () => onEntryTap!(entries[i]),
                trailing: trailingBuilder?.call(entries[i]),
              ),
            ),
        ],
      ),
    );
  }
}
