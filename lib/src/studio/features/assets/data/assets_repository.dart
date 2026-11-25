import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

/// Raw material and consent (group `assets`), plus uploads (group `media`).
class AssetsRepository {
  AssetsRepository(this._api);
  final StudioApi _api;

  Future<StudioAssetPage> list({
    String? kind,
    String? category,
    String? flavourId,
    String? status,
    String? consent,
    String? q,
    String? after,
  }) => _api.assetsList(
    kind: kind,
    category: category,
    flavourId: flavourId,
    status: status,
    consent: consent,
    q: q,
    after: after,
  );

  Future<StudioAsset> get(String id) => _api.assetsGet(assetId: id);

  Future<StudioAsset> create({
    required String mediaId,
    required String kind,
    String? title,
    String? flavourId,
    String? category,
    String? note,
    String? requestId,
  }) => _api.assetsCreate(
    mediaId: mediaId,
    kind: kind,
    title: title,
    flavourId: flavourId,
    category: category,
    note: note,
    requestId: requestId,
  );

  Future<StudioAsset> update(
    String id,
    Map<String, dynamic> fields, {
    String? baseModified,
  }) => _api.assetsUpdate(
    assetId: id,
    fields: fields,
    baseModified: baseModified,
  );

  Future<StudioAsset> setConsent(
    String id,
    String status, {
    String? who,
    String? date,
    String? scope,
    String? proofMediaId,
    String? requestId,
  }) => _api.assetsSetConsent(
    assetId: id,
    status: status,
    who: who,
    date: date,
    scope: scope,
    proofMediaId: proofMediaId,
    requestId: requestId,
  );

  Future<StudioAsset> markUsed(
    String id, {
    String? status,
    String? note,
    String? requestId,
  }) => _api.assetsMarkUsed(
    assetId: id,
    status: status,
    note: note,
    requestId: requestId,
  );

  Future<StudioAsset> rate(
    String id,
    int score, {
    String? comment,
    String? requestId,
  }) => _api.assetsRate(
    assetId: id,
    score: score,
    comment: comment,
    requestId: requestId,
  );

  Future<CommentResult> comment(String id, String body, {String? requestId}) =>
      _api.assetsComment(assetId: id, body: body, requestId: requestId);

  // Uploads go straight to S3 (contract 1.8): begin, PUT the bytes, complete.
  Future<UploadBegin> beginUpload({
    required String filename,
    required String contentType,
    required int bytes,
    required String purpose,
    String? sha256,
    String? requestId,
  }) => _api.mediaBeginUpload(
    filename: filename,
    contentType: contentType,
    bytes: bytes,
    purpose: purpose,
    sha256: sha256,
    requestId: requestId,
  );

  Future<StudioMedia> completeUpload(
    String uploadId, {
    List<Map<String, dynamic>>? parts,
    String? sha256,
    String? requestId,
  }) => _api.mediaCompleteUpload(
    uploadId: uploadId,
    parts: parts,
    sha256: sha256,
    requestId: requestId,
  );

  Future<OkResult> abortUpload(String uploadId) =>
      _api.mediaAbortUpload(uploadId: uploadId);

  /// A link valid for 10 minutes; never store it.
  Future<DownloadLink> downloadLink(String mediaId, {String? purpose}) =>
      _api.mediaDownloadLink(mediaId: mediaId, purpose: purpose);
}

final assetsRepositoryProvider = Provider<AssetsRepository>(
  (ref) => AssetsRepository(ref.watch(studioApiProvider)),
);

/// Asset filters, as wire values (null = no filter).
final assetsKindFilterProvider = StateProvider<String?>((ref) => null);

final assetsProvider =
    AsyncNotifierProvider<AssetsNotifier, PagedState<StudioAsset>>(
      AssetsNotifier.new,
    );

class AssetsNotifier extends PagedNotifier<StudioAsset> {
  @override
  Future<StudioAssetPage> fetchPage(String? after) => ref
      .read(assetsRepositoryProvider)
      .list(kind: ref.watch(assetsKindFilterProvider), after: after);
}

final assetProvider =
    AsyncNotifierProvider.family<AssetNotifier, StudioAsset, String>(
      AssetNotifier.new,
    );

class AssetNotifier extends EntityNotifier<StudioAsset> {
  AssetsRepository get _repo => ref.read(assetsRepositoryProvider);

  @override
  Future<StudioAsset> fetch(String id) => _repo.get(id);

  @override
  StudioAsset parse(Object? json) =>
      StudioAsset.fromJson(Map<String, dynamic>.from(json as Map));

  @override
  String? modifiedOf(StudioAsset value) => value.modified;

  Future<void> rate(int score, {String? comment, String? requestId}) => mutate(
    call: () => _repo.rate(arg, score, comment: comment, requestId: requestId),
  );

  Future<void> setConsent(
    String status, {
    String? who,
    String? date,
    String? scope,
    String? proofMediaId,
    String? requestId,
  }) => mutate(
    call: () => _repo.setConsent(
      arg,
      status,
      who: who,
      date: date,
      scope: scope,
      proofMediaId: proofMediaId,
      requestId: requestId,
    ),
  );

  Future<void> markUsed({String? status, String? note, String? requestId}) =>
      mutate(
        call: () => _repo.markUsed(
          arg,
          status: status,
          note: note,
          requestId: requestId,
        ),
      );
}
