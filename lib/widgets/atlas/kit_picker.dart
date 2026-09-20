import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/atlas_colors.dart';
import '../../theme/atlas_tokens.dart';
import '../../theme/atlas_typography.dart';
import '../../theme/team_palette.dart';

/// The localised name of a kit colour.
String kitColorName(AppLocalizations l10n, KitColor kit) => switch (kit) {
      KitColor.crimson => l10n.kitColorCrimson,
      KitColor.claret => l10n.kitColorClaret,
      KitColor.violet => l10n.kitColorViolet,
      KitColor.royal => l10n.kitColorRoyal,
      KitColor.teal => l10n.kitColorTeal,
      KitColor.forest => l10n.kitColorForest,
      KitColor.gold => l10n.kitColorGold,
      KitColor.steel => l10n.kitColorSteel,
    };

/// Eight swatches, one of them chosen.
///
/// The selected swatch carries a check mark as well as a ring, because the
/// spec forbids colour from being the only carrier of meaning — a
/// colour-blind user must be able to see which one is picked.
class KitPicker extends StatelessWidget {
  const KitPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final KitColor selected;
  final ValueChanged<KitColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final atlas = context.atlas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.teamColorLabel,
          style: AtlasTypography.heading.copyWith(color: atlas.textPrimary),
        ),
        const SizedBox(height: AtlasSpace.sm),
        Text(
          l10n.teamColorHint,
          style: AtlasTypography.body.copyWith(color: atlas.textMuted),
        ),
        const SizedBox(height: AtlasSpace.lg),
        Wrap(
          spacing: AtlasSpace.md,
          runSpacing: AtlasSpace.md,
          children: [
            for (final kit in KitColor.values)
              _Swatch(
                key: ValueKey('kit-${swatchOf(kit).slug}'),
                kit: kit,
                isSelected: kit == selected,
                label: kitColorName(l10n, kit),
                onTap: () => onChanged(kit),
              ),
          ],
        ),
        const SizedBox(height: AtlasSpace.md),
        Text(
          kitColorName(l10n, selected),
          style: AtlasTypography.label.copyWith(color: atlas.textPrimary),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.kit,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  final KitColor kit;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = swatchOf(kit);
    final atlas = context.atlas;
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: swatch.fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? atlas.textPrimary : atlas.line,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check, size: 22, color: swatch.onFill)
              : null,
        ),
      ),
    );
  }
}
