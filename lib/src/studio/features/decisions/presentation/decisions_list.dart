import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../shared/layout/master_detail.dart';
import '../../../shared/layout/studio_layout.dart';
import '../../../shared/person_name.dart';
import '../../../shared/person_text.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../../inbox/state/inbox_state.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../data/decisions_repository.dart';
import 'decision_card.dart';
import 'decisions_strings.dart';
import '../../../core/l10n/studio_strings.dart';

/// Decisions with Open and Answered tabs, as a list of cards.
class DecisionsList extends ConsumerWidget {
  const DecisionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wide: the list on the left, the decision with its options on the right.
    // A phone keeps the cards in one list.
    return MasterDetail(
      masterWidth: 400,
      onPush: (id) {},
      masterBuilder: (context, selected, open) =>
          _list(context, ref, selected, open),
      detailBuilder: (context, id) => _DecisionDetail(decisionId: id),
      emptyDetail: MasterDetailEmpty(
        icon: Icons.help_outline,
        text: DecisionsStrings.of(context).pickToOpen,
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    String? selected,
    void Function(String id) open,
  ) {
    final wide = context.isWideScreen;
    final t = DecisionsStrings.of(context);
    final filter = ref.watch(decisionsStatusFilterProvider);
    final answeredTab = filter == 'Answered';
    final value = ref.watch(decisionsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
          child: SegmentedButton<String>(
            key: const ValueKey('decisions-filter'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'Open',
                label: Text(t.tabOpen),
                icon: const Icon(Icons.help_outline, size: 16),
              ),
              ButtonSegment(
                value: 'Answered',
                label: Text(t.tabAnswered),
                icon: const Icon(Icons.check_circle_outline, size: 16),
              ),
            ],
            selected: {answeredTab ? 'Answered' : 'Open'},
            onSelectionChanged: (v) =>
                ref.read(decisionsStatusFilterProvider.notifier).state =
                    v.first,
          ),
        ),
        const SizedBox(height: StudioSpacing.sm),
        Expanded(
          child: StudioAsyncView<PagedState<StudioDecision>>(
            value: value,
            onRetry: () => ref.invalidate(decisionsProvider),
            isEmpty: (d) => d.items.isEmpty,
            empty: StudioEmptyConfig(
              purpose: answeredTab
                  ? t.emptyAnsweredPurpose
                  : t.emptyOpenPurpose,
              firstStep: answeredTab
                  ? t.emptyAnsweredFirstStep
                  : t.emptyOpenFirstStep,
              icon: Icons.help_outline,
            ),
            builder: (context, d) => RefreshIndicator(
              onRefresh: () => ref.read(decisionsProvider.notifier).refresh(),
              child: ListView(
                key: const ValueKey('decisions-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(
                  wide ? StudioSpacing.sm : StudioSpacing.gutter,
                ),
                children: [
                  if (wide)
                    for (final dec in d.items)
                      _DecisionRow(
                        key: ValueKey('dr-${dec.id}'),
                        decision: dec,
                        selected: dec.id == selected,
                        onTap: () => open(dec.id),
                      )
                  else
                    for (final dec in d.items)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: StudioSpacing.md,
                        ),
                        child: DecisionCard(
                          key: ValueKey('dc-${dec.id}'),
                          decision: dec,
                          onAnswer: (i, note, rid, {text}) => ref
                              .read(decisionsProvider.notifier)
                              .answer(
                                dec.id,
                                i,
                                note: note,
                                text: text,
                                requestId: rid,
                              ),
                        ),
                      ),
                  if (d.hasMore)
                    Center(
                      child: Tooltip(
                        message: StudioStrings.of(context).showMore,
                        child: TextButton(
                          onPressed: () =>
                              ref.read(decisionsProvider.notifier).loadMore(),
                          child: const Icon(Icons.expand_more),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The right pane on a wide window: the decision as the list holds it, so an
/// answer shows at once.
class _DecisionDetail extends ConsumerWidget {
  const _DecisionDetail({required this.decisionId});

  final String decisionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(decisionsProvider).valueOrNull?.items ?? const [];
    final dec = items.where((d) => d.id == decisionId).firstOrNull;
    if (dec == null) {
      return MasterDetailEmpty(
        icon: Icons.help_outline,
        text: DecisionsStrings.of(context).pickToOpen,
      );
    }
    return StudioPage(
      child: ListView(
        key: const ValueKey('decision-detail'),
        padding: const EdgeInsets.all(StudioSpacing.xl),
        children: [
          DecisionCard(
            key: ValueKey('dc-${dec.id}'),
            decision: dec,
            onAnswer: (i, note, rid, {text}) => ref
                .read(decisionsProvider.notifier)
                .answer(dec.id, i, note: note, text: text, requestId: rid),
          ),
        ],
      ),
    );
  }
}

/// One decision as a line in the wide list: the question, who raised it and
/// how long it has waited.
class _DecisionRow extends ConsumerWidget {
  const _DecisionRow({
    super.key,
    required this.decision,
    required this.selected,
    required this.onTap,
  });

  final StudioDecision decision;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DecisionsStrings.of(context);
    final s = InboxStrings.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(studioNowProvider)();
    final d = decision;
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
      child: Material(
        color: selected ? StudioColors.blushPale : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioRadii.md),
          side: BorderSide(
            color: selected ? StudioColors.berryPink : StudioColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(StudioSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonText(
                    d.question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(
                    [
                      t.raisedBy(personName(d.raisedBy)),
                      if (d.status == DecisionStatus.open)
                        t.waiting(waitedText(s, d.waitingSince, now)),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
