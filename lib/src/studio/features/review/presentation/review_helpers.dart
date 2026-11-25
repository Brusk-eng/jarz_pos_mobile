import 'package:flutter/material.dart';

import '../../../core/theme/studio_status_colors.dart' as sc;
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../../../shared/studio_error_text.dart';
import '../review_strings.dart';
import '../state/action_outcome.dart';

/// The stage as the coloured chip knows it (null for a stage the app does not
/// know yet: the chip is then left out).
sc.PieceStage? uiStage(PieceStage s) {
  for (final x in sc.PieceStage.values) {
    if (x.apiName == s.wire) return x;
  }
  return null;
}

/// RUN, FIX or DROP as the badge knows it (null for BLOCKED or unknown).
sc.Verdict? uiVerdict(VerdictLabel v) => switch (v) {
  VerdictLabel.rUN => sc.Verdict.run,
  VerdictLabel.fIX => sc.Verdict.fix,
  VerdictLabel.dROP => sc.Verdict.drop,
  _ => null,
};

/// What to look at for a version: a story's frames in order, otherwise its
/// files in order.
List<StudioMedia> versionMedia(PieceVersion v) {
  if (v.frames.isNotEmpty) {
    final frames = [...v.frames]..sort((a, b) => a.position - b.position);
    return [
      for (final f in frames)
        if (f.asset.media != null) f.asset.media!,
    ];
  }
  final files = [...v.files]..sort((a, b) => a.position - b.position);
  return [for (final f in files) f.media];
}

/// The title of a rating-feed card: the piece of a version, or the library
/// item's own title.
String rateCardTitle(RateCard c) =>
    c.version?.piece.title ?? c.asset?.title ?? '';

/// What to look at on a rating-feed card.
List<StudioMedia> rateCardMedia(RateCard c) {
  final v = c.version;
  if (v != null) return versionMedia(v);
  final m = c.asset?.media;
  return m == null ? const [] : [m];
}

/// The channel as a plain word ("Feed reel").
String? channelLabel(PostChannel? c) =>
    (c == null || c == PostChannel.unknown) ? null : c.wire;

/// The sentence for a failed action, from the one app-wide mapping. Gate
/// failures are listed in a dialog instead (see [showGateProblems]).
String failureText(BuildContext context, ActionOutcome o) =>
    studioErrorText(context, o.error ?? const StudioUnknownError('failed'));

/// The dialog that lists why a version cannot be approved yet, in the
/// server's own plain words.
Future<void> showGateProblems(
  BuildContext context,
  ReviewStrings t,
  List<StudioProblem> problems,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const ValueKey('gate-dialog'),
      title: Text(t.gateFailedTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.gateFailedIntro),
            const SizedBox(height: StudioSpacing.md),
            for (final p in problems)
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
                        color: StudioColors.danger,
                      ),
                    ),
                    const SizedBox(width: StudioSpacing.md),
                    Expanded(child: Text(p.message)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(t.gotIt),
        ),
      ],
    ),
  );
}

/// A 1 to 5 score as a short plain label.
String scoreText(ReviewStrings t, int score) => t.scoreLabel(score.clamp(1, 5));

/// Whether the server allowed [action] on this version.
bool can(PieceVersion v, String action) => v.actions.contains(action);
