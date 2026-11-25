import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/person_text.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/verdict_badge.dart';
import '../../../core/theme/studio_status_colors.dart' show Verdict;
import '../../review/data/review_repository.dart';
import '../state/inbox_state.dart';
import 'inbox_hub.dart';
import 'inbox_strings.dart';
import 'ui_helpers.dart';

/// The versions waiting for the founder's yes, oldest first. A tap opens the
/// version screen (`/inbox/approve/<id>`), where approve and fix live.
class ToApproveList extends ConsumerWidget {
  const ToApproveList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = InboxStrings.of(context);
    final value = ref.watch(toApproveProvider);
    final now = ref.watch(studioNowProvider)();

    return StudioAsyncView<PagedState<ApproveCard>>(
      value: value,
      onRetry: () => ref.invalidate(toApproveProvider),
      empty: StudioEmptyConfig(
        purpose: s.approveEmptyPurpose,
        firstStep: s.approveEmptyFirstStep,
        icon: Icons.verified_outlined,
      ),
      isEmpty: (d) => d.items.isEmpty,
      builder: (context, d) => RefreshIndicator(
        onRefresh: () => ref.read(toApproveProvider.notifier).refresh(),
        child: ListView(
          key: const ValueKey('approve-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          children: [
            NextStepLine(s.nextStepApprove),
            const SizedBox(height: StudioSpacing.md),
            for (final card in d.items)
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.md),
                child: ApproveRow(card: card, now: now),
              ),
            if (d.hasMore)
              Center(
                child: TextButton(
                  key: const ValueKey('approve-more'),
                  onPressed: () =>
                      ref.read(toApproveProvider.notifier).loadMore(),
                  child: Text(s.loadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ApproveRow extends StatelessWidget {
  const ApproveRow({super.key, required this.card, required this.now});

  final ApproveCard card;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final piece = card.piece;
    final media = card.version.files.isNotEmpty
        ? card.version.files.first.media
        : piece.picture;
    final slot = card.posts.isNotEmpty ? card.posts.first.slotTime : null;
    final flavours = piece.noFlavour
        ? ''
        : piece.flavours.map((f) => f.name).join(', ');
    final verdict = piece.verdict;

    return Card(
      key: ValueKey('approve-${card.version.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(InboxPaths.approve(card.version.id)),
        child: Padding(
          padding: const EdgeInsets.all(StudioSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudioThumb(
                media: media,
                width: 72,
                height: 90,
                radius: BorderRadius.circular(StudioRadii.sm),
              ),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PersonText(
                      piece.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (flavours.isNotEmpty)
                      Text(flavours, style: theme.textTheme.bodySmall),
                    const SizedBox(height: StudioSpacing.xs),
                    Text(
                      slot == null ? s.noSlot : slotText(s, slot),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: StudioSpacing.sm),
                    Wrap(
                      spacing: StudioSpacing.sm,
                      runSpacing: StudioSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (verdict == null)
                          Text(s.notJudged, style: theme.textTheme.bodySmall)
                        else ...[
                          _verdictChip(context, verdict),
                          if (verdict.sell != null)
                            Text(
                              s.sellScore(verdict.sell!.toStringAsFixed(1)),
                              style: theme.textTheme.bodySmall,
                            ),
                          if (verdict.stale)
                            Text(
                              s.stale,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: StudioColors.warning,
                              ),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: StudioSpacing.xs),
                    Text(
                      s.waiting(waitedText(s, card.waitingSince, now)),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: StudioColors.plumMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verdictChip(BuildContext context, VerdictBrief v) {
    final mapped = switch (v.label) {
      VerdictLabel.rUN => Verdict.run,
      VerdictLabel.fIX => Verdict.fix,
      VerdictLabel.dROP => Verdict.drop,
      _ => null,
    };
    if (mapped != null) return VerdictBadge(verdict: mapped);
    return Text(
      v.label == VerdictLabel.bLOCKED ? 'BLOCKED' : '-',
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
