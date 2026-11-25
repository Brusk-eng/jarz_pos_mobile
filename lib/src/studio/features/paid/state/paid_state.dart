import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../pieces/data/pieces_repository.dart';
import '../data/paid_repository.dart';

/// One test round with its ads. Setting an ad's state is optimistic: the
/// chip changes at once and rolls back when the server says no; the round is
/// read again afterwards because the counts and the rules' hint change.
final paidRoundStateProvider =
    AsyncNotifierProvider.family<PaidRoundNotifier, PaidRound, String>(
      PaidRoundNotifier.new,
    );

class PaidRoundNotifier extends EntityNotifier<PaidRound> {
  PaidRepository get _repo => ref.read(paidRepositoryProvider);

  @override
  Future<PaidRound> fetch(String id) => _repo.round(id);

  @override
  String? modifiedOf(PaidRound value) => value.modified;

  /// `STALE` and `ALREADY_DONE` on an ad write carry the fresh AD, not the
  /// round: it is put into the round on screen. A whole round is taken as is.
  @override
  PaidRound parse(Object? json) {
    final m = json is Map ? Map<String, dynamic>.from(json) : null;
    if (m != null && m.containsKey('ads')) return PaidRound.fromJson(m);
    final cur = state.valueOrNull;
    if (cur != null && m != null && m.containsKey('numbers')) {
      final ad = PaidAd.fromJson(m);
      return cur.copyWith(
        ads: [for (final a in cur.ads) a.id == ad.id ? ad : a],
      );
    }
    if (cur != null) return cur;
    throw StateError('No round to show');
  }

  /// [state] null clears the state ("Not set").
  Future<void> setAdState(String adId, AdState? state, {String? note}) async {
    try {
      await mutate(
        optimistic: (round) => round.copyWith(
          ads: [
            for (final a in round.ads)
              if (a.id == adId) a.copyWith(state: state) else a,
          ],
        ),
        call: () async {
          final ad = this.state.valueOrNull?.ads
              .where((a) => a.id == adId)
              .firstOrNull;
          await _repo.adSetState(
            adId,
            roundCode: ad?.roundCode == null ? arg : null,
            state: state?.wire ?? '',
            note: note,
            baseModified: ad?.modified,
          );
          return _repo.round(arg);
        },
      );
    } finally {
      ref.invalidate(paidOverviewProvider);
    }
  }

  /// Moves the round's launch date, title or note.
  Future<void> edit(String launchDate, {String? title, String? note}) async {
    try {
      await mutate(
        call: () => _repo.roundSet(arg, launchDate, title: title, note: note),
      );
    } finally {
      ref.invalidate(paidOverviewProvider);
    }
  }
}

/// A version that can be put in the queue, with its piece.
class QueueCandidate {
  const QueueCandidate({required this.piece, required this.version});

  final PieceSummary piece;
  final PieceVersion version;
}

/// Versions the server says are ready for ads: the current version of each
/// approved, scheduled or posted piece whose `ready_for_ads` is true and that
/// is not already in the queue.
final queueCandidatesProvider =
    FutureProvider.autoDispose<List<QueueCandidate>>((ref) async {
      final api = ref.watch(studioApiProvider);
      final pieces = ref.watch(piecesRepositoryProvider);
      final queued = {
        for (final q
            in ref.watch(paidOverviewProvider).valueOrNull?.queue ??
                const <QueueItem>[])
          q.version.id,
      };

      final found = <PieceSummary>[];
      final seen = <String>{};
      for (final stage in const ['Approved', 'Scheduled', 'Posted']) {
        final page = await pieces.list(stage: stage);
        for (final p in page.items) {
          if (seen.add(p.id)) found.add(p);
        }
      }
      final withVersion = [
        for (final p in found)
          if (p.currentVersion != null &&
              !queued.contains(p.currentVersion!.id))
            p,
      ].take(30).toList();

      final versions = await Future.wait([
        for (final p in withVersion)
          api.versionsGet(versionId: p.currentVersion!.id),
      ]);
      return [
        for (var i = 0; i < withVersion.length; i++)
          if (versions[i].readyForAds)
            QueueCandidate(piece: withVersion[i], version: versions[i]),
      ];
    });
