import '../../../shared/studio_chips.dart';
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
import '../../../shared/view_edit_scaffold.dart';
import '../../shell/more_common.dart';
import '../../shell/more_strings.dart';
import '../../session/state/studio_session_notifier.dart';
import '../../../shared/studio_tr.dart';
import '../data/references_repository.dart';
import 'competitor_actions.dart';
import '../references_strings.dart';
import '../state/references_state.dart';

/// The competitors we watch.
class CompetitorsScreen extends ConsumerWidget {
  const CompetitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final list = ref.watch(competitorListProvider);
    final q = ref.watch(competitorSearchProvider);
    final status = ref.watch(competitorStatusProvider);
    final me = ref.watch(studioSessionProvider).valueOrNull;
    return ViewEditScaffold(
      title: t.competitorsTitle,
      parentRoute: '/more/references',
      actions: [
        if (me != null && me.canAddReferences)
          IconButton(
            key: const ValueKey('competitor-add'),
            tooltip: context.tr('Add a competitor', 'ضيف منافس'),
            icon: const Icon(Icons.add),
            onPressed: () => CompetitorActions.add(context, ref),
          ),
        moreHelpAction(
          context,
          title: t.competitorsHelpTitle,
          lines: t.competitorsHelp,
        ),
      ],
      body: MoreBody(
        child: Column(
          children: [
            MoreSearchField(
              hint: t.competitorsSearchHint,
              initial: q,
              onChanged: (v) =>
                  ref.read(competitorSearchProvider.notifier).state = v,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.gutter,
              ),
              child: Wrap(
                spacing: StudioSpacing.sm,
                children: [
                  for (final (key, en, ar) in const [
                    ('Active', 'Active', 'شغّالين'),
                    ('Removed', 'Removed', 'اتشالوا'),
                  ])
                    StudioChoiceChip(
                      key: ValueKey('competitor-status-$key'),
                      label: Text(context.tr(en, ar)),
                      selected: status == key,
                      onSelected: (_) =>
                          ref.read(competitorStatusProvider.notifier).state =
                              key,
                    ),
                ],
              ),
            ),
            Expanded(
              child: StudioAsyncView<PagedState<StudioCompetitor>>(
                value: list,
                onRetry: () => ref.invalidate(competitorListProvider),
                empty: status == 'Removed'
                    ? StudioEmptyConfig(
                        purpose: context.tr(
                          'No removed competitors.',
                          'مفيش منافسين اتشالوا.',
                        ),
                        firstStep: context.tr(
                          'A competitor you remove shows here, and you can restore it.',
                          'أي منافس تشيله هيظهر هنا وتقدر ترجّعه.',
                        ),
                        icon: Icons.groups_outlined,
                      )
                    : StudioEmptyConfig(
                        purpose: t.competitorsEmptyPurpose,
                        firstStep: t.competitorsEmptyFirstStep,
                        icon: Icons.groups_outlined,
                      ),
                isEmpty: (s) => s.items.isEmpty,
                builder: (context, state) => ListView(
                  key: const ValueKey('competitor-list'),
                  children: [
                    for (final c in state.items) _CompetitorRow(c: c),
                    ShowMoreFooter(
                      state: state,
                      onMore: () =>
                          ref.read(competitorListProvider.notifier).loadMore(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitorRow extends ConsumerWidget {
  const _CompetitorRow({required this.c});

  final StudioCompetitor c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final theme = Theme.of(context);
    return MoreCard(
      key: ValueKey('competitor-${c.key}'),
      onTap: () => context.go('/more/references/competitors/${c.key}'),
      child: Row(
        children: [
          SizedBox(width: 52, height: 52, child: StudioThumb(media: c.image)),
          const SizedBox(width: StudioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonText(c.name, style: theme.textTheme.titleSmall),
                Text(
                  [
                    t.groupLabel(c.competitorGroup),
                    '${c.referencesCount} ${t.referencesCount}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (c.status == CompStatus.removed) MorePill(t.removedBadge),
          if (c.actions.contains('restore'))
            TextButton(
              key: ValueKey('competitor-restore-${c.key}'),
              onPressed: () => CompetitorActions.restore(context, ref, c),
              child: Text(context.tr('Restore', 'رجّعه')),
            ),
        ],
      ),
    );
  }
}

/// One competitor: who they are, their numbers, their links and notes.
class CompetitorScreen extends ConsumerWidget {
  const CompetitorScreen({super.key, required this.competitorKey});

  final String competitorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final value = ref.watch(competitorProvider(competitorKey));
    return ViewEditScaffold(
      title: value.valueOrNull?.name ?? t.competitorTitle,
      parentRoute: '/more/references/competitors',
      actions: [
        moreHelpAction(
          context,
          title: t.competitorsHelpTitle,
          lines: t.competitorsHelp,
        ),
      ],
      body: MoreBody(
        child: StudioAsyncView<StudioCompetitor>(
          value: value,
          onRetry: () => ref.invalidate(competitorProvider(competitorKey)),
          empty: StudioEmptyConfig(
            purpose: t.competitorsEmptyPurpose,
            firstStep: t.competitorsEmptyFirstStep,
          ),
          builder: (context, c) => _CompetitorBody(c: c),
        ),
      ),
    );
  }
}

class _CompetitorBody extends ConsumerWidget {
  const _CompetitorBody({required this.c});

  final StudioCompetitor c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final m = MoreStrings.of(context);
    final theme = Theme.of(context);

    String n(int? v) => v == null ? '-' : groupDigits(v);

    Widget link(String label, String? url, IconData icon, String key) {
      if (url == null || url.isEmpty) return const SizedBox.shrink();
      return ListTile(
        key: ValueKey(key),
        dense: true,
        leading: Icon(icon),
        title: Text(label),
        onTap: () => openMoreLink(context, ref, url),
      );
    }

    return ListView(
      key: const ValueKey('competitor-body'),
      padding: const EdgeInsets.only(bottom: StudioSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: StudioThumb(media: c.image),
              ),
              const SizedBox(width: StudioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PersonText(c.name, style: theme.textTheme.headlineSmall),
                    Text(
                      [
                        t.groupLabel(c.competitorGroup),
                        if (c.market != null && c.market != CompMarket.unknown)
                          c.market!.wire,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (c.status == CompStatus.removed)
                      Padding(
                        padding: const EdgeInsets.only(top: StudioSpacing.xs),
                        child: MorePill(t.removedBadge),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (c.removedWhy != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Text('${t.removedBecause}: ${c.removedWhy}'),
          ),
        if (c.summary != null)
          Padding(
            padding: const EdgeInsets.all(StudioSpacing.gutter),
            child: Text(c.summary!, style: theme.textTheme.bodyMedium),
          ),
        if (c.actions.contains('remove') || c.actions.contains('restore'))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Row(
              children: [
                if (c.actions.contains('remove'))
                  OutlinedButton(
                    key: const ValueKey('competitor-remove'),
                    onPressed: () => CompetitorActions.remove(context, ref, c),
                    child: Text(context.tr('Remove', 'شيل')),
                  ),
                if (c.actions.contains('restore'))
                  FilledButton.tonal(
                    key: const ValueKey('competitor-restore'),
                    onPressed: () => CompetitorActions.restore(context, ref, c),
                    child: Text(context.tr('Restore', 'رجّعه')),
                  ),
              ],
            ),
          ),
        MoreCard(
          child: Column(
            children: [
              LabeledValue(t.followers, n(c.followers)),
              LabeledValue(t.liveAds, n(c.liveAds)),
              LabeledValue(t.outliers, n(c.outliers)),
              LabeledValue(t.survivors, n(c.survivors)),
              LabeledValue(t.referencesCount, n(c.referencesCount)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.gutter),
          child: FilledButton.tonal(
            key: const ValueKey('competitor-see-references'),
            onPressed: () {
              ref.read(referenceFiltersProvider.notifier).state =
                  ReferenceFilters(competitorKey: c.key);
              context.go('/more/references');
            },
            child: Text(t.seeTheirReferences),
          ),
        ),
        link(
          c.igHandle == null ? t.instagram : '${t.instagram} ${c.igHandle}',
          c.igHandle == null ? null : 'https://instagram.com/${c.igHandle}',
          Icons.camera_alt_outlined,
          'competitor-ig',
        ),
        link(
          c.tiktokHandle == null ? t.tiktok : '${t.tiktok} ${c.tiktokHandle}',
          c.tiktokHandle == null
              ? null
              : 'https://www.tiktok.com/@${c.tiktokHandle}',
          Icons.music_note_outlined,
          'competitor-tiktok',
        ),
        link(t.website, c.site, Icons.language, 'competitor-site'),
        link(
          t.adLibrary,
          c.adlibUrl,
          Icons.campaign_outlined,
          'competitor-ads',
        ),
        SectionLabel(t.notes),
        if (c.notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.gutter,
            ),
            child: Text(t.noNotes, style: theme.textTheme.bodySmall),
          )
        else
          for (final n in c.notes)
            MoreCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonText(n.text),
                  const SizedBox(height: StudioSpacing.xs),
                  Text(
                    '${n.author.fullName}, ${m.dateTime(n.at)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
