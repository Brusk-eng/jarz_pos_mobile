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
  });

  /// Wire values: `In review`, `kareem`, `reel`, `Household`.
  final String? stage;
  final String? assignee;
  final String? format;
  final String? persona;
  final String? flavourId;
  final String q;

  bool get isEmpty =>
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
  }) => PieceFilters(
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
      other.q == q;

  @override
  int get hashCode =>
      Object.hash(stage, assignee, format, persona, flavourId, q);
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
