import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/verdict_badge.dart';
import '../review_strings.dart';
import '../state/version_review_state.dart';
import 'review_helpers.dart';

/// A titled white card used by every section of the version page.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StudioSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StudioRadii.md),
        border: Border.all(color: StudioColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ?trailing,
            ],
          ),
          const SizedBox(height: StudioSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// The sell judge: verdict word, score, why it sells, what stops it, fixes.
class VerdictSection extends StatelessWidget {
  const VerdictSection({super.key, required this.version});

  final PieceVersion version;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final theme = Theme.of(context);
    final v = version.verdict;
    if (v == null) {
      return SectionCard(
        title: t.verdictTitle,
        child: Text(t.noVerdict, key: const ValueKey('no-verdict')),
      );
    }
    final badge = uiVerdict(v.verdict);
    return SectionCard(
      title: t.verdictTitle,
      trailing: badge != null
          ? VerdictBadge(verdict: badge)
          : Text(
              t.verdictBlocked,
              key: const ValueKey('verdict-blocked'),
              style: theme.textTheme.labelMedium,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.sell != null)
            Text(
              t.sellScore(v.sell!.toStringAsFixed(1)),
              key: const ValueKey('verdict-score'),
              style: theme.textTheme.titleSmall,
            ),
          if (v.stale) ...[
            const SizedBox(height: StudioSpacing.sm),
            Text(
              t.verdictOutdated,
              key: const ValueKey('verdict-stale'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: StudioColors.warning,
              ),
            ),
          ],
          if ((v.why ?? '').isNotEmpty) ...[
            const SizedBox(height: StudioSpacing.md),
            _Labelled(label: t.whySells, text: v.why!),
          ],
          if ((v.stops ?? '').isNotEmpty) ...[
            const SizedBox(height: StudioSpacing.md),
            _Labelled(label: t.whatStops, text: v.stops!),
          ],
          if (v.fixes.isNotEmpty) ...[
            const SizedBox(height: StudioSpacing.md),
            Text(t.fixesTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: StudioSpacing.xs),
            for (final f in v.fixes)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.xs),
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
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: StudioSpacing.xs),
      Text(text),
    ],
  );
}

/// Rating stats (average, spread, who is still to rate) and my own rating.
class RatingsSection extends StatelessWidget {
  const RatingsSection({super.key, required this.version});

  final PieceVersion version;

  @override
  Widget build(BuildContext context) {
    final t = ReviewStrings.of(context);
    final theme = Theme.of(context);
    final r = version.rating;
    final mine = version.myRating;
    final top = r.distribution.fold<int>(0, (a, b) => a > b ? a : b);
    return SectionCard(
      title: t.ratingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.n == 0)
            Text(t.noRatingsYet, key: const ValueKey('no-ratings'))
          else ...[
            Text(
              t.ratingSummary(r.avg.toStringAsFixed(1), r.n),
              key: const ValueKey('rating-summary'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: StudioSpacing.md),
            for (var s = 5; s >= 1; s--)
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text('$s', textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: StudioSpacing.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: top == 0
                              ? 0
                              : (s <= r.distribution.length
                                        ? r.distribution[s - 1]
                                        : 0) /
                                    top,
                          minHeight: 8,
                          backgroundColor: StudioColors.blushPale,
                          color: StudioColors.berryPink,
                        ),
                      ),
                    ),
                    const SizedBox(width: StudioSpacing.sm),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${s <= r.distribution.length ? r.distribution[s - 1] : 0}',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (r.waiting.isNotEmpty) ...[
            const SizedBox(height: StudioSpacing.sm),
            Text(
              t.stillToRate(r.waiting.map((p) => p.fullName).join(', ')),
              key: const ValueKey('rating-waiting'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const Divider(height: StudioSpacing.xl),
          if (mine == null)
            Text(t.notRatedByMe, key: const ValueKey('my-rating-none'))
          else ...[
            Text(
              t.yourRating(mine.score, scoreText(t, mine.score)),
              key: const ValueKey('my-rating'),
              style: theme.textTheme.titleSmall,
            ),
            if ((mine.comment ?? '').isNotEmpty) ...[
              const SizedBox(height: StudioSpacing.xs),
              Text(mine.comment!),
            ],
          ],
        ],
      ),
    );
  }
}

/// Comments on the version. A story-frame comment shows the frame it is about.
class CommentsSection extends ConsumerWidget {
  const CommentsSection({super.key, required this.version});

  final PieceVersion version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReviewStrings.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(versionCommentsProvider(version.id));
    final frames = {for (final f in version.frames) f.position: f};
    return SectionCard(
      title: '${t.commentsTitle} (${version.commentsCount})',
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(StudioSpacing.md),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => Row(
          children: [
            Expanded(
              child: Text(
                t.commentsLoadFailed,
                key: const ValueKey('comments-error'),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(versionCommentsProvider(version.id)),
              child: Text(t.tryAgain),
            ),
          ],
        ),
        data: (items) => items.isEmpty
            ? Text(t.noComments, key: const ValueKey('no-comments'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in items)
                    Padding(
                      key: ValueKey('comment-${c.id}'),
                      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.frame != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: StudioSpacing.md,
                              ),
                              child: Column(
                                children: [
                                  StudioThumb(
                                    key: ValueKey('comment-frame-${c.id}'),
                                    media: frames[c.frame]?.asset.media,
                                    width: 40,
                                    height: 56,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.frameLabel(c.frame!),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c.person.fullName} · ${t.when(c.at)}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: StudioColors.plumMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(c.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
