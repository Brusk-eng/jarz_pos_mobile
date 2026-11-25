import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/studio_error.dart';
import '../data/review_repository.dart';
import 'action_outcome.dart';

/// The id of what a feed card rates: a version id or a library item (asset) id.
/// Null for a card the app cannot show (unknown target type, or a missing body).
String? rateCardId(RateCard c) => switch (c.targetType) {
  TargetType.version => c.version?.id,
  TargetType.asset => c.asset?.id,
  _ => null,
};

/// The cards of the rating feed the app can show, in feed order: versions and
/// library items (`inbox.to_rate` returns both).
List<RateCard> feedCards(Iterable<RateCard> cards) => [
  for (final c in cards)
    if (rateCardId(c) != null) c,
];

/// What this person rated in the current feed session: version or asset id
/// to score.
/// A rating is shown as saved at once and taken back if the server refuses.
class RateFeedState {
  const RateFeedState({this.rated = const {}, this.saved = const {}});

  /// Ratings shown as done (saved or on their way).
  final Map<String, int> rated;

  /// The part of [rated] the server has confirmed.
  final Set<String> saved;

  RateFeedState copyWith({Map<String, int>? rated, Set<String>? saved}) =>
      RateFeedState(rated: rated ?? this.rated, saved: saved ?? this.saved);
}

class RateFeedController extends Notifier<RateFeedState> {
  @override
  RateFeedState build() => const RateFeedState();

  /// Forget the session (a new visit to the feed).
  void reset() => state = const RateFeedState();

  /// Rate one version. The score counts as done at once; when the server
  /// refuses, it is taken back and the outcome says why.
  Future<ActionOutcome> rate(String versionId, int score, {String? comment}) =>
      _rate(
        versionId,
        score,
        (repo) => repo.rate(versionId, score, comment: comment),
      );

  /// Rate one library item (asset) with `assets.rate`.
  Future<ActionOutcome> rateAsset(
    String assetId,
    int score, {
    String? comment,
  }) => _rate(
    assetId,
    score,
    (repo) => repo.rateAsset(assetId, score, comment: comment),
  );

  /// Rate whatever [card] holds, a version or an asset.
  Future<ActionOutcome> rateCard(RateCard card, int score, {String? comment}) =>
      card.targetType == TargetType.asset
      ? rateAsset(card.asset!.id, score, comment: comment)
      : rate(card.version!.id, score, comment: comment);

  Future<ActionOutcome> _rate(
    String versionId,
    int score,
    Future<void> Function(ReviewRepository repo) send,
  ) async {
    state = state.copyWith(rated: {...state.rated, versionId: score});
    try {
      await send(ref.read(reviewRepositoryProvider));
    } on StudioAlreadyDone {
      // Rated already (another device): fine.
    } catch (e) {
      final rolled = {...state.rated}..remove(versionId);
      state = state.copyWith(rated: rolled);
      return ActionOutcome.fromError(e);
    }
    state = state.copyWith(saved: {...state.saved, versionId});
    ref.invalidate(inboxCountsProvider);
    return const ActionOutcome.ok();
  }
}

final rateFeedControllerProvider =
    NotifierProvider<RateFeedController, RateFeedState>(RateFeedController.new);
