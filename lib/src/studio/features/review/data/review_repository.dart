import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

/// Inbox, approve, rate and comment (contract groups `inbox` and `versions`).
class ReviewRepository {
  ReviewRepository(this._api);
  final StudioApi _api;

  Future<InboxCounts> counts() => _api.inboxCounts();

  Future<ApproveCardPage> toApprove({String? after, int? limit}) =>
      _api.inboxToApprove(after: after, limit: limit);

  /// [kind] is `version`, `asset` or `all` (default).
  Future<RateCardPage> toRate({String? after, String? kind, int? limit}) =>
      _api.inboxToRate(after: after, kind: kind, limit: limit);

  Future<PieceVersion> version(String id) => _api.versionsGet(versionId: id);

  Future<PieceVersion> approve(
    String id, {
    String? baseModified,
    String? requestId,
  }) => _api.versionsApprove(
    versionId: id,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<PieceVersion> fix(
    String id,
    String reason, {
    String? baseModified,
    String? requestId,
  }) => _api.versionsFix(
    versionId: id,
    reason: reason,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<PieceVersion> clearReview(
    String id, {
    String? baseModified,
    String? requestId,
  }) => _api.versionsClearReview(
    versionId: id,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<PieceVersion> rate(
    String id,
    int score, {
    String? comment,
    String? requestId,
  }) => _api.versionsRate(
    versionId: id,
    score: score,
    comment: comment,
    requestId: requestId,
  );

  /// Rates a library item (asset): the feed holds versions and assets.
  Future<StudioAsset> rateAsset(
    String assetId,
    int score, {
    String? comment,
    String? requestId,
  }) => _api.assetsRate(
    assetId: assetId,
    score: score,
    comment: comment,
    requestId: requestId,
  );

  Future<CommentResult> comment(
    String id,
    String body, {
    int? frame,
    String? requestId,
  }) => _api.versionsComment(
    versionId: id,
    body: body,
    frame: frame,
    requestId: requestId,
  );

  Future<StudioCommentPage> comments(String id, {int? frame, String? after}) =>
      _api.versionsComments(versionId: id, frame: frame, after: after);

  Future<RatingsResult> ratings(String id) =>
      _api.versionsRatings(versionId: id);
}

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(studioApiProvider)),
);

/// Badges for the Inbox tab and Today. Invalidate after a write that changes
/// them (the notifiers below do).
final inboxCountsProvider = FutureProvider.autoDispose<InboxCounts>(
  (ref) => ref.watch(reviewRepositoryProvider).counts(),
);

/// The swipe feed of versions waiting for the Founder, oldest first.
final toApproveProvider =
    AsyncNotifierProvider<ToApproveNotifier, PagedState<ApproveCard>>(
      ToApproveNotifier.new,
    );

class ToApproveNotifier extends PagedNotifier<ApproveCard> {
  ReviewRepository get _repo => ref.read(reviewRepositoryProvider);

  @override
  Future<ApproveCardPage> fetchPage(String? after) =>
      _repo.toApprove(after: after);

  bool Function(ApproveCard) _is(String id) =>
      (c) => c.version.id == id;

  /// Approve: the card leaves the feed at once; it comes back if the call fails.
  String? _modifiedOf(String versionId) => state.valueOrNull?.items
      .where(_is(versionId))
      .firstOrNull
      ?.version
      .modified;

  Future<void> approve(String versionId, {String? requestId}) async {
    final base = _modifiedOf(versionId);
    await mutate<PieceVersion>(
      match: _is(versionId),
      optimistic: (_) => null,
      call: () =>
          _repo.approve(versionId, baseModified: base, requestId: requestId),
      fromCurrent: (_) => null,
    );
    ref.invalidate(inboxCountsProvider);
  }

  /// Send back with a [reason] (required by the server).
  Future<void> fix(String versionId, String reason, {String? requestId}) async {
    final base = _modifiedOf(versionId);
    await mutate<PieceVersion>(
      match: _is(versionId),
      optimistic: (_) => null,
      call: () => _repo.fix(
        versionId,
        reason,
        baseModified: base,
        requestId: requestId,
      ),
      fromCurrent: (_) => null,
    );
    ref.invalidate(inboxCountsProvider);
  }
}

/// Versions and assets this person has not rated yet.
final toRateProvider =
    AsyncNotifierProvider<ToRateNotifier, PagedState<RateCard>>(
      ToRateNotifier.new,
    );

class ToRateNotifier extends PagedNotifier<RateCard> {
  @override
  Future<RateCardPage> fetchPage(String? after) =>
      ref.read(reviewRepositoryProvider).toRate(after: after);
}

/// One version with the review writes. `ref.watch(versionProvider(id))`.
final versionProvider =
    AsyncNotifierProvider.family<VersionNotifier, PieceVersion, String>(
      VersionNotifier.new,
    );

class VersionNotifier extends EntityNotifier<PieceVersion> {
  ReviewRepository get _repo => ref.read(reviewRepositoryProvider);

  @override
  Future<PieceVersion> fetch(String id) => _repo.version(id);

  @override
  PieceVersion parse(Object? json) =>
      PieceVersion.fromJson(Map<String, dynamic>.from(json as Map));

  @override
  String? modifiedOf(PieceVersion value) => value.modified;

  Future<void> approve({String? requestId}) => mutate(
    optimistic: (v) => v.copyWith(
      reviewOutcome: ReviewOutcome.approved,
      awaitingReview: false,
    ),
    call: () =>
        _repo.approve(arg, baseModified: baseModified, requestId: requestId),
  ).whenComplete(() => ref.invalidate(inboxCountsProvider));

  Future<void> fix(String reason, {String? requestId}) => mutate(
    optimistic: (v) => v.copyWith(
      reviewOutcome: ReviewOutcome.fix,
      awaitingReview: false,
      reviewReason: reason,
    ),
    call: () => _repo.fix(
      arg,
      reason,
      baseModified: baseModified,
      requestId: requestId,
    ),
  ).whenComplete(() => ref.invalidate(inboxCountsProvider));

  Future<void> clearReview({String? requestId}) => mutate(
    optimistic: (v) => v.copyWith(
      reviewOutcome: null,
      awaitingReview: true,
      reviewReason: null,
    ),
    call: () => _repo.clearReview(
      arg,
      baseModified: baseModified,
      requestId: requestId,
    ),
  );

  Future<void> rate(int score, {String? comment, String? requestId}) => mutate(
    optimistic: (v) => v.myRating == null
        ? v
        : v.copyWith(
            myRating: v.myRating!.copyWith(score: score, comment: comment),
          ),
    call: () => _repo.rate(arg, score, comment: comment, requestId: requestId),
  );

  /// Adds a comment; the version's count goes up at once.
  Future<void> comment(String body, {int? frame, String? requestId}) async {
    final before = state;
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncData(cur.copyWith(commentsCount: cur.commentsCount + 1));
    }
    try {
      final r = await _repo.comment(
        arg,
        body,
        frame: frame,
        requestId: requestId,
      );
      final now = state.valueOrNull;
      if (now != null) {
        state = AsyncData(now.copyWith(commentsCount: r.commentsCount));
      }
    } catch (_) {
      state = before;
      rethrow;
    }
  }
}
