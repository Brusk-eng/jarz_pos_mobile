import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_labels.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../shared/layout/studio_layout.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../inbox/presentation/inbox_strings.dart';
import '../../inbox/presentation/ui_helpers.dart';
import '../data/ideas_repository.dart';
import 'idea_forms.dart';
import 'ideas_strings.dart';
import '../../../core/l10n/studio_strings.dart';

/// Where the "My ideas" list lives (a pushed screen, not a tab).
const myIdeasPath = '/inbox/my-ideas';

/// The ideas the person raised, whatever became of them: the title, its
/// status and one line on what happens next.
class MyIdeasScreen extends ConsumerWidget {
  const MyIdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = IdeasStrings.of(context);
    final value = ref.watch(myIdeasProvider);
    return ViewEditScaffold(
      title: t.myIdeas,
      parentRoute: StudioRoutes.inboxIdeas,
      contentWidth: StudioContentWidth.full,
      showLanguageSwitch: true,
      actions: [
        IconButton(
          key: const ValueKey('my-ideas-new'),
          tooltip: t.newIdea,
          icon: const Icon(Icons.add),
          onPressed: () => showProposeSheet(context, ref),
        ),
      ],
      body: StudioAsyncView<PagedState<StudioIdea>>(
        value: value,
        onRetry: () => ref.invalidate(myIdeasProvider),
        isEmpty: (d) => d.items.isEmpty,
        empty: StudioEmptyConfig(
          purpose: t.myIdeasEmptyPurpose,
          firstStep: t.myIdeasEmptyFirstStep,
          icon: Icons.lightbulb_outline,
          actionLabel: t.newIdea,
          onAction: () => showProposeSheet(context, ref),
        ),
        builder: (context, d) => RefreshIndicator(
          onRefresh: () => ref.read(myIdeasProvider.notifier).refresh(),
          child: ListView(
            key: const ValueKey('my-ideas-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(
              context.isWideScreen ? StudioSpacing.xl : StudioSpacing.gutter,
            ),
            children: [
              ResponsiveCardGrid(
                minCellWidth: 400,
                children: [
                  for (final idea in d.items)
                    MyIdeaRow(key: ValueKey('my-idea-${idea.id}'), idea: idea),
                ],
              ),
              if (d.hasMore)
                Center(
                  child: Tooltip(
                    message: StudioStrings.of(context).showMore,
                    child: TextButton(
                      onPressed: () =>
                          ref.read(myIdeasProvider.notifier).loadMore(),
                      child: const Icon(Icons.expand_more),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One idea of the person: title, status, and what happens next.
class MyIdeaRow extends StatelessWidget {
  const MyIdeaRow({super.key, required this.idea});

  final StudioIdea idea;

  @override
  Widget build(BuildContext context) {
    final t = IdeasStrings.of(context);
    final theme = Theme.of(context);
    final arabic = InboxStrings.of(context).isArabic;
    final title = arabic && (idea.titleAr?.isNotEmpty ?? false)
        ? idea.titleAr!
        : idea.title;
    final next = switch (idea.status) {
      IdeaStatus.kept => t.nextKept,
      IdeaStatus.dropped => t.nextDropped,
      _ => t.nextOpenWaiting,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(StudioSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                const SizedBox(width: StudioSpacing.sm),
                Container(
                  key: const ValueKey('my-idea-status'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: StudioColors.blushPale,
                    border: Border.all(color: StudioColors.border),
                    borderRadius: BorderRadius.circular(StudioRadii.pill),
                  ),
                  child: Text(
                    StudioLabels.of(context).ideaStatus(idea.status),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: StudioSpacing.sm),
            NextStepLine(next),
            if (idea.status == IdeaStatus.kept && idea.keptPieceId != null)
              TextButton.icon(
                key: const ValueKey('my-idea-open-piece'),
                onPressed: () => context.push('/pieces/${idea.keptPieceId}'),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(t.openPiece),
              ),
            if (idea.status == IdeaStatus.dropped &&
                idea.dropReason != null &&
                idea.dropReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.xs),
                child: Text(
                  t.reasonOf(idea.dropReason!),
                  key: const ValueKey('my-idea-reason'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
