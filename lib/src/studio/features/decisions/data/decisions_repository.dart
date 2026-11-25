import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class DecisionsRepository {
  DecisionsRepository(this._api);
  final StudioApi _api;

  Future<StudioDecisionPage> list({
    String? status,
    String? reportId,
    String? after,
  }) => _api.decisionsList(status: status, reportId: reportId, after: after);

  Future<StudioDecision> get(String id) => _api.decisionsGet(decisionId: id);

  Future<StudioDecision> answer(
    String id,
    int? optionIndex, {
    String? note,
    String? text,
    String? requestId,
  }) => _api.decisionsAnswer(
    decisionId: id,
    optionIndex: optionIndex,
    note: note,
    text: text,
    requestId: requestId,
  );
}

final decisionsRepositoryProvider = Provider<DecisionsRepository>(
  (ref) => DecisionsRepository(ref.watch(studioApiProvider)),
);

/// `Open` (default), `Answered`, `Superseded`, `Withdrawn`, or null for all.
final decisionsStatusFilterProvider = StateProvider<String?>((ref) => 'Open');

final decisionsProvider =
    AsyncNotifierProvider<DecisionsNotifier, PagedState<StudioDecision>>(
      DecisionsNotifier.new,
    );

class DecisionsNotifier extends PagedNotifier<StudioDecision> {
  DecisionsRepository get _repo => ref.read(decisionsRepositoryProvider);

  @override
  Future<StudioDecisionPage> fetchPage(String? after) => _repo.list(
    status: ref.watch(decisionsStatusFilterProvider),
    after: after,
  );

  StudioDecision _parse(Object? j) =>
      StudioDecision.fromJson(Map<String, dynamic>.from(j as Map));

  /// Pick option [optionIndex], or (a text decision) answer in words with
  /// [text]. The decision shows as answered at once.
  ///
  /// A decision is answered once and kept (contract: `decisions.answer`): a
  /// second answer, with the same pick or another, answers ALREADY_DONE and the
  /// first answer stands. The list then shows that answer and this throws
  /// [StudioAlreadyDone] so the card can say "This was already done".
  Future<void> answer(
    String id,
    int? optionIndex, {
    String? note,
    String? text,
    String? requestId,
  }) async {
    final result = await mutate<StudioDecision>(
      match: (d) => d.id == id,
      optimistic: (d) => d.copyWith(
        status: DecisionStatus.answered,
        pickedIndex: optionIndex,
        pickNote: note,
        answerText: text,
        actions: const [],
      ),
      call: () => _repo.answer(
        id,
        optionIndex,
        note: note,
        text: text,
        requestId: requestId,
      ),
      toItem: (d) => d,
      fromCurrent: (c) => c == null ? null : _parse(c),
    );
    if (result == null) {
      throw const StudioAlreadyDone('Already answered.', null);
    }
  }
}

final decisionProvider = FutureProvider.autoDispose
    .family<StudioDecision, String>(
      (ref, id) => ref.watch(decisionsRepositoryProvider).get(id),
    );
