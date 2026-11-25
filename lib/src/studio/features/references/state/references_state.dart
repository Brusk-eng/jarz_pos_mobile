import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../pieces/data/pieces_repository.dart';
import '../../shoots/data/shoots_repository.dart';
import '../data/references_repository.dart';

/// What the references grid is filtered by. Every field is the wire value the
/// server takes; null means "any".
class ReferenceFilters {
  const ReferenceFilters({
    this.status,
    this.mediaType,
    this.srcType,
    this.remake,
    this.competitorKey,
    this.q,
    this.sort = 'new',
  });

  final String? status;
  final String? mediaType;
  final String? srcType;
  final String? remake;
  final String? competitorKey;
  final String? q;

  /// `new`, `reach` or `rank`.
  final String sort;

  /// How many filters besides the sort are on (for the badge on the button).
  int get activeCount => [
    status,
    mediaType,
    srcType,
    remake,
    competitorKey,
    q,
  ].where((v) => v != null && v.isNotEmpty).length;

  ReferenceFilters copyWith({
    Object? status = _keep,
    Object? mediaType = _keep,
    Object? srcType = _keep,
    Object? remake = _keep,
    Object? competitorKey = _keep,
    Object? q = _keep,
    String? sort,
  }) => ReferenceFilters(
    status: identical(status, _keep) ? this.status : status as String?,
    mediaType: identical(mediaType, _keep)
        ? this.mediaType
        : mediaType as String?,
    srcType: identical(srcType, _keep) ? this.srcType : srcType as String?,
    remake: identical(remake, _keep) ? this.remake : remake as String?,
    competitorKey: identical(competitorKey, _keep)
        ? this.competitorKey
        : competitorKey as String?,
    q: identical(q, _keep) ? this.q : q as String?,
    sort: sort ?? this.sort,
  );
}

const _keep = Object();

final referenceFiltersProvider = StateProvider<ReferenceFilters>(
  (ref) => const ReferenceFilters(),
);

/// The references grid: one cursor-paged list that reloads from the first page
/// when a filter changes.
final referenceGridProvider =
    AsyncNotifierProvider<ReferenceGridNotifier, PagedState<StudioReference>>(
      ReferenceGridNotifier.new,
    );

class ReferenceGridNotifier extends PagedNotifier<StudioReference> {
  @override
  Future<StudioReferencePage> fetchPage(String? after) {
    final f = ref.watch(referenceFiltersProvider);
    return ref
        .read(studioApiProvider)
        .referencesList(
          status: f.status,
          mediaType: f.mediaType,
          srcType: f.srcType,
          remake: f.remake,
          competitorKey: f.competitorKey,
          q: (f.q == null || f.q!.isEmpty) ? null : f.q,
          sort: f.sort,
          after: after,
        );
  }
}

/// What the competitors list is filtered by.
final competitorSearchProvider = StateProvider<String>((ref) => '');

final competitorListProvider =
    AsyncNotifierProvider<CompetitorListNotifier, PagedState<StudioCompetitor>>(
      CompetitorListNotifier.new,
    );

class CompetitorListNotifier extends PagedNotifier<StudioCompetitor> {
  @override
  Future<StudioCompetitorPage> fetchPage(String? after) {
    final q = ref.watch(competitorSearchProvider);
    return ref
        .read(referencesRepositoryProvider)
        .competitors(q: q.isEmpty ? null : q, after: after);
  }
}

/// The reference writes of one reference page. Each one is optimistic where
/// the answer is known (a status), takes the server's copy on `STALE` and
/// `ALREADY_DONE`, and also swaps the fresh copy into the grid.
class ReferenceActions {
  ReferenceActions(this._ref, this.id);

  final Ref _ref;
  final String id;

  ReferencesRepository get _repo => _ref.read(referencesRepositoryProvider);
  ReferenceNotifier get _notifier => _ref.read(referenceProvider(id).notifier);

  Future<void> _after() async {
    final fresh = _ref.read(referenceProvider(id)).valueOrNull;
    if (fresh == null) return;
    // The grid may not be loaded (deep link): only swap when it is.
    if (_ref.exists(referenceGridProvider)) {
      _ref.read(referenceGridProvider.notifier).swap((r) => r.id == id, fresh);
    }
  }

  Future<void> setStatus(
    RefStatus status, {
    String? note,
    String? shotId,
  }) async {
    try {
      await _notifier.mutate(
        optimistic: (r) => r.copyWith(status: status),
        call: () => _repo.updateStatus(
          id,
          status.wire,
          note: note,
          shotId: shotId,
          baseModified: _ref.read(referenceProvider(id)).valueOrNull?.modified,
        ),
      );
    } finally {
      await _after();
    }
  }

  Future<void> addNote(String text) async {
    try {
      await _notifier.mutate(call: () => _repo.note(id, text));
    } finally {
      await _after();
    }
  }

  Future<void> linkPiece(String pieceId) async {
    await _notifier.mutate(call: () => _repo.link(id, pieceId: pieceId));
    await _after();
  }

  Future<void> unlink({String? shotId, String? pieceId}) async {
    await _notifier.mutate(
      call: () =>
          _repo.link(id, shotId: shotId, pieceId: pieceId, unlink: true),
    );
    await _after();
  }
}

final referenceActionsProvider = Provider.family<ReferenceActions, String>(
  (ref, id) => ReferenceActions(ref, id),
);

/// Shoots that can still take a reference (not done), for the shot picker.
final shotPickerShootsProvider = FutureProvider.autoDispose<List<ShootSummary>>(
  (ref) async {
    final page = await ref.watch(shootsRepositoryProvider).list();
    return page.items;
  },
);

/// Pieces matching a search, for linking a reference to a piece.
final piecePickerProvider = FutureProvider.autoDispose
    .family<List<PieceSummary>, String>((ref, q) async {
      final page = await ref
          .watch(piecesRepositoryProvider)
          .list(q: q.isEmpty ? null : q);
      return page.items;
    });
