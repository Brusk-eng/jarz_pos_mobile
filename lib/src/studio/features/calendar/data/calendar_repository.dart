import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class CalendarRepository {
  CalendarRepository(this._api);
  final StudioApi _api;

  /// [from] and [to] are dates (`2026-11-23`), at most 92 days apart.
  Future<CalendarRange> range(
    String from,
    String to, {
    String? channel,
    String? status,
    String? assignee,
    String? modifiedSince,
  }) => _api.calendarRange(
    from: from,
    to: to,
    channel: channel,
    status: status,
    assignee: assignee,
    modifiedSince: modifiedSince,
  );

  Future<SocialPost> post(String id) => _api.calendarPostGet(postId: id);

  Future<PostResult> postSet({
    String? postId,
    String? pieceId,
    String? versionId,
    String? channel,
    String? slotTime,
    String? caption,
    String? postingMode,
    String? assignee,
    String? note,
    String? baseModified,
    String? requestId,
  }) => _api.calendarPostSet(
    postId: postId,
    pieceId: pieceId,
    versionId: versionId,
    channel: channel,
    slotTime: slotTime,
    caption: caption,
    postingMode: postingMode,
    assignee: assignee,
    note: note,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<PostResult> postMove(
    String id,
    String slotTime, {
    String? baseModified,
    String? requestId,
  }) => _api.calendarPostMove(
    postId: id,
    slotTime: slotTime,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<SocialPost> wontPost(String id, String reason, {String? requestId}) =>
      _api.calendarPostWontPost(
        postId: id,
        reason: reason,
        requestId: requestId,
      );

  Future<SocialPost> markPosted(String id, {String? link, String? requestId}) =>
      _api.calendarPostMarkPosted(postId: id, link: link, requestId: requestId);

  Future<SocialPost> retry(String id, {String? requestId}) =>
      _api.calendarPostRetry(postId: id, requestId: requestId);

  Future<SocialPost> frameSet(
    String id,
    int position,
    String status, {
    String? reason,
    String? requestId,
  }) => _api.calendarFrameSet(
    postId: id,
    position: position,
    status: status,
    reason: reason,
    requestId: requestId,
  );

  Future<ReadyPostPage> readyToPost({String? assignee, String? after}) =>
      _api.calendarReadyToPost(assignee: assignee, after: after);

  Future<PostDrift> drift({int? days}) => _api.calendarDrift(days: days);

  Future<ActualPost> actualMatch(String actualId, String postId) =>
      _api.calendarActualMatch(actualId: actualId, postId: postId);

  Future<ActualPost> actualIgnore(String actualId) =>
      _api.calendarActualIgnore(actualId: actualId);

  Future<PostChecks> checks({int? days}) => _api.calendarChecks(days: days);
}

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(ref.watch(studioApiProvider)),
);

/// A calendar window: `(from, to)` as dates.
typedef CalendarWindow = ({String from, String to});

final calendarRangeProvider = FutureProvider.autoDispose
    .family<CalendarRange, CalendarWindow>(
      (ref, w) => ref.watch(calendarRepositoryProvider).range(w.from, w.to),
    );

final postDriftProvider = FutureProvider.autoDispose<PostDrift>(
  (ref) => ref.watch(calendarRepositoryProvider).drift(),
);

final postChecksProvider = FutureProvider.autoDispose<PostChecks>(
  (ref) => ref.watch(calendarRepositoryProvider).checks(),
);

/// Posts due to go out by hand.
final readyToPostProvider =
    AsyncNotifierProvider<ReadyToPostNotifier, PagedState<ReadyPost>>(
      ReadyToPostNotifier.new,
    );

class ReadyToPostNotifier extends PagedNotifier<ReadyPost> {
  CalendarRepository get _repo => ref.read(calendarRepositoryProvider);

  @override
  Future<ReadyPostPage> fetchPage(String? after) =>
      _repo.readyToPost(after: after);

  /// "I posted it": the row leaves the list at once.
  Future<void> markPosted(String postId, {String? link, String? requestId}) =>
      mutate<SocialPost>(
        match: (r) => r.post.id == postId,
        optimistic: (_) => null,
        call: () => _repo.markPosted(postId, link: link, requestId: requestId),
        fromCurrent: (_) => null,
      ).then((_) => null);

  Future<void> wontPost(String postId, String reason, {String? requestId}) =>
      mutate<SocialPost>(
        match: (r) => r.post.id == postId,
        optimistic: (_) => null,
        call: () => _repo.wontPost(postId, reason, requestId: requestId),
        fromCurrent: (_) => null,
      ).then((_) => null);
}

/// One post with its hand-post writes.
final postProvider =
    AsyncNotifierProvider.family<PostNotifier, SocialPost, String>(
      PostNotifier.new,
    );

class PostNotifier extends EntityNotifier<SocialPost> {
  CalendarRepository get _repo => ref.read(calendarRepositoryProvider);

  @override
  Future<SocialPost> fetch(String id) => _repo.post(id);

  @override
  SocialPost parse(Object? json) =>
      SocialPost.fromJson(Map<String, dynamic>.from(json as Map));

  @override
  String? modifiedOf(SocialPost value) => value.modified;

  Future<void> markPosted({String? link, String? requestId}) => mutate(
    call: () => _repo.markPosted(arg, link: link, requestId: requestId),
  );

  Future<void> wontPost(String reason, {String? requestId}) =>
      mutate(call: () => _repo.wontPost(arg, reason, requestId: requestId));

  Future<void> retry({String? requestId}) =>
      mutate(call: () => _repo.retry(arg, requestId: requestId));

  Future<void> frameSet(
    int position,
    String status, {
    String? reason,
    String? requestId,
  }) => mutate(
    call: () => _repo.frameSet(
      arg,
      position,
      status,
      reason: reason,
      requestId: requestId,
    ),
  );
}
