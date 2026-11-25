import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';

class PaidRepository {
  PaidRepository(this._api);
  final StudioApi _api;

  Future<PaidOverview> overview() => _api.paidOverview();

  Future<PaidRound> round(String code) => _api.paidRoundGet(roundCode: code);

  Future<PaidRound> roundSet(
    String code,
    String launchDate, {
    String? title,
    String? note,
    String? requestId,
  }) => _api.paidRoundSet(
    roundCode: code,
    launchDate: launchDate,
    title: title,
    note: note,
    requestId: requestId,
  );

  Future<PaidAd> adSetState(
    String adId, {
    String? roundCode,
    String? state,
    String? note,
    String? baseModified,
    String? requestId,
  }) => _api.paidAdSetState(
    adId: adId,
    roundCode: roundCode,
    state: state,
    note: note,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<PaidQueue> queueAdd(
    String versionId, {
    String? note,
    String? requestId,
  }) =>
      _api.paidQueueAdd(versionId: versionId, note: note, requestId: requestId);

  Future<PaidQueue> queueRemove(String adId, {String? requestId}) =>
      _api.paidQueueRemove(adId: adId, requestId: requestId);

  Future<PaidQueue> queueReorder(List<String> adIds, {String? requestId}) =>
      _api.paidQueueReorder(adIds: adIds, requestId: requestId);
}

final paidRepositoryProvider = Provider<PaidRepository>(
  (ref) => PaidRepository(ref.watch(studioApiProvider)),
);

/// Rounds, what is due, the queue and the stop signs.
final paidOverviewProvider =
    AsyncNotifierProvider<PaidOverviewNotifier, PaidOverview>(
      PaidOverviewNotifier.new,
    );

class PaidOverviewNotifier extends AsyncNotifier<PaidOverview> {
  PaidRepository get _repo => ref.read(paidRepositoryProvider);

  @override
  Future<PaidOverview> build() => _repo.overview();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.overview);
  }

  /// The queue changes at once (item gone / new order); rolls back on failure.
  Future<void> removeFromQueue(String adId, {String? requestId}) async {
    final before = state;
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncData(
        cur.copyWith(queue: cur.queue.where((q) => q.adId != adId).toList()),
      );
    }
    try {
      await _repo.queueRemove(adId, requestId: requestId);
      await refresh();
    } catch (_) {
      state = before;
      rethrow;
    }
  }

  Future<void> reorderQueue(List<String> adIds, {String? requestId}) async {
    final before = state;
    final cur = state.valueOrNull;
    if (cur != null) {
      final byId = {for (final q in cur.queue) q.adId: q};
      state = AsyncData(
        cur.copyWith(queue: [for (final id in adIds) ?byId[id]]),
      );
    }
    try {
      await _repo.queueReorder(adIds, requestId: requestId);
    } catch (_) {
      state = before;
      rethrow;
    }
  }

  Future<void> addToQueue(
    String versionId, {
    String? note,
    String? requestId,
  }) async {
    await _repo.queueAdd(versionId, note: note, requestId: requestId);
    await refresh();
  }

  Future<void> setAdState(
    String adId,
    String state, {
    String? note,
    String? requestId,
  }) async {
    await _repo.adSetState(
      adId,
      state: state,
      note: note,
      requestId: requestId,
    );
    await refresh();
  }
}

final paidRoundProvider = FutureProvider.autoDispose.family<PaidRound, String>(
  (ref, code) => ref.watch(paidRepositoryProvider).round(code),
);
