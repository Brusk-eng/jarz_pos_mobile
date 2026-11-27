import '../../../shared/layout/studio_layout.dart';
import '../../../shared/studio_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/studio_strings.dart';
import '../../../core/router/studio_screen.dart';
import '../../../core/theme/studio_tokens.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../shared/studio_async_view.dart';
import '../data/pieces_repository.dart';
import '../pieces_strings.dart';
import '../state/piece_filters.dart';
import 'piece_widgets.dart';

/// One entry of the board: a stage, or the Parked shelf at the end.
class _BoardPage {
  const _BoardPage({
    required this.keyName,
    required this.label,
    required this.count,
    required this.items,
    this.stage,
    this.next,
  });

  final String keyName;
  final String label;
  final int count;
  final List<PieceSummary> items;
  final PieceStage? stage;
  final String? next;
}

/// The Board view: one column per stage with its count, then a Parked shelf.
/// Swipeable columns on a phone, side by side on a wide screen.
class PiecesBoardView extends ConsumerStatefulWidget {
  const PiecesBoardView({super.key});

  @override
  ConsumerState<PiecesBoardView> createState() => _PiecesBoardViewState();
}

class _PiecesBoardViewState extends ConsumerState<PiecesBoardView> {
  final _pages = PageController(viewportFraction: 0.92);
  int _current = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = StudioStrings.of(context);
    final s = PiecesStrings.of(context);
    final board = ref.watch(pieceBoardProvider);
    final parked = ref.watch(parkedPiecesProvider);
    final copy = t.screen(StudioScreen.pieces);

    return StudioAsyncView<PieceBoard>(
      value: board,
      onRetry: () => ref.invalidate(pieceBoardProvider),
      isEmpty: (b) => b.total == 0 && (parked.valueOrNull?.isEmpty ?? true),
      empty: StudioEmptyConfig(
        purpose: copy.purpose,
        firstStep: copy.firstStep,
      ),
      builder: (context, b) {
        final parkedItems = parked.valueOrNull ?? const <PieceSummary>[];
        final pages = [
          for (final c in b.columns)
            _BoardPage(
              keyName: c.stage.wire,
              label: stageName(context, c.stage),
              count: c.count,
              items: c.items,
              stage: c.stage,
              next: c.next,
            ),
          _BoardPage(
            keyName: 'parked',
            label: s.parkedShelf,
            count: parkedItems.length,
            items: parkedItems,
          ),
        ];
        return LayoutBuilder(
          builder: (context, box) {
            if (context.isWideScreen) {
              return ListView(
                key: const ValueKey('board-wide'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(StudioSpacing.gutter),
                children: [
                  for (final p in pages)
                    SizedBox(
                      width: 300,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: StudioSpacing.md,
                        ),
                        child: _BoardColumn(page: p, showHeader: true),
                      ),
                    ),
                ],
              );
            }
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: SingleChildScrollView(
                    key: const ValueKey('board-tabs'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: StudioSpacing.gutter,
                    ),
                    child: Row(
                      children: [
                        for (final (i, p) in pages.indexed)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: StudioSpacing.sm,
                            ),
                            child: StudioChoiceChip(
                              key: ValueKey('board-tab-${p.keyName}'),
                              label: Text('${p.label} ${p.count}'),
                              selected: i == _current,
                              onSelected: (_) {
                                _pages.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    key: const ValueKey('board-pages'),
                    controller: _pages,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StudioSpacing.xs,
                      ),
                      child: _BoardColumn(page: pages[i], showHeader: false),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BoardColumn extends ConsumerStatefulWidget {
  const _BoardColumn({required this.page, required this.showHeader});

  final _BoardPage page;
  final bool showHeader;

  @override
  ConsumerState<_BoardColumn> createState() => _BoardColumnState();
}

class _BoardColumnState extends ConsumerState<_BoardColumn> {
  final _more = <PieceSummary>[];
  String? _next;
  bool _usedNext = false;
  bool _loading = false;

  String? get _cursor => _usedNext ? _next : widget.page.next;

  @override
  void didUpdateWidget(_BoardColumn old) {
    super.didUpdateWidget(old);
    // The board was reloaded: forget the extra pages fetched on top of it.
    if (!identical(old.page.items, widget.page.items)) {
      _more.clear();
      _usedNext = false;
      _next = null;
    }
  }

  Future<void> _loadMore() async {
    final stage = widget.page.stage;
    final cursor = _cursor;
    if (stage == null || cursor == null || _loading) return;
    setState(() => _loading = true);
    try {
      final f = ref.read(pieceFiltersProvider);
      final page = await ref
          .read(piecesRepositoryProvider)
          .list(
            stage: stage.wire,
            assignee: f.assignee,
            format: f.format,
            q: f.q.isEmpty ? null : f.q,
            situation: f.situation,
            batch: f.batch,
            week: f.week,
            verdict: f.verdict,
            route: f.route,
            readyForAds: f.readyForAds,
            needsVerdict: f.needsVerdict,
            sort: f.sort,
            after: cursor,
          );
      if (!mounted) return;
      setState(() {
        _more.addAll(page.items);
        _next = page.next;
        _usedNext = true;
      });
    } catch (e) {
      if (mounted) showSnack(context, PiecesStrings.of(context).error(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = PiecesStrings.of(context);
    final p = widget.page;
    final shown = [
      ...p.items,
      ..._more.where((m) => !p.items.any((x) => x.id == m.id)),
    ];
    return Column(
      key: ValueKey('board-column-${p.keyName}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: StudioSpacing.sm),
            child: Text(
              '${p.label} (${p.count})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    s.emptyColumn,
                    key: ValueKey('board-empty-${p.keyName}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    StudioSpacing.xs,
                    StudioSpacing.sm,
                    StudioSpacing.xs,
                    StudioSpacing.xl,
                  ),
                  children: [
                    for (final piece in shown)
                      PieceCard(
                        piece: piece,
                        onTap: () => context.push('/pieces/${piece.id}'),
                      ),
                    if (_cursor != null)
                      Center(
                        child: TextButton(
                          key: ValueKey('board-more-${p.keyName}'),
                          onPressed: _loading ? null : _loadMore,
                          child: Text(s.showMore),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
