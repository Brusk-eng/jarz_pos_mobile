import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/studio_labels.dart';
import '../core/l10n/studio_strings.dart';
import '../core/theme/studio_tokens.dart';

/// The per-screen help sheet: a title and 3 to 5 lines, opened from the "?"
/// in the app bar.
class HowThisWorksSheet extends StatelessWidget {
  const HowThisWorksSheet({
    super.key,
    required this.title,
    required this.lines,
    this.detail = false,
  });

  final String title;
  final List<String> lines;

  /// True on a screen opened from a list: it has a Back arrow instead of the
  /// tabs, and the sheet says so.
  final bool detail;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<String> lines,
  }) {
    final detail = GoRouter.maybeOf(context)?.canPop() ?? false;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) =>
          HowThisWorksSheet(title: title, lines: lines, detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.gutter,
          0,
          StudioSpacing.gutter,
          StudioSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.howThisWorks, style: theme.textTheme.bodySmall),
            const SizedBox(height: StudioSpacing.xs),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: StudioSpacing.md),
            for (final line in [
              ...lines,
              if (detail) StudioLabels.of(context).backBarNote,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: StudioColors.berryPink,
                      ),
                    ),
                    const SizedBox(width: StudioSpacing.md),
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: StudioSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.gotIt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
