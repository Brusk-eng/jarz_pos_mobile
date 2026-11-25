import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class PiecesRepository {
  PiecesRepository(this._api);
  final StudioApi _api;

  Future<PieceBoard> board({
    String? assignee,
    String? format,
    String? persona,
    String? situation,
    String? layer,
    String? flavourId,
    String? q,
    bool? includeParked,
  }) => _api.piecesBoard(
    assignee: assignee,
    format: format,
    persona: persona,
    situation: situation,
    layer: layer,
    flavourId: flavourId,
    q: q,
    includeParked: includeParked,
  );

  Future<PieceSummaryPage> list({
    String? stage,
    String? assignee,
    String? format,
    String? q,
    bool? parked,
    String? after,
  }) => _api.piecesList(
    stage: stage,
    assignee: assignee,
    format: format,
    q: q,
    parked: parked,
    after: after,
  );

  Future<ThisWeek> thisWeek({String? weekStart}) =>
      _api.piecesThisWeek(weekStart: weekStart);

  Future<StudioPiece> get(String id) => _api.piecesGet(pieceId: id);

  Future<StudioPiece> create({
    required String title,
    required String format,
    String? titleAr,
    String? persona,
    String? situation,
    String? layer,
    List<String>? flavourIds,
    String? assignee,
    String? dueDate,
    String? note,
    String? requestId,
  }) => _api.piecesCreate(
    title: title,
    format: format,
    titleAr: titleAr,
    persona: persona,
    situation: situation,
    layer: layer,
    flavourIds: flavourIds,
    assignee: assignee,
    dueDate: dueDate,
    note: note,
    requestId: requestId,
  );

  Future<StudioPiece> update(
    String id,
    Map<String, dynamic> fields, {
    String? baseModified,
  }) => _api.piecesUpdate(
    pieceId: id,
    fields: fields,
    baseModified: baseModified,
  );

  Future<StudioPiece> assign(
    String id, {
    String? assignee,
    String? assigneeTeam,
    String? dueDate,
    String? baseModified,
  }) => _api.piecesAssign(
    pieceId: id,
    assignee: assignee,
    assigneeTeam: assigneeTeam,
    dueDate: dueDate,
    baseModified: baseModified,
  );

  Future<StudioPiece> park(String id, String reason, {String? requestId}) =>
      _api.piecesPark(pieceId: id, reason: reason, requestId: requestId);

  Future<StudioPiece> unpark(String id, {String? requestId}) =>
      _api.piecesUnpark(pieceId: id, requestId: requestId);

  /// Moves to the stage named [to]. A refused move throws `StudioGateFailed`
  /// with the reasons in `problems`; nothing changed.
  Future<StudioPiece> move(
    String id,
    String to, {
    String? reason,
    String? skipShootReason,
    String? baseModified,
    String? requestId,
  }) => _api.piecesMove(
    pieceId: id,
    to: to,
    reason: reason,
    skipShootReason: skipShootReason,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<HistoryItemPage> history(String id, {String? after}) =>
      _api.piecesHistory(pieceId: id, after: after);

  Future<PieceVersion> addVersion({
    required String pieceId,
    required String kind,
    List<String>? mediaIds,
    List<String>? frames,
    String? title,
    String? requestId,
  }) => _api.versionsAdd(
    pieceId: pieceId,
    kind: kind,
    mediaIds: mediaIds,
    frames: frames,
    title: title,
    requestId: requestId,
  );
}

final piecesRepositoryProvider = Provider<PiecesRepository>(
  (ref) => PiecesRepository(ref.watch(studioApiProvider)),
);

/// The stage board. Invalidate after a move.
final pieceBoardProvider = FutureProvider.autoDispose<PieceBoard>(
  (ref) => ref.watch(piecesRepositoryProvider).board(),
);

final thisWeekProvider = FutureProvider.autoDispose<ThisWeek>(
  (ref) => ref.watch(piecesRepositoryProvider).thisWeek(),
);

/// Stage filter for the flat piece list (wire value, e.g. `In review`).
final piecesStageFilterProvider = StateProvider<String?>((ref) => null);

final piecesProvider =
    AsyncNotifierProvider<PiecesNotifier, PagedState<PieceSummary>>(
      PiecesNotifier.new,
    );

class PiecesNotifier extends PagedNotifier<PieceSummary> {
  @override
  Future<PieceSummaryPage> fetchPage(String? after) => ref
      .read(piecesRepositoryProvider)
      .list(stage: ref.watch(piecesStageFilterProvider), after: after);
}

/// One piece with its lifecycle writes.
final pieceProvider =
    AsyncNotifierProvider.family<PieceNotifier, StudioPiece, String>(
      PieceNotifier.new,
    );

class PieceNotifier extends EntityNotifier<StudioPiece> {
  PiecesRepository get _repo => ref.read(piecesRepositoryProvider);

  @override
  Future<StudioPiece> fetch(String id) => _repo.get(id);

  @override
  StudioPiece parse(Object? json) =>
      StudioPiece.fromJson(Map<String, dynamic>.from(json as Map));

  @override
  String? modifiedOf(StudioPiece value) => value.modified;

  Future<void> move(
    String to, {
    String? reason,
    String? skipShootReason,
    String? requestId,
  }) async {
    await mutate(
      call: () => _repo.move(
        arg,
        to,
        reason: reason,
        skipShootReason: skipShootReason,
        baseModified: baseModified,
        requestId: requestId,
      ),
    );
    ref.invalidate(pieceBoardProvider);
  }

  Future<void> park(String reason, {String? requestId}) =>
      mutate(call: () => _repo.park(arg, reason, requestId: requestId));

  Future<void> unpark({String? requestId}) =>
      mutate(call: () => _repo.unpark(arg, requestId: requestId));

  Future<void> assign({
    String? assignee,
    String? assigneeTeam,
    String? dueDate,
  }) => mutate(
    call: () => _repo.assign(
      arg,
      assignee: assignee,
      assigneeTeam: assigneeTeam,
      dueDate: dueDate,
      baseModified: baseModified,
    ),
  );

  Future<void> edit(Map<String, dynamic> fields) =>
      mutate(call: () => _repo.update(arg, fields, baseModified: baseModified));
}

/// The change history of a piece, newest first.
final pieceHistoryProvider = FutureProvider.autoDispose
    .family<HistoryItemPage, String>(
      (ref, id) => ref.watch(piecesRepositoryProvider).history(id),
    );
