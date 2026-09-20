import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';

/// One number, stated plainly, with the thing it measures underneath.
///
/// The unit sits on the baseline beside the figure rather than inside it, so
/// the number itself stays a single tabular run and columns of tiles line up.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.icon,
  });

  final String value;
  final String label;
  final String? unit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final atlas = context.atlas;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AtlasSpace.lg),
      decoration: BoxDecoration(
        color: atlas.surface,
        borderRadius: BorderRadius.circular(AtlasRadius.card),
        border: isDark ? Border.all(color: atlas.line) : null,
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: AtlasTokens.lightShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: atlas.teamMark),
            const SizedBox(height: AtlasSpace.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AtlasTypography.display.copyWith(
                      color: atlas.textPrimary,
                    ),
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AtlasSpace.sm),
                Text(
                  unit!,
                  style: AtlasTypography.label.copyWith(
                    color: atlas.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AtlasSpace.xs),
          Text(
            label,
            style: AtlasTypography.label.copyWith(color: atlas.textMuted),
          ),
        ],
      ),
    );
  }
}
