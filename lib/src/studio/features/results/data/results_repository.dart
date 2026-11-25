import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class ResultsRepository {
  ResultsRepository(this._api);
  final StudioApi _api;

  /// [weekStart] is the Monday of the week (date); default: this week.
  Future<WeekScorecard> scorecard({String? weekStart}) =>
      _api.resultsScorecard(weekStart: weekStart);

  Future<WeekScorecard> scorecardNote(
    String weekStart, {
    String? reviewNotes,
    String? actionsAgreed,
    Map<String, dynamic>? line,
    bool? markReviewed,
    String? baseModified,
    String? requestId,
  }) => _api.resultsScorecardNote(
    weekStart: weekStart,
    reviewNotes: reviewNotes,
    actionsAgreed: actionsAgreed,
    line: line,
    markReviewed: markReviewed,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<PieceResultPage> byPiece({
    String? from,
    String? to,
    String? format,
    String? sort,
    String? after,
  }) => _api.resultsByPiece(
    from: from,
    to: to,
    format: format,
    sort: sort,
    after: after,
  );

  Future<ResultSummary> summary(String from, String to, String groupBy) =>
      _api.resultsSummary(from: from, to: to, groupBy: groupBy);

  Future<RatingsRollup> ratings() => _api.resultsRatings();

  Future<PostRead> readSet(
    String postId, {
    String? bucket,
    int? views,
    int? reach,
    int? sends,
    int? shares,
    int? likes,
    int? saves,
    String? requestId,
  }) => _api.resultsReadSet(
    postId: postId,
    bucket: bucket,
    views: views,
    reach: reach,
    sends: sends,
    shares: shares,
    likes: likes,
    saves: saves,
    requestId: requestId,
  );
}

final resultsRepositoryProvider = Provider<ResultsRepository>(
  (ref) => ResultsRepository(ref.watch(studioApiProvider)),
);

/// The Sunday scorecard of a week (null = this week).
final scorecardProvider =
    AsyncNotifierProvider.family<ScorecardNotifier, WeekScorecard, String>(
      ScorecardNotifier.new,
    );

/// Pass `''` for the current week.
class ScorecardNotifier extends EntityNotifier<WeekScorecard> {
  ResultsRepository get _repo => ref.read(resultsRepositoryProvider);

  @override
  Future<WeekScorecard> fetch(String id) =>
      _repo.scorecard(weekStart: id.isEmpty ? null : id);

  @override
  WeekScorecard parse(Object? json) =>
      WeekScorecard.fromJson(Map<String, dynamic>.from(json as Map));

  @override
  String? modifiedOf(WeekScorecard value) => value.modified;

  Future<void> saveNotes({String? reviewNotes, String? actionsAgreed}) async {
    final week = (await future).weekStart;
    await mutate(
      call: () => _repo.scorecardNote(
        week,
        reviewNotes: reviewNotes,
        actionsAgreed: actionsAgreed,
        baseModified: baseModified,
      ),
    );
  }

  Future<void> markReviewed() async {
    final week = (await future).weekStart;
    await mutate(
      call: () => _repo.scorecardNote(
        week,
        markReviewed: true,
        baseModified: baseModified,
      ),
    );
  }
}

final resultsByPieceProvider =
    AsyncNotifierProvider<ResultsByPieceNotifier, PagedState<PieceResult>>(
      ResultsByPieceNotifier.new,
    );

class ResultsByPieceNotifier extends PagedNotifier<PieceResult> {
  @override
  Future<PieceResultPage> fetchPage(String? after) =>
      ref.read(resultsRepositoryProvider).byPiece(after: after);
}

/// `(from, to, groupBy)`.
typedef ResultsSummaryQuery = ({String from, String to, String groupBy});

final resultsSummaryProvider = FutureProvider.autoDispose
    .family<ResultSummary, ResultsSummaryQuery>(
      (ref, q) =>
          ref.watch(resultsRepositoryProvider).summary(q.from, q.to, q.groupBy),
    );

/// The team's ratings roll-up (`results.ratings`; Founder and Lead).
final ratingsRollupProvider = FutureProvider.autoDispose<RatingsRollup>(
  (ref) => ref.watch(resultsRepositoryProvider).ratings(),
);
