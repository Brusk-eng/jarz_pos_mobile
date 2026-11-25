import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_status_colors.dart' as theme;
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../../shared/studio_async_view.dart';
import '../../settings/data/settings_repository.dart';
import '../pieces_strings.dart';
import '../state/piece_filters.dart';
import 'piece_widgets.dart';

/// The List view: search and filters over a cursor-paged list.
class PiecesListView extends ConsumerStatefulWidget {
  const PiecesListView({super.key});

  @override
  ConsumerState<PiecesListView> createState() => _PiecesListViewState();
}

class _PiecesListViewState extends ConsumerState<PiecesListView> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(pieceFiltersProvider).q;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final f = ref.read(pieceFiltersProvider);
      ref.read(pieceFiltersProvider.notifier).state = f.copyWith(
        q: text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final s = PiecesStrings.of(context);
    final filters = ref.watch(pieceFiltersProvider);
    final list = ref.watch(pieceListProvider);
    final copy = t.screen(StudioScreen.pieces);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.gutter,
            StudioSpacing.sm,
            StudioSpacing.gutter,
            0,
          ),
          child: TextField(
            key: const ValueKey('piece-search'),
            controller: _search,
            onChanged: _setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        _FilterBar(filters: filters),
        Expanded(
          child: StudioAsyncView<PagedState<PieceSummary>>(
            value: list,
            onRetry: () => ref.invalidate(pieceListProvider),
            isEmpty: (p) => p.items.isEmpty && !p.hasMore,
            empty: filters.isEmpty
                ? StudioEmptyConfig(
                    purpose: s.emptyListPurpose,
                    firstStep: s.emptyListFirst,
                  )
                : StudioEmptyConfig(
                    purpose: s.noMatches,
                    firstStep: copy.firstStep,
                    icon: Icons.search_off,
                    actionLabel: s.clearFilters,
                    onAction: () {
                      _search.clear();
                      ref.read(pieceFiltersProvider.notifier).state =
                          const PieceFilters();
                    },
                  ),
            builder: (context, p) => ListView(
              key: const ValueKey('piece-list'),
              padding: const EdgeInsets.all(StudioSpacing.gutter),
              children: [
                for (final piece in p.items)
                  PieceCard(
                    piece: piece,
                    onTap: () => context.push('/pieces/${piece.id}'),
                  ),
                if (p.hasMore)
                  Center(
                    child: TextButton(
                      key: const ValueKey('piece-list-more'),
                      onPressed: p.loadingMore
                          ? null
                          : () async {
                              try {
                                await ref
                                    .read(pieceListProvider.notifier)
                                    .loadMore();
                              } catch (e) {
                                if (context.mounted) {
                                  showSnack(context, s.error(e));
                                }
                              }
                            },
                      child: Text(s.showMore),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filters});

  final PieceFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = PiecesStrings.of(context);
    final t = StudioStrings.of(context);
    final people = ref.watch(peopleProvider).valueOrNull ?? const [];
    final flavours = ref.watch(flavoursProvider).valueOrNull ?? const [];
    void set(PieceFilters f) =>
        ref.read(pieceFiltersProvider.notifier).state = f;

    return SingleChildScrollView(
      key: const ValueKey('piece-filters'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: StudioSpacing.gutter,
        vertical: StudioSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterMenu(
            keyName: 'stage',
            label: s.filterStage,
            anyLabel: s.anyStage,
            value: filters.stage,
            options: [
              for (final st in theme.PieceStage.values)
                (st.apiName, t.stage(st.apiName)),
            ],
            onChanged: (v) => set(filters.copyWith(stage: v)),
          ),
          _FilterMenu(
            keyName: 'owner',
            label: s.filterOwner,
            anyLabel: s.anyOwner,
            value: filters.assignee,
            options: [
              (OwnerTeam.claude.wire, s.ownerClaude),
              (OwnerTeam.creators.wire, s.ownerCreators),
              for (final p in people.where((p) => p.enabled))
                (p.key, p.fullName),
            ],
            onChanged: (v) => set(filters.copyWith(assignee: v)),
          ),
          _FilterMenu(
            keyName: 'flavour',
            label: s.filterFlavour,
            anyLabel: s.anyFlavour,
            value: filters.flavourId,
            options: [for (final f in flavours) (f.id, f.name)],
            onChanged: (v) => set(filters.copyWith(flavourId: v)),
          ),
          _FilterMenu(
            keyName: 'format',
            label: s.filterFormat,
            anyLabel: s.anyFormat,
            value: filters.format,
            options: [
              for (final f in PieceFormat.values)
                if (f != PieceFormat.unknown) (f.wire, s.format(f)),
            ],
            onChanged: (v) => set(filters.copyWith(format: v)),
          ),
          _FilterMenu(
            keyName: 'persona',
            label: s.filterPersona,
            anyLabel: s.anyPersona,
            value: filters.persona,
            options: [
              for (final p in Persona.values)
                if (p != Persona.unknown) (p.wire, s.persona(p)),
            ],
            onChanged: (v) => set(filters.copyWith(persona: v)),
          ),
        ],
      ),
    );
  }
}

/// A filter as a chip that opens a menu of choices (value, label).
class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.keyName,
    required this.label,
    required this.anyLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String keyName;
  final String label;
  final String anyLabel;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chosen = options.where((o) => o.$1 == value);
    final text = chosen.isEmpty ? label : '$label: ${chosen.first.$2}';
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: StudioSpacing.sm),
      child: PopupMenuButton<String?>(
        key: ValueKey('filter-$keyName'),
        tooltip: label,
        onSelected: (v) => onChanged(v == '' ? null : v),
        itemBuilder: (_) => [
          PopupMenuItem<String?>(
            key: ValueKey('filter-$keyName-any'),
            value: '',
            child: Text(anyLabel),
          ),
          for (final o in options)
            PopupMenuItem<String?>(
              key: ValueKey('filter-$keyName-${o.$1}'),
              value: o.$1,
              child: Text(o.$2),
            ),
        ],
        child: Chip(
          label: Text(text),
          avatar: Icon(
            value == null ? Icons.filter_list : Icons.check,
            size: 16,
          ),
          backgroundColor: value == null ? null : StudioColors.softBlush,
        ),
      ),
    );
  }
}
