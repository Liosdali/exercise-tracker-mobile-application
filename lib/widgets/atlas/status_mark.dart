import 'package:flutter/material.dart';

import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';

enum AtlasStatus { success, warn, danger, info }

/// A small coloured mark with its meaning spelled out beside it.
///
/// Status colour only ever appears at this scale — a dot or a 16dp icon and a
/// line of text — so it never competes with a team's kit colour, which only
/// fills large fields.
class StatusMark extends StatelessWidget {
  const StatusMark({
    super.key,
    required this.status,
    required this.label,
    this.icon,
  });

  final AtlasStatus status;
  final String label;
  final IconData? icon;

  static Color colorOf(BuildContext context, AtlasStatus status) {
    final atlas = context.atlas;
    return switch (status) {
      AtlasStatus.success => atlas.success,
      AtlasStatus.warn => atlas.warn,
      AtlasStatus.danger => atlas.danger,
      AtlasStatus.info => atlas.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorOf(context, status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 16, color: color)
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: AtlasSpace.sm),
        Flexible(
          child: Text(
            label,
            style: AtlasTypography.label.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
