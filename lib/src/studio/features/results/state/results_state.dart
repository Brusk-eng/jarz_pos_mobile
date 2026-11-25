import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../shell/more_common.dart';
import '../data/results_repository.dart';

/// The week the scorecard shows: a Sunday as `YYYY-MM-DD`, or empty for the
/// newest week.
final scorecardWeekProvider = StateProvider<String>((ref) => '');

/// The scorecard writes of one week. Each one takes the server's copy (also
/// on `STALE` and `ALREADY_DONE`, through [ScorecardNotifier.mutate]).
class ScorecardActions {
  ScorecardActions(this._ref, this.week);

  final Ref _ref;
  final String week;

  ResultsRepository get _repo => _ref.read(resultsRepositoryProvider);
  ScorecardNotifier get _notifier =>
      _ref.read(scorecardProvider(week).notifier);

  Future<void> saveNotes({String? reviewNotes, String? actionsAgreed}) =>
      _notifier.saveNotes(
        reviewNotes: reviewNotes,
        actionsAgreed: actionsAgreed,
      );

  Future<void> markReviewed() => _notifier.markReviewed();

  /// A number the system cannot read, added by hand.
  Future<void> addLine(String label, String value) async {
    // Waits for the card instead of assuming it is already loaded.
    final current = await _ref.read(scorecardProvider(week).future);
    await _notifier.mutate(
      call: () => _repo.scorecardNote(
        current.weekStart,
        line: {'label': label, 'value': value},
        baseModified: current.modified,
      ),
    );
  }
}

final scorecardActionsProvider = Provider.family<ScorecardActions, String>(
  (ref, week) => ScorecardActions(ref, week),
);

/// `views`, `hold3` or `recent`.
final pieceResultsSortProvider = StateProvider<String>((ref) => 'recent');

/// Results by piece, cursor-paged, reloaded when the sort changes.
final pieceResultsProvider =
    AsyncNotifierProvider<PieceResultsNotifier, PagedState<PieceResult>>(
      PieceResultsNotifier.new,
    );

class PieceResultsNotifier extends PagedNotifier<PieceResult> {
  @override
  Future<PieceResultPage> fetchPage(String? after) => ref
      .read(resultsRepositoryProvider)
      .byPiece(sort: ref.watch(pieceResultsSortProvider), after: after);

  /// Files the 72-hour read of a post with the numbers a person typed (only
  /// what the API could not give). Throws the server's error.
  Future<PostRead> fileRead(
    String postId, {
    double? hold3Pct,
    int? views,
    int? reach,
    int? sends,
    int? shares,
    int? likes,
    int? commentsCount,
    int? saves,
    double? avgWatchS,
    double? reelLenS,
  }) async {
    final read = await ref
        .read(studioApiProvider)
        .resultsReadSet(
          postId: postId,
          bucket: '72h',
          hold3Pct: hold3Pct,
          views: views,
          reach: reach,
          sends: sends,
          shares: shares,
          likes: likes,
          commentsCount: commentsCount,
          saves: saves,
          avgWatchS: avgWatchS,
          reelLenS: reelLenS,
        );
    _swapRead(read);
    return read;
  }

  /// Puts the filed read into the piece that holds it.
  void _swapRead(PostRead read) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData(
      cur.copyWith(
        items: [
          for (final p in cur.items)
            if (p.piece.id == read.pieceId)
              p.copyWith(
                reads: [
                  for (final r in p.reads)
                    if (r.postId == read.postId) read else r,
                ],
              )
            else
              p,
        ],
      ),
    );
  }

  /// A read the server already holds (`ALREADY_DONE`) is taken as filed.
  void markFiled(String postId) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData(
      cur.copyWith(
        items: [
          for (final p in cur.items)
            p.copyWith(
              reads: [
                for (final r in p.reads)
                  if (r.postId == postId)
                    r.copyWith(filed: true, due: false)
                  else
                    r,
              ],
            ),
        ],
      ),
    );
  }
}

/// Group-by of the summary: format, persona, situation, layer, flavour,
/// series.
final summaryGroupByProvider = StateProvider<String>((ref) => 'format');

/// How many days back the summary looks.
final summaryDaysProvider = StateProvider<int>((ref) => 28);

/// The summary query for today: `(from, to, groupBy)`.
final summaryQueryProvider = Provider<ResultsSummaryQuery>((ref) {
  final days = ref.watch(summaryDaysProvider);
  final now = DateTime.now();
  return (
    from: isoDate(now.subtract(Duration(days: days))),
    to: isoDate(now),
    groupBy: ref.watch(summaryGroupByProvider),
  );
});
