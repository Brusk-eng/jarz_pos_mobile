import '../../../shared/layout/studio_layout.dart';
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
import '../../session/state/studio_session_notifier.dart';
import '../references_strings.dart';
import 'reference_add_sheet.dart';
import '../state/references_state.dart';

/// The widest a reference thumbnail card gets: phone and wide window.
const double _refCellExtent = 200;
const double _wideRefCellExtent = 240;

/// The references grid: ads and posts to learn from, with the contract's
/// filters and cursor paging.
class ReferencesScreen extends ConsumerWidget {
  const ReferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final filters = ref.watch(referenceFiltersProvider);
    final grid = ref.watch(referenceGridProvider);
    final canAdd =
        ref.watch(studioSessionProvider).valueOrNull?.canAddReferences ?? false;

    return ViewEditScaffold(
      contentWidth: StudioContentWidth.full,
      title: t.title,
      parentRoute: '/more',
      actions: [
        if (canAdd)
          IconButton(
            key: const ValueKey('refs-add'),
            tooltip: AddReferenceStrings.of(context).tooltip,
            icon: const Icon(Icons.add),
            onPressed: () => AddReferenceSheet.show(context),
          ),
        IconButton(
          key: const ValueKey('refs-competitors'),
          tooltip: t.competitorsButton,
          icon: const Icon(Icons.groups_outlined),
          onPressed: () => context.go('/more/references/competitors'),
        ),
        moreHelpAction(context, title: t.helpTitle, lines: t.help),
      ],
      body: MoreBody(
        maxWidth: StudioContentWidth.full,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: MoreSearchField(
                    hint: t.searchHint,
                    initial: filters.q ?? '',
                    onChanged: (q) => ref
                        .read(referenceFiltersProvider.notifier)
                        .update((f) => f.copyWith(q: q.isEmpty ? null : q)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: StudioSpacing.gutter,
                    top: StudioSpacing.sm,
                  ),
                  child: Badge(
                    isLabelVisible: filters.activeCount > 0,
                    label: Text('${filters.activeCount}'),
                    child: IconButton.filledTonal(
                      key: const ValueKey('refs-filters'),
                      tooltip: t.filters,
                      icon: const Icon(Icons.tune),
                      onPressed: () => _openFilters(context),
                    ),
                  ),
                ),
              ],
            ),
            ChoiceChipRow<RefStatus>(
              options: const [
                RefStatus.newValue,
                RefStatus.shortlisted,
                RefStatus.forAShoot,
                RefStatus.remade,
                RefStatus.dropped,
              ],
              value: _statusOf(filters.status),
              labelOf: t.statusLabel,
              onChanged: (s) => ref
                  .read(referenceFiltersProvider.notifier)
                  .update((f) => f.copyWith(status: s?.wire)),
            ),
            Expanded(
              child: StudioAsyncView<PagedState<StudioReference>>(
                value: grid,
                onRetry: () => ref.invalidate(referenceGridProvider),
                empty: StudioEmptyConfig(
                  purpose: t.emptyPurpose,
                  firstStep: filters.activeCount > 0
                      ? t.emptyFiltered
                      : t.emptyFirstStep,
                  icon: Icons.bookmarks_outlined,
                ),
                isEmpty: (s) => s.items.isEmpty,
                builder: (context, state) => _Grid(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static RefStatus? _statusOf(String? wire) =>
      wire == null ? null : RefStatus.parse(wire);

  void _openFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const _FiltersSheet(),
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.state});

  final PagedState<StudioReference> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(referenceGridProvider.notifier).refresh(),
      child: CustomScrollView(
        key: const ValueKey('refs-grid'),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(
              context.isWideScreen ? StudioSpacing.xl : StudioSpacing.gutter,
            ),
            sliver: SliverGrid.builder(
              // Thumbnails: about 2 across on a phone, as many as fit on a
              // wide window (taller cells there, the picture is the point).
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: context.isWideScreen
                    ? _wideRefCellExtent
                    : _refCellExtent,
                mainAxisSpacing: StudioSpacing.md,
                crossAxisSpacing: StudioSpacing.md,
                childAspectRatio: 0.62,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, i) => _RefCard(ref_: state.items[i]),
            ),
          ),
          SliverToBoxAdapter(
            child: ShowMoreFooter(
              state: state,
              onMore: () => ref.read(referenceGridProvider.notifier).loadMore(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefCard extends StatelessWidget {
  const _RefCard({required this.ref_});

  final StudioReference ref_;

  @override
  Widget build(BuildContext context) {
    final t = ReferencesStrings.of(context);
    final theme = Theme.of(context);
    return Material(
      key: ValueKey('ref-${ref_.id}'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudioRadii.md),
        side: const BorderSide(color: StudioColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/more/references/${ref_.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StudioThumb(media: ref_.image, radius: BorderRadius.zero),
                  PositionedDirectional(
                    start: StudioSpacing.sm,
                    top: StudioSpacing.sm,
                    child: MorePill(
                      t.statusLabel(ref_.status),
                      foreground: _statusFg(ref_.status),
                      background: _statusBg(ref_.status),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersonText(
                    ref_.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (ref_.brand != null)
                    Text(
                      ref_.brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
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

Color _statusFg(RefStatus s) => switch (s) {
  RefStatus.shortlisted => const Color(0xFF5A3E85),
  RefStatus.forAShoot => const Color(0xFF8A2F3B),
  RefStatus.remade => const Color(0xFF1F6B4A),
  RefStatus.dropped => StudioColors.plumMuted,
  _ => StudioColors.deepPlum,
};

Color _statusBg(RefStatus s) => switch (s) {
  RefStatus.shortlisted => const Color(0xFFE7DDF5),
  RefStatus.forAShoot => const Color(0xFFFBD9DE),
  RefStatus.remade => const Color(0xFFD7EFE2),
  RefStatus.dropped => const Color(0xFFF2EFF3),
  _ => Colors.white,
};

/// Colours of a status pill, for the reference page too.
({Color fg, Color bg}) referenceStatusColors(RefStatus s) =>
    (fg: _statusFg(s), bg: _statusBg(s));

class _FiltersSheet extends ConsumerWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ReferencesStrings.of(context);
    final f = ref.watch(referenceFiltersProvider);
    final competitors = ref.watch(competitorListProvider).valueOrNull?.items;

    void set(ReferenceFilters Function(ReferenceFilters) fn) =>
        ref.read(referenceFiltersProvider.notifier).update(fn);

    Widget group<T>(
      String label,
      List<T> options,
      String? current,
      String Function(T) labelOf,
      String Function(T) wireOf,
      ReferenceFilters Function(ReferenceFilters, String?) apply,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: StudioSpacing.md),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Wrap(
            spacing: StudioSpacing.sm,
            children: [
              for (final o in options)
                StudioChoiceChip(
                  key: ValueKey('filter-${wireOf(o)}'),
                  label: Text(labelOf(o)),
                  selected: current == wireOf(o),
                  onSelected: (sel) =>
                      set((cur) => apply(cur, sel ? wireOf(o) : null)),
                ),
            ],
          ),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.gutter,
          0,
          StudioSpacing.gutter,
          StudioSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.filtersTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            group<RefMedia>(
              t.format,
              const [RefMedia.reel, RefMedia.staticValue, RefMedia.carousel],
              f.mediaType,
              t.formatLabel,
              (o) => o.wire,
              (cur, v) => cur.copyWith(mediaType: v),
            ),
            group<RefSrcType>(
              t.source,
              const [
                RefSrcType.metaAd,
                RefSrcType.tiktokAd,
                RefSrcType.igPost,
                RefSrcType.igReel,
              ],
              f.srcType,
              t.sourceLabel,
              (o) => o.wire,
              (cur, v) => cur.copyWith(srcType: v),
            ),
            group<String>(
              t.remakeFit,
              const ['ok', 'learn'],
              f.remake,
              t.remakeLabel,
              (o) => o,
              (cur, v) => cur.copyWith(remake: v),
            ),
            if (competitors != null && competitors.isNotEmpty)
              group<StudioCompetitor>(
                t.competitor,
                competitors,
                f.competitorKey,
                (c) => c.name,
                (c) => c.key,
                (cur, v) => cur.copyWith(competitorKey: v),
              ),
            group<String>(
              t.sortBy,
              const ['new', 'reach', 'rank'],
              f.sort,
              t.sortLabel,
              (o) => o,
              (cur, v) => cur.copyWith(sort: v ?? 'new'),
            ),
            const SizedBox(height: StudioSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const ValueKey('filters-reset'),
                    onPressed: () => set((_) => const ReferenceFilters()),
                    child: Text(t.reset),
                  ),
                ),
                const SizedBox(width: StudioSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('filters-apply'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.apply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
