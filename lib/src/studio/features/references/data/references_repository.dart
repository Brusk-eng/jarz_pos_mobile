import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class ReferencesRepository {
  ReferencesRepository(this._api);
  final StudioApi _api;

  Future<StudioReferencePage> list({
    String? status,
    String? competitorKey,
    String? srcType,
    String? mediaType,
    String? q,
    String? sort,
    String? after,
  }) => _api.referencesList(
    status: status,
    competitorKey: competitorKey,
    srcType: srcType,
    mediaType: mediaType,
    q: q,
    sort: sort,
    after: after,
  );

  Future<StudioReference> get(String id) => _api.referencesGet(referenceId: id);

  Future<StudioReference> create({
    required String title,
    String? brand,
    String? url,
    String? mediaType,
    String? srcType,
    String? imageMediaId,
    String? text,
    String? why,
    String? take,
    String? requestId,
  }) => _api.referencesCreate(
    title: title,
    brand: brand,
    url: url,
    mediaType: mediaType,
    srcType: srcType,
    imageMediaId: imageMediaId,
    text: text,
    why: why,
    take: take,
    requestId: requestId,
  );

  Future<StudioReference> updateStatus(
    String id,
    String status, {
    String? note,
    String? shotId,
    String? baseModified,
    String? requestId,
  }) => _api.referencesUpdateStatus(
    referenceId: id,
    status: status,
    note: note,
    shotId: shotId,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<StudioReference> link(
    String id, {
    String? shotId,
    String? pieceId,
    bool? unlink,
    String? grade,
    String? requestId,
  }) => _api.referencesLink(
    referenceId: id,
    shotId: shotId,
    pieceId: pieceId,
    unlink: unlink,
    grade: grade,
    requestId: requestId,
  );

  Future<StudioReference> note(String id, String text, {String? requestId}) =>
      _api.referencesNote(referenceId: id, text: text, requestId: requestId);

  Future<StudioCompetitorPage> competitors({
    String? competitorGroup,
    String? market,
    String? status,
    String? q,
    String? after,
  }) => _api.referencesCompetitors(
    competitorGroup: competitorGroup,
    market: market,
    status: status,
    q: q,
    after: after,
  );

  Future<StudioCompetitor> competitor(String key) =>
      _api.referencesCompetitorGet(key: key);
}

final referencesRepositoryProvider = Provider<ReferencesRepository>(
  (ref) => ReferencesRepository(ref.watch(studioApiProvider)),
);

/// Reference status filter (wire value, e.g. `Shortlisted`), null = all.
final referencesStatusFilterProvider = StateProvider<String?>((ref) => null);

final referencesProvider =
    AsyncNotifierProvider<ReferencesNotifier, PagedState<StudioReference>>(
      ReferencesNotifier.new,
    );

class ReferencesNotifier extends PagedNotifier<StudioReference> {
  @override
  Future<StudioReferencePage> fetchPage(String? after) => ref
      .read(referencesRepositoryProvider)
      .list(status: ref.watch(referencesStatusFilterProvider), after: after);
}

final referenceProvider =
    AsyncNotifierProvider.family<ReferenceNotifier, StudioReference, String>(
      ReferenceNotifier.new,
    );

class ReferenceNotifier extends EntityNotifier<StudioReference> {
  ReferencesRepository get _repo => ref.read(referencesRepositoryProvider);

  @override
  Future<StudioReference> fetch(String id) => _repo.get(id);

  @override
  StudioReference parse(Object? json) =>
      StudioReference.fromJson(Map<String, dynamic>.from(json as Map));

  @override
  String? modifiedOf(StudioReference value) => value.modified;

  Future<void> setStatus(String status, {String? note, String? requestId}) =>
      mutate(
        call: () => _repo.updateStatus(
          arg,
          status,
          note: note,
          baseModified: baseModified,
          requestId: requestId,
        ),
      );

  Future<void> addNote(String text, {String? requestId}) =>
      mutate(call: () => _repo.note(arg, text, requestId: requestId));
}

final competitorsProvider = FutureProvider.autoDispose<StudioCompetitorPage>(
  (ref) => ref.watch(referencesRepositoryProvider).competitors(),
);

final competitorProvider = FutureProvider.autoDispose
    .family<StudioCompetitor, String>(
      (ref, key) => ref.watch(referencesRepositoryProvider).competitor(key),
    );
