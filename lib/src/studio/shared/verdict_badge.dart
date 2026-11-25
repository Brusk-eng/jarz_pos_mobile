import 'package:flutter/material.dart';

import '../core/l10n/studio_strings.dart';
import '../core/theme/studio_status_colors.dart';
import '../core/theme/studio_tokens.dart';

/// RUN, FIX or DROP from the sell judge. The word is always shown, never
/// colour alone.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final colors = verdictColors[verdict]!;
    final label = StudioStrings.of(context).verdict(verdict.name);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.md,
        vertical: StudioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(StudioRadii.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.foreground,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
