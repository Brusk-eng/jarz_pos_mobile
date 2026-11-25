import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/roles/studio_role.dart' show StudioRole;
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../../session/state/studio_session_notifier.dart';
import '../data/ideas_repository.dart';
import 'idea_card.dart';
import 'idea_forms.dart';
import 'my_ideas_screen.dart';
import 'ideas_strings.dart';
import '../../../core/l10n/studio_strings.dart';

/// The Ideas inbox: To decide / Kept / Dropped, a New idea button for anyone.
class IdeasList extends ConsumerWidget {
  const IdeasList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = IdeasStrings.of(context);
    final filter = ref.watch(ideasStatusFilterProvider) ?? 'Open';
    final value = ref.watch(ideasProvider);
    final role = ref.watch(studioSessionProvider).valueOrNull?.primaryRole;
    final hasMine = role == StudioRole.creator || role == StudioRole.story;

    final firstStep = switch (filter) {
      'Kept' => t.emptyKeptFirstStep,
      'Dropped' => t.emptyDroppedFirstStep,
      _ => t.emptyFirstStep,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.gutter),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  key: const ValueKey('ideas-filter'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'Open', label: Text(hasMine ? t.tabOpenWaiting : t.tabOpen),
                    ),
                    ButtonSegment(value: 'Kept', label: Text(t.tabKept)),
                    ButtonSegment(value: 'Dropped', label: Text(t.tabDropped)),
                  ],
                  selected: {filter},
                  onSelectionChanged: (v) =>
                      ref.read(ideasStatusFilterProvider.notifier).state =
                          v.first,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            StudioSpacing.sm,
            StudioSpacing.gutter,
            0,
          ),
          child: Wrap(
            spacing: StudioSpacing.sm,
            runSpacing: StudioSpacing.xs,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('idea-new'),
                onPressed: () => showProposeSheet(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.newIdea),
              ),
              if (hasMine)
                TextButton.icon(
                  key: const ValueKey('ideas-mine'),
                  onPressed: () => context.push(myIdeasPath),
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: Text(t.myIdeas),
                ),
            ],
          ),
        ),
        const SizedBox(height: StudioSpacing.sm),
        Expanded(
          child: StudioAsyncView<PagedState<StudioIdea>>(
            value: value,
            onRetry: () => ref.invalidate(ideasProvider),
            isEmpty: (d) => d.items.isEmpty,
            empty: StudioEmptyConfig(
              purpose: t.emptyPurpose,
              firstStep: firstStep,
              icon: Icons.lightbulb_outline,
              actionLabel: filter == 'Open' ? t.newIdea : null,
              onAction: filter == 'Open'
                  ? () => showProposeSheet(context, ref)
                  : null,
            ),
            builder: (context, d) => RefreshIndicator(
              onRefresh: () => ref.read(ideasProvider.notifier).refresh(),
              child: ListView(
                key: const ValueKey('ideas-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(StudioSpacing.gutter),
                children: [
                  for (final idea in d.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: StudioSpacing.md),
                      child: IdeaCard(
                        key: ValueKey('ic-${idea.id}'),
                        idea: idea,
                      ),
                    ),
                  if (d.hasMore)
                    Center(
                      child: Tooltip(
                        message: StudioStrings.of(context).showMore,
                        child: TextButton(
                          onPressed: () =>
                              ref.read(ideasProvider.notifier).loadMore(),
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
