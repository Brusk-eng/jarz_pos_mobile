import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/studio_models.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../review/data/review_repository.dart';
import '../../review/state/action_outcome.dart';

/// Cards the founder approved on this screen, kept in the To approve list with
/// the sentence of what happens next until the list is pulled to refresh. The
/// server has already moved them out of "waiting", so without this the card
/// would vanish the moment it is approved. Keyed by version id.
final approvedHereProvider =
    NotifierProvider<ApprovedHereNotifier, Map<String, ApproveCard>>(
      ApprovedHereNotifier.new,
    );

class ApprovedHereNotifier extends Notifier<Map<String, ApproveCard>> {
  @override
  Map<String, ApproveCard> build() => const {};

  void put(ApproveCard c) => state = {...state, c.version.id: c};
  void remove(String versionId) {
    if (!state.containsKey(versionId)) return;
    state = {...state}..remove(versionId);
  }

  void clear() => state = const {};
}

/// The four writes of the approvals list, each as an [ActionOutcome] (nothing
/// is thrown to the screen). The lists refresh themselves through the write
/// map in `write_refresh.dart`.
class ApprovalsActions {
  ApprovalsActions(this._ref);
  final Ref _ref;

  ReviewRepository get _review => _ref.read(reviewRepositoryProvider);
  ApprovedHereNotifier get _here => _ref.read(approvedHereProvider.notifier);

  Future<ActionOutcome> _run(Future<void> Function() call) async {
    try {
      await call();
      return const ActionOutcome.ok();
    } catch (e) {
      return ActionOutcome.fromError(e);
    }
  }

  Future<ActionOutcome> approve(ApproveCard c) => _run(() async {
    final v = await _review.approve(
      c.version.id,
      baseModified: c.version.modified,
    );
    _here.put(c.copyWith(version: v));
  });

  Future<ActionOutcome> sendBack(ApproveCard c, String reason) => _run(
    () async {
      await _review.fix(c.version.id, reason, baseModified: c.version.modified);
      _here.remove(c.version.id);
    },
  );

  Future<ActionOutcome> undo(ApproveCard c) => _run(() async {
    await _review.clearReview(c.version.id, baseModified: c.version.modified);
    _here.remove(c.version.id);
  });

  /// Saves a new slot (`slot` is the wire string) on the card's post.
  Future<ActionOutcome> changeTime(
    ApproveCard c,
    PostSummary post,
    String slot,
  ) => _run(() async {
    final r = await _ref
        .read(calendarRepositoryProvider)
        .postMove(post.id, slot, baseModified: post.modified);
    final here = _ref.read(approvedHereProvider)[c.version.id];
    if (here != null) {
      _here.put(
        here.copyWith(
          posts: [
            for (final p in here.posts)
              p.id == post.id
                  ? p.copyWith(
                      slotTime: r.post.slotTime,
                      modified: r.post.modified,
                    )
                  : p,
          ],
        ),
      );
    }
  });
}

final approvalsActionsProvider = Provider<ApprovalsActions>(
  (ref) => ApprovalsActions(ref),
);
