import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../data/decisions_repository.dart';
import 'decision_card.dart';
import 'decisions_strings.dart';

/// Decisions with Open and Answered tabs, as a list of cards.
class DecisionsList extends ConsumerWidget {
  const DecisionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                padding: const EdgeInsets.all(StudioSpacing.gutter),
                children: [
                  for (final dec in d.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
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
                      child: TextButton(
                        onPressed: () =>
                            ref.read(decisionsProvider.notifier).loadMore(),
                        child: const Icon(Icons.expand_more),
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
