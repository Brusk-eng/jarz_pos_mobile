import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_enums.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';
import '../../review/data/review_repository.dart' show inboxCountsProvider;
import '../../today/data/today_repository.dart' show todayProvider;

class IdeasRepository {
  IdeasRepository(this._api);
  final StudioApi _api;

  Future<StudioIdeaPage> list({
    String? status,
    String? source,
    bool? mine,
    String? after,
  }) =>
      _api.ideasList(status: status, source: source, mine: mine, after: after);

  Future<StudioIdea> get(String id) => _api.ideasGet(ideaId: id);

  Future<StudioIdea> propose({
    required String title,
    String? titleAr,
    String? hook,
    String? format,
    String? angle,
    String? sourceReferenceId,
    List<String>? flavourIds,
    String? requestId,
  }) => _api.ideasPropose(
    title: title,
    titleAr: titleAr,
    hook: hook,
    format: format,
    angle: angle,
    sourceReferenceId: sourceReferenceId,
    flavourIds: flavourIds,
    requestId: requestId,
  );

  Future<StudioIdea> update(
    String id,
    Map<String, dynamic> fields, {
    String? baseModified,
  }) =>
      _api.ideasUpdate(ideaId: id, fields: fields, baseModified: baseModified);

  Future<IdeaKeepResult> keep(
    String id, {
    String? assignee,
    String? requestId,
  }) => _api.ideasKeep(ideaId: id, assignee: assignee, requestId: requestId);

  Future<StudioIdea> drop(String id, String reason, {String? requestId}) =>
      _api.ideasDrop(ideaId: id, reason: reason, requestId: requestId);
}

final ideasRepositoryProvider = Provider<IdeasRepository>(
  (ref) => IdeasRepository(ref.watch(studioApiProvider)),
);

/// `Open` (default), `Kept`, `Dropped` or null for all.
final ideasStatusFilterProvider = StateProvider<String?>((ref) => 'Open');

final ideasProvider =
    AsyncNotifierProvider<IdeasNotifier, PagedState<StudioIdea>>(
      IdeasNotifier.new,
    );

class IdeasNotifier extends PagedNotifier<StudioIdea> {
  IdeasRepository get _repo => ref.read(ideasRepositoryProvider);

  @override
  Future<StudioIdeaPage> fetchPage(String? after) =>
      _repo.list(status: ref.watch(ideasStatusFilterProvider), after: after);

  StudioIdea? _parse(Object? j) => j == null
      ? null
      : StudioIdea.fromJson(Map<String, dynamic>.from(j as Map));

  /// Keep: the idea shows as kept at once. Returns the piece it became (null when it
  /// was already kept).
  Future<PieceSummary?> keep(
    String id, {
    String? assignee,
    String? requestId,
  }) async {
    final r = await mutate<IdeaKeepResult>(
      match: (i) => i.id == id,
      optimistic: (i) => i.copyWith(status: IdeaStatus.kept, actions: const []),
      call: () => _repo.keep(id, assignee: assignee, requestId: requestId),
      toItem: (r) => r.idea,
      fromCurrent: _parse,
    );
    ref.invalidate(todayProvider);
    ref.invalidate(inboxCountsProvider);
    return r?.piece;
  }

  Future<void> drop(String id, String reason, {String? requestId}) async {
    await mutate<StudioIdea>(
      match: (i) => i.id == id,
      optimistic: (i) => i.copyWith(
        status: IdeaStatus.dropped,
        dropReason: reason,
        actions: const [],
      ),
      call: () => _repo.drop(id, reason, requestId: requestId),
      toItem: (i) => i,
      fromCurrent: _parse,
    );
    ref.invalidate(todayProvider);
    ref.invalidate(inboxCountsProvider);
  }

  /// Adds a new idea at the top of the list.
  Future<StudioIdea> propose({
    required String title,
    String? titleAr,
    String? hook,
    String? requestId,
  }) async {
    final idea = await _repo.propose(
      title: title,
      titleAr: titleAr,
      hook: hook,
      requestId: requestId,
    );
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncData(
        PagedState(items: [idea, ...cur.items], next: cur.next),
      );
    }
    return idea;
  }
}

final ideaProvider = FutureProvider.autoDispose.family<StudioIdea, String>(
  (ref, id) => ref.watch(ideasRepositoryProvider).get(id),
);
