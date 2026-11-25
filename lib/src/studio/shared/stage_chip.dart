import 'package:flutter/material.dart';

import '../core/l10n/studio_strings.dart';
import '../core/theme/studio_status_colors.dart';
import '../core/theme/studio_tokens.dart';

/// One of the nine piece stages as a small coloured pill.
class StageChip extends StatelessWidget {
  const StageChip({super.key, required this.stage});

  final PieceStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = stageColors[stage]!;
    final label = StudioStrings.of(context).stage(stage.apiName);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.md,
        vertical: StudioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(StudioRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colors.foreground),
      ),
    );
  }
}
