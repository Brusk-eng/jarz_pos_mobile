import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class ShootsRepository {
  ShootsRepository(this._api);
  final StudioApi _api;

  Future<ShootSummarySync> list({
    String? status,
    String? from,
    String? to,
    bool? includeDone,
    String? after,
    String? modifiedSince,
  }) => _api.shootsList(
    status: status,
    from: from,
    to: to,
    includeDone: includeDone,
    after: after,
    modifiedSince: modifiedSince,
  );

  Future<StudioShoot> get(String id) => _api.shootsGet(shootId: id);

  /// Everything the On set screen needs offline, or only what changed since
  /// [modifiedSince] (the previous `serverTime`).
  Future<StudioShootSync> sync({String? modifiedSince, String? after}) =>
      _api.shootsSync(modifiedSince: modifiedSince, after: after);

  Future<StudioShoot> create({
    required String title,
    String? shootDate,
    String? shootTime,
    String? place,
    String? assignee,
    String? notes,
    String? requestId,
  }) => _api.shootsCreate(
    title: title,
    shootDate: shootDate,
    shootTime: shootTime,
    place: place,
    assignee: assignee,
    notes: notes,
    requestId: requestId,
  );

  Future<StudioShoot> update(
    String id,
    Map<String, dynamic> fields, {
    String? baseModified,
  }) => _api.shootsUpdate(
    shootId: id,
    fields: fields,
    baseModified: baseModified,
  );

  Future<ShootShot> shotSet(
    String shootId, {
    String? shotId,
    String? what,
    String? setup,
    String? baseModified,
    String? requestId,
  }) => _api.shootsShotSet(
    shootId: shootId,
    shotId: shotId,
    what: what,
    setup: setup,
    baseModified: baseModified,
    requestId: requestId,
  );

  /// [ticks] is a list of `{shot_id, done, at, request_id}` (one call can carry
  /// a whole offline queue; each item answers on its own).
  Future<ShotTickResult> shotTick(List<Map<String, dynamic>> ticks) =>
      _api.shootsShotTick(ticks: ticks);

  Future<ShootShot> shotNote(
    String shotId,
    String note, {
    String? baseModified,
    String? requestId,
  }) => _api.shootsShotNote(
    shotId: shotId,
    note: note,
    baseModified: baseModified,
    requestId: requestId,
  );

  Future<StudioTask> prepTick(String taskId, {bool? done, String? requestId}) =>
      _api.shootsPrepTick(taskId: taskId, done: done, requestId: requestId);

  Future<ShareLink> shareLink(String shootId, {bool? regenerate}) =>
      _api.shootsShareLink(shootId: shootId, regenerate: regenerate);

  Future<PublicPrep> publicPrep(String token) =>
      _api.shootsPublicPrep(token: token);
}

final shootsRepositoryProvider = Provider<ShootsRepository>(
  (ref) => ShootsRepository(ref.watch(studioApiProvider)),
);

final shootsProvider =
    AsyncNotifierProvider<ShootsNotifier, PagedState<ShootSummary>>(
      ShootsNotifier.new,
    );

class ShootsNotifier extends PagedNotifier<ShootSummary> {
  @override
  Future<ShootSummarySync> fetchPage(String? after) =>
      ref.read(shootsRepositoryProvider).list(after: after);
}

/// One shoot, with the shot and prep ticks of the On set screen.
final shootProvider =
    AsyncNotifierProvider.family<ShootNotifier, StudioShoot, String>(
      ShootNotifier.new,
    );

class ShootNotifier extends EntityNotifier<StudioShoot> {
  ShootsRepository get _repo => ref.read(shootsRepositoryProvider);

  @override
  Future<StudioShoot> fetch(String id) => _repo.get(id);

  @override
  StudioShoot parse(Object? json) =>
      StudioShoot.fromJson(Map<String, dynamic>.from(json as Map));

  @override
  String? modifiedOf(StudioShoot value) => value.modified;

  /// Ticks one shot; the answer carries the updated shoot.
  Future<ShotTickResult> tickShot(
    String shotId, {
    bool done = true,
    String? requestId,
  }) async {
    final r = await _repo.shotTick([
      {
        'shot_id': shotId,
        'done': done,
        'at': DateTime.now().toIso8601String(),
        'request_id': requestId ?? newRequestId(),
      },
    ]);
    await refresh();
    return r;
  }

  Future<void> note(String shotId, String text, {String? requestId}) async {
    await _repo.shotNote(shotId, text, requestId: requestId);
    await refresh();
  }
}

/// The public read-only prep page (`/prep/<token>`), no login.
final publicPrepProvider = FutureProvider.autoDispose
    .family<PublicPrep, String>(
      (ref, token) => ref.watch(shootsRepositoryProvider).publicPrep(token),
    );
