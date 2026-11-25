import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../data/pieces_repository.dart';

/// The filters of the List view. Stage, owner, format and text go to the
/// server (`pieces.list`); flavour and persona are applied to what came back,
/// because `pieces.list` has no such parameters.
class PieceFilters {
  const PieceFilters({
    this.stage,
    this.assignee,
    this.format,
    this.persona,
    this.flavourId,
    this.q = '',
    this.situation,
    this.batch,
    this.week,
    this.verdict,
    this.route,
    this.readyForAds,
    this.needsVerdict,
    this.sort,
  });

  /// Wire values: `In review`, `kareem`, `reel`, `Household`.
  final String? stage;
  final String? assignee;
  final String? format;
  final String? persona;
  final String? flavourId;
  final String q;

  /// Sent to the server (`pieces.list`, `pieces.board`): a situation, a batch
  /// name, any date of the wanted week (the week is Saturday to Friday), the
  /// newest final verdict (`RUN`, `FIX`, `DROP`, `none`), a route, "ready for
  /// ads", "has no final verdict yet" and the sort (`recent` or `rating`).
  final String? situation;
  final String? batch;
  final String? week;
  final String? verdict;
  final String? route;
  final bool? readyForAds;
  final bool? needsVerdict;
  final String? sort;

  /// How many of the sheet's filters are on (the sort counts when it is not
  /// the default).
  int get sheetCount => [
    situation,
    batch,
    week,
    verdict,
    route,
    readyForAds == true ? 'x' : null,
    needsVerdict == true ? 'x' : null,
    sort == null || sort == 'recent' ? null : sort,
  ].where((e) => e != null).length;

  bool get isEmpty =>
      sheetCount == 0 &&
      stage == null &&
      assignee == null &&
      format == null &&
      persona == null &&
      flavourId == null &&
      q.isEmpty;

  PieceFilters copyWith({
    Object? stage = _keep,
    Object? assignee = _keep,
    Object? format = _keep,
    Object? persona = _keep,
    Object? flavourId = _keep,
    String? q,
    Object? situation = _keep,
    Object? batch = _keep,
    Object? week = _keep,
    Object? verdict = _keep,
    Object? route = _keep,
    Object? readyForAds = _keep,
    Object? needsVerdict = _keep,
    Object? sort = _keep,
  }) => PieceFilters(
    situation: identical(situation, _keep)
        ? this.situation
        : situation as String?,
    batch: identical(batch, _keep) ? this.batch : batch as String?,
    week: identical(week, _keep) ? this.week : week as String?,
    verdict: identical(verdict, _keep) ? this.verdict : verdict as String?,
    route: identical(route, _keep) ? this.route : route as String?,
    readyForAds: identical(readyForAds, _keep)
        ? this.readyForAds
        : readyForAds as bool?,
    needsVerdict: identical(needsVerdict, _keep)
        ? this.needsVerdict
        : needsVerdict as bool?,
    sort: identical(sort, _keep) ? this.sort : sort as String?,
    stage: identical(stage, _keep) ? this.stage : stage as String?,
    assignee: identical(assignee, _keep) ? this.assignee : assignee as String?,
    format: identical(format, _keep) ? this.format : format as String?,
    persona: identical(persona, _keep) ? this.persona : persona as String?,
    flavourId: identical(flavourId, _keep)
        ? this.flavourId
        : flavourId as String?,
    q: q ?? this.q,
  );

  @override
  bool operator ==(Object other) =>
      other is PieceFilters &&
      other.stage == stage &&
      other.assignee == assignee &&
      other.format == format &&
      other.persona == persona &&
      other.flavourId == flavourId &&
      other.situation == situation &&
      other.batch == batch &&
      other.week == week &&
      other.verdict == verdict &&
      other.route == route &&
      other.readyForAds == readyForAds &&
      other.needsVerdict == needsVerdict &&
      other.sort == sort &&
      other.q == q;

  @override
  int get hashCode => Object.hash(
    stage,
    assignee,
    format,
    persona,
    flavourId,
    q,
    situation,
    batch,
    week,
    verdict,
    route,
    readyForAds,
    needsVerdict,
    sort,
  );
}

const Object _keep = Object();

final pieceFiltersProvider = StateProvider<PieceFilters>(
  (ref) => const PieceFilters(),
);

/// The flat, filtered, cursor-paged piece list.
final pieceListProvider =
    AsyncNotifierProvider<PieceListNotifier, PagedState<PieceSummary>>(
      PieceListNotifier.new,
    );

class PieceListNotifier extends PagedNotifier<PieceSummary> {
  PieceFilters _filters = const PieceFilters();

  @override
  Future<PagedState<PieceSummary>> build() {
    _filters = ref.watch(pieceFiltersProvider);
    return super.build();
  }

  @override
  Future<PieceSummaryPage> fetchPage(String? after) async {
    final f = _filters;
    final page = await ref
        .read(piecesRepositoryProvider)
        .list(
          stage: f.stage,
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
          after: after,
        );
    final items = [
      for (final p in page.items)
        if ((f.persona == null || p.persona?.wire == f.persona) &&
            (f.flavourId == null || p.flavours.any((x) => x.id == f.flavourId)))
          p,
    ];
    return PieceSummaryPage(items: items, next: page.next);
  }
}

/// Parked pieces, for the board's shelf.
final parkedPiecesProvider = FutureProvider.autoDispose<List<PieceSummary>>((
  ref,
) async {
  final page = await ref.watch(piecesRepositoryProvider).list(parked: true);
  return page.items;
});
