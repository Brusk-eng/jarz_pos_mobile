import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/studio_api.dart';
import '../../../data/models/studio_models.dart';
import '../../../data/paging.dart';

class TodayRepository {
  TodayRepository(this._api);
  final StudioApi _api;

  Future<TodayView> today({String? date}) => _api.todayGet(date: date);

  Future<StudioTaskPage> tasks({
    String? assignee,
    String? status,
    String? dueBefore,
    String? after,
  }) => _api.todayTasks(
    assignee: assignee,
    status: status,
    dueBefore: dueBefore,
    after: after,
  );

  Future<StudioTask> create({
    required String text,
    String? kind,
    String? assignee,
    String? assigneeTeam,
    String? due,
    String? dueTime,
    String? pieceId,
    String? shootId,
    String? postId,
    String? note,
    String? requestId,
  }) => _api.todayTaskCreate(
    text: text,
    kind: kind,
    assignee: assignee,
    assigneeTeam: assigneeTeam,
    due: due,
    dueTime: dueTime,
    pieceId: pieceId,
    shootId: shootId,
    postId: postId,
    note: note,
    requestId: requestId,
  );

  Future<StudioTask> update(
    String id,
    Map<String, dynamic> fields, {
    String? baseModified,
  }) => _api.todayTaskUpdate(
    taskId: id,
    fields: fields,
    baseModified: baseModified,
  );

  Future<StudioTask> tick(
    String id, {
    bool? done,
    bool? skipped,
    String? requestId,
  }) => _api.todayTaskTick(
    taskId: id,
    done: done,
    skipped: skipped,
    requestId: requestId,
  );
}

final todayRepositoryProvider = Provider<TodayRepository>(
  (ref) => TodayRepository(ref.watch(studioApiProvider)),
);

/// What waits on this person today (blocks already in the role's order).
final todayProvider = FutureProvider.autoDispose<TodayView>(
  (ref) => ref.watch(todayRepositoryProvider).today(),
);

/// `open` (default), `done` or `all`.
final tasksStatusFilterProvider = StateProvider<String>((ref) => 'open');

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, PagedState<StudioTask>>(
      TasksNotifier.new,
    );

class TasksNotifier extends PagedNotifier<StudioTask> {
  TodayRepository get _repo => ref.read(todayRepositoryProvider);

  @override
  Future<StudioTaskPage> fetchPage(String? after) =>
      _repo.tasks(status: ref.watch(tasksStatusFilterProvider), after: after);

  StudioTask? _parse(Object? j) => j == null
      ? null
      : StudioTask.fromJson(Map<String, dynamic>.from(j as Map));

  /// Tick (or untick with `done: false`, or skip). The row changes at once.
  Future<void> tick(
    String id, {
    bool done = true,
    bool skipped = false,
    String? requestId,
  }) => mutate<StudioTask>(
    match: (t) => t.id == id,
    optimistic: (t) => t.copyWith(done: done && !skipped, skipped: skipped),
    call: () =>
        _repo.tick(id, done: done, skipped: skipped, requestId: requestId),
    toItem: (t) => t,
    fromCurrent: _parse,
  ).then((_) => null);

  Future<StudioTask> create({
    required String text,
    String? assignee,
    String? due,
    String? requestId,
  }) async {
    final t = await _repo.create(
      text: text,
      assignee: assignee,
      due: due,
      requestId: requestId,
    );
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncData(PagedState(items: [t, ...cur.items], next: cur.next));
    }
    return t;
  }
}
