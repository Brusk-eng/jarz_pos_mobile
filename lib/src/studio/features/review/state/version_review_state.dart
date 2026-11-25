import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_models.dart';
import '../data/review_repository.dart';
import 'action_outcome.dart';

/// Every comment on a version (all pages, newest last as the server sends
/// them). Invalidate after a comment is added.
final versionCommentsProvider = FutureProvider.autoDispose
    .family<List<StudioComment>, String>((ref, versionId) async {
      final repo = ref.watch(reviewRepositoryProvider);
      final all = <StudioComment>[];
      String? after;
      // A version has a handful of comments; stop at 10 pages to be safe.
      for (var i = 0; i < 10; i++) {
        final page = await repo.comments(versionId, after: after);
        all.addAll(page.items);
        after = page.next;
        if (after == null) break;
      }
      return all;
    });

/// The review writes of one version, as outcomes instead of exceptions. The
/// optimistic update, the rollback and the STALE reload are done by
/// [VersionNotifier]; this class only turns what it throws into an
/// [ActionOutcome] the screen can word.
class VersionActions {
  VersionActions(this._ref, this.id);

  final Ref _ref;
  final String id;

  VersionNotifier get _notifier => _ref.read(versionProvider(id).notifier);

  Future<ActionOutcome> _run(Future<void> Function() call) async {
    try {
      await call();
      return const ActionOutcome.ok();
    } catch (e) {
      final outcome = ActionOutcome.fromError(e);
      if (outcome.failure == ActionFailure.notPermitted) {
        // The buttons were out of date: load the real ones.
        await _notifier.refresh();
      }
      return outcome;
    }
  }

  Future<ActionOutcome> approve() => _run(() => _notifier.approve());

  Future<ActionOutcome> sendBack(String reason) =>
      _run(() => _notifier.fix(reason));

  Future<ActionOutcome> clearDecision() => _run(() => _notifier.clearReview());

  Future<ActionOutcome> rate(int score, {String? comment}) =>
      _run(() => _notifier.rate(score, comment: comment));

  Future<ActionOutcome> comment(String body, {int? frame}) async {
    final outcome = await _run(() => _notifier.comment(body, frame: frame));
    if (outcome.ok) _ref.invalidate(versionCommentsProvider(id));
    return outcome;
  }
}

final versionActionsProvider = Provider.family<VersionActions, String>(
  (ref, id) => VersionActions(ref, id),
);
