import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../core/upload/upload_engine.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/media/studio_media_widgets.dart';
import '../../../shared/studio_async_view.dart';
import '../../../shared/view_edit_scaffold.dart';
import '../../settings/data/settings_repository.dart';
import '../assets_strings.dart';
import '../state/library_state.dart';
import 'asset_widgets.dart';

/// `/assets`: the Library. A grid of raw clips, photos, templates and
/// customer content, with the filters the contract gives and cursor paging.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final container = ProviderScope.containerOf(context, listen: false);
    Future(() {
      if (!mounted) return;
      registerAssetFollowUp(container);
      container.read(studioUploadEngineProvider.notifier).restore();
    });
    _search.text = ref.read(assetFiltersProvider).q;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _set(AssetFilters Function(AssetFilters) f) =>
      ref.read(assetFiltersProvider.notifier).update(f);

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    final st = StudioStrings.of(context);
    final filters = ref.watch(assetFiltersProvider);
    final value = ref.watch(libraryProvider);

    return Stack(
      children: [
        ViewEditScaffold(
          title: st.screen(StudioScreen.assets).title,
          screen: StudioScreen.assets,
          parentRoute: '/more',
          body: Column(
            children: [
              _FilterBar(search: _search, filters: filters, onChange: _set),
              Expanded(
                child: StudioAsyncView<PagedAssets>(
                  value: value.whenData((p) => PagedAssets(p.items, p.hasMore)),
                  onRetry: () => ref.invalidate(libraryProvider),
                  empty: filters.any
                      ? StudioEmptyConfig(
                          purpose: t.emptyFilteredPurpose,
                          firstStep: t.emptyFilteredFirstStep,
                          icon: Icons.filter_alt_off_outlined,
                          actionLabel: t.clearFilters,
                          onAction: () {
                            _search.clear();
                            _set((_) => const AssetFilters());
                          },
                        )
                      : StudioEmptyConfig(
                          purpose: t.emptyPurpose,
                          firstStep: t.emptyFirstStep,
                          icon: Icons.photo_library_outlined,
                          actionLabel: t.addAsset,
                          onAction: () => context.push('/assets/new'),
                        ),
                  isEmpty: (d) => d.items.isEmpty,
                  builder: (context, d) => _Grid(data: d),
                ),
              ),
            ],
          ),
        ),
        if (ref.watch(canAddAssetsProvider))
          PositionedDirectional(
            end: StudioSpacing.gutter,
            bottom: StudioSpacing.gutter,
            child: FloatingActionButton.extended(
              key: const ValueKey('add-asset'),
              onPressed: () => context.push('/assets/new'),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(t.addAsset),
            ),
          ),
      ],
    );
  }
}

class PagedAssets {
  const PagedAssets(this.items, this.hasMore);
  final List<StudioAsset> items;
  final bool hasMore;
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.search,
    required this.filters,
    required this.onChange,
  });
  final TextEditingController search;
  final AssetFilters filters;
  final void Function(AssetFilters Function(AssetFilters)) onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AssetStrings.of(context);
    final flavours = ref.watch(flavoursProvider).valueOrNull ?? const [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.gutter,
        StudioSpacing.sm,
        StudioSpacing.gutter,
        0,
      ),
      child: Column(
        children: [
          TextField(
            key: const ValueKey('library-search'),
            controller: search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: t.search,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onSubmitted: (v) => onChange((f) => f.copyWith(q: v)),
          ),
          const SizedBox(height: StudioSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip<String>(
                  key: const ValueKey('filter-kind'),
                  label: t.filterKind,
                  current: filters.kind,
                  anyLabel: t.any,
                  options: [
                    for (final k in AssetKind.values)
                      if (k != AssetKind.unknown) (k.wire, t.kind(k)),
                  ],
                  onPick: (v) => onChange((f) => f.copyWith(kind: v)),
                ),
                if (flavours.isNotEmpty)
                  _FilterChip<String>(
                    key: const ValueKey('filter-flavour'),
                    label: t.filterFlavour,
                    current: filters.flavourId,
                    anyLabel: t.any,
                    options: [for (final f in flavours) (f.id, f.name)],
                    onPick: (v) => onChange((f) => f.copyWith(flavourId: v)),
                  ),
                _FilterChip<String>(
                  key: const ValueKey('filter-status'),
                  label: t.filterStatus,
                  current: filters.status,
                  anyLabel: t.any,
                  options: [
                    for (final s in AssetStatus.values)
                      if (s != AssetStatus.unknown) (s.wire, t.status(s)),
                  ],
                  onPick: (v) => onChange((f) => f.copyWith(status: v)),
                ),
                _FilterChip<String>(
                  key: const ValueKey('filter-consent'),
                  label: t.filterConsent,
                  current: filters.consent,
                  anyLabel: t.any,
                  options: [
                    for (final c in ConsentStatus.values)
                      if (c != ConsentStatus.unknown)
                        (c.wire, t.consentStatus(c)),
                  ],
                  onPick: (v) => onChange((f) => f.copyWith(consent: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.current,
    required this.anyLabel,
    required this.options,
    required this.onPick,
  });
  final String label;
  final T? current;
  final String anyLabel;
  final List<(T, String)> options;
  final void Function(T? value) onPick;

  @override
  Widget build(BuildContext context) {
    final active = current == null
        ? null
        : options.where((o) => o.$1 == current).map((o) => o.$2).firstOrNull;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
      child: PopupMenuButton<Object?>(
        tooltip: label,
        onSelected: (v) => onPick(v == _anyMarker ? null : v as T),
        itemBuilder: (_) => [
          PopupMenuItem<Object?>(value: _anyMarker, child: Text(anyLabel)),
          for (final o in options)
            PopupMenuItem<Object?>(value: o.$1, child: Text(o.$2)),
        ],
        child: Chip(
          avatar: active == null ? null : const Icon(Icons.check, size: 16),
          label: Text(active == null ? label : '$label: $active'),
          backgroundColor: active == null
              ? Colors.white
              : StudioColors.softBlush.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

const _anyMarker = '__any__';

class _Grid extends ConsumerWidget {
  const _Grid({required this.data});
  final PagedAssets data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AssetStrings.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              StudioSpacing.gutter,
              StudioSpacing.md,
              StudioSpacing.gutter,
              0,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: StudioSpacing.md,
                crossAxisSpacing: StudioSpacing.md,
                childAspectRatio: 0.72,
              ),
              itemCount: data.items.length,
              itemBuilder: (context, i) => AssetTile(asset: data.items[i]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, StudioSpacing.md, 0, 96),
              child: data.hasMore
                  ? Center(
                      child: TextButton(
                        key: const ValueKey('load-more'),
                        onPressed: () =>
                            ref.read(libraryProvider.notifier).loadMore(),
                        child: Text(t.loadMore),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class AssetTile extends StatelessWidget {
  const AssetTile({super.key, required this.asset});
  final StudioAsset asset;

  @override
  Widget build(BuildContext context) {
    final t = AssetStrings.of(context);
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('asset-${asset.id}'),
      borderRadius: BorderRadius.circular(StudioRadii.md),
      onTap: () => context.push('/assets/${asset.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StudioThumb(media: asset.media),
                  if (asset.consent != null)
                    PositionedDirectional(
                      top: StudioSpacing.xs,
                      start: StudioSpacing.xs,
                      child: ConsentPill(consent: asset.consent!),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: StudioColors.deepPlum,
                    ),
                  ),
                  Text(
                    [
                      t.kind(asset.kind),
                      if (asset.flavour != null) asset.flavour!.name,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
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
